-- Database: OrderService_WriteDb
USE OrderService_WriteDb;
GO

-- وضعیت‌های سفارش
CREATE TABLE dbo.OrderStatuses (
    StatusCode      VARCHAR(30)     PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    IsFinal         BIT             NOT NULL DEFAULT 0,
    SortOrder       INT             NOT NULL
);
GO

-- سفارش‌های اصلی
CREATE TABLE dbo.Orders (
    OrderId             UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderNumber         VARCHAR(50)      UNIQUE NOT NULL, -- ORD-2503-987654
    CustomerId          UNIQUEIDENTIFIER NOT NULL,     -- از Auth Service
    VendorId            UNIQUEIDENTIFIER NULL,         -- فروشنده یا فروشگاه زنجیره‌ای
    StoreId             UNIQUEIDENTIFIER NULL,         -- اگر فروشنده چند شعبه داشته باشد

    Status              VARCHAR(30)      NOT NULL DEFAULT 'Draft'
                        CONSTRAINT FK_Order_Status FOREIGN KEY REFERENCES dbo.OrderStatuses(StatusCode),

    TotalAmount         DECIMAL(18,0)    NOT NULL DEFAULT 0,     -- IRR
    DiscountAmount      DECIMAL(18,0)    NOT NULL DEFAULT 0,
    DeliveryFee         DECIMAL(18,0)    NOT NULL DEFAULT 0,
    FinalAmount         DECIMAL(18,0)    NOT NULL DEFAULT 0,

    Currency            CHAR(3)          NOT NULL DEFAULT 'IRR',
    PaymentStatus       VARCHAR(20)      NOT NULL DEFAULT 'Pending', -- Pending, Paid, Refunded, Failed
    PaymentMethod       VARCHAR(50),                           -- Wallet, OnlineGateway, COD

    DeliveryType        VARCHAR(20)      NOT NULL DEFAULT 'Standard', -- Standard, Express, Pickup
    DeliveryAddress     NVARCHAR(500),
    DeliveryCity        NVARCHAR(100),
    DeliveryPostalCode  VARCHAR(20),
    DeliveryGeoLat      FLOAT,
    DeliveryGeoLng      FLOAT,

    CustomerNote        NVARCHAR(1000),
    InternalNote        NVARCHAR(1000),

    CreatedAt           DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    PlacedAt            DATETIME2,       -- زمان تأیید توسط مشتری
    PaidAt              DATETIME2,
    DeliveredAt         DATETIME2,
    CancelledAt         DATETIME2,
    RowVersion          ROWVERSION
);
GO

-- آیتم‌های سفارش
CREATE TABLE dbo.OrderItems (
    OrderItemId         BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId             UNIQUEIDENTIFIER NOT NULL 
                        REFERENCES dbo.Orders(OrderId) ON DELETE CASCADE,
    ProductId           UNIQUEIDENTIFIER NOT NULL,
    Sku                 VARCHAR(100)     NOT NULL,
    ProductName         NVARCHAR(255)    NOT NULL,
    Quantity            INT              NOT NULL CHECK (Quantity > 0),
    UnitPrice           DECIMAL(18,0)    NOT NULL,
    DiscountedPrice     DECIMAL(18,0)    NOT NULL,
    TotalPrice          DECIMAL(18,0)    NOT NULL,
    WeightKg            DECIMAL(8,2)
);
GO

-- تاریخچه تغییرات وضعیت سفارش (Event Sourcing سبک)
CREATE TABLE dbo.OrderStatusHistory (
    HistoryId           BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId             UNIQUEIDENTIFIER NOT NULL,
    OldStatus           VARCHAR(30),
    NewStatus           VARCHAR(30)      NOT NULL,
    Reason              NVARCHAR(500),
    ChangedBy           UNIQUEIDENTIFIER NULL, -- UserId یا System
    ChangedAt           DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    Metadata            NVARCHAR(MAX)    -- JSON (مثلاً دلیل کنسلی، IP، ...)
);
GO

-- کوپن‌ها و تخفیف‌های اعمال‌شده
CREATE TABLE dbo.OrderDiscounts (
    DiscountId          BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderId             UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Orders(OrderId) ON DELETE CASCADE,
    DiscountCode        VARCHAR(50),
    DiscountType        VARCHAR(20)      NOT NULL, -- Percent, Fixed
    DiscountValue       DECIMAL(18,0)    NOT NULL,
    DiscountAmount      DECIMAL(18,0)    NOT NULL
);
GO

-- ایندکس‌های حیاتی Write
CREATE INDEX IX_Orders_CustomerId       ON dbo.Orders(CustomerId);
CREATE INDEX IX_Orders_VendorId         ON dbo.Orders(VendorId);
CREATE INDEX IX_Orders_Status           ON dbo.Orders(Status);
CREATE INDEX IX_Orders_PaymentStatus    ON dbo.Orders(PaymentStatus);
CREATE INDEX IX_Orders_CreatedAt        ON dbo.Orders(CreatedAt DESC);
CREATE INDEX IX_Orders_OrderNumber      ON dbo.Orders(OrderNumber);
CREATE INDEX IX_OrderItems_OrderId      ON dbo.OrderItems(OrderId);
CREATE INDEX IX_OrderStatusHistory_OrderId ON dbo.OrderStatusHistory(OrderId);
GO