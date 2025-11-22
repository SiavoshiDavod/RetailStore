-- دسته‌بندی‌های اصلی مواد غذایی
INSERT INTO dbo.Categories (CategoryId, ParentId, Name, Slug, SortOrder, IsActive) VALUES
(NEWID(), NULL, N'لبنیات', 'dairy', 10, 1),
(NEWID(), NULL, N'گوشت و پروتئین', 'meat-protein', 20, 1),
(NEWID(), NULL, N'میوه و سبزیجات', 'fruits-vegetables', 30, 1),
(NEWID(), NULL, N'نوشیدنی', 'beverages', 40, 1);