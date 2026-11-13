<?php
/*
 * The catalogue: categories, components, and how each is described.
 */

declare(strict_types=1);

/**
 * What each category's components carry besides a name, brand, price and
 * stock, with the label the form and the catalogue use. Keyed by category
 * name, as the category table records it.
 *
 * Every component has a wattage, but it means different things: the most a
 * processor draws (Intel's Maximum Turbo Power, AMD's package power limit,
 * not the lower TDP), a card's board power, a power supply's rated output.
 * Only the supply's is a limit; the rest are what the power rule adds up. socket and
 * memory_type are what the compatibility rules compare; capacity_gb is shown
 * to the customer and added up in the configurator (FR3.13). A processor's
 * two yes-or-no fields are what the requirement rules read. The four counts
 * are what the counting rules add up: on a motherboard or a case what it has,
 * on memory or a drive what it takes.
 */
const CATEGORY_FIELDS = [
    'CPU'         => ['wattage' => 'Maximum power (W)', 'socket' => 'Socket',
                      'has_integrated_graphics' => 'Integrated graphics', 'includes_cooler' => 'Cooler in the box'],
    'Cooler'      => ['wattage' => 'Power draw (W)'],
    'Motherboard' => ['wattage' => 'Power draw (W)',   'socket' => 'Socket', 'memory_type' => 'Memory type',
                      'memory_slots' => 'Memory slots', 'm2_slots' => 'M.2 slots', 'sata_ports' => 'SATA ports'],
    'RAM'         => ['wattage' => 'Power draw (W)',   'capacity_gb' => 'Capacity (GB)', 'memory_type' => 'Memory type',
                      'memory_slots' => 'Sticks (memory slots it takes)'],
    'GPU'         => ['wattage' => 'Board power (W)',  'capacity_gb' => 'Video memory (GB)'],
    'Storage'     => ['wattage' => 'Power draw (W)',   'capacity_gb' => 'Capacity (GB)',
                      'm2_slots' => 'M.2 slots it takes', 'sata_ports' => 'SATA ports it takes', 'drive_bays' => 'Drive bays it takes'],
    'Case'        => ['wattage' => 'Power draw (W)',   'drive_bays' => 'Drive bays (3.5-inch)'],
    'PSU'         => ['wattage' => 'Rated output (W)'],
];

/** The optional attributes a component can carry, in the order the form shows them. */
const OPTIONAL_FIELDS = ['capacity_gb', 'socket', 'memory_type', 'memory_slots', 'm2_slots', 'sata_ports', 'drive_bays',
                         'has_integrated_graphics', 'includes_cooler'];

/** The optional attributes that are counts: whole numbers, zero or more. */
const COUNT_FIELDS = ['memory_slots', 'm2_slots', 'sata_ports', 'drive_bays'];

/**
 * The optional attributes that are yes-or-no answers, stored as 1 or 0. The
 * REQUIRES_CATEGORY rules read them: a processor without integrated graphics
 * needs a GPU in the build, one sold without a cooler needs a Cooler.
 */
const FLAG_FIELDS = ['has_integrated_graphics', 'includes_cooler'];

/** Fewer than this many available is shown as low stock, here and on the dashboard. */
const LOW_STOCK_BELOW = 3;

/** The fields and labels for a category; a category added later gets a wattage only. */
function category_fields(string $category): array
{
    return CATEGORY_FIELDS[$category] ?? ['wattage' => 'Wattage (W)'];
}

/** Every category, in the order the configurator and the catalogue present them. */
function categories(): array
{
    return db()->query(
        'SELECT category_id, category_name, max_quantity, is_required, display_order
         FROM category ORDER BY display_order, category_name'
    )->fetchAll();
}

/** Active components for the catalogue (FR2.5), cheapest first within each category. */
function catalogue_components(): array
{
    return db()->query(
        'SELECT c.*, cat.category_name
         FROM component c JOIN category cat ON cat.category_id = c.category_id
         WHERE c.is_active = 1
         ORDER BY cat.display_order, c.price, c.name'
    )->fetchAll();
}

/** Every component, deactivated ones included, for the administrator (FR6.3). */
function all_components(): array
{
    return db()->query(
        'SELECT c.*, cat.category_name
         FROM component c JOIN category cat ON cat.category_id = c.category_id
         ORDER BY cat.display_order, c.name'
    )->fetchAll();
}

function find_component(int $id): ?array
{
    $stmt = db()->prepare(
        'SELECT c.*, cat.category_name
         FROM component c JOIN category cat ON cat.category_id = c.category_id
         WHERE c.component_id = ?'
    );
    $stmt->execute([$id]);
    return $stmt->fetch() ?: null;
}

/**
 * Whether a component appears in any saved configuration or order. Its
 * category must not change then: an order recorded as holding a processor
 * would suddenly hold a memory kit.
 */
function component_in_use(int $id): bool
{
    $stmt = db()->prepare(
        'SELECT EXISTS (SELECT 1 FROM build_item WHERE component_id = ?)
             OR EXISTS (SELECT 1 FROM order_item WHERE component_id = ?)'
    );
    $stmt->execute([$id, $id]);
    return (bool) $stmt->fetchColumn();
}

/** Every distinct value a column holds, for the form's suggestions. */
function distinct_values(string $column): array
{
    if (!in_array($column, ['socket', 'memory_type'], true)) {
        return [];
    }
    return db()->query(
        "SELECT DISTINCT $column FROM component WHERE $column IS NOT NULL AND $column <> '' ORDER BY $column"
    )->fetchAll(PDO::FETCH_COLUMN);
}

/**
 * Availability as the customer sees it (FR2.4): stock less what pending orders
 * have reserved, shown as a state rather than a bare number (section 9.2).
 * Returns [label, css modifier, units available].
 */
function availability(array $component): array
{
    $available = (int) $component['stock_qty'] - (int) $component['reserved_qty'];
    if ($available <= 0) {
        return ['Unavailable', 'out', 0];
    }
    if ($available < LOW_STOCK_BELOW) {
        return ['Low stock', 'low', $available];
    }
    return ['In stock', 'in', $available];
}

/** Capacity in the unit a shop would use: 2000 GB reads as 2 TB. */
function capacity_text(int $gigabytes): string
{
    return $gigabytes >= 1000 && $gigabytes % 1000 === 0
        ? ($gigabytes / 1000) . ' TB'
        : $gigabytes . ' GB';
}

/**
 * The short specification line under a component's name, e.g. "AM5 · 230 W max".
 * A processor's two flags are mentioned only when they are the exception: no
 * integrated graphics, or a cooler in the box. The counts read as a shop would
 * put them: a board's slots and ports, a kit's sticks, how a drive connects.
 */
function component_specs(array $component): array
{
    $specs = [];
    $category = (string) $component['category_name'];
    $count = static fn (string $field): ?int => ($component[$field] ?? null) === null ? null : (int) $component[$field];
    if ($component['socket'] !== null && $component['socket'] !== '') {
        $specs[] = (string) $component['socket'];
    }
    if ($component['capacity_gb'] !== null) {
        $specs[] = capacity_text((int) $component['capacity_gb']) . ($category === 'GPU' ? ' video memory' : '');
    }
    if ($component['memory_type'] !== null && $component['memory_type'] !== '') {
        $specs[] = (string) $component['memory_type'];
    }
    if ($category === 'Motherboard') {
        foreach (['memory_slots' => 'memory slot', 'm2_slots' => 'M.2 slot', 'sata_ports' => 'SATA port'] as $field => $noun) {
            if ($count($field) !== null) {
                $specs[] = $count($field) . ' ' . $noun . ($count($field) === 1 ? '' : 's');
            }
        }
    } elseif ($category === 'RAM' && $count('memory_slots') !== null) {
        $specs[] = $count('memory_slots') === 1 ? '1 stick' : $count('memory_slots') . ' sticks';
    } elseif ($category === 'Storage') {
        if (($count('m2_slots') ?? 0) > 0) {
            $specs[] = 'M.2';
        } elseif (($count('drive_bays') ?? 0) > 0) {
            $specs[] = '3.5-inch SATA';
        } elseif (($count('sata_ports') ?? 0) > 0) {
            $specs[] = 'SATA';
        }
    } elseif ($count('drive_bays') !== null) {
        $specs[] = $count('drive_bays') . ' drive bay' . ($count('drive_bays') === 1 ? '' : 's');
    }
    $watts = (int) $component['wattage'];
    $specs[] = match ($category) {
        'PSU'   => $watts . ' W output',
        'CPU'   => $watts . ' W max',
        default => $watts . ' W',
    };
    if (($component['has_integrated_graphics'] ?? null) !== null && (int) $component['has_integrated_graphics'] === 0) {
        $specs[] = 'No integrated graphics';
    }
    if (($component['includes_cooler'] ?? null) !== null && (int) $component['includes_cooler'] === 1) {
        $specs[] = 'Cooler included';
    }
    return $specs;
}

/** A component's picture: its own photograph if one is recorded, else its icon (an SSD's own, or its category's). */
function component_picture(array $component): string
{
    $url = (string) ($component['image_url'] ?? '');
    if ($url !== '') {
        $src = preg_match('#^https?://#i', $url) ? $url : url($url);
        return '<img src="' . e($src) . '" alt="" loading="lazy">';
    }
    return component_icon($component);
}
