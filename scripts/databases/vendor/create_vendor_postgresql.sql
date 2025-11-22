-- Database: product_service_read

-- محصول کامل برای نمایش و جستجو (Denormalized + JSONB)
CREATE TABLE products_search (
    product_id      UUID PRIMARY KEY,
    sku             TEXT,
    title           TEXT NOT NULL,
    slug            TEXT UNIQUE NOT NULL,
    description     TEXT,
    category        JSONB,           -- {id, name, path: ["غذا","لبنیات","شیر"]}
    brand           JSONB,           -- {id, name}
    vendor          JSONB,           -- {id, name}
    price           NUMERIC(18,0),
    discounted_price NUMERIC(18,0),
    discount_percent INT,
    stock           INT,
    rating          NUMERIC(3,2),
    review_count    INT,
    thumbnail       TEXT,
    gallery         TEXT[],
    attributes      JSONB,           -- {weight_gram: "950", origin: "ایران"}
    tags            TEXT[],
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    search_vector   TSVECTOR         -- برای جستجوی فارسی
);

-- ایندکس جستجوی فارسی (با hunspell یا پارسر فارسی)
CREATE INDEX idx_products_search_vector ON products_search USING GIN (search_vector);
CREATE INDEX idx_products_search_category ON products_search USING GIN ((category->'path'));
CREATE INDEX idx_products_search_price ON products_search(price);
CREATE INDEX idx_products_search_brand ON products_search((brand->>'id'));
CREATE INDEX idx_products_search_active_stock ON products_search(is_active, stock) WHERE is_active = true AND stock > 0;

-- به‌روزرسانی خودکار search_vector
CREATE OR REPLACE FUNCTION update_product_search_vector() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('persian', coalesce(NEW.title,'')), 'A') ||
        setweight(to_tsvector('persian', coalesce(NEW.description,'')), 'B') ||
        setweight(to_tsvector('english', coalesce(NEW.sku,'')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_product_search_vector
    BEFORE INSERT OR UPDATE ON products_search
    FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();