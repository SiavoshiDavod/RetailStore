-- Database: NotificationService_WriteDb
USE NotificationService_WriteDb;
GO

-- کانال‌های ارسال
CREATE TABLE dbo.NotificationChannels (
    ChannelCode     VARCHAR(30)     PRIMARY KEY,
    Name            NVARCHAR(100)   NOT NULL,
    IsActive        BIT             NOT NULL DEFAULT 1,
    Priority        INT             NOT NULL DEFAULT 100
);
GO

-- قالب‌های پیام (Handlebars/Mustache)
CREATE TABLE dbo.NotificationTemplates (
    TemplateId      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Code            VARCHAR(100)     UNIQUE NOT NULL, -- OrderCreated_SMS, Welcome_Email
    ChannelCode     VARCHAR(30)      NOT NULL REFERENCES dbo.NotificationChannels(ChannelCode),
    Title           NVARCHAR(200),
    Subject         NVARCHAR(300),   -- برای Email
    Body            NVARCHAR(MAX)    NOT NULL, -- {{customerName}} عزیز، سفارش شما ثبت شد
    Variables       VARCHAR(MAX),    -- JSON array مثال: ["customerName","orderNumber"]
    IsActive        BIT              NOT NULL DEFAULT 1,
    Version         INT              NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- پیام‌های ارسالی (Master)
CREATE TABLE dbo.Notifications (
    NotificationId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL,      -- گیرنده (از Auth)
    TemplateCode    VARCHAR(100)     NOT NULL,
    ChannelCode     VARCHAR(30)      NOT NULL,
    Priority        VARCHAR(20)      NOT NULL DEFAULT 'Normal', -- Low, Normal, High, Critical
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Pending'
                    CONSTRAINT CK_NotifStatus CHECK (Status IN 
                        ('Pending','Queued','Sent','Delivered','Failed','Cancelled')),
    Subject         NVARCHAR(500),
    Body            NVARCHAR(MAX),
    Data            NVARCHAR(MAX),   -- JSON داده‌های دینامیک (برای قالب)
    ReferenceId     UNIQUEIDENTIFIER NULL, -- OrderId, PaymentId و ...
    ReferenceType   VARCHAR(50),     -- Order, Payment, Delivery و ...
    SentAt          DATETIME2,
    DeliveredAt     DATETIME2,
    FailedAt        DATETIME2,
    FailReason      NVARCHAR(1000),
    RetryCount      INT              NOT NULL DEFAULT 0,
    MaxRetries      INT              NOT NULL DEFAULT 3,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- لاگ ارسال به ارائه‌دهنده (SMS/Push/Email)
CREATE TABLE dbo.NotificationLogs (
    LogId           BIGINT IDENTITY(1,1) PRIMARY KEY,
    NotificationId  UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Notifications(NotificationId),
    Provider        VARCHAR(100),    -- Kavenegar, FCM, Mailgun
    ProviderMessageId VARCHAR(200),
    RequestPayload  NVARCHAR(MAX),
    ResponsePayload NVARCHAR(MAX),
    HttpStatus      INT,
    SentAt          DATETIME2        DEFAULT SYSUTCDATETIME()
);
GO

-- ایندکس‌های حیاتی Write
CREATE INDEX IX_Notifications_User_Status ON dbo.Notifications(UserId, Status);
CREATE INDEX IX_Notifications_Reference ON dbo.Notifications(ReferenceType, ReferenceId);
CREATE INDEX IX_Notifications_Priority_Created ON dbo.Notifications(Priority, CreatedAt) 
    WHERE Status IN ('Pending','Queued');
CREATE INDEX IX_NotificationLogs_Notif ON dbo.NotificationLogs(NotificationId);
GO