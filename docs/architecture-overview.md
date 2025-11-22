# Architecture Overview

## 1. Vision & Scope
- **Domain**: بازار خرده‌فروشی مواد غذایی با تمرکز بر سفارش آنلاین، مدیریت فروشندگان و عملیات تحویل.
- **اهداف کلان**:
  - تجربه خرید سریع (بارگذاری صفحه < ۳ ثانیه) برای ≥۱۰٬۰۰۰ کاربر همزمان.
  - پشتیبانی کامل از چند زبان/چند ارز و رابط RTL پیش‌فرض.
  - معماری میکروسرویسی مبتنی بر CQRS، مقیاس‌پذیر و قابل مشاهده‌پذیری کامل.
  - آماده‌سازی کامل برای CI/CD و استقرار کانتینری.

---

## 2. فناوری‌ها و لایه‌ها
| لایه | فناوری‌ها |
|------|------------|
| Backend | .NET 8، ASP.NET Core، CQRS، EF Core |
| Frontend | **ASP.NET Core MVC + Razor Pages** (PWA) |
| API Gateway | YARP |
| Messaging | RabbitMQ |
| پایگاه‌داده | SQL Server (نوشتن)، PostgreSQL (خواندن، آنالیتیکس، لاگ) |
| Containerization | Docker، Docker Compose |
| Observability | OpenTelemetry، Serilog (لاگ در PostgreSQL)، Dashboards |
| CI/CD | GitHub Actions (workflowهای آماده و غیرفعال) |

---

## 3. معماری کلان
- **Microservices + CQRS**: هر سرویس پایگاه‌داده مستقل و الگوی Outbox برای انتشار رویدادها.
- **Event-Driven**: تبادل رویدادها و فرمان‌ها از طریق RabbitMQ (مثلاً `OrderCreated`, `PaymentCaptured`).
- **API Gateway (YARP)**: نقطه ورودی واحد برای احراز هویت، مسیریابی، Rate Limiting.
- **Read Models**: پردازش رویدادها و ساخت Snapshot در PostgreSQL جهت پاسخ‌دهی سریع وب‌سایت.
- **Security**: ارتباطات TLS، JWT داخلی/خارجی، OTP روی موبایل، محافظت OWASP Top 10، مدیریت Secret.

---

## 4. سرویس‌ها و مسئولیت‌ها
| سرویس | شرح |
|-------|-----|
| **Auth Service** | ثبت‌نام، OTP، JWT (داخلی/خارجی)، نقش‌ها (SystemAdmin, Supplier, OrderSupport, Customer)، نگاشت Operation ↔ UserGroup برای منوها. |
| **Product Service** | SKU، بارکد، موجودی (Available/Reserved)، محاسبه قیمت نهایی با ۵ نوع تخفیف (`Supplier`, `Campaign`, `System`, `Customer`, `Order`)، Bulk Update Inventory. |
| **Order Service** | سفارش تک‌تأمین‌کننده با `SupplierId` و `GeoPoint`، هزینه حمل/بسته‌بندی، `OrderCode` و `DeliveryCode`. |
| **Payment & Wallet Service** | تراکنش‌های بانکی/کیف پول، نگهداری `BankReference`, Gateway، دفتر کل کیف پول چندارزی. |
| **Delivery Service** | مدیریت CourierProvider، `ProviderTrackingId`، بایکرها، عملیات تحویل/بازگشت، اتصال به Snapp Box، Miare، Alopeyk، Tapsi. |
| **Notification Service** | ارسال ایمیل/SMS/Webhook برای مشتری، مدیر، پشتیبان، فروشنده، بایکر؛ اعلان‌های عمومی برای صفحه اصلی. |
| **Vendor Service** | پروفایل حقوقی، فروشگاه‌ها (آدرس و محدوده جغرافیایی)، Vendor Agents، اسناد تطبیق (حذف حساب بانکی). |
| **Campaign Service** | مدیریت جشنواره‌ها، Featured Products، شمارش معکوس، انتشار رویداد. |
| **Reporting Service** | گزارش‌گیری و داشبوردها با PostgreSQL. |
| **Retail Integration Service** | (آماده توسعه) اتصال به زنجیره‌های خرده‌فروشی، همگام‌سازی موجودی و سفارش. |
| **Homepage Aggregator** | گردآوری محصولات منتخب، کمپین‌ها، اعلان‌ها و ایجاد Snapshot در PostgreSQL برای PWA. |

---

## 5. جریان‌های کلیدی

### 5.1 سفر مشتری
1. درخواست `/api/homepage` → YARP → Homepage Aggregator → Snapshot Postgres.
2. جستجو و مرور محصول با استفاده از Read Model در Postgres (RT < ۱ ثانیه).
3. ثبت سفارش → Order Service (SQL Server) → رویداد `OrderCreated`.
4. پرداخت → Payment & Wallet → رویداد `PaymentSucceeded`.
5. تحویل → Delivery Service (انتخاب Courier، `ProviderTrackingId`).
6. اعلان‌ها → Notification Service (SMS/Email/Webhook/Announcement).

### 5.2 عملیات فروشنده
- مدیریت پروفایل و فروشگاه در Vendor Service.
- مدیریت موجودی/محصول در Product Service (API + Bulk Update).
- پردازش سفارش‌های تک‌تأمین‌کننده در Order Service.
- مانیتورینگ کیف پول و پرداخت‌های تسویه در Payment Service.

### 5.3 مدیریت سیستم
- دسترسی از Admin Portal به Auth, Product, Order, Vendor.
- مدیریت نقش‌ها و Operationها.
- ایجاد کمپین‌ها و اعلان‌ها.
- مشاهده گزارش‌ها و Dashboardها از Reporting Service.

---

## 6. Customer PWA (ASP.NET Core MVC + Razor)
- **Layout RTL-first** با انتخابگر زبان/ارز، هدر چسبنده، ناوبری Mega Menu.
- **ViewComponents**: `FeaturedProducts`, `CampaignCarousel`, `PublicAnnouncements`.
- **PWA**: Service Worker، Offline Cache، Manifest و Install Prompt.
- **Localization**: `IStringLocalizer`، Resourceهای فارسی/عربی/انگلیسی/ترکی/اردو.
- **Styling**: رنگ آبی کاربنی (#2A2A81) + طلایی (#F9A825) + پس‌زمینه کرم (#FFF8E1)، فونت وزیر/شبنم، کارت‌های گوشه‌گرد ۱۰px.
- **Testing**: Playwright/Selenium برای سناریوهای End-to-End.

---

## 7. داده و ذخیره‌سازی
- **SQL Server**: برای Write Model هر سرویس با طرح جداگانه (`auth`, `product`, …).
- **PostgreSQL**:
  - Read Models (Product، Order، Homepage Snapshot).
  - لاگ‌های ساخت‌یافته و Analytics.
- **Backup & Replication**: سیاست‌گذاری برای SQL Server و PostgreSQL، پشتیبان‌گیری خودکار و بازگردانی.
- **Data Retention**: چرخه حیات داده، انطباق با GDPR.

---

## 8. پیام‌رسانی و یکپارچگی
- **RabbitMQ**:
  - تبادل رویدادها (`topic exchange`).
  - صف فرمان‌ها برای عملیات همزمان (مثلاً Delivery Commands).
- **Outbox Pattern**: انتشار تضمینی رویدادها از پایگاه‌داده تراکنشی.
- **Integration**:
  - درگاه‌های پرداخت خارجی.
  - SMS/Email Providers.
  - Google Maps API برای Geo و نقشه.
  - سرویس‌های حمل (Snapp Box, Miare, Alopeyk, Tapsi).
  - API شرکت‌های خرده‌فروشی (رفاه، اتکا، شهروند، هایپراستار).

---

## 9. امنیت و تطبیق
- TLS/SSL برای تمام ارتباطات.
- JWT + OTP (موبایل/ایمیل)، Rate Limiting در Gateway.
- ممنوعیت حملات OWASP Top 10 (Input Validation، CSRF، XSS).
- Secret Management (Azure Key Vault/HashiCorp Vault).
- نقش‌های مجزا برای SystemAdmin، Supplier، OrderSupport، Customer.
- سیاست دسترسی مبتنی بر Operation/UserGroup.
- انطباق با GDPR، مدیریت داده‌های حساس و رمزنگاری در حالت سکون.

---

## 10. عملکرد و مقیاس‌پذیری
- بارگذاری صفحه < ۳ ثانیه، API زیر ۱ ثانیه (برای خواندن).
- مقیاس‌پذیری افقی برای هر سرویس (Stateless).
- محدودیت اتصال در Gateway، استفاده از Polly برای Circuit Breaker/Retry.
- کش سمت سرویس (Memory Cache/Redis اختیاری) برای داده‌های پرمصرف.
- Service Worker برای کش سمت کلاینت.

---

## 11. مشاهده‌پذیری و عملیات
- **Logging**: Serilog → PostgreSQL + Dashboards.
- **Metrics**: OpenTelemetry → Prometheus-compatible؛ سنجه‌های latency، error rate، queue depth.
- **Tracing**: Distributed tracing از Gateway تا سرویس‌ها با Correlation ID.
- **Alerting**: بر اساس SLA/SLO، مصرف CPU/RAM، lag صف‌ها.
- **Runbooks**: دستورات اضطراری برای پاک‌سازی صف، بازسازی read model، Rollback دیتابیس.

---

## 12. استقرار و CI/CD
- **محیط توسعه**: Docker Compose (SQL Server، PostgreSQL، RabbitMQ، سرویس‌ها، Customer MVC).
- **پکیج Docker**: Dockerfile اختصاصی برای هر سرویس + Customer MVC.
- **GitHub Actions** (غیرفعال):
  - `backend-ci.yml`: dotnet restore/build/test + build image.
  - `frontend-mvc-ci.yml`: build/test Customer MVC.
  - `docker-publish.yml`: انتشار تصاویر.
- **پشته استقرار**: Dev → Staging → Prod با کانفیگ جداگانه، Secrets از Vault، قابلیت ارتقاء به Kubernetes.

---

## 13. آینده و توسعه‌های بعدی
- اتوماسیون کامل CI/CD پس از آماده‌سازی Secrets.
- موتور شخصی‌سازی پیشنهادها (AI/ML) برای صفحه اصلی.
- بازگرداندن Supplier Service در صورت نیاز به تفکیک فراتر از Vendor.
- افزایش یکپارچگی با Courier و Retail Partners.
- Feature Flag برای کمپین‌ها و آزمایش‌های UI.

