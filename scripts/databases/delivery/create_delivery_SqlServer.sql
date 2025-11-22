-- Database: DeliveryService_WriteDb
USE DeliveryService_WriteDb;
GO

-- سرویس‌دهندگان حمل (SnappBox, Miare, Alopeyk, TapsiCourier, Internal)
CREATE TABLE dbo.DeliveryProviders (
    ProviderCode    VARCHAR(50)     PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    BaseUrl         VARCHAR(255),
    ApiKey          VARCHAR(512),
    IsActive        BIT             NOT NULL DEFAULT 1,
    Priority        INT             DEFAULT 100,
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Active'
                    CONSTRAINT CK_ProviderStatus CHECK (Status IN ('Active','Disabled','Degraded')),
    LastHealthCheck DATETIME2,
    CreatedAt       DATETIME2       DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- بایکرهای داخلی (Internal Fleet)
CREATE TABLE dbo.Couriers (
    CourierId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FullName        NVARCHAR(150)   NOT NULL,
    PhoneNumber     VARCHAR(20)     UNIQUE NOT NULL,
    VehicleType     VARCHAR(20)     NOT NULL
                    CONSTRAINT CK_VehicleType CHECK (VehicleType IN ('Bike','Motorbike','Car','Van')),
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Available'
                    CONSTRAINT CK_CourierStatus CHECK (Status IN ('Available','OnDelivery','Inactive','Offline')),
    CurrentLocation GEOGRAPHY,
    CreatedAt       DATETIME2       DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2       DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- مأموریت‌های تحویل (قلب سرویس)
CREATE TABLE dbo.Deliveries (
    DeliveryId          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId             UNIQUEIDENTIFIER NOT NULL,
    ProviderCode        VARCHAR(50)      NOT NULL REFERENCES dbo.DeliveryProviders(ProviderCode),
    TrackingCode        VARCHAR(100),                    -- از سرویس‌دهنده خارجی
    Status              VARCHAR(20)      NOT NULL DEFAULT 'Pending'
                        CONSTRAINT CK_DeliveryStatus CHECK (Status IN 
                            ('Pending','Assigned','PickedUp','InTransit','Delivered','Failed','Cancelled')),
    CourierId           UNIQUEIDENTIFIER NULL REFERENCES dbo.Couriers(CourierId),
    
    PickupAddress       NVARCHAR(500)    NOT NULL,
    PickupCity          NVARCHAR(100)    NOT NULL,
    PickupPostalCode    VARCHAR(20),
    PickupGeoLat        FLOAT            NOT NULL,
    PickupGeoLng        FLOAT            NOT NULL,

    DropoffAddress      NVARCHAR(500)    NOT NULL,
    DropoffCity         NVARCHAR(100)    NOT NULL,
    DropoffPostalCode   VARCHAR(20),
    DropoffGeoLat       FLOAT            NOT NULL,
    DropoffGeoLng       FLOAT            NOT NULL,

    ContactName         NVARCHAR(150),
    ContactPhone        VARCHAR(20),
    ContactInstructions NVARCHAR(500),

    WeightKg            DECIMAL(10,2),
    EstimatedCost       DECIMAL(18,0),
    FinalCost           DECIMAL(18,0),
    Currency            CHAR(3)          DEFAULT 'IRR',

    AssignedAt          DATETIME2,
    PickedUpAt          DATETIME2,
    DeliveredAt         DATETIME2,
    FailedAt            DATETIME2,
    CancelledAt         DATETIME2,

    CreatedAt           DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion          ROWVERSION
);
GO

-- آیتم‌های بسته (اختیاری – برای گزارش‌گیری)
CREATE TABLE dbo.DeliveryItems (
    DeliveryItemId      BIGINT IDENTITY(1,1) PRIMARY KEY,
    DeliveryId          UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Deliveries(DeliveryId) ON DELETE CASCADE,
    Sku                 VARCHAR(100),
    Description         NVARCHAR(500),
    Quantity            INT              NOT NULL DEFAULT 1,
    WeightKg            DECIMAL(8,2)
);
GO

-- رویدادهای تحویل (Event Sourcing سبک)
CREATE TABLE dbo.DeliveryEvents (
    EventId             BIGINT IDENTITY(1,1) PRIMARY KEY,
    DeliveryId          UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Deliveries(DeliveryId) ON DELETE CASCADE,
    EventCode           VARCHAR(50)      NOT NULL
                        CONSTRAINT CK_EventCode CHECK (EventCode IN 
                            ('Created','Assigned','PickedUp','ArrivedPickup','DepartedPickup',
                             'ArrivedDropoff','Delivered','Failed','Cancelled','ProviderWebhook')),
    OccurredAt          DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    RecordedAt          DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    Source              VARCHAR(50),     -- Internal, SnappBox, Miare, Webhook, ...
    Notes               NVARCHAR(1000),
    LocationLat         FLOAT,
    LocationLng         FLOAT,
    Metadata            NVARCHAR(MAX)    -- JSON از Webhook
);
GO

-- ایندکس‌های حیاتی Write
CREATE INDEX IX_Deliveries_OrderId      ON dbo.Deliveries(OrderId);
CREATE INDEX IX_Deliveries_Status       ON dbo.Deliveries(Status);
CREATE INDEX IX_Deliveries_Provider     ON dbo.Deliveries(ProviderCode);
CREATE INDEX IX_Deliveries_Courier      ON dbo.Deliveries(CourierId) WHERE CourierId IS NOT NULL;
CREATE INDEX IX_DeliveryEvents_Delivery ON dbo.DeliveryEvents(DeliveryId);
CREATE INDEX IX_DeliveryEvents_Code_Time ON dbo.DeliveryEvents(EventCode, OccurredAt DESC);
GO