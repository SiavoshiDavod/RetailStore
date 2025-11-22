-- درگاه‌های اصلی ایران
INSERT INTO dbo.PaymentGateways (GatewayCode, Name, IsActive, Priority, SupportsWallet) VALUES
('Zarinpal',     N'زرین‌پال',        1, 10, 1),
('BehPardakht',  N'به‌پرداخت ملت',   1, 20, 0),
('Saman',        N'سامان کیش',       1, 30, 0),
('Wallet',       N'کیف پول داخلی',    1, 5,  1);  -- اولویت بالا