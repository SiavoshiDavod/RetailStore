-- وضعیت‌های اصلی سفارش
INSERT INTO dbo.OrderStatuses (StatusCode, Name, IsFinal, SortOrder) VALUES
('Draft',           N'پیش‌نویس',           0, 10),
('PendingPayment',  N'در انتظار پرداخت',    0, 20),
('Paid',            N'پرداخت شده',         0, 30),
('Preparing',       N'در حال آماده‌سازی',   0, 40),
('ReadyForDelivery',N'آماده تحویل',        0, 50),
('OutForDelivery',  N'در مسیر تحویل',       0, 60),
('Delivered',       N'تحویل شده',          1, 70),
('Cancelled',       N'کنسل شده',           1, 80),
('Refunded',        N'مسترد شده',          1, 90);
GO