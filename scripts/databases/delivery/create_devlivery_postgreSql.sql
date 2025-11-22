-- Database: delivery_service_read

-- مدل خواندنی کامل مأموریت تحویل (Denormalized برای سرعت)
CREATE TABLE deliveries_read (
    delivery_id         UUID PRIMARY KEY,
    order_id            UUID NOT NULL,
    provider_code       TEXT,
    tracking_code       TEXT,
    status              TEXT NOT NULL,
    courier             JSONB,           -- {id, name, phone, vehicle}
    pickup              JSONB,           -- {address, city, geo: {lat,lng}}
    dropoff             JSONB,
    contact             JSONB,
    cost_irr            NUMERIC(18,0),
    timeline            JSONB,           -- آخرین رویدادها
    events              JSONB[],         -- آرایه‌ای از رویدادها (آخرین ۱۰ تا)
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- وضعیت لحظه‌ای بایکرها (برای داشبورد)
CREATE TABLE couriers_live (
    courier_id          UUID PRIMARY KEY,
    full_name           TEXT,
    phone               TEXT,
    vehicle_type        TEXT,
    status              TEXT,
    current_location    POINT,           -- (lng, lat)
    active_delivery_id  UUID,
    last_seen_at        TIMESTAMPTZ DEFAULT NOW()
);

-- لاگ‌های کامل رویداد (فقط PostgreSQL – حجم بالا)
CREATE TABLE delivery_events_log (
    event_id            BIGSERIAL PRIMARY KEY,
    delivery_id         UUID NOT NULL,
    event_code          TEXT NOT NULL,
    occurred_at         TIMESTAMPTZ NOT NULL,
    source              TEXT,
    location            POINT,
    metadata            JSONB,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ایندکس‌های مهم Read
CREATE INDEX idx_deliveries_read_status       ON deliveries_read(status);
CREATE INDEX idx_deliveries_read_order        ON deliveries_read(order_id);
CREATE INDEX idx_deliveries_read_provider     ON deliveries_read(provider_code);
CREATE INDEX idx_deliveries_read_updated      ON deliveries_read(updated_at DESC);
CREATE INDEX idx_couriers_live_status         ON couriers_live(status);
CREATE INDEX idx_couriers_live_location       ON couriers_live USING GIST (current_location);
CREATE INDEX idx_events_log_delivery_time     ON delivery_events_log(delivery_id, occurred_at DESC);
CREATE INDEX idx_events_log_code              ON delivery_events_log(event_code);