## Architecture Overview

### 1. Vision and Scope
- **Domain**: Retail food marketplace providing multi-vendor, multi-branch operations with customer PWA, admin portal, and vendor portal.
- **Objectives**:
  - Fast, reliable shopping experience (<3s page load, ≥10k concurrent users).
  - Multi-lingual, multi-currency support; RTL-first UX.
  - Full observability, CI/CD ready, modular microservices that scale independently.
  - Event-driven backbone for consistency across services.

---

### 2. High-Level Architecture
- **Pattern**: Microservices with CQRS, database per service, event-driven integration.
- **Transport**:
  - HTTP/REST via **YARP API Gateway**.
  - Async messaging via **RabbitMQ** (events + commands).
- **Data Stores**:
  - **SQL Server** for transactional/write workloads (one schema per service).
  - **PostgreSQL** for read models, analytics, centralized logging, homepage snapshots.
- **Runtime**:
  - **.NET 8** services containerized with Docker.
  - Local orchestration via `docker-compose`, production-ready for K8s.
- **Security**:
  - TLS for transport, JWT for auth, OTP via SMS/email, rate limiting, secret management.
- **Observability**:
  - OpenTelemetry exporters, centralized logs in PostgreSQL, dashboards for uptime and SLA.

---

### 3. Service Inventory & Responsibilities
| Service | Key Responsibilities | Datastore |
|---------|---------------------|-----------|
| **Auth Service** | User accounts, OTP, JWT, Operation ↔ UserGroup mapping, role-based access (SystemAdmin, Supplier, OrderSupport, Customer). | SQL Server `auth-schema` |
| **Product Service** | SKU & barcode management, available/reserved stock, discount engine (`Supplier`, `Campaign`, `System`, `Customer`, `Order`), bulk inventory API. | SQL Server `product-schema`, Postgres read model |
| **Order Service** | Single-supplier orders, supplier/customer GeoPoint, shipping & packing cost, `OrderCode`, `DeliveryCode`, line-level discount breakdown. | SQL Server `order-schema`, Postgres read |
| **Payment & Wallet Service** | Wallet ledger, bank transactions with `BankReference`, gateway metadata, refunds. | SQL Server `payment-schema` |
| **Delivery Service** | Courier providers, `ProviderTrackingId`, rider info, ship/return workflows. | SQL Server `delivery-schema` |
| **Notification Service** | Email/SMS/Webhook dispatch for customers, vendors, admins, bikers. Public announcements for homepage. | SQL Server `notification-schema` |
| **Vendor Service** | Vendor legal profiles, stores (geo coverage), vendor agents, compliance documents. | SQL Server `vendor-schema` |
| **Campaign Service** | Campaign lifecycle, featured products, countdown promos, event publication. | SQL Server `campaign-schema` |
| **Homepage Aggregator** | Collects featured products (default supplier), campaigns, notifications; writes snapshot to Postgres for PWA. | PostgreSQL `homepage_snapshot` |
| **Retail Integration Service** (future) | Connects external retail chains for inventory/order syncing. | TBD |
| **Reporting Service** | Aggregated analytics, dashboard feeds (leverages Postgres). | PostgreSQL |

---

### 4. Data Flow Summary

1. **Customer Journey**:
   - PWA calls `/api/homepage` (YARP → Homepage Aggregator).
   - Aggregator fetches Product/Campaign/Notification APIs, writes Postgres snapshot.
   - Customer searches products (Product Service read model in Postgres) and adds to cart (Cart handled client-side / session service).
   - Checkout triggers Order Service (writes to SQL Server), emits `OrderCreated`.
   - Payment Service processes wallet/bank, emits `PaymentSucceeded`.
   - Delivery Service assigns courier, updates status via events.
   - Notification Service sends updates (SMS/email/webhook) on order and delivery milestones.

2. **Vendor Operations**:
   - Vendor Portal hits Vendor Service for profile, Product Service for listings, Order Service for fulfillment queues.
   - Bulk inventory updates via Product API; events propagate to read models.

3. **Admin Operations**:
   - Admin Portal manages campaigns, announcements, user roles.
   - CRUD actions stored in respective services; changes broadcast via RabbitMQ for syncing caches/read models.

---

### 5. Integration Patterns
- **YARP API Gateway**: unified ingress, TLS termination, routing to microservices, rate limiting, auth enforcement.
- **RabbitMQ**:
  - Domain events (`ProductStockAdjusted`, `OrderPlaced`, `PaymentCaptured`, `DeliveryStatusChanged`, `CampaignPublished`, `PublicNotificationUpdated`).
  - Integration commands (e.g., Delivery Service command queue).
- **Outbox Pattern**: each service persists events in SQL Server outbox table, background dispatcher publishes to RabbitMQ to guarantee delivery.
- **Read Models**: Event processors project SQL Server writes into PostgreSQL for fast reads (Product, Order, Homepage).

---

### 6. Deployment & Infrastructure
- **Local**: `docker-compose.local.yml` spins up SQL Server, Postgres, RabbitMQ, services, gateways.
- **CI Pipelines** (prepared, not active):
  - `.github/workflows/backend-ci.yml`: dotnet build/test, image build.
  - `.github/workflows/frontend-ci.yml`: Node build/test/lint for portals + PWA.
  - `.github/workflows/docker-publish.yml`: build & push service images.
- **Environment Promotion**: Dev → Staging → Prod with configuration per service; secrets managed via environment vault (e.g., Azure Key Vault/HashiCorp Vault). 

---

### 7. Non-Functional Requirements
- **Performance**: homepage API < 1s via snapshot + caching; overall page load < 3s.
- **Scalability**: horizontal scaling per service; stateless compute with sticky sessions avoided.
- **Availability**: target 99.9%; health probes + circuit breakers (Polly) per service.
- **Security & Compliance**:
  - TLS/SSL enforced, JWT auth, OTP, OWASP Top 10 protections, rate limiting, GDPR alignment.
  - Secure secret storage, encrypted databases at rest, replication + automated backups.

---

### 8. Observability & Operations
- **Logging**: structured logs (Serilog) shipped to PostgreSQL + centralized dashboard.
- **Metrics**: Prometheus-compatible exporters (via OpenTelemetry) for request latency, error rates, queue depth.
- **Tracing**: Distributed tracing across gateway + services for request correlation.
- **Alerting**: thresholds on availability (SLO), RabbitMQ lag, service CPU/memory.
- **Data Retention**: policies for transactional data, audit logs, and customer data lifecycle.

---

### 9. Future Enhancements
- Supplier Service reintroduction (if business requires supplier-specific workflows distinct from vendors).
- Personalization engine for homepage recommendations.
- Full automation of CI/CD pipelines post repository migration.
- Integration with additional third-party couriers and retail chains.
- Feature flags for staged rollout of campaigns and UI experiments.
