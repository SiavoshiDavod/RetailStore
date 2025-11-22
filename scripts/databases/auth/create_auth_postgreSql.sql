-- Database: auth_service_read
-- تمام داده‌ها از طریق Kafka/Debezium یا Event Handler از SQL Server می‌آیند

CREATE TABLE users_read (
    user_id         UUID        PRIMARY KEY,
    full_name       TEXT,
    mobile          TEXT        UNIQUE,
    email           TEXT,
    user_type       TEXT,
    status          TEXT,
    groups          TEXT[],     -- ['Customer','VendorOwner']
    permissions     TEXT[],     -- ['order.manage','product.manage',...]
    menu_json       JSONB,      -- منوی کامل تودرتو
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- منوی داینامیک (یک رکورد برای هر کاربر – به‌روز می‌شود با هر تغییر گروه)
CREATE TABLE user_menus (
    user_id         UUID PRIMARY KEY,
    menu            JSONB NOT NULL,  -- ساختار درختی کامل
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- لاگ‌های امنیتی و فعالیت (فقط PostgreSQL – حجم بالا)
CREATE TABLE auth_audit_logs (
    log_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID,
    action          TEXT NOT NULL,        -- LoginSuccess, RoleChanged, OTPFailed, ...
    ip_address      INET,
    user_agent      TEXT,
    device_info     JSONB,
    details         JSONB,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- لاگ‌های Event Sourcing (اختیاری – برای دیباگ کامل)
CREATE TABLE auth_events (
    event_id        BIGSERIAL PRIMARY KEY,
    aggregate_id    UUID NOT NULL,        -- UserId یا GroupId
    aggregate_type  TEXT NOT NULL,        -- User, UserGroup, Operation
    event_type      TEXT NOT NULL,        -- UserRegistered, GroupAssigned, OperationGranted
    payload         JSONB NOT NULL,
    metadata        JSONB,
    occurred_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ایندکس‌های مهم Read
CREATE INDEX idx_users_read_mobile      ON users_read(mobile);
CREATE INDEX idx_users_read_permissions ON users_read USING GIN(permissions);
CREATE INDEX idx_audit_logs_action_time ON auth_audit_logs(action, created_at DESC);
CREATE INDEX idx_auth_events_agg_type   ON auth_events(aggregate_type, aggregate_id);