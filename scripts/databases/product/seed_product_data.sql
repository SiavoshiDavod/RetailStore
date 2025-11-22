-- دسته‌بندی‌های اصلی مواد غذایی
INSERT INTO dbo.Categories (CategoryId, ParentId, Name, Slug, FullPath, SortOrder, IsActive) VALUES
(NEWID(), NULL, N'لبنیات', 'dairy', N'لبنیات', 10, 1),
(NEWID(), NULL, N'میوه و سبزیجات', 'fruits-vegetables', N'میوه و سبزیجات', 20, 1),
(NEWID(), NULL, N'گوشت و پروتئین', 'meat-protein', N'گوشت و پروتئین', 30, 1),
(NEWID(), NULL, N'نوشیدنی', 'beverages', N'نوشیدنی', 40, 1),
(NEWID(), NULL, N'تنقلات', 'snacks', N'تنقلات', 50, 1);