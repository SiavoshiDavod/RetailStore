-- Database: payment_service_read

-- موجودی کیف پول (برای نمایش سریع)
CREATE TABLE wallets_read (
    owner_id        UUID PRIMARY KEY,
    owner_type      TEXT NOT NULL,
    full_name       TEXT,
    mobile          TEXT,
    balance_irr     NUMERIC(18,0) DEFAULT 0,
    credit_limit    NUMERIC(18,0) DEFAULT 0,
    total_deposit   NUMERIC(18,0) DEFAULT 0,
    total_withdraw  NUMERIC(18,0) DEFAULT 0,
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- تراکنش‌های اخیر (آخرین 100 تراکنش هر کیف پول)
CREATE TABLE wallet_transactions_read (
    transaction_id  BIGINT PRIMARY KEY,
    wallet_owner_id UUID NOT NULL,
    amount          NUMERIC(18,0) NOT NULL,
    type            TEXT NOT NULL,
    description     TEXT,
    balance_after   NUMERIC(18,0),
    created_at      TIMESTAMPTZ NOT NULL
);

-- داشبورد مالی روزانه
CREATE TABLE payment_dashboard (
    date_key        DATE PRIMARY KEY,
    total_revenue   NUMERIC(20,0) DEFAULT 0,
    wallet_revenue  NUMERIC(20,0) DEFAULT 0,
    gateway_revenue NUMERIC(20,0) DEFAULT 0,
    refund_amount   NUMERIC(20,0) DEFAULT 0,
    transaction_count BIGINT DEFAULT 0,
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- لاگ کامل تراکنش‌ها (برای حسابرسی)
CREATE TABLE payment_audit_log (
    log_id          BIGSERIAL PRIMARY KEY,
    transaction_id  BIGINT,
    payment_id      UUID,
    event_type      TEXT NOT NULL,    -- WalletDeposit, PaymentFailed, RefundProcessed, ...
    payload         JSONB NOT NULL,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ایندکس‌ها
CREATE INDEX idx_wallets_read_balance    ON wallets_read(balance_irr DESC);
CREATE INDEX idx_wallet_tx_wallet_time   ON wallet_transactions_read(wallet_owner_id, created_at DESC);
CREATE INDEX idx_audit_event_type        ON payment_audit_log(event_type);