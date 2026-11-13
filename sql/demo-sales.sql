-- ============================================================================
-- Demonstration sales: OPTIONAL. Import it after schema.sql and components.sql
-- only when the Sales page should have something to show. Leave it out and the
-- system is exactly as installed.
--
-- 18 made-up customers (email ending @demo.pcbuild.local, password Demo@1234) and
-- 67 orders over the last twelve months, counted back from the moment this
-- file is imported: 61 approved (sales), the rest cancelled or rejected. Every
-- configuration is one the rule engine accepts. Prices are taken from the
-- catalogue as it is when this file is imported.
--
-- Stock ends where it was. The shop builds to order: for each approved order
-- it ordered the parts in from its supplier and sold them, so the stock ledger
-- (stock_movement) gets a "received" row and a "sold" row for every line, both
-- naming the order, and the stock figures stay today's. The catalogue's
-- opening rows are dated back a year, to before the first of these sales, so
-- the Inventory log reads in order. Nothing is pending, so nothing is
-- reserved, and both of the dashboard's checks stay clear.
--
-- Importing it again replaces the earlier import: it first removes every
-- customer whose email ends @demo.pcbuild.local, with their orders and configurations.
--
-- Written by tools/make-demo-sales.php; edit that, not this.
-- ============================================================================

USE pc_build_configurator;

START TRANSACTION;

DELETE FROM stock_movement WHERE order_id IN (SELECT order_id FROM orders WHERE user_id IN (SELECT user_id FROM `user` WHERE email LIKE '%@demo.pcbuild.local'));
DELETE FROM orders WHERE user_id IN (SELECT user_id FROM `user` WHERE email LIKE '%@demo.pcbuild.local');
DELETE FROM quotation_request WHERE user_id IN (SELECT user_id FROM `user` WHERE email LIKE '%@demo.pcbuild.local');
DELETE FROM build WHERE user_id IN (SELECT user_id FROM `user` WHERE email LIKE '%@demo.pcbuild.local');
DELETE FROM `user` WHERE email LIKE '%@demo.pcbuild.local';

-- The first of this month, by the database's clock: every date below is counted from it.
SET @month0 = TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-01'));
-- Whoever approves: the administrator the database came with.
SET @admin = (SELECT user_id FROM `user` WHERE email = 'admin@pcbuild.local');
-- The catalogue's opening stock, dated back to before the first sale below.
UPDATE stock_movement SET created_at = @month0 - INTERVAL 12 MONTH
  WHERE reason = 'opening' AND user_id IS NULL AND created_at > @month0 - INTERVAL 12 MONTH;

INSERT INTO `user` (username, email, password_hash, role, created_at) VALUES
  ('Aisyah Rahman', 'aisyah.rahman@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 1 DAY),
  ('Daniel Tan', 'daniel.tan@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 2 DAY),
  ('Priya Nair', 'priya.nair@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 3 DAY),
  ('Muhammad Hafiz', 'muhammad.hafiz@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 4 DAY),
  ('Lim Wei Jie', 'lim.wei.jie@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 5 DAY),
  ('Nur Izzati', 'nur.izzati@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 6 DAY),
  ('Kevin Ong', 'kevin.ong@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 7 DAY),
  ('Siti Aminah', 'siti.aminah@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 8 DAY),
  ('Arjun Pillai', 'arjun.pillai@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 9 DAY),
  ('Chong Mei Ling', 'chong.mei.ling@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 10 DAY),
  ('Farid Ismail', 'farid.ismail@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 11 DAY),
  ('Jason Lee', 'jason.lee@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 12 DAY),
  ('Kavitha Raj', 'kavitha.raj@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 13 DAY),
  ('Amirul Hakim', 'amirul.hakim@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 14 DAY),
  ('Teoh Jia Hui', 'teoh.jia.hui@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 15 DAY),
  ('Ravi Kumar', 'ravi.kumar@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 16 DAY),
  ('Nadia Yusof', 'nadia.yusof@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 17 DAY),
  ('Ethan Goh', 'ethan.goh@demo.pcbuild.local', '$2y$12$KC64DPvbejqnNLf0Kpr2h./qO55dH7idIOy.I2OfD3.yqH4GBHzD.', 'customer', @month0 - INTERVAL 12 MONTH + INTERVAL 18 DAY);

-- Order 1: Daniel Tan, Streaming setup, approved, 11 months ago
SET @placed = @month0 - INTERVAL 11 MONTH + INTERVAL 14 DAY + INTERVAL 844 MINUTE;
SET @decided = @placed + INTERVAL 289 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i5-14400F' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 2: Lim Wei Jie, Streaming setup, approved, 11 months ago
SET @placed = @month0 - INTERVAL 11 MONTH + INTERVAL 13 DAY + INTERVAL 571 MINUTE;
SET @decided = @placed + INTERVAL 417 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 9800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 3: Arjun Pillai, Budget build, approved, 11 months ago
SET @placed = @month0 - INTERVAL 11 MONTH + INTERVAL 7 DAY + INTERVAL 574 MINUTE;
SET @decided = @placed + INTERVAL 1420 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'arjun.pillai@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 9800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 3 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 4: Daniel Tan, Home studio, approved, 10 months ago
SET @placed = @month0 - INTERVAL 10 MONTH + INTERVAL 4 DAY + INTERVAL 705 MINUTE;
SET @decided = @placed + INTERVAL 808 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING Z890-PLUS WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core Ultra 9 285K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'NH-D15 G2' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 5: Arjun Pillai, Office PC, approved, 10 months ago
SET @placed = @month0 - INTERVAL 10 MONTH + INTERVAL 3 DAY + INTERVAL 813 MINUTE;
SET @decided = @placed + INTERVAL 1323 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'arjun.pillai@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i5-14400F' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 Ti INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 6: Farid Ismail, Video editing rig, approved, 10 months ago
SET @placed = @month0 - INTERVAL 10 MONTH + INTERVAL 24 DAY + INTERVAL 691 MINUTE;
SET @decided = @placed + INTERVAL 1368 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'farid.ismail@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 9800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 7: Ravi Kumar, Study PC, approved, 10 months ago
SET @placed = @month0 - INTERVAL 10 MONTH + INTERVAL 0 DAY + INTERVAL 810 MINUTE;
SET @decided = @placed + INTERVAL 1063 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Study PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'ravi.kumar@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 8: Priya Nair, Family PC, cancelled, 10 months ago
SET @placed = @month0 - INTERVAL 10 MONTH + INTERVAL 4 DAY + INTERVAL 816 MINUTE;
SET @decided = @placed + INTERVAL 917 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Family PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'AEGIS DDR4 16GB 3200' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'cancelled', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

-- Order 9: Muhammad Hafiz, Office PC, approved, 9 months ago
SET @placed = @month0 - INTERVAL 9 MONTH + INTERVAL 18 DAY + INTERVAL 1019 MINUTE;
SET @decided = @placed + INTERVAL 736 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 Ti 8G' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'Gamma P550 550W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 10: Ethan Goh, Workstation, approved, 9 months ago
SET @placed = @month0 - INTERVAL 9 MONTH + INTERVAL 3 DAY + INTERVAL 618 MINUTE;
SET @decided = @placed + INTERVAL 714 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Workstation', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'ethan.goh@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 11: Farid Ismail, Office PC, approved, 9 months ago
SET @placed = @month0 - INTERVAL 9 MONTH + INTERVAL 2 DAY + INTERVAL 707 MINUTE;
SET @decided = @placed + INTERVAL 1413 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'farid.ismail@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'Dual Radeon RX 9060 XT 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 12: Nadia Yusof, Esports rig, approved, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 16 DAY + INTERVAL 1061 MINUTE;
SET @decided = @placed + INTERVAL 718 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nadia.yusof@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 13: Kavitha Raj, Gaming PC, approved, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 15 DAY + INTERVAL 767 MINUTE;
SET @decided = @placed + INTERVAL 1329 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'kavitha.raj@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'Dual Radeon RX 9060 XT 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 14: Daniel Tan, Family PC, approved, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 11 DAY + INTERVAL 739 MINUTE;
SET @decided = @placed + INTERVAL 620 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Family PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'RM1000E 1000W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 15: Daniel Tan, Home studio 2, approved, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 13 DAY + INTERVAL 591 MINUTE;
SET @decided = @placed + INTERVAL 702 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 16: Siti Aminah, Gaming PC, approved, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 1 DAY + INTERVAL 864 MINUTE;
SET @decided = @placed + INTERVAL 1350 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'siti.aminah@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 17: Muhammad Hafiz, Streaming setup, cancelled, 8 months ago
SET @placed = @month0 - INTERVAL 8 MONTH + INTERVAL 11 DAY + INTERVAL 984 MINUTE;
SET @decided = @placed + INTERVAL 1078 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'cancelled', total_price, 'Our supplier could not deliver the graphics card this month.', @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

-- Order 18: Chong Mei Ling, Home studio, approved, 7 months ago
SET @placed = @month0 - INTERVAL 7 MONTH + INTERVAL 9 DAY + INTERVAL 649 MINUTE;
SET @decided = @placed + INTERVAL 1140 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'chong.mei.ling@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'AEGIS DDR4 16GB 3200' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 19: Priya Nair, Streaming setup, approved, 7 months ago
SET @placed = @month0 - INTERVAL 7 MONTH + INTERVAL 1 DAY + INTERVAL 800 MINUTE;
SET @decided = @placed + INTERVAL 690 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'Dual Radeon RX 9060 XT 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 20: Kavitha Raj, Video editing rig, approved, 7 months ago
SET @placed = @month0 - INTERVAL 7 MONTH + INTERVAL 17 DAY + INTERVAL 857 MINUTE;
SET @decided = @placed + INTERVAL 843 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'kavitha.raj@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'NH-D15 G2' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 21: Farid Ismail, Study PC, approved, 7 months ago
SET @placed = @month0 - INTERVAL 7 MONTH + INTERVAL 3 DAY + INTERVAL 1206 MINUTE;
SET @decided = @placed + INTERVAL 1405 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Study PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'farid.ismail@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'NH-D15 G2' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 22: Jason Lee, Budget build, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 7 DAY + INTERVAL 956 MINUTE;
SET @decided = @placed + INTERVAL 1312 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'jason.lee@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 23: Arjun Pillai, Workstation, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 15 DAY + INTERVAL 557 MINUTE;
SET @decided = @placed + INTERVAL 298 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Workstation', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'arjun.pillai@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 24: Chong Mei Ling, Esports rig, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 6 DAY + INTERVAL 774 MINUTE;
SET @decided = @placed + INTERVAL 712 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'chong.mei.ling@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'RM1000E 1000W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 25: Kavitha Raj, Home studio, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 20 DAY + INTERVAL 821 MINUTE;
SET @decided = @placed + INTERVAL 798 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'kavitha.raj@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 26: Muhammad Hafiz, Budget build, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 6 DAY + INTERVAL 1046 MINUTE;
SET @decided = @placed + INTERVAL 772 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 27: Aisyah Rahman, Video editing rig, approved, 6 months ago
SET @placed = @month0 - INTERVAL 6 MONTH + INTERVAL 8 DAY + INTERVAL 1223 MINUTE;
SET @decided = @placed + INTERVAL 487 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'aisyah.rahman@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i5-14400F' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 28: Chong Mei Ling, Family PC, approved, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 16 DAY + INTERVAL 881 MINUTE;
SET @decided = @placed + INTERVAL 349 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Family PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'chong.mei.ling@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 29: Lim Wei Jie, Video editing rig, approved, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 8 DAY + INTERVAL 846 MINUTE;
SET @decided = @placed + INTERVAL 1277 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING Z890-PLUS WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core Ultra 9 285K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 30: Jason Lee, Home studio, approved, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 2 DAY + INTERVAL 605 MINUTE;
SET @decided = @placed + INTERVAL 527 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'jason.lee@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 31: Aisyah Rahman, Video editing rig 2, approved, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 22 DAY + INTERVAL 1062 MINUTE;
SET @decided = @placed + INTERVAL 1009 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'aisyah.rahman@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'Gamma P550 550W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 32: Aisyah Rahman, Gaming PC, approved, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 12 DAY + INTERVAL 1073 MINUTE;
SET @decided = @placed + INTERVAL 251 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'aisyah.rahman@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING Z890-PLUS WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core Ultra 9 285K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 33: Muhammad Hafiz, Study PC, cancelled, 5 months ago
SET @placed = @month0 - INTERVAL 5 MONTH + INTERVAL 12 DAY + INTERVAL 945 MINUTE;
SET @decided = @placed + INTERVAL 1381 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Study PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'cancelled', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

-- Order 34: Nur Izzati, Study PC, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 22 DAY + INTERVAL 694 MINUTE;
SET @decided = @placed + INTERVAL 856 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Study PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nur.izzati@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 Ti 8G' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 35: Chong Mei Ling, Streaming setup, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 16 DAY + INTERVAL 864 MINUTE;
SET @decided = @placed + INTERVAL 205 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'chong.mei.ling@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 36: Priya Nair, Office PC, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 1 DAY + INTERVAL 1183 MINUTE;
SET @decided = @placed + INTERVAL 1416 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 37: Teoh Jia Hui, Budget build, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 16 DAY + INTERVAL 752 MINUTE;
SET @decided = @placed + INTERVAL 1149 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'teoh.jia.hui@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 3 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 38: Lim Wei Jie, Gaming PC, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 5 DAY + INTERVAL 631 MINUTE;
SET @decided = @placed + INTERVAL 114 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 39: Daniel Tan, Home studio 3, approved, 4 months ago
SET @placed = @month0 - INTERVAL 4 MONTH + INTERVAL 1 DAY + INTERVAL 1043 MINUTE;
SET @decided = @placed + INTERVAL 766 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio 3', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'Dual Radeon RX 9060 XT 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 40: Kevin Ong, Budget build, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 4 DAY + INTERVAL 1069 MINUTE;
SET @decided = @placed + INTERVAL 1214 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'kevin.ong@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 41: Lim Wei Jie, Study PC, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 8 DAY + INTERVAL 994 MINUTE;
SET @decided = @placed + INTERVAL 883 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Study PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'AEGIS DDR4 16GB 3200' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 42: Nadia Yusof, Streaming setup, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 7 DAY + INTERVAL 802 MINUTE;
SET @decided = @placed + INTERVAL 1250 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nadia.yusof@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'RM1000E 1000W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 43: Priya Nair, Office PC 2, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 20 DAY + INTERVAL 895 MINUTE;
SET @decided = @placed + INTERVAL 363 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 44: Aisyah Rahman, Video editing rig 3, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 0 DAY + INTERVAL 596 MINUTE;
SET @decided = @placed + INTERVAL 851 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Video editing rig 3', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'aisyah.rahman@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'MWE GOLD V3 850W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 45: Lim Wei Jie, Gaming PC 2, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 21 DAY + INTERVAL 983 MINUTE;
SET @decided = @placed + INTERVAL 184 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 46: Priya Nair, Gaming PC, approved, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 19 DAY + INTERVAL 828 MINUTE;
SET @decided = @placed + INTERVAL 1376 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'NH-D15 G2' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 47: Lim Wei Jie, Office PC, rejected, 3 months ago
SET @placed = @month0 - INTERVAL 3 MONTH + INTERVAL 11 DAY + INTERVAL 1071 MINUTE;
SET @decided = @placed + INTERVAL 233 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Office PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'rejected', total_price, 'The case you chose is out of production; please choose another and resubmit.', @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

-- Order 48: Daniel Tan, Budget build, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 24 DAY + INTERVAL 1050 MINUTE;
SET @decided = @placed + INTERVAL 371 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 49: Arjun Pillai, Workstation 2, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 4 DAY + INTERVAL 710 MINUTE;
SET @decided = @placed + INTERVAL 318 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Workstation 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'arjun.pillai@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 Ti INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 50: Nur Izzati, Home studio, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 14 DAY + INTERVAL 549 MINUTE;
SET @decided = @placed + INTERVAL 1437 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nur.izzati@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 OC Low Profile 8GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 51: Muhammad Hafiz, Home studio, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 18 DAY + INTERVAL 1110 MINUTE;
SET @decided = @placed + INTERVAL 91 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 52: Lim Wei Jie, Streaming setup 2, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 14 DAY + INTERVAL 989 MINUTE;
SET @decided = @placed + INTERVAL 589 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 53: Muhammad Hafiz, Budget build 2, approved, 2 months ago
SET @placed = @month0 - INTERVAL 2 MONTH + INTERVAL 7 DAY + INTERVAL 881 MINUTE;
SET @decided = @placed + INTERVAL 87 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'MWE GOLD V3 850W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 54: Nadia Yusof, Esports rig 2, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 15 DAY + INTERVAL 1106 MINUTE;
SET @decided = @placed + INTERVAL 200 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nadia.yusof@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i5-14400F' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'RM1000E 1000W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 55: Daniel Tan, Gaming PC, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 22 DAY + INTERVAL 847 MINUTE;
SET @decided = @placed + INTERVAL 1283 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR4 Desktop 16GB 3200 CL22' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'Dual Radeon RX 9060 XT 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 56: Priya Nair, Esports rig, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 18 DAY + INTERVAL 564 MINUTE;
SET @decided = @placed + INTERVAL 180 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 GAMING TRIO OC 12GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'Gamma P550 550W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 57: Nur Izzati, Streaming setup, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 23 DAY + INTERVAL 1141 MINUTE;
SET @decided = @placed + INTERVAL 397 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nur.izzati@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'H610M K DDR4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i9-14900K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'NOX DDR4 8GB 3200' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'N300 NAS 4TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 58: Lim Wei Jie, Budget build, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 15 DAY + INTERVAL 1058 MINUTE;
SET @decided = @placed + INTERVAL 1256 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'lim.wei.jie@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 59: Priya Nair, Family PC 2, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 12 DAY + INTERVAL 636 MINUTE;
SET @decided = @placed + INTERVAL 514 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Family PC 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'MAG B850M MORTAR WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 Black' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5070 Ti INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GP-P650SS 650W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 60: Aisyah Rahman, Esports rig, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 22 DAY + INTERVAL 1076 MINUTE;
SET @decided = @placed + INTERVAL 343 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'aisyah.rahman@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 9 9950X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'P3 Plus 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 61: Nur Izzati, Esports rig, approved, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 18 DAY + INTERVAL 902 MINUTE;
SET @decided = @placed + INTERVAL 354 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Esports rig', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nur.izzati@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 9800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GAMING GeForce RTX 5090 SOLID OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 62: Muhammad Hafiz, Streaming setup 2, cancelled, 1 month ago
SET @placed = @month0 - INTERVAL 1 MONTH + INTERVAL 22 DAY + INTERVAL 1032 MINUTE;
SET @decided = @placed + INTERVAL 165 MINUTE;
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Streaming setup 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'muhammad.hafiz@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING Z890-PLUS WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core Ultra 9 285K' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Peerless Assassin 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'MWE GOLD V3 850W ATX3.1' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'cancelled', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

-- Order 63: Nadia Yusof, Gaming PC, approved this month
SET @placed = @month0 + INTERVAL FLOOR(TIMESTAMPDIFF(MINUTE, @month0, NOW()) * 0.19) MINUTE;
SET @decided = LEAST(NOW(), @placed + INTERVAL 123 MINUTE);
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'nadia.yusof@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 9800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'DDR5 U-DIMM 16GB 5600' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'BarraCuda 2TB SATA HDD' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, '4000D AIRFLOW' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Dark Rock Pro 5' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5080 INSPIRE 3X OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'AP Series 750W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 64: Daniel Tan, Budget build 2, approved this month
SET @placed = @month0 + INTERVAL FLOOR(TIMESTAMPDIFF(MINUTE, @month0, NOW()) * 0.54) MINUTE;
SET @decided = LEAST(NOW(), @placed + INTERVAL 66 MINUTE);
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Budget build 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'daniel.tan@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 9600X' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'Phantom Spirit 120 SE' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'PRIME Radeon RX 9070 EVO OC 16GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 65: Priya Nair, Workstation, approved this month
SET @placed = @month0 + INTERVAL FLOOR(TIMESTAMPDIFF(MINUTE, @month0, NOW()) * 0.79) MINUTE;
SET @decided = LEAST(NOW(), @placed + INTERVAL 122 MINUTE);
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Workstation', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'priya.nair@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'PRO X870E-S EVO WIFI' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 5 8600G' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30' AS part, 2 AS quantity
        UNION ALL SELECT 'Storage' AS category, 'SN850X 2TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'AIR 903 MAX Black' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 66: Siti Aminah, Gaming PC 2, approved this month
SET @placed = @month0 + INTERVAL FLOOR(TIMESTAMPDIFF(MINUTE, @month0, NOW()) * 0.7) MINUTE;
SET @decided = LEAST(NOW(), @placed + INTERVAL 151 MINUTE);
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Gaming PC 2', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'siti.aminah@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'TUF GAMING B760M-PLUS WIFI D4' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Core i5-14400F' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'NOX DDR4 8GB 3200' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 2 AS quantity
        UNION ALL SELECT 'Case' AS category, 'LANCOOL 216' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5060 Ti 8G' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'GAMERSTORM PFX PF500X 500W' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'approved', total_price, NULL, @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note, created_at)
  SELECT oi.component_id, oi.quantity, c.stock_qty + oi.quantity, 'received', @order, @admin, 'Ordered in from the supplier', @decided - INTERVAL 1 MINUTE
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, created_at)
  SELECT oi.component_id, -oi.quantity, c.stock_qty, 'sold', @order, @admin, @decided
  FROM order_item oi JOIN component c ON c.component_id = oi.component_id WHERE oi.order_id = @order ORDER BY oi.component_id;

-- Order 67: Teoh Jia Hui, Home studio, rejected this month
SET @placed = @month0 + INTERVAL FLOOR(TIMESTAMPDIFF(MINUTE, @month0, NOW()) * 0.09) MINUTE;
SET @decided = LEAST(NOW(), @placed + INTERVAL 61 MINUTE);
INSERT INTO build (user_id, build_name, total_price, total_wattage, is_valid, created_at, updated_at)
  SELECT user_id, 'Home studio', 0, 0, 1, @placed - INTERVAL 30 MINUTE, @placed - INTERVAL 30 MINUTE FROM `user` WHERE email = 'teoh.jia.hui@demo.pcbuild.local';
SET @build = LAST_INSERT_ID();
INSERT INTO build_item (build_id, component_id, quantity)
  SELECT @build, c.component_id, p.quantity
  FROM (SELECT 'Motherboard' AS category, 'B850 AORUS STEALTH BLACK' AS part, 1 AS quantity
        UNION ALL SELECT 'CPU' AS category, 'Ryzen 7 7800X3D' AS part, 1 AS quantity
        UNION ALL SELECT 'RAM' AS category, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36' AS part, 1 AS quantity
        UNION ALL SELECT 'Storage' AS category, '990 PRO 1TB PCIe Gen4 NVMe' AS part, 1 AS quantity
        UNION ALL SELECT 'Case' AS category, 'CH560 White' AS part, 1 AS quantity
        UNION ALL SELECT 'Cooler' AS category, 'AK620' AS part, 1 AS quantity
        UNION ALL SELECT 'GPU' AS category, 'GeForce RTX 5090 GAMING TRIO OC 32GB' AS part, 1 AS quantity
        UNION ALL SELECT 'PSU' AS category, 'PQ1200G 1200W Fully Modular' AS part, 1 AS quantity) p
  JOIN category k ON k.category_name = p.category
  JOIN component c ON c.category_id = k.category_id AND c.name = p.part;
UPDATE build SET updated_at = created_at,
  total_price = (SELECT SUM(bi.quantity * c.price) FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build),
  total_wattage = (SELECT SUM(bi.quantity * COALESCE(c.wattage, 0)) FROM build_item bi JOIN component c ON c.component_id = bi.component_id
                   JOIN category k ON k.category_id = c.category_id WHERE bi.build_id = @build AND k.category_name <> 'PSU')
  WHERE build_id = @build;
INSERT INTO orders (user_id, build_id, status, total_price, admin_remark, created_at, updated_at)
  SELECT user_id, build_id, 'rejected', total_price, 'Please call us about the delivery address before we accept this order.', @placed, @decided FROM build WHERE build_id = @build;
SET @order = LAST_INSERT_ID();
INSERT INTO order_item (order_id, component_id, quantity, unit_price_snapshot)
  SELECT @order, bi.component_id, bi.quantity, c.price FROM build_item bi JOIN component c ON c.component_id = bi.component_id WHERE bi.build_id = @build;

COMMIT;
