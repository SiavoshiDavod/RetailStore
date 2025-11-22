# Vendor Service Specification

## 1. Purpose & Scope
Vendor Service مدیریت موجودیت‌های فروشندگان پلتفرم را بر عهده دارد؛ تمرکز اصلی بر پروفایل حقوقی، فروشگاه‌ها، محدوده‌های جغرافیایی، کاربران نماینده و اسناد تطبیق است. این سرویس در فاز اول ارتباطی با تأمین محصول (Supplier) یا حساب‌های بانکی ندارد و صرفاً مدیریت هویت و انطباق فروشندگان را پوشش می‌دهد.

---

## 2. Functional Requirements

### 2.1 Vendor Profile
- ایجاد و ویرایش پروفایل حقوقی شامل: نام رسمی، شناسه مالیاتی، شماره ثبت، آدرس دفتر مرکزی، اطلاعات تماس، لوگو و وضعیت انطباق.
- نگهداری وضعیت‌های چرخه‌عمر: `Draft`, `PendingReview`, `Approved`, `Suspended`, `Rejected`.
- ذخیره اطلاعات SLA و سطح خدمات توافق‌شده.

### 2.2 Vendor Stores
- تعریف چند فروشگاه برای هر Vendor، با مشخصات زیر:
  - `StoreName`, `StoreCode`, `ContactInfo`, `OpeningHours`.
  - آدرس پستی کامل با مختصات جغرافیایی (`GeoPoint`).
  - محدوده سرویس (Polygon یا Radius) جهت تعیین پوشش جغرافیایی.
  - وضعیت: `Inactive`, `Active`, `TemporarilyClosed`.
- پشتیبانی از نسخه‌بندی تغییرات فروشگاه و تاریخچه فعالیت.

### 2.3 Vendor Users (Agents)
- مدیریت کاربران مرتبط با Vendor:
  - نقش‌ها: `Owner`, `Manager`, `InventoryAgent`, `ComplianceAgent`.
  - تعیین دسترسی‌ها با اتصال به Auth Service (UserId خارجی).
  - نگهداری اطلاعات تماس و وضعیت فعال/غیرفعال.

### 2.4 Compliance Documents
- ثبت و مدیریت اسناد مورد نیاز (پروانه کسب، گواهی بهداشت، قراردادها و ...).
- Metadata: نوع سند، شماره/مرجع، تاریخ صدور و انقضا، وضعیت تأیید (`Pending`, `Approved`, `Rejected`).
- آپلود و ذخیره ارجاع فایل در Object Storage (مسیر/URL).
- اعلان تغییر وضعیت سند به Notification Service.

### 2.5 Workflows & Approvals
- گردش‌کار تأیید Vendor و فروشگاه‌ها با قابلیت درج یادداشت و پیگیری.
- ثبت تاریخچه عملیات (Audit Log) برای اقدامات کلیدی: ایجاد، ویرایش، تغییر وضعیت، تأیید/رد اسناد.

---

## 3. Non-Functional Requirements
- پاسخ‌دهی API < 500ms برای عملیات CRUD معمول.
- تحمل بار اولیه ~500 فروشنده و 2000 فروشگاه، مقیاس‌پذیر تا 10 برابر.
- امنیت: JWT، RBAC مبتنی بر Operationها، اعتبارسنجی ورودی و ضد تزریق.
- دسترسی‌پذیری 99.9%، لاگ و مانیتورینگ با OpenTelemetry.
- پشتیبان‌گیری و بازیابی مستقل دیتابیس Vendor.

---

## 4. Bounded Context & Integration
- **Upstream:** Auth Service (برای UserId و نقش‌ها)، Notification Service (اعلان‌ها)، Document Storage.
- **Downstream:** Product، Order، Delivery برای دریافت اطلاعات فروشگاه و پوشش جغرافیایی.
- **Events منتشرشده:** `VendorCreated`, `VendorStatusChanged`, `VendorStoreCreated`, `ComplianceDocumentApproved`.

---

## 5. Data Model (Simplified)

### 5.1 Tables (SQL Server Write Model)
| Table | Key Fields | Notes |
|-------|------------|-------|
| `Vendors` | `VendorId (PK)`, `LegalName`, `RegistrationNumber`, `TaxId`, `Status`, `HeadOfficeAddress`, `ContactEmail`, `ContactPhone`, `SlaTier`, `CreatedAt`, `UpdatedAt` | نسخه‌برداری کامل پروفایل |
| `VendorStores` | `StoreId (PK)`, `VendorId (FK)`, `StoreName`, `StoreCode`, `Status`, `GeoPoint`, `ServiceArea`, `AddressLine`, `City`, `PostalCode`, `ContactPhone`, `OpeningHours`, `CreatedAt`, `UpdatedAt` | `ServiceArea` به صورت GeoJSON |
| `VendorUsers` | `VendorUserId (PK)`, `VendorId (FK)`, `AuthUserId`, `Role`, `FullName`, `Mobile`, `Email`, `IsActive`, `CreatedAt` | نگهداری لینک به Auth |
| `ComplianceDocuments` | `DocumentId (PK)`, `VendorId (FK)`, `DocumentType`, `ReferenceNumber`, `IssueDate`, `ExpiryDate`, `Status`, `FileUrl`, `ReviewerUserId`, `ReviewedAt` | |
| `VendorAuditLogs` | `AuditId (PK)`, `EntityType`, `EntityId`, `Action`, `PerformedBy`, `PerformedAt`, `Payload` | ذخیره JSON تغییرات |

### 5.2 Read Model (PostgreSQL)
- Denormalized View برای لیست فروشندگان با آخرین وضعیت و شمار فروشگاه‌ها.
- نمای فروشگاه‌ها با هندسه جغرافیایی جهت کوئری شعاع/پلیگون.

---

## 6. API Endpoints (REST)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `POST` | `/api/vendor` | ایجاد Vendor جدید (Draft) | Admin |
| `GET` | `/api/vendor/{id}` | مشاهده جزئیات Vendor | Admin/VendorOwner |
| `PUT` | `/api/vendor/{id}` | ویرایش پروفایل | Admin/VendorOwner |
| `PATCH` | `/api/vendor/{id}/status` | تغییر وضعیت با دلیل | Admin |
| `POST` | `/api/vendor/{id}/stores` | افزودن فروشگاه | VendorManager |
| `PUT` | `/api/vendor/{id}/stores/{storeId}` | به‌روزرسانی فروشگاه | VendorManager |
| `PATCH` | `/api/vendor/{id}/stores/{storeId}/status` | فعال/غیرفعال کردن فروشگاه | Admin/VendorManager |
| `GET` | `/api/vendor/{id}/users` | لیست کاربران Vendor | VendorOwner |
| `POST` | `/api/vendor/{id}/users` | افزودن کاربر Vendor | VendorOwner |
| `PATCH` | `/api/vendor/{id}/users/{vendorUserId}` | تغییر نقش/وضعیت کاربر | VendorOwner |
| `POST` | `/api/vendor/{id}/documents` | آپلود متادیتای سند تطبیق | VendorComplianceAgent |
| `PATCH` | `/api/vendor/{id}/documents/{docId}/status` | تأیید/رد سند | Admin/ComplianceOfficer |
| `GET` | `/api/vendor` | جستجو/فیلتر فروشندگان (status, city, SLA) | Admin |
| `GET` | `/api/vendor/{id}/audit` | مشاهده تاریخچه اقدامات | Admin |

> تمام پاسخ‌ها شامل `ETag` برای همگام‌سازی خوشه‌ای و جلوگیری از Conflict است.

---

## 7. Messaging & Events
- **Outbox:** رویدادها پس از Commit ثبت می‌شوند و از طریق RabbitMQ منتشر می‌گردند.
- **نمونه رویداد:**
```json
{
  "eventName": "VendorStoreCreated",
  "eventId": "uuid",
  "occurredAt": "2025-11-22T10:15:30Z",
  "payload": {
    "vendorId": "VND-10045",
    "storeId": "STR-8891",
    "storeName": "Store Alborz",
    "geoPoint": { "lat": 35.715, "lng": 51.404 }
  }
}
```

---

## 8. Validation & Business Rules
- شناسه ثبت و مالیاتی باید یکتا باشد.
- هر Vendor حداقل یک `Owner` فعال.
- حداکثر 5 فروشگاه در وضعیت `PendingReview` همزمان (قابل پیکربندی).
- اسناد با تاریخ انقضای عبورکرده به صورت خودکار به وضعیت `Expired` تغییر می‌کنند و اعلان صادر می‌شود.
- فروشگاه فعال بدون حداقل یک سند تطبیق معتبر مجاز نیست (قانون قابل تنظیم).

---

## 9. Observability & Operations
- متریک‌ها: تعداد Vendorهای فعال، زمان تأیید متوسط، تعداد اسناد در انتظار، شمار فروشگاه‌های فعال بر مبنای شهر.
- لاگ‌ها با Serilog به PostgreSQL ارسال می‌شود؛ فیلدهای PII ماسک می‌شوند.
- Health Checks: اتصال SQL Server/PostgreSQL، دسترسی به RabbitMQ، دسترسی به Object Storage.

---

## 10. Deployment & Configuration
- سرویس مستقل .NET 8 (Web API) با پوشه‌بندی `Api`, `Application`, `Domain`, `Infrastructure`, `Tests`.
- پیکربندی قابل مدیریت از طریق `appsettings` و Secret Store (JWT، Connection Strings، Storage Keys).
- Dockerfile اختصاصی و سرویس در `docker-compose.local.yml`.
- تست‌های Unit/Integration در `src/services/VendorService.Tests`.

