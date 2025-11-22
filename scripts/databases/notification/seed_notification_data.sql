-- کانال‌ها
INSERT INTO dbo.NotificationChannels (ChannelCode, Name, IsActive, Priority) VALUES
('SMS',      N'پیامک',         1, 10),
('PUSH',     N'نوتیفیکیشن اپ',1, 20),
('EMAIL',    N'ایمیل',         1, 30),
('INAPP',    N'داخل برنامه',   1, 40);

-- قالب‌های اصلی
INSERT INTO dbo.NotificationTemplates (TemplateId, Code, ChannelCode, Title, Subject, Body, IsActive) VALUES
(NEWID(), 'OrderCreated_SMS', 'SMS',   NULL, NULL, 
 N'سفارش {{orderNumber}} ثبت شد. مبلغ: {{finalAmount}} تومان', 1),

(NEWID(), 'OrderDelivered_PUSH', 'PUSH', N'سفارشتون رسید!', NULL,
 N'🎉 سفارش {{orderNumber}} تحویل شد. ممنون از خریدتون!', 1),

(NEWID(), 'Welcome_Email', 'EMAIL', N'خوش آمدید!', N'به بازار خوش آمدید {{fullName}} عزیز',
 N'<h1>سلام {{fullName}}</h1><p>خوشحالیم که به جمع ما پیوستید!</p>', 1);