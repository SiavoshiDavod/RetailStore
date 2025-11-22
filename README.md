# README.md

## 1. معرفی پروژه
بازار خرده‌فروشی مواد غذایی یک پلتفرم میکروسرویسی است که خرید آنلاین محصولات غذایی، مدیریت فروشندگان و عملیات پشتیبانی را پوشش می‌دهد. این پروژه شامل:

- **Customer PWA** بر پایه **ASP.NET Core MVC + Razor Pages** با پشتیبانی PWA، RTL و چندزبانه/چندارزی
- سرویس‌های مستقل (Auth، Product، Order، Payment & Wallet، Delivery، Notification، Vendor)
- ارتباطات ناهمزمان با **RabbitMQ** و **CQRS** با Read Model در PostgreSQL
- استقرار کانتینری‌شده با Docker و آماده‌سازی CI/CD در GitHub

## 2. ساختار مخزن
```text
.
├── README.md
├── docs/
│   ├── architecture-overview.md
│   ├── business-plan-summary.md
│   ├── deployment-guide.md
│   ├── frontend-styleguide.md
│   └── api/
│       └── *.yaml
├── scripts/
│   ├── databases/<service>/*.sql
│   └── tests/
├── src/
│   ├── services/<ServiceName>.(Api|Application|Domain|Infrastructure|Tests)/
│   ├── integrations/
│   └── web/
│       ├── CustomerMvc/
│       ├── AdminPortal/
│       └── VendorPortal/
├── tests/
│   ├── end-to-end/
│   └── contracts/
├── docker/
│   ├── docker-compose.local.yml
│   ├── Dockerfile.*
│   └── env/*.env
└── .github/workflows/
```

## 3. پشته فناوری
| لایه | تکنولوژی |
|------|-----------|
| Backend | .NET 8، ASP.NET Core، CQRS |
| Frontend | ASP.NET Core MVC + Razor Pages (PWA) |
| Messaging | RabbitMQ |
| Databases | SQL Server (Write)، PostgreSQL (Read/Analytics) |
| Containerization | Docker، Docker Compose |
| API Gateway | YARP |
| Observability | OpenTelemetry، Serilog (logs → PostgreSQL) |
| CI/CD | GitHub Actions (غیرفعال تا زمان فعال‌سازی) |

## 4. سرویس‌ها
1. **Auth Service**: OTP، JWT، نقش‌ها و Operation/UserGroup.
2. **Product Service**: SKU، بارکد، موجودی، موتور تخفیف پنج‌گانه و Bulk Inventory Update.
3. **Order Service**: سفارش تک‌تأمین‌کننده، GeoPoint، هزینه حمل/بسته‌بندی، OrderCode/DeliveryCode.
4. **Payment & Wallet Service**: تراکنش‌ها با BankReference، درگاه‌ها، کیف پول چندارزی.
5. **Delivery Service**: CourierProvider، ProviderTrackingId، مدیریت بایکر و مرجوعی.
6. **Notification Service**: ایمیل، SMS، Webhook برای تمامی ذی‌نفعان.
7. **Vendor Service**: پروفایل حقوقی، فروشگاه‌ها، آژانس‌ها، اسناد تطبیق (بدون حساب بانکی).

## 5. Customer PWA (Razor)
- Layout RTL-first با انتخابگر زبان/ارز و Service Worker
- ViewComponent‌ها برای Featured Products، Campaigns، Announcements
- Snapshot Read Model از PostgreSQL برای پاسخ‌گویی زیر ۱ ثانیه
- تست UI با Playwright

## 6. راه‌اندازی سریع

### 6.1 پیش‌نیازها
- Docker Desktop 4.x
- .NET SDK 8.0
- Node.js 20.x (برای پورتال‌های React در صورت نیاز)
- PowerShell یا Bash

### 6.2 پیکربندی متغیرهای محیطی
فایل‌های `.env` در `docker/env/` را با مقادیر مناسب (Connection Strings، JWT secrets، SMTP و …) پر کنید.

### 6.3 اجرای محیط محلی
```bash
docker compose -f docker/docker-compose.local.yml up -d
```
سرویس‌ها پس از بالا آمدن از طریق YARP در `https://localhost:5001` قابل دسترس هستند. Customer MVC روی `https://localhost:7001`.

### 6.4 اجرای تست‌ها
**Backend**
```bash
dotnet test src/services/AuthService.Tests/AuthService.Tests.csproj
```
**Playwright (Customer Journey)**
```bash
cd tests/end-to-end
npx playwright test
```

## 7. گردش توسعه
1. ایجاد Branch جدید از `main`.
2. اجرای تست‌های واحد/یکپارچه (`scripts/tests/*.ps1`).
3. به‌روزرسانی مستندات مرتبط در `docs/`.
4. Pull Request با لینک به نیازمندی/Issue و نتایج تست.

## 8. CI/CD (غیرفعال)
| Workflow | مسیر | توضیح |
|----------|------|-------|
| Backend CI | `.github/workflows/backend-ci.yml` | build/test سرویس‌های .NET، تولید image |
| Frontend MVC CI | `.github/workflows/frontend-mvc-ci.yml` | build/test CustomerMvc |
| Docker Publish | `.github/workflows/docker-publish.yml` | ارسال تصاویر به Registry |

> برای فعال‌سازی، triggers را از `on: workflow_dispatch` به رویداد دلخواه تغییر دهید و Secrets را در GitHub تنظیم کنید.

## 9. مستندات کلیدی
- **معماری**: `docs/architecture-overview.md`
- **نیازمندی‌ها**: `docs/business-plan-summary.md`
- **راهنمای استقرار**: `docs/deployment-guide.md`
- **API Contracts**: `docs/api/*.yaml`
- **سبک UI/UX**: `docs/frontend-styleguide.md`

## 10. مجوز و پشتیبانی
- مجوز پروژه (در صورت نیاز) در `LICENSE` درج می‌شود.
- پرسش‌ها و باگ‌ها را از طریق Issues در GitHub مطرح کنید.