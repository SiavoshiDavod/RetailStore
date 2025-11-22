# README.md – بازار خرده‌فروشی مواد غذایی

## معرفی پروژه
پلتفرم بازار خرده‌فروشی مواد غذایی یک سامانه‌ی میکروسرویسی است که به مشتریان اجازه می‌دهد محصولات غذایی را به‌صورت آنلاین خریداری کنند، فروشندگان شعب و کالاهای خود را مدیریت نمایند و مدیران بر کل اکوسیستم نظارت داشته باشند. سامانه از چندزبانگی، چندارزی، کیف پول، جشنواره‌های فروش، صفحات اطلاع‌رسانی و یک PWA مشتری‌محور بهره می‌برد.

---

## معماری و فناوری‌ها
- **Backend**: ASP.NET Core 8، معماری Clean، CQRS و Event-Driven  
- **Frontend**: React/TypeScript برای Admin Portal، Supplier (Vendor) Portal و Customer PWA  
- **پیام‌رسان**: RabbitMQ برای ارتباط ناهمزمان  
- **داده**: SQL Server (نوشتن تراکنش‌ها)، PostgreSQL (خواندن/تحلیل، لاگ‌ها، Snapshot صفحه اصلی)  
- **Gateway**: YARP  
- **کانتینر**: Docker برای توسعه محلی و استقرار  
- **احراز هویت**: JWT + OTP موبایل  
- **الگوهای اصلی**: Database per Service، Outbox، Saga، Service Mesh-ready

---

## سرویس‌ها و مسئولیت‌ها
1. **Auth Service**: عملیات احراز هویت، Operation/UserGroup، OTP موبایل، JWT داخلی/خارجی  
2. **Product Service**: مدیریت SKU، بارکد، موجودی Available/Reserved، تخفیف‌های پنج‌گانه، Bulk Inventory Update  
3. **Order Service**: سفارش تک‌تأمین‌کننده، هزینه حمل/بسته‌بندی، OrderCode، DeliveryCode، DiscountBreakdown  
4. **Payment & Wallet Service**: تراکنش‌ها با BankReference، Gateway، کیف پول با دفترکل امن  
5. **Delivery Service**: مدیریت CourierProvider، ProviderTrackingId، اطلاعات بایکر و یکپارچگی سرویس‌های حمل  
6. **Notification Service**: ارسال ایمیل/SMS/Webhook برای مشتری، مدیر، فروشنده، پشتیبان، بایکر  
7. **Vendor Service**: پروفایل فروشندگان، فروشگاه‌ها، Vendor Agents، Compliance Documents (بدون VendorBankAccount)  
8. **Campaign Service**: کمپین‌ها، کدهای تخفیف، جشنواره‌های فروش، اتصال به صفحه اصلی  
9. **Homepage Aggregation**: تجمیع محصولات تامین‌کننده پیش‌فرض، کمپین‌ها و اطلاعیه‌ها برای نمایش در Customer PWA

---

## ساختار مخزن
retail-marketplace/
├── README.md
├── docs/
│   ├── architecture-overview.md
│   ├── homepage-content-spec.md
│   ├── vendor-service-spec.md
│   ├── notification-spec.md
│   └── decision-records/
│       ├── adr-004-vendor-vs-supplier.md
│       └── adr-005-homepage-content-engine.md
├── docker/
│   ├── docker-compose.local.yml
│   ├── docker-compose.tests.yml
│   └── otel-collector-config.yaml
├── scripts/
│   ├── databases/
│   │   ├── sqlserver/
│   │   │   ├── auth-schema.sql
│   │   │   ├── product-schema.sql
│   │   │   ├── campaign-schema.sql
│   │   │   ├── vendor-schema.sql
│   │   │   ├── order-schema.sql
│   │   │   ├── payment-schema.sql
│   │   │   ├── delivery-schema.sql
│   │   │   └── notification-schema.sql
│   │   └── postgres/
│   │       ├── product-read-schema.sql
│   │       ├── order-read-schema.sql
│   │       └── homepage-read-schema.sql
│   ├── seed/
│   │   ├── product/
│   │   ├── campaign/
│   │   └── notification/
│   └── tools/
│       └── install-dotnet.ps1
├── src/
│   ├── gateway/YarpGateway/
│   ├── services/
│   │   ├── AuthService/
│   │   ├── ProductService/
│   │   ├── OrderService/
│   │   ├── PaymentWalletService/
│   │   ├── DeliveryService/
│   │   ├── NotificationService/
│   │   ├── VendorService/
│   │   └── CampaignService/
│   ├── web/
│   │   ├── admin-portal/
│   │   ├── supplier-portal/
│   │   └── customer-pwa/
│   └── shared/
│       ├── BuildingBlocks/
│       ├── Common/
│       └── Contracts/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── ui/
└── .github/workflows/
    ├── backend-ci.yml
    ├── frontend-ci.yml
    └── docker-publish.yml


---

## راه‌اندازی سریع (Development)
### پیش‌نیازها
- .NET SDK 8
- Node.js 20+
- Docker Desktop
- SQL Server و PostgreSQL ران‌شده در Docker (از طریق compose)

### مراحل
```bash
# 1. کلون ریپو
git clone https://github.com/<USERNAME>/retail-marketplace.git
cd retail-marketplace

# 2. اجرای وابستگی‌ها
docker compose -f docker/docker-compose.local.yml up -d

# 3. اعمال اسکریپت‌ها
./scripts/tools/install-dotnet.ps1       # در ویندوز اختیاری
dotnet tool restore

# 4. ساخت سرویس‌ها
dotnet build retail-marketplace.sln

# 5. اجرای سرویس‌ها (مثال)
cd src/services/ProductService/ProductService.Api
dotnet run
```

برای فرانت‌اندها:
```bash
cd src/web/customer-pwa
npm install
npm run dev
```

---

## دیتابیس و Seed
1. اجرای اسکریپت‌های SQL Server و PostgreSQL از مسیر `scripts/databases`.  
2. استفاده از فایل‌های Seed (`scripts/seed/*`) برای ایجاد داده‌های اولیه مانند محصولات Featured، کمپین‌ها و اعلان‌های عمومی.  
3. Snapshot صفحه اصلی در جدول `homepage_snapshot` ذخیره می‌شود تا پاسخ‌دهی سریع API تضمین گردد.

---

## صفحه اصلی (Homepage)
- **Featured Products**: فیلتر شده بر اساس Supplier پیش‌فرض، تخفیف نهایی محاسبه‌شده در Product Service.  
- **Campaign Carousel**: داده از Campaign Service؛ امکان شمارش‌گر معکوس و لینک به صفحهٔ فروش ویژه.  
- **Public Announcements**: محتوای اطلاعیه‌ها از Notification Service با هدایت به جزئیات.  
- **Caching**: Service Worker برای کش استاتیک، React Query برای داده‌های پویا، Snapshot Postgres برای پاسخ سریع.  
- **RTL/L10n**: پشتیبانی کامل فارسی، عربی، اردو (RTL) و انگلیسی، ترکی (LTR) با انتخابگر زبان/ارز.

---

## تست و کیفیت
- تست‌های واحد برای دامنه هر سرویس در `tests/unit`.  
- تست‌های یکپارچگی (SQL Server + RabbitMQ) با Testcontainers در `tests/integration`.  
- تست‌های UI PWA در `tests/ui`.  
- پوشش هدف: 85٪ حداقل.  
- تست‌های Contract برای API Gateway و مصرف‌کنندگان در `tests/contract`.

اجرای نمونه:
```bash
dotnet test retail-marketplace.sln
npm run test --prefix src/web/customer-pwa
```

---

## CI/CD
- فایل‌های GitHub Actions در `.github/workflows/` شامل build backend، build frontend و انتشار Docker.  
- طبق الزامات فعلی، Workflowها فقط در ریپو قرار دارند و اجرای خودکارشان غیرفعال است؛ پس از انتقال به ریپوی عمومی می‌توان آن‌ها را فعال/تنظیم کرد.

---

## امنیت و انطباق
- TLS اجباری، ذخیره‌سازی امن Secretها، JWT و Rate Limiting.  
- مدیریت دسترسی مبتنی بر Operation/UserGroup.  
- Data Retention، پشتیبان‌گیری منظم، انطباق با GDPR و الزامات داخلی.  
- Logging متمرکز در PostgreSQL، مانیتورینگ با OpenTelemetry و داشبورد مرکزی.

---

## نقشهٔ راه
- توسعه سیستم توصیه‌گر شخصی‌سازی‌شده برای Homepage.  
- اضافه‌کردن سرویس Supplier مستقل در فاز بعدی در صورت نیاز.  
- پیاده‌سازی Feature Flag برای کمپین‌های آزمایشی.  
- یکپارچه‌سازی Retail Integration Service برای فروشگاه‌های زنجیره‌ای بزرگ.  
- خودکارسازی کامل CI/CD پس از استقرار محیط‌های بالاتر.

---

## مجوز و مشارکت
- مجوز پروژه پس از انتقال به GitHub عمومی مشخص می‌شود (پیشنهاد: MIT یا Apache 2.0).  
- برای مشارکت، Pull Request با توضیح کامل و تست‌های مرتبط ارسال شود.  
- مستندات کامل در پوشه `docs/` موجود است.