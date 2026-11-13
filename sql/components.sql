-- ===========================================================================
-- PC Build Configurator and Inventory Management System
-- Component catalogue. Run AFTER schema.sql.
--
--     mysql -u root pc_build_configurator < components.sql
--
-- ---------------------------------------------------------------------------
-- WHERE THESE PRICES COME FROM
--
-- Malaysian retail, collected 22 September 2026, mostly from Thunder Match
-- (tmt.my) with a few rows from named Shopee Malaysia merchants. The method is
-- written up in docs/data-sourcing-prompt.md, and the raw returns are kept in
-- docs/research/.
--
-- Every row is tagged with how well its price is attested:
--
--   [verified]  the source URL opens the product named in the row, and the
--               price is the one shown there.
--   [plausible] the product is real and the price is consistent with the rest
--               of the catalogue, but the source given was a search result or
--               a shop front page rather than the product's own page.
--   [supplied]  priced from the shop's listing: the coolers and
--               cases on 28 September 2026, the graphics cards above the
--               RTX 5070 on 1 October 2026, which came later than the rest.
--
-- The tag is honest rather than decorative: about a third of these prices have
-- not been read off the product's own page. Replacing one is a single UPDATE.
--
-- WATTAGE IS NOT A LOOKED-UP PRICE. Retail listings rarely publish board
-- power, module draw or card TGP. A processor's figure is the most it draws,
-- from its maker (see the processors below); a graphics card's is its board
-- power; everything else is a NOMINAL figure chosen per category so the
-- capacity rule has something sensible to add up. Those are not manufacturer
-- specifications and must not be presented as any:
--     motherboard 40W · memory 5W a module and 10W a two-stick kit
--     NVMe 7W · hard disk 9W
--     case 3W for each fan it comes with
-- A cooler's figure is what its fans are rated to draw, from the makers' own
-- numbers. A power supply's wattage is its rated output, which is the limit
-- the rule checks against rather than a draw.
--
-- ROWS THAT WERE DROPPED, and why, so the gaps are not mistaken for oversights:
--   - Two used graphics cards. The catalogue is new retail only.
--   - Every 8GB DDR5 module returned by the research (RM799, RM898, RM1,499).
--     All three cost more than the 16GB modules and came from a search for
--     laptop memory, so they are almost certainly SO-DIMM or mis-read.
--   - A second RTX 5070 at RM2,679 alongside one at RM4,946. Same chip, 85 per
--     cent apart; one of them is wrong and there is no way to tell which.
--   - Two 1TB NVMe drives at RM862 and RM1,278, both above a 2TB drive at
--     RM859. Their pages list several capacities, so the price shown is
--     probably not the 1TB one.
--
-- MEMORY IS STOCKED AS THE SHOP SELLS IT. Checking the Malaysian retail
-- channel found no single DDR5 module on sale anywhere: desktop DDR5 is sold
-- as matched kits, 2x16GB and 2x32GB. The catalogue therefore holds the kit as
-- one product, and capacity_gb is the total the customer receives. A customer
-- reaches 128GB by taking two 64GB kits, which is also how it is done in
-- practice on a four-slot board. RAM max_quantity is 2 for that reason, and
-- Storage stays at 4.
--
-- Two power supply prices are the cheapest variant of a listing covering
-- several wattages (DeepCool PF500X/600X/700X at RM179-219, Ocypus P550/P650
-- at RM159-189). The lowest wattage is the cheapest variant, so the low end of
-- the range belongs to it, but that is an inference and the rows say so.
-- ===========================================================================

USE pc_build_configurator;

SET @cpu     = (SELECT category_id FROM category WHERE category_name = 'CPU');
SET @mb      = (SELECT category_id FROM category WHERE category_name = 'Motherboard');
SET @ram     = (SELECT category_id FROM category WHERE category_name = 'RAM');
SET @gpu     = (SELECT category_id FROM category WHERE category_name = 'GPU');
SET @storage = (SELECT category_id FROM category WHERE category_name = 'Storage');
SET @psu     = (SELECT category_id FROM category WHERE category_name = 'PSU');
SET @cooler  = (SELECT category_id FROM category WHERE category_name = 'Cooler');
SET @case    = (SELECT category_id FROM category WHERE category_name = 'Case');


-- Processors. Three sockets are stocked on purpose: a customer who picks an
-- AM5 processor and an LGA1700 board must be stopped by the socket rule, and
-- that cannot be demonstrated unless both are in the catalogue.
--
-- The last two columns say whether the processor has integrated graphics and
-- whether a cooler comes in its box. They were read off the makers' own pages
-- on 25 September 2026, not written from memory:
--   AMD product pages, "Graphics Model" and "Thermal Solution (PIB)": the
--     9950X3D, 9800X3D, 7800X3D and 9600X have graphics and ship without a
--     cooler; the 8600G has Radeon 760M graphics. AMD's page does not state
--     the 8600G's cooler. Its boxed part, 100-100001237BOX, is sold with a
--     Wraith Stealth by the retailers checked (pcworth.com, mini-itx.com), so
--     that one value is second-hand.
--   Intel: the 14400F's specification page lists no processor graphics, and
--     support article 000089190 names it among the boxed processors that
--     ship with a Laminar RM1 cooler. Article 000005940 says every K, KF and
--     KS processor ships without one, which covers the 14900K and the 285K;
--     both list processor graphics (UHD Graphics 770, Intel Graphics).
-- So the 14400F is the one processor that needs a graphics card, and six of
-- the eight need a cooler bought separately.
--
-- wattage is the MOST a processor draws, not its base figure (team decision, 1 October
-- 2026: so that no machine is sold with a supply that cannot carry it at full
-- load). Until then the column held Intel's Processor Base Power and AMD's TDP,
-- which a processor exceeds whenever it turbos: the i9-14900K's 125 W against
-- its 253 W. Read 1 October 2026:
--   Intel, each processor's specification page, "Maximum Turbo Power": 253 W
--     for the i9-14900K, 250 W for the Ultra 9 285K, 148 W for the i5-14400F.
--   AMD gives its package power limit (PPT) as a rule rather than per model:
--     "TDP*1.35 is the standard calculation for TDP v. PPT for AMD sockets in
--     the Zen era" (AMD's statement on AM5 of May 2022, quoted by PC
--     Perspective). With the TDPs on AMD's product pages, 170 W, 120 W and
--     65 W, that is 230 W for the 9950X3D (AMD's own rounding), 162 W for the
--     9800X3D and 7800X3D, and 88 W for the 9600X and 8600G.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, socket, has_integrated_graphics, includes_cooler) VALUES
  (@cpu, 'Ryzen 9 9950X3D',    'AMD',   3048.21,  4, 230, 'AM5',     1, 0),  -- [verified]  tmt.my
  (@cpu, 'Ryzen 7 9800X3D',    'AMD',   2940.31,  7, 162, 'AM5',     1, 0),  -- [verified]  Shopee product page
  (@cpu, 'Ryzen 7 7800X3D',    'AMD',   1291.00,  5, 162, 'AM5',     1, 0),  -- [plausible]
  (@cpu, 'Ryzen 5 9600X',      'AMD',    593.00, 12,  88, 'AM5',     1, 0),  -- [plausible]
  (@cpu, 'Ryzen 5 8600G',      'AMD',   1079.00,  9,  88, 'AM5',     1, 1),  -- [verified]  Shopee product page
  (@cpu, 'Core Ultra 9 285K',  'Intel', 2889.81,  2, 250, 'LGA1851', 1, 0),  -- [verified]  tmt.my   low stock
  (@cpu, 'Core i9-14900K',     'Intel', 2305.71,  6, 253, 'LGA1700', 1, 0),  -- [verified]  tmt.my
  (@cpu, 'Core i5-14400F',     'Intel',  796.00, 14, 148, 'LGA1700', 0, 1);  -- [plausible]


-- Motherboards. Each socket has at least one board, and both memory
-- generations appear, so a DDR4 module in a DDR5 board is a mistake the
-- catalogue can actually produce.
--
-- The last three columns are what each board has room for: memory slots,
-- M.2 slots and SATA ports, which the counting rules compare with what the
-- memory and the drives take. Read off the makers' own documents on
-- 29 September 2026, not written from memory:
--   MSI datasheets (storage-asset.msi.com): PRO X870E-S EVO WIFI and MAG
--     B850M MORTAR WIFI, 4 DIMMs, 3 M.2 slots, 4 SATA ports each.
--   Gigabyte's manual for the B850 AORUS STEALTH ICE and STEALTH, one board
--     in two colours (a copy on gzhls.at; gigabyte.com refuses automated
--     visitors): 4 DIMMs, 4 M.2 connectors, 2 SATA ports. One of the four,
--     M2B_CPU, goes dark under a Ryzen 8000 "Phoenix 2" processor; the 8600G
--     sold here is Phoenix 1, so all four count.
--   ASUS tech specs (asus.com): TUF GAMING Z890-PLUS WIFI, 4 DIMMs, 4 M.2,
--     4 SATA; TUF GAMING B760M-PLUS WIFI D4, 4 DIMMs, 2 M.2, 4 SATA.
--   Gigabyte's manual (download.gigabyte.com): H610M K DDR4, 2 DIMMs,
--     1 M.2 connector, 2 SATA ports.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, socket, memory_type, memory_slots, m2_slots, sata_ports) VALUES
  (@mb, 'PRO X870E-S EVO WIFI',          'MSI',      1179.09,  5, 40, 'AM5',     'DDR5', 4, 3, 4),  -- [verified]  tmt.my
  (@mb, 'MAG B850M MORTAR WIFI',         'MSI',      1080.09,  8, 40, 'AM5',     'DDR5', 4, 3, 4),  -- [verified]  tmt.my
  (@mb, 'B850 AORUS STEALTH BLACK',      'Gigabyte', 1599.00,  3, 40, 'AM5',     'DDR5', 4, 4, 2),  -- [plausible]
  (@mb, 'TUF GAMING Z890-PLUS WIFI',     'ASUS',      898.97,  4, 40, 'LGA1851', 'DDR5', 4, 4, 4),  -- [plausible]  only LGA1851 board
  (@mb, 'TUF GAMING B760M-PLUS WIFI D4', 'ASUS',      647.05,  6, 40, 'LGA1700', 'DDR4', 4, 2, 4),  -- [plausible]
  (@mb, 'H610M K DDR4',                  'Gigabyte',  278.19, 11, 40, 'LGA1700', 'DDR4', 2, 1, 2);  -- [verified]  tmt.my


-- Memory. Sold as the shop sells it: a kit of two sticks is one product with
-- one price, and capacity_gb is the total the customer receives. Single DDR5
-- modules are not retailed in Malaysia at any of the shops checked, so the
-- earlier decision to stock sticks rather than kits could not survive contact
-- with the catalogue.
--
-- memory_slots is how many sticks the product is, so how many slots it takes:
-- 2 for the Corsair kits, whose names say 2x, and 1 for the rest, which were
-- recorded as single modules (5 W each, where a two-stick kit is 10 W). The
-- G.SKILL AEGIS 16GB is also sold as a 2x8GB kit; the one recorded here is
-- the single 16GB stick.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, capacity_gb, memory_type, memory_slots) VALUES
  (@ram, 'NOX DDR4 8GB 3200',                    'Apacer',   90.00, 20,  5,  8, 'DDR4', 1),  -- [plausible]
  (@ram, 'DDR4 Desktop 16GB 3200 CL22',          'Lexar',   238.59, 16,  5, 16, 'DDR4', 1),  -- [verified]  tmt.my
  (@ram, 'AEGIS DDR4 16GB 3200',                 'G.SKILL', 429.00, 10,  5, 16, 'DDR4', 1),  -- [plausible]
  (@ram, 'DDR5 U-DIMM 16GB 5600',                'ADATA',   689.00,  9,  5, 16, 'DDR5', 1),  -- [plausible]
  (@ram, 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36', 'Corsair', 3032.00, 4, 10, 32, 'DDR5', 2),  -- [verified]  Shopee, Corsair official store
  (@ram, 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30', 'Corsair', 6702.00, 2, 10, 64, 'DDR5', 2);  -- [verified]  Shopee, Corsair official store   low stock


-- Graphics. Optional in a build: many of the processors above include
-- integrated graphics, which is why the GPU category is not required.
-- wattage is the card's board power and capacity_gb its video memory. The
-- first five carry their chips' reference board power. The cards above the
-- RTX 5070 came on 1 October 2026 at the shop's prices, their figures read the
-- same day from the makers' own documents:
--   MSI datasheets (storage-asset.msi.com; msi.com turns automated visitors
--   away): RTX 5070 Ti 16G INSPIRE 3X OC, 300 W, 288 mm, recommended supply
--   750 W; RTX 5080 16G INSPIRE 3X OC, 360 W, 288 mm, 850 W; RTX 5090 32G
--   GAMING TRIO OC, 575 W, 359 mm, 1000 W. Each takes one 16-pin connector.
--   ZOTAC GAMING RTX 5090 SOLID OC: 575 W, 329.7 mm, recommended supply
--   1000 W, one 12V-2x6 input, second-hand from pages reprinting ZOTAC's
--   table (zotac.com turns automated visitors away).
-- Every one of them is shorter than the shortest case's limit (the 4000D
-- AIRFLOW's 360 mm), the 5090 GAMING TRIO by 1 mm. Corsair does not say
-- whether its 360 mm allows for the front fan it ships with.
-- Left out: the RTX 5090 LIGHTNING Z, liquid-cooled and drawing up to
-- 1000 W with a 1600 W supply recommended by MSI (team decision, 1 October 2026).
-- Not stocked until the team decides: the ASUS RTX 5080 Noctua OC Edition
-- (RM 10,399.00), 385 mm long by ASUS's figures, which only two of the four
-- cases take (the LANCOOL 216 and the AIR 903 MAX). Stocking it means either
-- a rule on card length or a shop whose every case takes it.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, capacity_gb) VALUES
  (@gpu, 'GeForce RTX 5060 OC Low Profile 8GB', 'Gigabyte', 1662.21, 8, 145,  8),  -- [verified]  tmt.my
  (@gpu, 'Dual Radeon RX 9060 XT 16GB',         'ASUS',     2315.61, 6, 160, 16),  -- [verified]  tmt.my
  (@gpu, 'GeForce RTX 5060 Ti 8G',              'MSI',      2931.45, 4, 180,  8),  -- [plausible]
  (@gpu, 'PRIME Radeon RX 9070 EVO OC 16GB',    'ASUS',     3696.00, 3, 220, 16),  -- [plausible]
  (@gpu, 'GeForce RTX 5070 GAMING TRIO OC 12GB','MSI',      4946.00, 1, 250, 12),  -- [plausible]  low stock
  (@gpu, 'GeForce RTX 5070 Ti INSPIRE 3X OC 16GB', 'MSI',  6999.00, 3, 300, 16),  -- [supplied]
  (@gpu, 'GeForce RTX 5080 INSPIRE 3X OC 16GB',  'MSI',     8899.00, 2, 360, 16),  -- [supplied]
  (@gpu, 'GAMING GeForce RTX 5090 SOLID OC 32GB', 'ZOTAC', 26999.00, 1, 575, 32),  -- [supplied]  low stock
  (@gpu, 'GeForce RTX 5090 GAMING TRIO OC 32GB', 'MSI',    28399.00, 1, 575, 32);  -- [supplied]  low stock


-- Storage. Capacity is held in gigabytes, so a 2TB drive is 2000.
--
-- The last three columns are what a drive takes: an NVMe drive takes an M.2
-- slot; a hard disk takes a SATA port and a 3.5-inch drive bay in the case.
-- Both hard disks are 3.5-inch desktop drives. The BarraCuda 2TB also comes
-- as a 2.5-inch laptop drive; the one recorded here, at 9 W, is the desktop
-- one.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, capacity_gb, m2_slots, sata_ports, drive_bays) VALUES
  (@storage, 'BarraCuda 2TB SATA HDD',          'Seagate',         265.00, 13,  9, 2000, 0, 1, 1),  -- [plausible]
  (@storage, 'P3 Plus 1TB PCIe Gen4 NVMe',      'Crucial',         315.00, 15,  6, 1000, 1, 0, 0),  -- [plausible]
  (@storage, '990 PRO 1TB PCIe Gen4 NVMe',      'Samsung',         549.00, 10,  7, 1000, 1, 0, 0),  -- [verified]  tmt.my
  (@storage, 'SN850X 2TB PCIe Gen4 NVMe',       'Western Digital', 859.00,  7,  7, 2000, 1, 0, 0),  -- [verified]  tmt.my
  (@storage, 'N300 NAS 4TB SATA HDD',           'Toshiba',        1490.41,  2, 10, 4000, 0, 1, 1);  -- [plausible]  low stock


-- Power supplies. wattage here is the RATED OUTPUT, which is the ceiling the
-- capacity rule measures a build against, not a draw. The 550W unit exists so
-- that an expensive build genuinely fails the rule.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage) VALUES
  (@psu, 'Gamma P550 550W',               'Ocypus',        159.00, 11,  550),  -- [plausible]  cheapest variant of a multi-variant listing
  (@psu, 'AP Series 750W',                'AIGO',          179.00, 10,  750),  -- [plausible]
  (@psu, 'GAMERSTORM PFX PF500X 500W',    'DeepCool',      179.00,  8,  500),  -- [plausible]  cheapest variant of a multi-variant listing
  (@psu, 'C750 750W Bronze ATX3.1',       'NZXT',          299.00,  7,  750),  -- [verified]   single price on the listing
  (@psu, 'PQ1200G 1200W Fully Modular',   'DeepCool',      749.00,  2, 1200),  -- [verified]   single price on the listing   low stock
  (@psu, 'GP-P650SS 650W',                'Gigabyte',      218.00, 12,  650),  -- [plausible]
  (@psu, 'MAG A650BN 650W',               'MSI',           256.00,  9,  650),  -- [plausible]
  (@psu, 'CX550 550W 80+ Bronze',         'Corsair',       260.00, 14,  550),  -- [plausible]
  (@psu, 'P650G PG5 650W ATX3.1',         'Gigabyte',      349.00,  7,  650),  -- [plausible]
  (@psu, 'MWE GOLD V3 850W ATX3.1',       'Cooler Master', 349.00,  5,  850),  -- [plausible]
  (@psu, 'RM850e 850W 80+ Gold',          'Corsair',       535.59,  6,  850),  -- [verified]  tmt.my
  (@psu, 'RM1000E 1000W ATX3.1',          'Corsair',       599.00,  3, 1000);  -- [plausible]


-- Coolers. Air only (team decision, 28 September 2026: liquid coolers bring
-- after-sales trouble, pumps that fail and loops that leak), and only
-- dual-tower ones, the strongest air offers. Whether a cooler can keep up with
-- its processor is not a rule; the shop sells only coolers meant for every
-- processor it stocks. The limit of that, stated plainly: on air the
-- i9-14900K and Ultra 9 285K slow down under long all-core loads, and AMD's
-- advice of a liquid cooler for the X3D processors is not followed.
--
-- Prices from the shop's listing, 28 September 2026. Specifications checked the same day:
--   thermalright.com: Peerless Assassin 120 SE, 155 mm tall, two TL-C12C fans
--     at 0.20 A; Phantom Spirit 120 SE, 154 mm, two TL-C12B V2 fans at
--     0.20 A. Both list LGA1851, LGA1700 and AM5.
--   deepcool.com: AK620, 160 mm, two fans at 1.44 W, LGA1851, LGA1700, AM5.
--   bequiet.com and noctua.at turn automated visitors away, so these two are
--   second-hand, from pages that reprint the makers' tables:
--     Dark Rock Pro 5 (APH Networks review): 168 mm, a 135 mm fan at 3.36 W
--       and a 120 mm fan at 2.4 W, LGA1700 and AM5. LGA1851 boards keep
--       LGA1700's mounting holes, and current listings name LGA1851.
--     NH-D15 G2 (quietpc-usa): 168 mm, two NF-A14x25r G2 fans at 2.28 W,
--       LGA1851, LGA1700 and AM5 (the standard version, not LBC or HBC).
-- wattage is what the fans are rated to draw, added up and rounded up.
--
-- ONE COMBINATION CANNOT BE BUILT AS SOLD, and whether to keep the cooler is
-- the team's decision (asked 28 September 2026). With both fans on, the NH-D15 G2
-- clears memory up to 32 mm tall. The Corsair Vengeance RGB kits stand 44 mm
-- (Tom's Hardware), so the front fan moves up 12 mm and the cooler becomes
-- 180 mm tall: too tall for the 4000D AIRFLOW (170 mm) and the CH560
-- (175 mm) below. With the front fan left off it clears 59 mm and stays
-- 168 mm, which Noctua supports. The other coolers clear 42 to 43 mm, so they
-- rise 1 or 2 mm under those kits and fit every case, the Dark Rock Pro 5
-- (170 mm) exactly in the 4000D AIRFLOW.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage) VALUES
  (@cooler, 'Phantom Spirit 120 SE',    'Thermalright', 170.00, 12, 5),  -- [supplied]
  (@cooler, 'Peerless Assassin 120 SE', 'Thermalright', 180.00, 15, 5),  -- [supplied]
  (@cooler, 'AK620',                    'DeepCool',     280.00,  8, 3),  -- [supplied]
  (@cooler, 'Dark Rock Pro 5',          'be quiet!',    400.00,  5, 6),  -- [supplied]
  (@cooler, 'NH-D15 G2',                'Noctua',       700.00,  2, 5);  -- [supplied]  low stock


-- Cases. They fit because of what is stocked, not because of a rule: every
-- case here takes every board sold (ATX and Micro-ATX), the longest graphics
-- card (the RTX 5090 GAMING TRIO, 359 mm, since 1 October 2026; until then
-- the RTX 5070 GAMING TRIO, 338 mm), the tallest cooler (168 mm) and
-- the power supplies (the largest, 850 W to 1200 W, measure 140 to 160 mm in
-- published reviews). The makers' own figures, read 28 September 2026:
--                   card     cooler    supply   fans included
--   CH560           380 mm   175 mm    170 mm   3x140 + 1x120, ARGB   deepcool.com
--   LANCOOL 216     392 mm   180.5 mm  220 mm   2x160 + 1x140         lian-li.com
--   4000D AIRFLOW   360 mm   170 mm    220 mm   2x120                 Corsair's quick start guide
--   AIR 903 MAX     400 mm   180 mm    240 mm   4x140, 3 ARGB         montechpc.com
-- The two colours of the CH560 and the AIR 903 MAX are priced differently, so
-- each colour is a product of its own. The shop's prices for the LANCOOL 216 and
-- the 4000D AIRFLOW name no colour.
-- wattage is NOMINAL: 3 W for each fan included, since the makers do not
-- publish what their case fans draw.
--
-- drive_bays is how many 3.5-inch hard disks a case holds: 2 in every one of
-- them, by the same makers' pages (the CH560's two 3.5-inch drive bays, the
-- LANCOOL 216's drive cage for two 3.5-inch disks, the 4000D AIRFLOW's two
-- HDD trays, the AIR 903 MAX's two 3.5-inch places). So no case sold takes
-- three or four hard disks, and the drive bay rule says so.
INSERT INTO component
  (category_id, name, brand, price, stock_qty, wattage, drive_bays) VALUES
  (@case, 'CH560 Black',       'DeepCool', 500.00, 6, 12, 2),  -- [supplied]
  (@case, 'CH560 White',       'DeepCool', 600.00, 4, 12, 2),  -- [supplied]
  (@case, 'LANCOOL 216',       'Lian Li',  500.00, 7,  9, 2),  -- [supplied]
  (@case, '4000D AIRFLOW',     'Corsair',  500.00, 9,  6, 2),  -- [supplied]
  (@case, 'AIR 903 MAX White', 'Montech',  510.00, 3, 12, 2),  -- [supplied]
  (@case, 'AIR 903 MAX Black', 'Montech',  520.00, 5, 12, 2);  -- [supplied]


-- ---------------------------------------------------------------------------
-- Product photographs (13 November 2026), in assets/img/components/: one per
-- part, squared on white so the catalogue's thumbnails never crop a product.
-- A part with no photograph shows its category's icon instead. Four of the
-- pictures show a close relative rather than the exact product, and are used
-- as stand-ins until an exact one is found: PRO X870E-S EVO WIFI (the box is
-- the X870E GAMING PLUS WIFI), the Lexar DDR4 16GB (the stick is ADATA), the
-- PRIME RX 9070 EVO OC (the card is the RX 9070 GRE) and the AP Series 750W
-- (the unit pictured is ASUS's, the shop lists AIGO).
-- ---------------------------------------------------------------------------
UPDATE component SET image_url = 'assets/img/components/msi-mag-b850m-mortar-wifi.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'MAG B850M MORTAR WIFI';
UPDATE component SET image_url = 'assets/img/components/gigabyte-b850-aorus-stealth-black.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'B850 AORUS STEALTH BLACK';
UPDATE component SET image_url = 'assets/img/components/asus-tuf-gaming-z890-plus-wifi.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'TUF GAMING Z890-PLUS WIFI';
UPDATE component SET image_url = 'assets/img/components/asus-tuf-gaming-b760m-plus-wifi-d4.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'TUF GAMING B760M-PLUS WIFI D4';
UPDATE component SET image_url = 'assets/img/components/gigabyte-h610m-k-ddr4.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'H610M K DDR4';
UPDATE component SET image_url = 'assets/img/components/amd-ryzen-9-9950x3d.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Ryzen 9 9950X3D';
UPDATE component SET image_url = 'assets/img/components/amd-ryzen-7-9800x3d.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Ryzen 7 9800X3D';
UPDATE component SET image_url = 'assets/img/components/amd-ryzen-7-7800x3d.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Ryzen 7 7800X3D';
UPDATE component SET image_url = 'assets/img/components/amd-ryzen-5-9600x.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Ryzen 5 9600X';
UPDATE component SET image_url = 'assets/img/components/amd-ryzen-5-8600g.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Ryzen 5 8600G';
UPDATE component SET image_url = 'assets/img/components/intel-core-ultra-9-285k.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Core Ultra 9 285K';
UPDATE component SET image_url = 'assets/img/components/intel-core-i9-14900k.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Core i9-14900K';
UPDATE component SET image_url = 'assets/img/components/intel-core-i5-14400f.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'CPU') AND name = 'Core i5-14400F';
UPDATE component SET image_url = 'assets/img/components/thermalright-phantom-spirit-120-se.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Cooler') AND name = 'Phantom Spirit 120 SE';
UPDATE component SET image_url = 'assets/img/components/thermalright-peerless-assassin-120-se.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Cooler') AND name = 'Peerless Assassin 120 SE';
UPDATE component SET image_url = 'assets/img/components/deepcool-ak620.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Cooler') AND name = 'AK620';
UPDATE component SET image_url = 'assets/img/components/be-quiet-dark-rock-pro-5.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Cooler') AND name = 'Dark Rock Pro 5';
UPDATE component SET image_url = 'assets/img/components/noctua-nh-d15-g2.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Cooler') AND name = 'NH-D15 G2';
UPDATE component SET image_url = 'assets/img/components/apacer-nox-ddr4-8gb-3200.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'NOX DDR4 8GB 3200';
UPDATE component SET image_url = 'assets/img/components/g-skill-aegis-ddr4-16gb-3200.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'AEGIS DDR4 16GB 3200';
UPDATE component SET image_url = 'assets/img/components/adata-ddr5-u-dimm-16gb-5600.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'DDR5 U-DIMM 16GB 5600';
UPDATE component SET image_url = 'assets/img/components/corsair-vengeance-rgb-ddr5-32gb-2x16gb-6000-cl36.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'Vengeance RGB DDR5 32GB (2x16GB) 6000 CL36';
UPDATE component SET image_url = 'assets/img/components/corsair-vengeance-rgb-ddr5-64gb-2x32gb-6000-cl30.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'Vengeance RGB DDR5 64GB (2x32GB) 6000 CL30';
UPDATE component SET image_url = 'assets/img/components/gigabyte-geforce-rtx-5060-oc-low-profile-8gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5060 OC Low Profile 8GB';
UPDATE component SET image_url = 'assets/img/components/asus-dual-radeon-rx-9060-xt-16gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'Dual Radeon RX 9060 XT 16GB';
UPDATE component SET image_url = 'assets/img/components/msi-geforce-rtx-5060-ti-8g.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5060 Ti 8G';
UPDATE component SET image_url = 'assets/img/components/msi-geforce-rtx-5070-gaming-trio-oc-12gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5070 GAMING TRIO OC 12GB';
UPDATE component SET image_url = 'assets/img/components/msi-geforce-rtx-5070-ti-inspire-3x-oc-16gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5070 Ti INSPIRE 3X OC 16GB';
UPDATE component SET image_url = 'assets/img/components/msi-geforce-rtx-5080-inspire-3x-oc-16gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5080 INSPIRE 3X OC 16GB';
UPDATE component SET image_url = 'assets/img/components/zotac-gaming-geforce-rtx-5090-solid-oc-32gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GAMING GeForce RTX 5090 SOLID OC 32GB';
UPDATE component SET image_url = 'assets/img/components/msi-geforce-rtx-5090-gaming-trio-oc-32gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'GeForce RTX 5090 GAMING TRIO OC 32GB';
UPDATE component SET image_url = 'assets/img/components/seagate-barracuda-2tb-sata-hdd.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Storage') AND name = 'BarraCuda 2TB SATA HDD';
UPDATE component SET image_url = 'assets/img/components/crucial-p3-plus-1tb-pcie-gen4-nvme.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Storage') AND name = 'P3 Plus 1TB PCIe Gen4 NVMe';
UPDATE component SET image_url = 'assets/img/components/samsung-990-pro-1tb-pcie-gen4-nvme.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Storage') AND name = '990 PRO 1TB PCIe Gen4 NVMe';
UPDATE component SET image_url = 'assets/img/components/western-digital-sn850x-2tb-pcie-gen4-nvme.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Storage') AND name = 'SN850X 2TB PCIe Gen4 NVMe';
UPDATE component SET image_url = 'assets/img/components/toshiba-n300-nas-4tb-sata-hdd.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Storage') AND name = 'N300 NAS 4TB SATA HDD';
UPDATE component SET image_url = 'assets/img/components/deepcool-ch560-black.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = 'CH560 Black';
UPDATE component SET image_url = 'assets/img/components/deepcool-ch560-white.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = 'CH560 White';
UPDATE component SET image_url = 'assets/img/components/lian-li-lancool-216.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = 'LANCOOL 216';
UPDATE component SET image_url = 'assets/img/components/corsair-4000d-airflow.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = '4000D AIRFLOW';
UPDATE component SET image_url = 'assets/img/components/montech-air-903-max-white.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = 'AIR 903 MAX White';
UPDATE component SET image_url = 'assets/img/components/montech-air-903-max-black.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Case') AND name = 'AIR 903 MAX Black';
UPDATE component SET image_url = 'assets/img/components/ocypus-gamma-p550-550w.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'Gamma P550 550W';
UPDATE component SET image_url = 'assets/img/components/deepcool-gamerstorm-pfx-pf500x-500w.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'GAMERSTORM PFX PF500X 500W';
UPDATE component SET image_url = 'assets/img/components/nzxt-c750-750w-bronze-atx3-1.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'C750 750W Bronze ATX3.1';
UPDATE component SET image_url = 'assets/img/components/deepcool-pq1200g-1200w-fully-modular.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'PQ1200G 1200W Fully Modular';
UPDATE component SET image_url = 'assets/img/components/gigabyte-gp-p650ss-650w.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'GP-P650SS 650W';
UPDATE component SET image_url = 'assets/img/components/msi-mag-a650bn-650w.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'MAG A650BN 650W';
UPDATE component SET image_url = 'assets/img/components/corsair-cx550-550w-80-bronze.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'CX550 550W 80+ Bronze';
UPDATE component SET image_url = 'assets/img/components/gigabyte-p650g-pg5-650w-atx3-1.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'P650G PG5 650W ATX3.1';
UPDATE component SET image_url = 'assets/img/components/cooler-master-mwe-gold-v3-850w-atx3-1.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'MWE GOLD V3 850W ATX3.1';
UPDATE component SET image_url = 'assets/img/components/corsair-rm850e-850w-80-gold.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'RM850e 850W 80+ Gold';
UPDATE component SET image_url = 'assets/img/components/corsair-rm1000e-1000w-atx3-1.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'RM1000E 1000W ATX3.1';
UPDATE component SET image_url = 'assets/img/components/msi-pro-x870e-s-evo-wifi.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'Motherboard') AND name = 'PRO X870E-S EVO WIFI';
UPDATE component SET image_url = 'assets/img/components/lexar-ddr4-desktop-16gb-3200-cl22.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'RAM') AND name = 'DDR4 Desktop 16GB 3200 CL22';
UPDATE component SET image_url = 'assets/img/components/asus-prime-radeon-rx-9070-evo-oc-16gb.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'GPU') AND name = 'PRIME Radeon RX 9070 EVO OC 16GB';
UPDATE component SET image_url = 'assets/img/components/aigo-ap-series-750w.jpg' WHERE category_id = (SELECT category_id FROM category WHERE category_name = 'PSU') AND name = 'AP Series 750W';

-- ---------------------------------------------------------------------------
-- The stock ledger's first page (3 November 2026): one "opening" row for every
-- part with something on the shelf, so that from here on every change to a
-- stock figure is a row in stock_movement, and the latest row of each part
-- equals its stock_qty (the dashboard's stock check). A part stocked at 0 has
-- no row yet; its first delivery will be its first.
-- ---------------------------------------------------------------------------
INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, note)
SELECT component_id, stock_qty, stock_qty, 'opening', 'Stock when the catalogue was loaded'
FROM component
WHERE stock_qty > 0
ORDER BY component_id;
