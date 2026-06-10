-- ============================================
-- قاعدة بيانات Rawaaj - متجر المحتوى الذكي
-- الإصدار: 1.0
-- المحارف: UTF-8 (utf8mb4)
-- محرك التخزين: InnoDB
-- ============================================

-- إنشاء قاعدة البيانات
CREATE DATABASE IF NOT EXISTS rawaaj_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE rawaaj_db;

-- ============================================
-- 1. جدول المستخدمين (users)
-- ============================================
CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'الاسم الكامل',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT 'البريد الإلكتروني (فريد)',
    password VARCHAR(255) NOT NULL COMMENT 'كلمة المرور (مشفرة)',
    phone VARCHAR(20) NULL COMMENT 'رقم الهاتف',
    business_type ENUM('restaurant', 'salon', 'ecommerce', 'startup', 'shop', 'other') DEFAULT 'other' COMMENT 'نوع المشروع',
    avatar VARCHAR(255) NULL COMMENT 'مسار الصورة الشخصية',
    email_notifications BOOLEAN DEFAULT TRUE COMMENT 'إشعارات البريد',
    sms_notifications BOOLEAN DEFAULT FALSE COMMENT 'إشعارات SMS',
    special_offers_notifications BOOLEAN DEFAULT TRUE COMMENT 'إشعارات العروض',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_email (email),
    INDEX idx_business_type (business_type)
) ENGINE=InnoDB COMMENT='المستخدمين';

-- ============================================
-- 2. جدول الخدمات الفردية (services)
-- ============================================
CREATE TABLE services (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'اسم الخدمة',
    description TEXT NOT NULL COMMENT 'وصف الخدمة',
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0) COMMENT 'السعر',
    icon VARCHAR(50) NOT NULL COMMENT 'أيقونة FontAwesome',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط/غير نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='الخدمات الفردية';

-- ============================================
-- 3. جدول الباقات الشهرية (packages)
-- ============================================
CREATE TABLE packages (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'اسم الباقة',
    description TEXT NOT NULL COMMENT 'وصف الباقة',
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0) COMMENT 'السعر الشهري',
    features JSON NOT NULL COMMENT 'المميزات (مصفوفة)',
    is_featured BOOLEAN DEFAULT FALSE COMMENT 'باقة مميزة؟',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط/غير نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='الباقات الشهرية';

-- ============================================
-- 4. جدول العروض الخاصة (offers)
-- ============================================
CREATE TABLE offers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL COMMENT 'عنوان العرض',
    description TEXT NOT NULL COMMENT 'وصف العرض',
    badge VARCHAR(50) NULL COMMENT 'شارة العرض (مثلاً: حصري للمطاعم)',
    discount_type ENUM('percentage', 'fixed') NOT NULL COMMENT 'نوع الخصم (نسبة أو مبلغ ثابت)',
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0) COMMENT 'قيمة الخصم',
    original_price DECIMAL(10,2) NOT NULL CHECK (original_price >= 0) COMMENT 'السعر الأصلي',
    -- السعر بعد الخصم (محسوب آلياً)
    discount_price DECIMAL(10,2) GENERATED ALWAYS AS (
        CASE
            WHEN discount_type = 'percentage' THEN ROUND(original_price * (1 - discount_value/100), 2)
            ELSE original_price - discount_value
        END
    ) STORED COMMENT 'السعر بعد الخصم',
    applicable_to_type ENUM('service', 'package', 'none') DEFAULT 'none' COMMENT 'ينطبق على (خدمة، باقة، لا شيء)',
    applicable_to_id INT UNSIGNED NULL COMMENT 'معرف العنصر (إذا كان مطبقاً)',
    start_date DATE NOT NULL COMMENT 'بداية العرض',
    end_date DATE NOT NULL COMMENT 'نهاية العرض',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط/غير نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_applicable (applicable_to_type, applicable_to_id),
    INDEX idx_dates (start_date, end_date)
) ENGINE=InnoDB COMMENT='العروض الخاصة';

-- ============================================
-- 5. جدول الطلبات (orders)
-- ============================================
CREATE TABLE orders (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL COMMENT 'معرف المستخدم',
    order_number VARCHAR(20) UNIQUE NOT NULL COMMENT 'رقم الطلب (فريد)',
    order_type ENUM('service', 'package', 'offer') NOT NULL COMMENT 'نوع الطلب',
    item_id INT UNSIGNED NOT NULL COMMENT 'معرف العنصر (خدمة/باقة/عرض)',
    service_name VARCHAR(150) NOT NULL COMMENT 'اسم الخدمة/الباقة وقت الطلب',
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0) COMMENT 'السعر الأساسي',
    tax DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (tax >= 0) COMMENT 'الضريبة',
    discount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (discount >= 0) COMMENT 'الخصم',
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0) COMMENT 'الإجمالي',
    status ENUM('pending', 'processing', 'completed', 'cancelled') DEFAULT 'pending' COMMENT 'حالة الطلب',
    payment_method ENUM('card', 'applepay', 'stcpay', 'bank') NOT NULL COMMENT 'طريقة الدفع',
    payment_status ENUM('pending', 'paid', 'failed') DEFAULT 'pending' COMMENT 'حالة الدفع',
    transaction_reference VARCHAR(100) NULL COMMENT 'مرجع الدفع من بوابة الدفع',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_payment_status (payment_status)
) ENGINE=InnoDB COMMENT='الطلبات';

-- ============================================
-- 6. جدول تتبع الطلبات (order_tracking)
-- ============================================
CREATE TABLE order_tracking (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL COMMENT 'معرف الطلب',
    step INT UNSIGNED NOT NULL COMMENT 'رقم الخطوة',
    title VARCHAR(100) NOT NULL COMMENT 'عنوان الخطوة',
    description TEXT NULL COMMENT 'وصف الخطوة',
    completed BOOLEAN DEFAULT FALSE COMMENT 'مكتملة؟',
    estimated_date DATE NULL COMMENT 'التاريخ المتوقع',
    actual_date DATE NULL COMMENT 'التاريخ الفعلي',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    UNIQUE KEY unique_order_step (order_id, step)
) ENGINE=InnoDB COMMENT='مراحل تتبع الطلب';

-- ============================================
-- 7. جدول المشاريع (projects)
-- ============================================
CREATE TABLE projects (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL COMMENT 'معرف المستخدم',
    name VARCHAR(150) NOT NULL COMMENT 'اسم المشروع',
    description TEXT NULL COMMENT 'وصف المشروع',
    type ENUM('service', 'package') NOT NULL COMMENT 'نوع المشروع',
    package_id INT UNSIGNED NULL COMMENT 'معرف الباقة (إن وجد)',
    service_id INT UNSIGNED NULL COMMENT 'معرف الخدمة (إن وجدت)',
    status ENUM('active', 'inactive', 'completed') DEFAULT 'active' COMMENT 'حالة المشروع',
    progress INT UNSIGNED DEFAULT 0 CHECK (progress BETWEEN 0 AND 100) COMMENT 'نسبة التقدم',
    start_date DATE NOT NULL COMMENT 'تاريخ البدء',
    end_date DATE NULL COMMENT 'تاريخ الانتهاء',
    features JSON NULL COMMENT 'المميزات (لقطة من الباقة)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='مشاريع المستخدم';

-- ============================================
-- 8. جدول ملاحظات المشروع (project_notes)
-- ============================================
CREATE TABLE project_notes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    project_id INT UNSIGNED NOT NULL COMMENT 'معرف المشروع',
    note TEXT NOT NULL COMMENT 'الملاحظة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='ملاحظات المشروع';

-- ============================================
-- 9. جدول المدفوعات (payments)
-- ============================================
CREATE TABLE payments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL COMMENT 'معرف الطلب',
    user_id INT UNSIGNED NOT NULL COMMENT 'معرف المستخدم',
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0) COMMENT 'المبلغ',
    payment_method ENUM('card', 'applepay', 'stcpay', 'bank') NOT NULL COMMENT 'طريقة الدفع',
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending' COMMENT 'حالة الدفع',
    transaction_id VARCHAR(100) NULL COMMENT 'رقم العملية من البوابة',
    gateway_response JSON NULL COMMENT 'استجابة بوابة الدفع كاملة',
    receipt_sent BOOLEAN DEFAULT FALSE COMMENT 'هل تم إرسال الإيصال؟',
    payment_date DATETIME NULL COMMENT 'تاريخ الدفع الفعلي',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_order (order_id)
) ENGINE=InnoDB COMMENT='سجل المدفوعات';

-- ============================================
-- 10. جدول كوبونات الخصم (coupons)
-- ============================================
CREATE TABLE coupons (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL COMMENT 'كود الكوبون (فريد)',
    discount_type ENUM('percentage', 'fixed') NOT NULL COMMENT 'نوع الخصم',
    discount_value DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0) COMMENT 'قيمة الخصم',
    min_order_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (min_order_amount >= 0) COMMENT 'الحد الأدنى للطلب',
    max_uses INT UNSIGNED DEFAULT 1 COMMENT 'الحد الأقصى للاستخدام',
    used_count INT UNSIGNED DEFAULT 0 COMMENT 'عدد مرات الاستخدام',
    valid_from DATE NOT NULL COMMENT 'تاريخ البدء',
    valid_until DATE NOT NULL COMMENT 'تاريخ الانتهاء',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'نشط/غير نشط',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_code (code),
    INDEX idx_valid (valid_from, valid_until)
) ENGINE=InnoDB COMMENT='كوبونات الخصم';

-- ============================================
-- 11. جدول ربط الكوبونات بالطلبات (order_coupons)
-- ============================================
CREATE TABLE order_coupons (
    order_id INT UNSIGNED NOT NULL,
    coupon_id INT UNSIGNED NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (order_id, coupon_id),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='الطلبات والكوبونات المرتبطة';

-- ============================================
-- 12. جدول إحصائيات المستخدمين (user_stats) - اختياري
-- ============================================
CREATE TABLE user_stats (
    user_id INT UNSIGNED PRIMARY KEY,
    projects_count INT UNSIGNED DEFAULT 0 COMMENT 'عدد المشاريع',
    orders_count INT UNSIGNED DEFAULT 0 COMMENT 'عدد الطلبات',
    balance DECIMAL(10,2) DEFAULT 0.00 COMMENT 'الرصيد',
    membership_days INT UNSIGNED DEFAULT 0 COMMENT 'أيام العضوية',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='إحصائيات المستخدم (للتسريع)';

-- ============================================
-- 13. جدول الجلسات (sessions)
-- ============================================
CREATE TABLE sessions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL COMMENT 'معرف المستخدم',
    token VARCHAR(255) UNIQUE NOT NULL COMMENT 'توكن الجلسة',
    expires_at DATETIME NOT NULL COMMENT 'تاريخ انتهاء الجلسة',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token)
) ENGINE=InnoDB COMMENT='جلسات المستخدمين';

-- ============================================
-- إدخال البيانات التجريبية (Seeding)
-- ============================================

-- مستخدم تجريبي (كلمة المرور مشفرة: "password" باستخدام bcrypt، لكن هنا نضع قيمة وهمية)
INSERT INTO users (name, email, password, phone, business_type, avatar) VALUES
('أحمد محمد', 'ahmed@example.com', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '0551234567', 'restaurant', NULL),
('سارة علي', 'sara@example.com', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '0557654321', 'salon', NULL);

-- إحصائيات المستخدمين
INSERT INTO user_stats (user_id, projects_count, orders_count, balance, membership_days) VALUES
(1, 2, 5, 150.00, 30),
(2, 1, 3, 75.50, 15);

-- الخدمات
INSERT INTO services (name, description, price, icon) VALUES
('مقالة مدونة احترافية', 'مقالة متكاملة (800-1000 كلمة) حول موضوع يتناسب مع مجال عملك، مع تحسين لمحركات البحث وتركيب صور مناسبة.', 29.00, 'fa-newspaper'),
('حزمة تصاميم إنستغرام', '5 تصاميم احترافية لجزيرة الإنستغرام (بوست، ستوري، هايلايت) مصممة خصيصاً لعلامتك التجارية.', 49.00, 'fa-hashtag'),
('إعلان فيسبوك متكامل', 'تصميم إعلان + نص إعلان مكتوب بطريقة جذابة + استهداف دقيق لجمهورك المثالي على فيسبوك وإنستغرام.', 39.00, 'fa-ad'),
('حملة محتوى أسبوعية', '3 مقالات قصيرة + 7 تصاميم لوسائل التواصل + تقرير أداء أسبوعي. مثالي للحفاظ على وجود دائم على الإنترنت.', 99.00, 'fa-bullhorn'),
('محتوى فيديو قصير', 'سيناريو فيديو قصير (للرييلز أو تيك توك) + نص إرشادات تصوير + تصميم جرافيك للفيديو.', 59.00, 'fa-video'),
('تحليل أداء المحتوى', 'تحليل شامل لمحتواك الحالي + توصيات عملية للتحسين + خطة محتوى شهرية مخصصة لمشروعك.', 79.00, 'fa-chart-line');

-- الباقات
INSERT INTO packages (name, description, price, features, is_featured) VALUES
('باقة النشأة', 'باقة مناسبة للمشاريع الصغيرة في بداية الطريق.', 199.00, '["4 مقالات مدونة شهرياً", "8 تصاميم لوسائل التواصل", "2 تصميم إعلان فيسبوك", "تقرير شهري عن الأداء", "مراجعة محتوى أسبوعية"]', FALSE),
('باقة النمو', 'الباقة الأكثر طلباً للنمو المستدام.', 399.00, '["8 مقالات مدونة شهرياً", "16 تصميم لوسائل التواصل", "4 تصميمات إعلانية", "2 محتوى فيديو قصير", "إدارة حملة إعلانية واحدة", "تقرير أداء أسبوعي", "استشارة شهرية مع خبير"]', TRUE),
('باقة التميز', 'باقة شاملة للشركات التي تبحث عن التميز.', 699.00, '["12 مقالة مدونة شهرياً", "24 تصميم لوسائل التواصل", "8 تصميمات إعلانية", "4 محتوى فيديو قصير", "إدارة 3 حملات إعلانية", "تحليل منافسين شهري", "خطة محتوى ربع سنوية"]', FALSE);

-- العروض
INSERT INTO offers (title, description, badge, discount_type, discount_value, original_price, applicable_to_type, start_date, end_date) VALUES
('عرض التوفير الذهبي', 'باقة النمو كاملة لمدة 3 أشهر مع شهر إضافي مجاناً', 'الأكثر طلباً', 'percentage', 50.00, 399.00, 'package', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY)),
('حزمة المطاعم المميزة', 'تصاميم وأدوات خاصة للمطاعم', 'حصري للمطاعم', 'percentage', 40.00, 249.00, 'none', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY)),
('باقة الصالونات الجمالية', 'خدمات متكاملة للصالونات', 'للصالونات', 'percentage', 35.00, 275.00, 'none', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY));

-- كوبونات تجريبية
INSERT INTO coupons (code, discount_type, discount_value, min_order_amount, valid_from, valid_until, max_uses) VALUES
('RAWAJ10', 'percentage', 10.00, 50.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 100),
('RAWAAJ25', 'percentage', 25.00, 100.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), 50),
('WELCOME50', 'fixed', 50.00, 200.00, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 6 MONTH), 10);

-- طلبات تجريبية
INSERT INTO orders (user_id, order_number, order_type, item_id, service_name, price, tax, discount, total, status, payment_method, payment_status, transaction_reference) VALUES
(1, 'ORD-001', 'package', 2, 'باقة النمو', 399.00, 59.85, 0.00, 458.85, 'completed', 'card', 'paid', 'TXN123456'),
(2, 'ORD-002', 'service', 1, 'مقالة مدونة احترافية', 29.00, 4.35, 0.00, 33.35, 'processing', 'stcpay', 'paid', 'TXN789012'),
(1, 'ORD-003', 'offer', 1, 'عرض التوفير الذهبي', 199.50, 29.93, 0.00, 229.43, 'pending', 'bank', 'pending', NULL);

-- تتبع الطلبات
INSERT INTO order_tracking (order_id, step, title, description, completed, estimated_date, actual_date) VALUES
(1, 1, 'تم استلام الطلب', 'تم استلام طلبك بنجاح', TRUE, '2025-01-01', '2025-01-01'),
(1, 2, 'قيد المراجعة', 'يجري مراجعة الطلب من قبل فريقنا', TRUE, '2025-01-02', '2025-01-02'),
(1, 3, 'بدأ التنفيذ', 'بدأ العمل على مشروعك', TRUE, '2025-01-03', '2025-01-03'),
(1, 4, 'جارٍ العمل', 'يجري إعداد المحتوى', TRUE, '2025-01-10', NULL),
(1, 5, 'تم التسليم', 'تم تسليم الطلب', FALSE, '2025-01-15', NULL);

-- مشاريع تجريبية
INSERT INTO projects (user_id, name, description, type, package_id, service_id, status, progress, start_date, end_date, features) VALUES
(1, 'مشروع باقة النمو', 'مشروع شامل لتسويق المطعم عبر المحتوى', 'package', 2, NULL, 'active', 40, '2025-01-01', '2025-01-31', '["8 مقالات", "16 تصميم", "4 إعلانات", "2 فيديو", "إدارة حملة"]'),
(2, 'مقالة مدونة للمطعم', 'مقالة تعريفية عن المطعم', 'service', NULL, 1, 'active', 100, '2025-01-05', '2025-01-10', NULL);

-- ملاحظات مشروع
INSERT INTO project_notes (project_id, note) VALUES
(1, 'يرجى التركيز على صور الأكل في التصاميم'),
(1, 'تم إرسال المسودة الأولى للمقالات، بانتظار الموافقة');

-- مدفوعات تجريبية
INSERT INTO payments (order_id, user_id, amount, payment_method, status, transaction_id, gateway_response, receipt_sent, payment_date) VALUES
(1, 1, 458.85, 'card', 'completed', 'TXN123456', '{"status":"success","auth_code":"123abc"}', TRUE, '2025-01-01 10:30:00'),
(2, 2, 33.35, 'stcpay', 'completed', 'TXN789012', NULL, FALSE, '2025-01-05 15:45:00'),
(3, 1, 229.43, 'bank', 'pending', NULL, NULL, FALSE, NULL);

-- ============================================
-- إنشاء مستخدم قاعدة البيانات (اختياري)
-- ============================================
-- CREATE USER IF NOT EXISTS 'rawaaj_user'@'localhost' IDENTIFIED BY 'your_strong_password';
-- GRANT ALL PRIVILEGES ON rawaaj_db.* TO 'rawaaj_user'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================
-- انتهى ملف الإنشاء
-- ============================================
