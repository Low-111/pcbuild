-- ===========================================================================
-- PC Build Configurator and Inventory Management System
-- DCS2102 Rapid Application Development
--
-- Schema and reference data. Import through phpMyAdmin, or:
--     mysql -u root < schema.sql
--
-- Ten tables, eighty-one columns, fifteen foreign keys (nine, seventy-two and
-- twelve until the stock ledger, stock_movement, on 3 November 2026). It began
-- as section 7 of the project proposal, column for column, and has since moved past it on
-- purpose: two processor columns, two more categories (Cooler, Case) and a
-- third kind of rule were added on 25 September 2026, and four counts (memory
-- slots, M.2 slots, SATA ports, drive bays) with the rules that compare them
-- on 29 September, after the proposal was handed in. The proposal was left as
-- submitted (the team's decision).
--
-- Component rows are NOT in this file. They carry real retail prices that
-- have to be looked up rather than invented, and they live in components.sql.
-- ===========================================================================

DROP DATABASE IF EXISTS pc_build_configurator;
CREATE DATABASE pc_build_configurator
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE pc_build_configurator;


-- ---------------------------------------------------------------------------
-- 1. user
-- One row per person who can log in. The role is what the session carries and
-- what decides which pages a user may reach.
-- ---------------------------------------------------------------------------
CREATE TABLE `user` (
  user_id        INT AUTO_INCREMENT PRIMARY KEY,
  username       VARCHAR(50)  NOT NULL,
  email          VARCHAR(100) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,
  role           ENUM('customer','admin') NOT NULL DEFAULT 'customer',
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_user_email UNIQUE (email)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 2. category
-- Eight rows. Three of its columns drive the configurator, so the
-- behaviour of the system changes by editing data rather than code.
-- ---------------------------------------------------------------------------
CREATE TABLE category (
  category_id    INT AUTO_INCREMENT PRIMARY KEY,
  category_name  VARCHAR(30)      NOT NULL,
  max_quantity   TINYINT UNSIGNED NOT NULL DEFAULT 1,
  is_required    TINYINT(1)       NOT NULL DEFAULT 1,
  display_order  TINYINT UNSIGNED NOT NULL,
  CONSTRAINT uq_category_name UNIQUE (category_name),
  CONSTRAINT ck_category_max_quantity CHECK (max_quantity >= 1)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 3. component
-- One row per product the shop sells. socket and memory_type are the
-- attributes the compatibility rules compare, and are null for the categories
-- that do not have them. wattage is power drawn, except on a PSU where it is
-- power supplied.
--
-- has_integrated_graphics and includes_cooler describe a processor, and are
-- null on every other category: whether it can drive a screen without a
-- graphics card, and whether a cooler comes in its box. The REQUIRES_CATEGORY
-- rules read them to decide whether a build also needs a GPU or a Cooler.
--
-- memory_slots, m2_slots, sata_ports and drive_bays are counts, read the way
-- wattage is: on the part that sets a limit they are what it has, on every
-- other part what it takes. A motherboard has 4 memory slots and a kit of two
-- sticks takes 2; a board has 3 M.2 slots and an NVMe drive takes 1; a case
-- has 2 drive bays (3.5-inch, for hard disks) and a hard disk takes 1 of them
-- and 1 SATA port. Null where a part has nothing to do with the count.
-- ---------------------------------------------------------------------------
CREATE TABLE component (
  component_id  INT AUTO_INCREMENT PRIMARY KEY,
  category_id   INT           NOT NULL,
  name          VARCHAR(120)  NOT NULL,
  brand         VARCHAR(50)   NOT NULL,
  price         DECIMAL(10,2) NOT NULL,
  stock_qty     INT           NOT NULL DEFAULT 0,
  reserved_qty  INT           NOT NULL DEFAULT 0,
  wattage       INT           NOT NULL DEFAULT 0,
  capacity_gb   INT           NULL,
  socket        VARCHAR(20)   NULL,
  memory_type   VARCHAR(10)   NULL,
  has_integrated_graphics TINYINT(1) NULL,
  includes_cooler         TINYINT(1) NULL,
  memory_slots  TINYINT UNSIGNED NULL,
  m2_slots      TINYINT UNSIGNED NULL,
  sata_ports    TINYINT UNSIGNED NULL,
  drive_bays    TINYINT UNSIGNED NULL,
  image_url     VARCHAR(255)  NULL,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  CONSTRAINT uq_component_category_name UNIQUE (category_id, name),
  CONSTRAINT fk_component_category FOREIGN KEY (category_id)
    REFERENCES category (category_id) ON DELETE RESTRICT,
  CONSTRAINT ck_component_price    CHECK (price >= 0),
  CONSTRAINT ck_component_stock    CHECK (stock_qty >= 0),
  CONSTRAINT ck_component_reserved CHECK (reserved_qty >= 0),
  CONSTRAINT ck_component_wattage  CHECK (wattage >= 0),
  CONSTRAINT ck_component_graphics CHECK (has_integrated_graphics IN (0, 1)),
  CONSTRAINT ck_component_cooler   CHECK (includes_cooler IN (0, 1))
) ENGINE=InnoDB;

CREATE INDEX ix_component_category ON component (category_id, is_active);


-- ---------------------------------------------------------------------------
-- 4. compatibility_rule
-- The table that makes the system extensible. The application reads every
-- active row and applies whatever it finds, so a rule inserted here takes
-- effect without any change to the source code.
--
-- ATTRIBUTE_MATCH  category_a is the left of the comparison, category_b the right.
--                  headroom_pct is NULL: nothing is being sized.
-- CAPACITY_CHECK   category_a holds the limit and category_b is NULL, because
--                  the sum is taken across the whole build: the power supply's
--                  output against what everything else draws, or a board's
--                  slots and a case's bays against what the parts take.
--                  headroom_pct is the share of that limit a build may plan to
--                  use, and NULL means the whole of it.
-- REQUIRES_CATEGORY  category_a is looked at, category_b is what it may need.
--                  The rule fails when the component chosen in category_a has
--                  attribute_key = 0 and category_b holds nothing: a processor
--                  without integrated graphics needs a graphics card. NULL
--                  counts as 0, so a processor whose flag was never filled in
--                  asks for the part rather than letting the build through.
--                  headroom_pct is NULL. Like the others, it is skipped while
--                  category_a is empty.
--
-- WHY headroom_pct EXISTS. A power supply's rated output is what it can deliver
-- at peak, not a budget a machine may sit against continuously. Comparing the
-- sum of the draws against the rated output alone is therefore too generous,
-- and measurably so: NVIDIA asks for a 650W supply behind a GeForce RTX 5070
-- and gives a Ryzen 9 9950X as the reference processor, while the parts of that
-- same machine draw about 506W by the figures in this catalogue. Without a
-- headroom the rule passes that build on a 550W unit the manufacturer says is
-- too small. At 80.00, the conventional planning ceiling, the rule agrees with
-- the manufacturer on every supply stocked: 500W and 550W are refused, 650W is
-- allowed. The figure is data rather than code, so an administrator who
-- disagrees changes one cell in phpMyAdmin.
-- ---------------------------------------------------------------------------
CREATE TABLE compatibility_rule (
  rule_id        INT AUTO_INCREMENT PRIMARY KEY,
  rule_name      VARCHAR(100) NOT NULL,
  rule_type      ENUM('ATTRIBUTE_MATCH','CAPACITY_CHECK','REQUIRES_CATEGORY') NOT NULL,
  category_a     INT          NOT NULL,
  category_b     INT          NULL,
  attribute_key  VARCHAR(30)  NOT NULL,
  headroom_pct   DECIMAL(5,2) NULL,
  error_message  VARCHAR(255) NOT NULL,
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  CONSTRAINT ck_rule_headroom CHECK (
    headroom_pct IS NULL
    OR (rule_type = 'CAPACITY_CHECK' AND headroom_pct > 0 AND headroom_pct <= 100)),
  -- Only a capacity check works without a second category.
  CONSTRAINT ck_rule_category_b CHECK ((rule_type = 'CAPACITY_CHECK') = (category_b IS NULL)),
  CONSTRAINT fk_rule_category_a FOREIGN KEY (category_a)
    REFERENCES category (category_id) ON DELETE RESTRICT,
  CONSTRAINT fk_rule_category_b FOREIGN KEY (category_b)
    REFERENCES category (category_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 5. build
-- A configuration saved by a customer. The stored totals are the figures at
-- the moment of saving; reopening one recalculates from current prices and
-- shows the difference. is_valid means complete AND passing every active rule.
-- ---------------------------------------------------------------------------
CREATE TABLE build (
  build_id       INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT           NOT NULL,
  build_name     VARCHAR(100)  NOT NULL,
  total_price    DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_wattage  INT           NOT NULL DEFAULT 0,
  is_valid       TINYINT(1)    NOT NULL DEFAULT 0,
  created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_build_user_name UNIQUE (user_id, build_name),
  CONSTRAINT fk_build_user FOREIGN KEY (user_id)
    REFERENCES `user` (user_id) ON DELETE RESTRICT
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 6. build_item
-- Junction between build and component, carrying the quantity chosen.
-- ---------------------------------------------------------------------------
CREATE TABLE build_item (
  build_item_id  INT AUTO_INCREMENT PRIMARY KEY,
  build_id       INT              NOT NULL,
  component_id   INT              NOT NULL,
  quantity       TINYINT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT uq_build_item UNIQUE (build_id, component_id),
  CONSTRAINT fk_build_item_build FOREIGN KEY (build_id)
    REFERENCES build (build_id) ON DELETE CASCADE,
  CONSTRAINT fk_build_item_component FOREIGN KEY (component_id)
    REFERENCES component (component_id) ON DELETE RESTRICT,
  CONSTRAINT ck_build_item_quantity CHECK (quantity >= 1)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 7. orders
-- A build submitted for review. Named orders because ORDER is reserved in SQL.
-- approved and cancelled are terminal; a rejected order may be closed by the
-- customer or revised and submitted again.
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
  order_id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT           NOT NULL,
  build_id      INT           NOT NULL,
  status        ENUM('pending','approved','rejected','cancelled')
                              NOT NULL DEFAULT 'pending',
  total_price   DECIMAL(10,2) NOT NULL,
  admin_remark  VARCHAR(255)  NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id)
    REFERENCES `user` (user_id) ON DELETE RESTRICT,
  CONSTRAINT fk_orders_build FOREIGN KEY (build_id)
    REFERENCES build (build_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX ix_orders_status ON orders (status);


-- ---------------------------------------------------------------------------
-- 8. order_item
-- A snapshot, not a live reference: the components, quantities and prices are
-- copied in at submission, so a later edit to the build or to a price cannot
-- rewrite an order already placed.
-- ---------------------------------------------------------------------------
CREATE TABLE order_item (
  order_item_id        INT AUTO_INCREMENT PRIMARY KEY,
  order_id             INT              NOT NULL,
  component_id         INT              NOT NULL,
  quantity             TINYINT UNSIGNED NOT NULL DEFAULT 1,
  unit_price_snapshot  DECIMAL(10,2)    NOT NULL,
  CONSTRAINT uq_order_item UNIQUE (order_id, component_id),
  CONSTRAINT fk_order_item_order FOREIGN KEY (order_id)
    REFERENCES orders (order_id) ON DELETE CASCADE,
  CONSTRAINT fk_order_item_component FOREIGN KEY (component_id)
    REFERENCES component (component_id) ON DELETE RESTRICT,
  CONSTRAINT ck_order_item_quantity CHECK (quantity >= 1),
  CONSTRAINT ck_order_item_price    CHECK (unit_price_snapshot >= 0)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 9. quotation_request
-- Raised by a customer the configurator cannot serve. It carries no stock
-- consequences of any kind, which is what keeps it out of the single routine
-- that moves stock.
-- ---------------------------------------------------------------------------
CREATE TABLE quotation_request (
  request_id     INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT          NOT NULL,
  build_id       INT          NULL,
  contact_phone  VARCHAR(20)  NOT NULL,
  message        TEXT         NOT NULL,
  status         ENUM('new','answered','closed') NOT NULL DEFAULT 'new',
  admin_reply    TEXT         NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_quotation_user FOREIGN KEY (user_id)
    REFERENCES `user` (user_id) ON DELETE RESTRICT,
  CONSTRAINT fk_quotation_build FOREIGN KEY (build_id)
    REFERENCES build (build_id) ON DELETE SET NULL
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------------
-- 10. stock_movement (added 3 November 2026)
-- The stock ledger: one row each time a part's stock_qty changes, so that the
-- administrator can see on the admin pages how every figure came about,
-- without opening phpMyAdmin. A row is written in the same transaction as the
-- change it records, and never edited afterwards: a mistake is put right with
-- another row.
--
--   opening      the stock a part started with (components.sql, a new part)
--   received     goods arrived: the Add stock button
--   sold         an order approved: one row per line, naming the order
--   correction   the stock figure typed over in the component form (a count)
--
-- stock_after is the stock once the row's change is made, so the latest row
-- of a part must always equal its stock_qty; the dashboard checks it.
-- Reservations are not stock movements: reserved goods are still on the
-- shelf, and they leave it only when the order is approved (a "sold" row).
-- The part's own page lists the pending orders holding them.
--
-- A part is never deleted once it is used, so its history stays; if one is
-- deleted while nothing else refers to it, its history goes with it. An
-- order's rows keep the movement when the order is removed, without the link.
-- ---------------------------------------------------------------------------
CREATE TABLE stock_movement (
  movement_id   INT AUTO_INCREMENT PRIMARY KEY,
  component_id  INT           NOT NULL,
  change_qty    INT           NOT NULL,
  stock_after   INT           NOT NULL,
  reason        ENUM('opening','received','sold','correction') NOT NULL,
  order_id      INT           NULL,
  user_id       INT           NULL,
  note          VARCHAR(255)  NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_movement_component FOREIGN KEY (component_id)
    REFERENCES component (component_id) ON DELETE CASCADE,
  CONSTRAINT fk_movement_order FOREIGN KEY (order_id)
    REFERENCES orders (order_id) ON DELETE SET NULL,
  CONSTRAINT fk_movement_user FOREIGN KEY (user_id)
    REFERENCES `user` (user_id) ON DELETE SET NULL,
  CONSTRAINT ck_movement_change CHECK (change_qty <> 0),
  CONSTRAINT ck_movement_after  CHECK (stock_after >= 0)
) ENGINE=InnoDB;

CREATE INDEX ix_movement_component ON stock_movement (component_id, movement_id);
CREATE INDEX ix_movement_created ON stock_movement (created_at);


-- ===========================================================================
-- Reference data
-- ===========================================================================

-- The eight categories. max_quantity caps how many units of one component a
-- build may hold, is_required says whether a build must fill the slot, and
-- display_order fixes where the slot appears in the configurator. Change a
-- value here and the configurator changes with it.
--
-- The motherboard comes first (team decision, 29 September 2026): the configurator
-- asks for the category in first place before it opens any other slot, and
-- every other slot narrows to what fits the board chosen.
--
-- Cooler and GPU are not required as such: whether a particular build needs
-- them depends on the processor chosen, and the two REQUIRES_CATEGORY rules
-- below decide it. Every build needs a case.
INSERT INTO category (category_name, max_quantity, is_required, display_order) VALUES
  ('Motherboard', 1, 1, 1),
  ('CPU',         1, 1, 2),
  ('Cooler',      1, 0, 3),
  ('RAM',         2, 1, 4),
  ('GPU',         1, 0, 5),
  ('Storage',     4, 1, 6),
  ('Case',        1, 1, 7),
  ('PSU',         1, 1, 8);

-- The nine rules the system ships with, of three kinds. Another rule of an
-- existing kind needs no code, only a row. The last four (29 September 2026)
-- are capacity checks that count rather than add up watts: they keep a build
-- from holding more memory sticks, M.2 drives or hard disks than the board
-- and the case have room for.
INSERT INTO compatibility_rule
  (rule_name, rule_type, category_a, category_b, attribute_key,
   headroom_pct, error_message)
VALUES
  ('CPU socket must match the motherboard',
   'ATTRIBUTE_MATCH',
   (SELECT category_id FROM category WHERE category_name = 'CPU'),
   (SELECT category_id FROM category WHERE category_name = 'Motherboard'),
   'socket',
   NULL,
   'The CPU socket does not match the motherboard.'),

  ('Memory type must match the motherboard',
   'ATTRIBUTE_MATCH',
   (SELECT category_id FROM category WHERE category_name = 'RAM'),
   (SELECT category_id FROM category WHERE category_name = 'Motherboard'),
   'memory_type',
   NULL,
   'The memory type is not supported by this motherboard.'),

  ('Total power must stay within the safe load of the power supply',
   'CAPACITY_CHECK',
   (SELECT category_id FROM category WHERE category_name = 'PSU'),
   NULL,
   'wattage',
   80.00,
   'The components draw more power than the chosen power supply can safely provide.'),

  ('A processor without integrated graphics needs a graphics card',
   'REQUIRES_CATEGORY',
   (SELECT category_id FROM category WHERE category_name = 'CPU'),
   (SELECT category_id FROM category WHERE category_name = 'GPU'),
   'has_integrated_graphics',
   NULL,
   'This processor has no integrated graphics, so the build needs a graphics card.'),

  ('A processor sold without a cooler needs one',
   'REQUIRES_CATEGORY',
   (SELECT category_id FROM category WHERE category_name = 'CPU'),
   (SELECT category_id FROM category WHERE category_name = 'Cooler'),
   'includes_cooler',
   NULL,
   'This processor comes without a cooler, so the build needs a CPU cooler.'),

  ('Memory sticks must fit the memory slots',
   'CAPACITY_CHECK',
   (SELECT category_id FROM category WHERE category_name = 'Motherboard'),
   NULL,
   'memory_slots',
   NULL,
   'The motherboard does not have enough memory slots for this memory.'),

  ('NVMe drives must fit the M.2 slots',
   'CAPACITY_CHECK',
   (SELECT category_id FROM category WHERE category_name = 'Motherboard'),
   NULL,
   'm2_slots',
   NULL,
   'The motherboard does not have enough M.2 slots for these drives.'),

  ('Hard disks must fit the SATA ports',
   'CAPACITY_CHECK',
   (SELECT category_id FROM category WHERE category_name = 'Motherboard'),
   NULL,
   'sata_ports',
   NULL,
   'The motherboard does not have enough SATA ports for these drives.'),

  ('Hard disks must fit the drive bays',
   'CAPACITY_CHECK',
   (SELECT category_id FROM category WHERE category_name = 'Case'),
   NULL,
   'drive_bays',
   NULL,
   'The case does not have enough drive bays for these hard disks.');

-- One administrator to start from. Administrators are not created through
-- public registration, so this row is the only way in on a fresh install.
-- The password is Admin@123 and MUST be changed before the system is shown.
INSERT INTO `user` (username, email, password_hash, role) VALUES
  ('Administrator', 'admin@pcbuild.local',
   '$2y$12$aiV8PuFNf9VKwmlfHGMXiuvWzWWNvB/fBKFyxAyU3HeSKlgrlp9mu', 'admin');


-- ===========================================================================
-- The data consistency check shown on the administrator dashboard.
-- It compares the reserved quantity held against each component with the
-- quantity actually reserved by pending orders, and should always return
-- zero rows. It is run from the dashboard page rather than stored as a view,
-- so that the query is visible in the code it belongs to.
--
--   SELECT c.component_id, c.name, c.reserved_qty,
--          COALESCE(SUM(CASE WHEN o.status = 'pending' THEN oi.quantity END), 0)
--            AS actual_reserved
--   FROM component c
--   LEFT JOIN order_item oi ON oi.component_id = c.component_id
--   LEFT JOIN orders     o  ON o.order_id      = oi.order_id
--   GROUP BY c.component_id, c.name, c.reserved_qty
--   HAVING c.reserved_qty <> actual_reserved;
-- ===========================================================================
