-- Database: order_service_read

-- مدل خواندنی کامل سفارش (Denormalized برای سرعت 100ms)
CREATE TABLE orders_read (
    order_id            UUID PRIMARY KEY,
    order_number        TEXT,
    customer            JSONB NOT NULL,           -- {id, name, mobile}
    vendor              JSONB,                    -- {id, name, store}
    status              TEXT NOT NULL,
    payment_status      TEXT,
    total_amount        NUMERIC(18,0),
    final_amount        NUMERIC(18,0),
    delivery_type       TEXT,
    delivery_address    JSONB,
    items               JSONB[],                  -- آرایه آیتم‌ها
    timeline            JSONB[],                  -- آخرین وضعیت‌ها
    created_at          TIMESTAMPTZ,
    placed_at           TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- داشبورد لحظه‌ای (برای مانیتورینگ)
CREATE TABLE orders_dashboard (
    date_key            DATE PRIMARY KEY,
    total_orders        BIGINT DEFAULT 0,
    total_revenue       NUMERIC(20,0) DEFAULT 0,
    cancelled_orders    BIGINT DEFAULT 0,
    avg_delivery_time   INTERVAL,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- لاگ کامل رویدادها (برای دیباگ و گزارش‌گیری پیشرفته)
CREATE TABLE order_events_log (
    event_id            BIGSERIAL PRIMARY KEY,
    order_id            UUID NOT NULL,
    event_type          TEXT NOT NULL,  -- OrderCreated, StatusChanged, PaymentSucceeded, ...
    payload             JSONB NOT NULL,
    occurred_at         TIMESTAMPTZ NOT NULL,
    processed_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ایندکس‌های مهم Read
CREATE INDEX idx_orders_read_customer    ON orders_read((customer->>'id'));
CREATE INDEX idx_orders_read_vendor      ON orders_read((vendor->>'id'));
CREATE INDEX idx_orders_read_status      ON orders_read(status);
CREATE INDEX idx_orders_read_created     ON orders_read(created_at DESC);
CREATE INDEX idx_orders_read_number      ON orders_read(order_number);
CREATE INDEX idx_order_events_order      ON order_events_log(order_id, occurred_at DESC);
CREATE INDEX idx_order_events_type       ON order_events_log(event_type);