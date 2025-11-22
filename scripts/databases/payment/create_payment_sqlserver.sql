-- Database: PaymentService_WriteDb
USE PaymentService_WriteDb;
GO

-- درگاه‌های پرداخت
CREATE TABLE dbo.PaymentGateways (
    GatewayCode     VARCHAR(50)     PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    BaseUrl         VARCHAR(255)    NOT NULL,
    MerchantId      VARCHAR(100),
    ApiKey          VARCHAR(512),
    IsActive        BIT             NOT NULL DEFAULT 1,
    Priority        INT             NOT NULL DEFAULT 100,
    SupportsWallet  BIT             NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2       DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- کیف پول کاربران و فروشندگان
CREATE TABLE dbo.Wallets (
    WalletId        UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerId         UNIQUEIDENTIFIER NOT NULL,      -- CustomerId یا VendorId از Auth
    OwnerType       VARCHAR(20)      NOT NULL        -- Customer / Vendor
                    CONSTRAINT CK_OwnerType CHECK (OwnerType IN ('Customer','Vendor')),
    Balance         DECIMAL(18,0)    NOT NULL DEFAULT 0,     -- به ریال
    CreditLimit     DECIMAL(18,0)    NOT NULL DEFAULT 0,     -- برای فروشندگان
    Currency        CHAR(3)          NOT NULL DEFAULT 'IRR',
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Active'
                    CONSTRAINT CK_WalletStatus CHECK (Status IN ('Active','Frozen','Closed')),
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- تراکنش‌های کیف پول (مهم‌ترین جدول مالی)
CREATE TABLE dbo.WalletTransactions (
    TransactionId   BIGINT IDENTITY(100000000,1) PRIMARY KEY, -- شماره تراکنش منحصربه‌فرد
    WalletId        UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Wallets(WalletId),
    OrderId         UNIQUEIDENTIFIER NULL,                    -- اگر مربوط به سفارش باشد
    Amount          DECIMAL(18,0)    NOT NULL,                -- مثبت = واریز، منفی = برداشت
    PreviousBalance DECIMAL(18,0)    NOT NULL,
    NewBalance      DECIMAL(18,0)    NOT NULL,
    Type            VARCHAR(30)      NOT NULL                 -- Deposit, Withdraw, OrderPayment, Refund, Adjustment
                    CONSTRAINT CK_TxnType CHECK (Type IN 
                        ('Deposit','Withdraw','OrderPayment','Refund','Adjustment','Transfer','Settlement')),
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Completed'
                    CONSTRAINT CK_TxnStatus CHECK (Status IN ('Pending','Completed','Failed','Reversed')),
    ReferenceId     VARCHAR(200),                             -- شماره تراکنش درگاه یا مرجع
    Description     NVARCHAR(500),
    PerformedBy     UNIQUEIDENTIFIER NULL,                    -- کاربر یا سیستم
    Metadata        NVARCHAR(MAX),                            -- JSON اضافی
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- پرداخت‌های آنلاین (از درگاه)
CREATE TABLE dbo.PaymentRequests (
    PaymentId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId         UNIQUEIDENTIFIER NOT NULL,
    Amount          DECIMAL(18,0)    NOT NULL,
    GatewayCode     VARCHAR(50)      NOT NULL REFERENCES dbo.PaymentGateways(GatewayCode),
    Token           VARCHAR(512),                             -- توکن درگاه
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Created'
                    CONSTRAINT CK_PaymentStatus CHECK (Status IN 
                        ('Created','SentToGateway','Paid','Failed','Cancelled','Refunded')),
    Authority       VARCHAR(200),                             -- Authority از درگاه
    RefId           VARCHAR(100),                             -- RefId برگشتی
    CardPan         VARCHAR(19),                              -- ماسک‌شده
    CallbackUrl     VARCHAR(512)     NOT NULL,
    CustomerIp      VARCHAR(45),
    CustomerAgent   VARCHAR(512),
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    PaidAt          DATETIME2,
    RowVersion      ROWVERSION
);
GO

-- ایندکس‌های حیاتی Write
CREATE UNIQUE INDEX UX_Wallet_Owner ON dbo.Wallets(OwnerId, OwnerType);
CREATE INDEX IX_WalletTransactions_Wallet ON dbo.WalletTransactions(WalletId);
CREATE INDEX IX_WalletTransactions_Order ON dbo.WalletTransactions(OrderId) WHERE OrderId IS NOT NULL;
CREATE INDEX IX_WalletTransactions_Created ON dbo.WalletTransactions(CreatedAt DESC);
CREATE INDEX IX_PaymentRequests_Order ON dbo.PaymentRequests(OrderId);
CREATE INDEX IX_PaymentRequests_Status ON dbo.PaymentRequests(Status);
GO