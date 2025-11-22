-- نقش‌های اصلی
INSERT INTO dbo.UserGroups (GroupId, Code, Name, IsSystem) VALUES
(NEWID(), 'Customer',      N'مشتری',            1),
(NEWID(), 'VendorOwner',   N'مالک فروشنده',     1),
(NEWID(), 'VendorManager', N'مدیر فروشنده',     1),
(NEWID(), 'SystemAdmin',   N'مدیر کل سیستم',     1),
(NEWID(), 'OrderSupport',  N'پشتیبانی سفارش',   1),
(NEWID(), 'Supplier',      N'تأمین‌کننده',      1);