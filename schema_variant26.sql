-- =====================================================
-- БАЗА ДАННЫХ ДЛЯ СИСТЕМЫ ЗАПИСИ В АТЕЛЬЕ
-- Студент: Шило Александр Александрович
-- Группа: 454
-- Вариант: 26
-- Дата: 19.05.2026
-- =====================================================

-- 1. СОЗДАНИЕ БАЗЫ ДАННЫХ
CREATE DATABASE IF NOT EXISTS atelier_variant26 
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. ПЕРЕКЛЮЧЕНИЕ НА БАЗУ ДАННЫХ
USE atelier_variant26;

-- 3. УДАЛЕНИЕ СТАРЫХ ТАБЛИЦ (ЕСЛИ ОНИ ЕСТЬ)
DROP TABLE IF EXISTS order_accessory;
DROP TABLE IF EXISTS order_stage;
DROP TABLE IF EXISTS garment_order;
DROP TABLE IF EXISTS accessory;
DROP TABLE IF EXISTS seamstress;
DROP TABLE IF EXISTS client;
DROP TRIGGER IF EXISTS check_complexity_vs_skill_rank;

-- =====================================================
-- 4. СОЗДАНИЕ ТАБЛИЦ
-- =====================================================

-- 4.1 ТАБЛИЦА КЛИЕНТОВ
CREATE TABLE client (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- 4.2 ТАБЛИЦА ШВЕЙ
CREATE TABLE seamstress (
    seamstress_id INT AUTO_INCREMENT PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    skill_rank INT NOT NULL CHECK (skill_rank BETWEEN 1 AND 6)
);

-- 4.3 ТАБЛИЦА ФУРНИТУРЫ
CREATE TABLE accessory (
    accessory_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    unit VARCHAR(20) NOT NULL
);

-- 4.4 ТАБЛИЦА ЗАКАЗОВ
CREATE TABLE garment_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    seamstress_id INT NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    complexity INT NOT NULL CHECK (complexity BETWEEN 1 AND 5),
    created_date DATE NOT NULL DEFAULT (CURDATE()),
    status ENUM('в работе', 'готов', 'отменён') DEFAULT 'в работе',
    FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (seamstress_id) REFERENCES seamstress(seamstress_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 4.5 ТРИГГЕР ДЛЯ ПРОВЕРКИ ПРАВИЛА (сложность >3 нельзя швее с разрядом 2)
DELIMITER $$
CREATE TRIGGER check_complexity_vs_skill_rank
BEFORE INSERT ON garment_order
FOR EACH ROW
BEGIN
    DECLARE seamstress_skill_rank INT;
    SELECT skill_rank INTO seamstress_skill_rank FROM seamstress WHERE seamstress_id = NEW.seamstress_id;
    IF NEW.complexity > 3 AND seamstress_skill_rank <= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Заказ сложности выше 3 нельзя назначить швее с разрядом 2';
    END IF;
END$$
DELIMITER ;

-- 4.6 ТАБЛИЦА ЭТАПОВ ЗАКАЗА
CREATE TABLE order_stage (
    order_id INT NOT NULL,
    stage ENUM('раскрой', 'примерка', 'пошив', 'финиш') NOT NULL,
    start_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_date DATETIME,
    PRIMARY KEY (order_id, stage),
    FOREIGN KEY (order_id) REFERENCES garment_order(order_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- 4.7 ТАБЛИЦА ИСПОЛЬЗОВАНИЯ ФУРНИТУРЫ
CREATE TABLE order_accessory (
    order_accessory_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    accessory_id INT NOT NULL,
    quantity_used INT NOT NULL CHECK (quantity_used > 0),
    FOREIGN KEY (order_id) REFERENCES garment_order(order_id) ON DELETE CASCADE,
    FOREIGN KEY (accessory_id) REFERENCES accessory(accessory_id) ON DELETE RESTRICT,
    UNIQUE KEY unique_order_accessory (order_id, accessory_id)
);

-- =====================================================
-- 5. СОЗДАНИЕ ИНДЕКСОВ ДЛЯ УСКОРЕНИЯ ЗАПРОСОВ
-- =====================================================
CREATE INDEX idx_order_client ON garment_order(client_id);
CREATE INDEX idx_order_seamstress ON garment_order(seamstress_id);
CREATE INDEX idx_stage_enddate ON order_stage(end_date);
CREATE INDEX idx_accessory_stock ON accessory(stock);

-- =====================================================
-- 6. ЗАПОЛНЕНИЕ ТЕСТОВЫМИ ДАННЫМИ
-- =====================================================

-- 6.1 КЛИЕНТЫ (5 записей)
INSERT INTO client (last_name, first_name, phone, email) VALUES
('Иванова', 'Анна', '+79161234567', 'anna@mail.ru'),
('Петров', 'Игорь', '+79162345678', 'igor@mail.ru'),
('Сидорова', 'Мария', '+79163456789', 'maria@mail.ru'),
('Козлов', 'Дмитрий', '+79164567890', 'dmitry@mail.ru'),
('Новикова', 'Елена', '+79165678901', 'elena@mail.ru');

-- 6.2 ШВЕИ (5 записей)
INSERT INTO seamstress (last_name, first_name, skill_rank) VALUES
('Кузнецова', 'Елена', 4),
('Смирнова', 'Ольга', 2),
('Васильева', 'Татьяна', 5),
('Морозова', 'Ирина', 3),
('Фёдорова', 'Светлана', 1);

-- 6.3 ФУРНИТУРА (5 записей)
INSERT INTO accessory (name, stock, unit) VALUES
('Пуговица белая', 200, 'шт'),
('Молния 50см', 50, 'шт'),
('Нитки чёрные', 30, 'катушка'),
('Кружево', 15, 'метр'),
('Лента атласная', 40, 'метр');

-- 6.4 ЗАКАЗЫ (5 записей)
INSERT INTO garment_order (client_id, seamstress_id, fabric_type, complexity, created_date, status) VALUES
(1, 1, 'шёлк', 4, '2026-05-10', 'в работе'),
(2, 2, 'лён', 2, '2026-05-12', 'в работе'),
(3, 3, 'джинса', 5, '2026-05-14', 'в работе'),
(4, 4, 'хлопок', 3, '2026-05-15', 'в работе'),
(5, 5, 'вельвет', 2, '2026-05-16', 'готов');

-- 6.5 ЭТАПЫ ЗАКАЗОВ (12 записей)
INSERT INTO order_stage (order_id, stage, start_date, end_date) VALUES
(1, 'раскрой', '2026-05-10 09:00:00', '2026-05-10 11:00:00'),
(1, 'примерка', '2026-05-11 10:00:00', NULL),
(2, 'раскрой', '2026-05-12 09:00:00', '2026-05-12 10:00:00'),
(2, 'примерка', '2026-05-13 09:00:00', '2026-05-13 10:00:00'),
(2, 'пошив', '2026-05-14 09:00:00', NULL),
(3, 'раскрой', '2026-05-14 09:00:00', NULL),
(4, 'раскрой', '2026-05-15 09:00:00', '2026-05-15 11:00:00'),
(4, 'примерка', '2026-05-16 10:00:00', NULL),
(5, 'раскрой', '2026-05-16 09:00:00', '2026-05-16 10:00:00'),
(5, 'примерка', '2026-05-17 09:00:00', '2026-05-17 10:00:00'),
(5, 'пошив', '2026-05-18 09:00:00', '2026-05-18 16:00:00'),
(5, 'финиш', '2026-05-19 09:00:00', NULL);

-- 6.6 ИСПОЛЬЗОВАНИЕ ФУРНИТУРЫ (6 записей)
INSERT INTO order_accessory (order_id, accessory_id, quantity_used) VALUES
(1, 1, 6),
(1, 2, 1),
(2, 3, 2),
(3, 1, 4),
(4, 4, 3),
(5, 5, 2);

-- =====================================================
-- 7. СООБЩЕНИЕ ОБ УСПЕШНОМ СОЗДАНИИ
-- =====================================================
SELECT 'База данных atelier_variant26 успешно создана!' AS Результат;
