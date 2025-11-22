-- Database: ProductService_WriteDb
USE ProductService_WriteDb;
GO

-- دسته‌بندی محصولات (درخت سلسله‌مراتبی)
CREATE TABLE dbo.Categories (
    CategoryId      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ParentId        UNIQUEIDENTIFIER NULL REFERENCES dbo.Categories(CategoryId),
    Name            NVARCHAR(200)    NOT NULL,
    Slug            VARCHAR(200)     UNIQUE NOT NULL,
    IconUrl         VARCHAR(512),
    SortOrder       INT              NOT NULL DEFAULT 0,
    IsActive        BIT              NOT NULL DEFAULT 1,
    Level           INT              NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- برندها
CREATE TABLE dbo.Brands (
    BrandId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name            NVARCHAR(150)    NOT NULL,
    EnglishName     NVARCHAR(150),
    LogoUrl         VARCHAR(512),
    IsActive        BIT              NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- ویژگی‌های محصول (مثل وزن، حجم، کشور سازنده)
CREATE TABLE dbo.Attributes (
    AttributeId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name            NVARCHAR(100)    NOT NULL,
    Code            VARCHAR(50)      UNIQUE NOT NULL, -- weight_gram, origin_country
    DataType        VARCHAR(20)      NOT NULL -- String, Number, Boolean, Enum
                    CONSTRAINT CK_AttrType CHECK (DataType IN ('String','Number','Boolean','Enum')),
    Unit            VARCHAR(20),     -- گرم، لیتر، عدد
    IsFilterable    BIT              NOT NULL DEFAULT 1,
    IsRequired      BIT              NOT NULL DEFAULT 0,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME()
);
GO

-- محصولات اصلی (Master Product)
CREATE TABLE dbo.Products (
    ProductId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Title           NVARCHAR(500)    NOT NULL,
    Slug            VARCHAR(500)     UNIQUE NOT NULL,
    Description     NVARCHAR(MAX),
    ShortDescription NVARCHAR(1000),
    BrandId         UNIQUEIDENTIFIER NULL REFERENCES dbo.Brands(BrandId),
    CategoryId      UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Categories(CategoryId),
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Draft'
                    CONSTRAINT CK_ProductStatus CHECK (Status IN ('Draft','PendingReview','Active','Inactive','Rejected')),
    ThumbnailUrl    VARCHAR(512),
    GalleryUrls     VARCHAR(MAX),    -- JSON array
    AverageRating   DECIMAL(3,2)     DEFAULT 0,
    ReviewCount     INT              DEFAULT 0,
    CreatedBy       UNIQUEIDENTIFIER NOT NULL, -- VendorId یا Admin
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- مقادیر ویژگی برای هر محصول
CREATE TABLE dbo.ProductAttributes (
    ProductId       UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Products(ProductId) ON DELETE CASCADE,
    AttributeId     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Attributes(AttributeId),
    Value           NVARCHAR(500)    NOT NULL,
    PRIMARY KEY (ProductId, AttributeId)
);
GO

-- SKUها (واحد قابل فروش)
CREATE TABLE dbo.ProductVariants (
    Sku             VARCHAR(100)     PRIMARY KEY,
    ProductId       UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Products(ProductId),
    VendorId        UNIQUEIDENTIFIER NULL,           -- فروشنده مالک این SKU
    RetailPartnerId VARCHAR(50)      NULL,                    -- اگر از رفاه/هایپراستار باشد
    Title           NVARCHAR(500)    NOT NULL,
    Barcode         VARCHAR(100),
    Price           DECIMAL(18,0)    NOT NULL,
    DiscountedPrice DECIMAL(18,0)    NULL,
    DiscountStart   DATETIME2,
    DiscountEnd     DATETIME2,
    WeightGram      INT,
    IsActive        BIT              NOT NULL DEFAULT 1,
    StockQuantity   INT              NOT NULL DEFAULT 0,
    ReservedStock   INT              NOT NULL DEFAULT 0,
    WarehouseLocation VARCHAR(100),
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- موجودی در انبارهای مختلف (در آینده برای چندانباری)
CREATE TABLE dbo.Inventory (
    InventoryId     BIGINT IDENTITY(1,1) PRIMARY KEY,
    Sku             VARCHAR(100) NOT NULL REFERENCES dbo.ProductVariants(Sku),
    WarehouseCode   VARCHAR(50)  NOT NULL, -- WH-TEH-01, WH-SHOP-123
    Quantity        INT          NOT NULL DEFAULT 0,
    Reserved        INT          NOT NULL DEFAULT 0,
    LastUpdated     DATETIME2    DEFAULT SYSUTCDATETIME()
);
GO

-- ایندکس‌های حیاتی Write
CREATE INDEX IX_Products_Category        ON dbo.Products(CategoryId);
CREATE INDEX IX_Products_Brand           ON dbo.Products(BrandId);
CREATE INDEX IX_Products_Status          ON dbo.Products(Status);
CREATE INDEX IX_ProductVariants_Product  ON dbo.ProductVariants(ProductId);
CREATE INDEX IX_ProductVariants_Vendor   ON dbo.ProductVariants(VendorId);
CREATE INDEX IX_ProductVariants_Price    ON dbo.ProductVariants(Price);
CREATE INDEX IX_ProductVariants_Active   ON dbo.ProductVariants(IsActive, StockQuantity) WHERE IsActive = 1;
CREATE INDEX IX_Inventory_Sku            ON dbo.Inventory(Sku);
GO