-- Database: notification_service_read

-- پیام‌های در انتظار ارسال (برای Workerها)
CREATE TABLE notification_queue (
    queue_id        BIGSERIAL PRIMARY KEY,
    notification_id UUID NOT NULL,
    channel         TEXT NOT NULL,
    priority        INT NOT NULL DEFAULT 3, -- 1=Critical, 5=Low
    user_id         UUID NOT NULL,
    recipient       TEXT,                   -- شماره موبایل یا ایمیل یا FCM token
    subject         TEXT,
    body            TEXT,
    data            JSONB,
    retry_count     INT DEFAULT 0,
    next_retry_at   TIMESTAMPTZ,
    locked_until    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- پیام‌های خوانده‌شده کاربر (In-App)
CREATE TABLE user_notifications (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL,
    title           TEXT NOT NULL,
    body            TEXT,
    data            JSONB,
    is_read         BOOLEAN DEFAULT FALSE,
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- داشبورد آماری
CREATE TABLE notification_stats (
    date_key        DATE PRIMARY KEY,
    channel         TEXT NOT NULL,
    total_sent      BIGINT DEFAULT 0,
    total_delivered BIGINT DEFAULT 0,
    total_failed    BIGINT DEFAULT 0,
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ایندکس‌های مهم
CREATE INDEX idx_queue_priority_nextretry ON notification_queue(priority, next_retry_at) 
    WHERE locked_until IS NULL OR locked_until < NOW();
CREATE INDEX idx_queue_user ON notification_queue(user_id);
CREATE INDEX idx_user_notifs_user_read ON user_notifications(user_id, is_read, created_at DESC);