-- Database: product_service_read

-- محصول کامل برای نمایش، فیلتر و جستجو (Denormalized + JSONB)
CREATE TABLE products_search (
    product_id          UUID PRIMARY KEY,
    sku                 TEXT,
    title               TEXT NOT NULL,
    slug                TEXT UNIQUE NOT NULL,
    short_description   TEXT,
    description         TEXT,
    category            JSONB NOT NULL,           -- {id, name, path: ["لبنیات","شیر"], level: 2}
    brand               JSONB,                    -- {id, name, slug}
    vendor              JSONB,                    -- {id, name, store_name}
    retail_partner      JSONB,                    -- {id, name}
    price               NUMERIC(18,0) NOT NULL,
    discounted_price    NUMERIC(18,0),
    discount_percent    INT GENERATED ALWAYS AS (
                          CASE WHEN discounted_price IS NOT NULL AND discounted_price < price 
                               THEN ROUND(((price - discounted_price) * 100.0 / price)) 
                               ELSE NULL END) STORED,
    stock               INT NOT NULL,
    rating              NUMERIC(3,2) DEFAULT 0,
    review_count        INT DEFAULT 0,
    thumbnail           TEXT,
    gallery             TEXT[],
    attributes          JSONB,                    -- {weight_gram: 950, origin: "ایران"}
    tags                TEXT[],
    is_active           BOOLEAN DEFAULT true,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    search_vector       TSVECTOR
);

-- ایندکس جستجوی فارسی (بهترین عملکرد)
CREATE INDEX idx_products_search_vector ON products_search USING GIN (search_vector);
CREATE INDEX idx_products_search_category_path ON products_search USING GIN ((category->'path'));
CREATE INDEX idx_products_search_price ON products_search(price);
CREATE INDEX idx_products_search_brand ON products_search((brand->>'id'));
CREATE INDEX idx_products_search_vendor ON products_search((vendor->>'id'));
CREATE INDEX idx_products_search_active_stock ON products_search(is_active, stock) 
      WHERE is_active = true AND stock > 0;

-- تابع به‌روزرسانی خودکار search_vector
CREATE OR REPLACE FUNCTION update_product_search_vector() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('persian', coalesce(NEW.title,'')), 'A') ||
        setweight(to_tsvector('persian', coalesce(NEW.short_description,'')), 'B') ||
        setweight(to_tsvector('persian', coalesce(NEW.description,'')), 'C') ||
        setweight(to_tsvector('english', coalesce(NEW.sku,'')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_search_vector
    BEFORE INSERT OR UPDATE ON products_search
    FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();