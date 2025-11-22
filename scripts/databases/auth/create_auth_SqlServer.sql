-- Database: AuthService_WriteDb (SQL Server)
USE AuthService_WriteDb;
GO

-- کاربران (Master)
CREATE TABLE dbo.Users (
    UserId          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FullName        NVARCHAR(150)    NOT NULL,
    Mobile          VARCHAR(20)      UNIQUE NOT NULL,
    MobileVerified  BIT              NOT NULL DEFAULT 0,
    Email           VARCHAR(255)     UNIQUE,
    EmailVerified   BIT              NOT NULL DEFAULT 0,
    PasswordHash    VARBINARY(64)    NULL, -- bcrypt hash
    UserType        VARCHAR(30)      NOT NULL 
                    CONSTRAINT CK_UserType CHECK (UserType IN 
                        ('SystemAdmin','Supplier','Vendor','OrderSupport','Customer','DeliveryAgent')),
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Pending'
                    CONSTRAINT CK_UserStatus CHECK (Status IN ('Active','Suspended','Pending','Deactivated')),
    AvatarUrl       VARCHAR(512),
    LastLoginAt     DATETIME2,
    CreatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        NOT NULL DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- گروه‌های کاربری (UserGroup)
CREATE TABLE dbo.UserGroups (
    GroupId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Code            VARCHAR(50)      UNIQUE NOT NULL,   -- Customer, VendorOwner, Admin, ...
    Name            NVARCHAR(100)    NOT NULL,
    Description     NVARCHAR(500),
    IsSystem        BIT              NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- عملیات سیستم (Operation = Permission + Menu)
CREATE TABLE dbo.Operations (
    OperationId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Code            VARCHAR(100)     UNIQUE NOT NULL,
    Name            NVARCHAR(150)    NOT NULL,
    Category        VARCHAR(50),
    MenuPath        VARCHAR(255),
    MenuTitle       NVARCHAR(100),
    Icon            VARCHAR(100),
    ParentCode      VARCHAR(100),
    SortOrder       INT              DEFAULT 0,
    IsVisible       BIT              NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- نگاشت گروه → عملیات
CREATE TABLE dbo.GroupOperations (
    GroupId         UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.UserGroups(GroupId) ON DELETE CASCADE,
    OperationId     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Operations(OperationId) ON DELETE CASCADE,
    GrantedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (GroupId, OperationId)
);
GO

-- نگاشت کاربر → گروه (یک کاربر چند گروه دارد)
CREATE TABLE dbo.UserGroupMembers (
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Users(UserId) ON DELETE CASCADE,
    GroupId         UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.UserGroups(GroupId) ON DELETE CASCADE,
    AssignedAt      DATETIME2        DEFAULT SYSUTCDATETIME(),
    AssignedBy      UNIQUEIDENTIFIER NULL,
    PRIMARY KEY (UserId, GroupId)
);
GO

-- توکن‌های ریفرش (Write فقط برای ابطال)
CREATE TABLE dbo.RefreshTokens (
    TokenId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Users(UserId),
    Token           VARCHAR(512)     NOT NULL UNIQUE,
    DeviceId        VARCHAR(255),
    ExpiresAt       DATETIME2        NOT NULL,
    RevokedAt       DATETIME2        NULL,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME()
);
GO

-- ایندکس‌های حیاتی Write
CREATE INDEX IX_Users_Mobile ON dbo.Users(Mobile);
CREATE INDEX IX_Users_Email  ON dbo.Users(Email);
CREATE INDEX IX_RefreshTokens_User_Active ON dbo.RefreshTokens(UserId) 
    WHERE RevokedAt IS NULL;
GO