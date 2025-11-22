-- Database: ProductService_WriteDb
USE ProductService_WriteDb;
GO

-- دسته‌بندی‌ها (درخت سلسله‌مراتبی)
CREATE TABLE dbo.Categories (
    CategoryId      UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    ParentId        UNIQUEIDENTIFIER NULL REFERENCES dbo.Categories(CategoryId),
    Name            NVARCHAR(200)    NOT NULL,
    Slug            VARCHAR(250)     UNIQUE NOT NULL,
    FullPath        VARCHAR(1000),   -- لبنیات/شیر/شیر پرچرب
    IconUrl         VARCHAR(512),
    BannerUrl       VARCHAR(512),
    SortOrder       INT              NOT NULL DEFAULT 0,
    IsActive        BIT              NOT NULL DEFAULT 1,
    Level           AS CASE WHEN ParentId IS NULL THEN 1 ELSE 2 END PERSISTED,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- برندها
CREATE TABLE dbo.Brands (
    BrandId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name            NVARCHAR(150)    NOT NULL,
    EnglishName     NVARCHAR(150),
    Slug            VARCHAR(200)     UNIQUE NOT NULL,
    LogoUrl         VARCHAR(512),
    Website         VARCHAR(255),
    IsActive        BIT              NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- ویژگی‌های عمومی (Attribute)
CREATE TABLE dbo.Attributes (
    AttributeId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Name            NVARCHAR(100)    NOT NULL,
    Code            VARCHAR(80)      UNIQUE NOT NULL, -- weight_gram, volume_ml, origin_country
    DataType        VARCHAR(20)      NOT NULL 
                    CONSTRAINT CK_AttrType CHECK (DataType IN ('String','Number','Boolean','Enum','Date')),
    Unit            VARCHAR(30),     -- گرم، میلی‌لیتر، عدد
    IsFilterable    BIT              NOT NULL DEFAULT 1,
    IsRequired      BIT              NOT NULL DEFAULT 0,
    SortOrder       INT              DEFAULT 0,
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME()
);
GO

-- محصولات اصلی (Master Product)
CREATE TABLE dbo.Products (
    ProductId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Title           NVARCHAR(500)    NOT NULL,
    Slug            VARCHAR(600)     UNIQUE NOT NULL,
    ShortDescription NVARCHAR(1000),
    Description     NVARCHAR(MAX),
    MetaTitle       NVARCHAR(200),
    MetaDescription NVARCHAR(500),
    BrandId         UNIQUEIDENTIFIER NULL REFERENCES dbo.Brands(BrandId),
    CategoryId      UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Categories(CategoryId),
    ThumbnailUrl    VARCHAR(512),
    GalleryUrls     VARCHAR(MAX),    -- JSON: ["url1","url2"]
    Status          VARCHAR(20)      NOT NULL DEFAULT 'Draft'
                    CONSTRAINT CK_ProductStatus CHECK (Status IN 
                        ('Draft','PendingReview','Active','Inactive','Rejected','Archived')),
    AverageRating   DECIMAL(3,2)     DEFAULT 0,
    ReviewCount     INT              DEFAULT 0,
    TotalSales      INT              DEFAULT 0,
    CreatedBy       UNIQUEIDENTIFIER NOT NULL, -- VendorId یا Admin
    CreatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion      ROWVERSION
);
GO

-- مقادیر ویژگی محصول
CREATE TABLE dbo.ProductAttributes (
    ProductId       UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Products(ProductId) ON DELETE CASCADE,
    AttributeId     UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Attributes(AttributeId),
    Value           NVARCHAR(500)    NOT NULL,
    PRIMARY KEY (ProductId, AttributeId)
);
GO

-- SKUها (واحد قابل فروش – Variant)
CREATE TABLE dbo.ProductVariants (
    Sku                 VARCHAR(120)     PRIMARY KEY,
    ProductId           UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Products(ProductId),
    VendorId            UNIQUEIDENTIFIER NULL,            -- فروشنده مالک این SKU
    RetailPartnerId     VARCHAR(80)      NULL,                     -- برای رفاه، هایپراستار و ...
    Title               NVARCHAR(500)    NOT NULL,
    Barcode             VARCHAR(100),
    Price               DECIMAL(18,0)    NOT NULL,         -- ریال
    DiscountedPrice     DECIMAL(18,0)    NULL,
    DiscountStart       DATETIME2,
    DiscountEnd         DATETIME2,
    WeightGram          INT,
    LengthCm            DECIMAL(6,2),
    WidthCm             DECIMAL(6,2),
    HeightCm            DECIMAL(6,2),
    IsActive            BIT              NOT NULL DEFAULT 1,
    StockQuantity       INT              NOT NULL DEFAULT 0,
    ReservedStock       INT              NOT NULL DEFAULT 0,
    MinOrderQuantity    INT              DEFAULT 1,
    MaxOrderQuantity    INT              DEFAULT 100,
    WarehouseLocation   VARCHAR(100),
    CreatedAt           DATETIME2        DEFAULT SYSUTCDATETIME(),
    UpdatedAt           DATETIME2        DEFAULT SYSUTCDATETIME(),
    RowVersion          ROWVERSION
);
GO

-- موجودی در انبارهای مختلف (Multi-Warehouse)
CREATE TABLE dbo.Inventory (
    InventoryId         BIGINT IDENTITY(1,1) PRIMARY KEY,
    Sku                 VARCHAR(120) NOT NULL REFERENCES dbo.ProductVariants(Sku),
    WarehouseCode       VARCHAR(50)  NOT NULL, -- WH-TEH-01, WH-VENDOR-123
    WarehouseName       NVARCHAR(200),
    AvailableQuantity   INT          NOT NULL DEFAULT 0,
    ReservedQuantity    INT          NOT NULL DEFAULT 0,
    LastUpdated         DATETIME2    DEFAULT SYSUTCDATETIME()
);
GO

-- تگ‌ها و کلمات کلیدی
CREATE TABLE dbo.ProductTags (
    ProductId           UNIQUEIDENTIFIER NOT NULL REFERENCES dbo.Products(ProductId) ON DELETE CASCADE,
    Tag                 NVARCHAR(100) NOT NULL,
    PRIMARY KEY (ProductId, Tag)
);
GO

-- ایندکس‌های حیاتی Write Side
CREATE UNIQUE INDEX UX_Products_Slug          ON dbo.Products(Slug);
CREATE INDEX IX_Products_Category             ON dbo.Products(CategoryId);
CREATE INDEX IX_Products_Brand                ON dbo.Products(BrandId);
CREATE INDEX IX_Products_Status               ON dbo.Products(Status);
CREATE INDEX IX_Products_CreatedBy            ON dbo.Products(CreatedBy);

CREATE INDEX IX_ProductVariants_Product       ON dbo.ProductVariants(ProductId);
CREATE INDEX IX_ProductVariants_Vendor        ON dbo.ProductVariants(VendorId);
CREATE INDEX IX_ProductVariants_Price         ON dbo.ProductVariants(Price);
CREATE INDEX IX_ProductVariants_Active_Stock  ON dbo.ProductVariants(IsActive, StockQuantity) 
      WHERE IsActive = 1 AND StockQuantity > 0;

CREATE INDEX IX_Inventory_Sku                 ON dbo.Inventory(Sku);
CREATE INDEX IX_Inventory_Warehouse           ON dbo.Inventory(WarehouseCode);
GO