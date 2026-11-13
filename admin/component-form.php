<?php
/*
 * Component management, the form (section 9.6; FR6.1, FR6.2, FR6.4).
 *
 * Adds a component, or edits one when opened as component-form.php?id=N.
 * The form shows only the attributes the chosen category uses
 * (component-form.js), and every rule the markup declares is checked again
 * here, whatever the browser sent (FR11.2). An attribute the category does
 * not use is stored as NULL even if one arrives.
 *
 * Stock also moves while the form is open: an approved order takes its parts
 * out (step 5). So the form remembers the stock it showed (stock_seen). Left
 * as it was, the stock is not written at all, and whatever an approval did in
 * the meantime stands; changed, it is written only if the stock is still the
 * figure shown and still covers what pending orders have reserved.
 *
 * Every stock figure written here goes into the stock ledger in the same
 * transaction (includes/inventory.php): a new part's first stock as its
 * opening, a figure typed over as a correction. A delivery is booked with
 * Add stock instead, which adds to the figure rather than replacing it. The
 * part's page shows its stock history and the pending orders holding it.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

const PRICE_PATTERN = '/^\d{1,8}(\.\d{1,2})?$/';     // DECIMAL(10,2), never negative
const CODE_PATTERN  = '[A-Za-z0-9\-]+';              // sockets and memory types: AM5, LGA1851, DDR5
const MAX_WATTAGE   = 5000;
const MAX_CAPACITY  = 1000000;                       // gigabytes
const MAX_COUNT     = 16;                            // slots, ports and bays
const CODE_LENGTH   = ['socket' => 20, 'memory_type' => 10];

$categories = [];
foreach (categories() as $category) {
    $categories[(int) $category['category_id']] = $category;
}

$id = is_post() ? (int) posted('id') : (int) (is_string($_GET['id'] ?? null) ? $_GET['id'] : 0);
$existing = null;
if ($id > 0) {
    $existing = find_component($id);
    if ($existing === null) {
        flash('error', 'That component no longer exists.');
        redirect('admin/components.php');
    }
}
$editing = $existing !== null;
$reserved = $editing ? (int) $existing['reserved_qty'] : 0;

// The stock the form showed when it was opened, to tell a change the administrator
// made from one an order made meanwhile. A form from before this existed sends none.
$stockSeen = $editing ? (string) $existing['stock_qty'] : '';
if ($editing && is_post() && ctype_digit(posted('stock_seen'))) {
    $stockSeen = posted('stock_seen');
}

$values = [
    'category_id' => $editing ? (string) $existing['category_id'] : '',
    'name'        => $editing ? (string) $existing['name'] : '',
    'brand'       => $editing ? (string) $existing['brand'] : '',
    'price'       => $editing ? number_format((float) $existing['price'], 2, '.', '') : '',
    'stock_qty'   => $editing ? (string) $existing['stock_qty'] : '',
    'wattage'     => $editing ? (string) $existing['wattage'] : '',
    'capacity_gb' => $editing ? (string) ($existing['capacity_gb'] ?? '') : '',
    'socket'      => $editing ? (string) ($existing['socket'] ?? '') : '',
    'memory_type' => $editing ? (string) ($existing['memory_type'] ?? '') : '',
    'memory_slots' => $editing ? (string) ($existing['memory_slots'] ?? '') : '',
    'm2_slots'     => $editing ? (string) ($existing['m2_slots'] ?? '') : '',
    'sata_ports'   => $editing ? (string) ($existing['sata_ports'] ?? '') : '',
    'drive_bays'   => $editing ? (string) ($existing['drive_bays'] ?? '') : '',
    'has_integrated_graphics' => $editing ? (string) ($existing['has_integrated_graphics'] ?? '') : '',
    'includes_cooler'         => $editing ? (string) ($existing['includes_cooler'] ?? '') : '',
    'image_url'   => $editing ? (string) ($existing['image_url'] ?? '') : '',
];
$errors = [];

if (is_post()) {
    csrf_verify();
    foreach (array_keys($values) as $field) {
        $values[$field] = posted($field);
    }

    $category = $categories[(int) $values['category_id']] ?? null;
    $fields = $category !== null ? category_fields($category['category_name']) : [];
    if ($category === null) {
        $errors['category_id'] = 'Choose a category.';
    }

    if ($values['name'] === '') {
        $errors['name'] = "Enter the component's name.";
    } elseif (mb_strlen($values['name']) > 120) {
        $errors['name'] = 'Use no more than 120 characters.';
    }

    if ($values['brand'] === '') {
        $errors['brand'] = 'Enter the brand.';
    } elseif (mb_strlen($values['brand']) > 50) {
        $errors['brand'] = 'Use no more than 50 characters.';
    }

    if ($values['price'] === '') {
        $errors['price'] = 'Enter the price.';
    } elseif (!preg_match(PRICE_PATTERN, $values['price'])) {
        $errors['price'] = 'Enter a price of zero or more, with at most two decimal places.';
    }

    if ($values['stock_qty'] === '') {
        $errors['stock_qty'] = 'Enter the stock quantity.';
    } elseif (!ctype_digit($values['stock_qty']) || (int) $values['stock_qty'] > MAX_STOCK) {
        $errors['stock_qty'] = 'Enter a whole number, zero or more.';
    } elseif ((int) $values['stock_qty'] < $reserved && (!$editing || (int) $values['stock_qty'] !== (int) $stockSeen)) {
        $errors['stock_qty'] = "Stock cannot go below the $reserved units reserved by pending orders.";
    }

    if ($values['wattage'] === '') {
        $errors['wattage'] = 'Enter the wattage.';
    } elseif (!ctype_digit($values['wattage']) || (int) $values['wattage'] > MAX_WATTAGE) {
        $errors['wattage'] = 'Enter a whole number of watts, from 0 to ' . MAX_WATTAGE . '.';
    }

    foreach (OPTIONAL_FIELDS as $field) {
        if (!isset($fields[$field])) {
            $values[$field] = '';               // not used by this category: stored as NULL
            continue;
        }
        if (in_array($field, FLAG_FIELDS, true)) {
            // A yes-or-no answer, never left open: the rules act on a missing one as a no.
            if ($values[$field] !== '0' && $values[$field] !== '1') {
                $errors[$field] = 'Choose yes or no.';
            }
            continue;
        }
        if (in_array($field, COUNT_FIELDS, true)) {
            // A count the counting rules add up: what a board or case has, what a part takes.
            if ($values[$field] === '') {
                $errors[$field] = 'Enter a number, 0 if none.';
            } elseif (!ctype_digit($values[$field]) || (int) $values[$field] > MAX_COUNT) {
                $errors[$field] = 'Enter a whole number from 0 to ' . MAX_COUNT . '.';
            }
            continue;
        }
        if ($values[$field] === '') {
            $errors[$field] = 'Enter the ' . strtolower(preg_replace('/ \(.*\)$/', '', $fields[$field])) . '.';
        } elseif ($field === 'capacity_gb') {
            if (!ctype_digit($values[$field]) || (int) $values[$field] < 1 || (int) $values[$field] > MAX_CAPACITY) {
                $errors[$field] = 'Enter a whole number of gigabytes, 1 or more.';
            }
        } else {
            // In capitals, so "am5" and "AM5" are one socket to the compatibility rules.
            $values[$field] = strtoupper($values[$field]);
            if (!preg_match('/^' . CODE_PATTERN . '$/', $values[$field]) || strlen($values[$field]) > CODE_LENGTH[$field]) {
                $errors[$field] = 'Use up to ' . CODE_LENGTH[$field] . ' letters, digits or dashes, such as '
                                . ($field === 'socket' ? 'AM5' : 'DDR5') . '.';
            }
        }
    }

    if ($values['image_url'] !== '') {
        $isWebAddress = (bool) preg_match('#^https?://[^\s"\'<>]+$#i', $values['image_url']);
        $isLocalPath  = (bool) preg_match('#^(?!/)(?!.*\.\.)[A-Za-z0-9._/-]+$#', $values['image_url']);
        if (strlen($values['image_url']) > 255 || (!$isWebAddress && !$isLocalPath)) {
            $errors['image_url'] = 'Give a path inside the application, such as assets/photos/ryzen.jpg, or a web address starting with http.';
        }
    }

    if ($editing && $category !== null && (int) $category['category_id'] !== (int) $existing['category_id']
        && component_in_use($id)) {
        $errors['category_id'] = 'This component is in saved configurations or orders, so its category cannot change. Deactivate it and add a new one instead.';
    }

    // FR6.2: one name per category. The same name in another category is fine.
    if (!isset($errors['name']) && $category !== null) {
        $stmt = db()->prepare('SELECT 1 FROM component WHERE category_id = ? AND name = ? AND component_id <> ?');
        $stmt->execute([$category['category_id'], $values['name'], $id]);
        if ($stmt->fetchColumn() !== false) {
            $errors['name'] = 'There is already a ' . $category['category_name'] . ' with this name.';
        }
    }

    if ($errors === []) {
        $row = [
            (int) $category['category_id'],
            $values['name'],
            $values['brand'],
            $values['price'],
            (int) $values['wattage'],
            $values['capacity_gb'] === '' ? null : (int) $values['capacity_gb'],
            $values['socket'] === '' ? null : $values['socket'],
            $values['memory_type'] === '' ? null : $values['memory_type'],
            $values['memory_slots'] === '' ? null : (int) $values['memory_slots'],
            $values['m2_slots'] === '' ? null : (int) $values['m2_slots'],
            $values['sata_ports'] === '' ? null : (int) $values['sata_ports'],
            $values['drive_bays'] === '' ? null : (int) $values['drive_bays'],
            $values['has_integrated_graphics'] === '' ? null : (int) $values['has_integrated_graphics'],
            $values['includes_cooler'] === '' ? null : (int) $values['includes_cooler'],
            $values['image_url'] === '' ? null : $values['image_url'],
        ];
        $pdo = db();
        $pdo->beginTransaction();
        try {
            $stock = (int) $values['stock_qty'];
            if ($editing) {
                // The stock is written only when the administrator changed it, and then only if
                // it is still the figure the form showed and still covers what is reserved.
                $stockChanged = $stock !== (int) $stockSeen;
                $stmt = db()->prepare(
                    'UPDATE component SET category_id = ?, name = ?, brand = ?, price = ?, wattage = ?,
                            capacity_gb = ?, socket = ?, memory_type = ?, memory_slots = ?, m2_slots = ?, sata_ports = ?,
                            drive_bays = ?, has_integrated_graphics = ?, includes_cooler = ?, image_url = ?'
                    . ($stockChanged ? ', stock_qty = ? WHERE component_id = ? AND stock_qty = ? AND reserved_qty <= ?' : ' WHERE component_id = ?')
                );
                $stmt->execute($stockChanged ? [...$row, $stock, $id, (int) $stockSeen, $stock] : [...$row, $id]);
                if ($stockChanged && $stmt->rowCount() === 0) {
                    $pdo->rollBack();
                    $now = find_component($id);
                    if ($now === null) {
                        flash('error', 'That component no longer exists.');
                        redirect('admin/components.php');
                    }
                    $reserved = (int) $now['reserved_qty'];
                    if ((int) $now['stock_qty'] !== (int) $stockSeen) {
                        $errors['stock_qty'] = 'The stock changed while you were editing: it is now ' . (int) $now['stock_qty']
                            . '. Check the figure and save again.';
                        $stockSeen = (string) $now['stock_qty'];
                    } else {
                        $errors['stock_qty'] = "Stock cannot go below the $reserved units reserved by pending orders.";
                    }
                } else {
                    if ($stockChanged) {
                        record_movement($id, $stock - (int) $stockSeen, $stock, 'correction', null, 'Typed over in the component form');
                    }
                    $pdo->commit();
                    flash('success', '“' . $values['name'] . '” was saved.'
                        . ($stockChanged ? ' Its stock went from ' . (int) $stockSeen . ' to ' . $stock . ', recorded as a correction.' : ''));
                    redirect('admin/components.php');
                }
            } else {
                $stmt = db()->prepare(
                    'INSERT INTO component (category_id, name, brand, price, wattage, capacity_gb, socket, memory_type,
                                            memory_slots, m2_slots, sata_ports, drive_bays,
                                            has_integrated_graphics, includes_cooler, image_url, stock_qty)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
                );
                $stmt->execute([...$row, $stock]);
                if ($stock > 0) {
                    record_movement((int) $pdo->lastInsertId(), $stock, $stock, 'opening', null, 'Stock when the part was added');
                }
                $pdo->commit();
                flash('success', '“' . $values['name'] . '” was added to the catalogue.');
                redirect('admin/components.php');
            }
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            // Two saves of one name at the same instant both pass the check above;
            // the UNIQUE (category_id, name) index stops the second.
            if (!is_duplicate_key($e)) {
                throw $e;
            }
            $errors['name'] = 'There is already a ' . $category['category_name'] . ' with this name.';
        }
    }
}

// What the form looks like for the category now chosen. The script keeps it
// up to date as the choice changes; this is the state without it.
$chosen = $categories[(int) $values['category_id']] ?? null;
$chosenFields = $chosen !== null ? category_fields($chosen['category_name']) : [];

$categoryOptions = [];
foreach ($categories as $category) {
    $labels = category_fields($category['category_name']);
    $attributes = ['data-fields' => implode(' ', array_values(array_intersect(OPTIONAL_FIELDS, array_keys($labels))))];
    foreach ($labels as $field => $label) {
        $attributes['data-label-' . str_replace('_', '-', $field)] = $label;
    }
    $categoryOptions[$category['category_id']] = ['label' => $category['category_name'], 'attributes' => $attributes];
}

/** Wrapper attributes for an optional field: hidden, and its input disabled, when the category does not use it. */
function optional_wrapper(string $field, array $chosenFields): array
{
    return ['data-field' => $field, 'hidden' => !isset($chosenFields[$field])];
}

$title = $editing ? 'Edit component' : 'Add a component';
render_header($title, 'components');
?>
<div class="container page">
    <a class="back-link" href="<?= e(url('admin/components.php')) ?>">← All components</a>
    <div class="page-head">
        <h1 class="page-title"><?= e($title) ?></h1>
        <p class="page-lead"><?= $editing
            ? 'Changes apply to the catalogue at once. Orders already placed keep the price they recorded.'
            : 'Choose the category first: the form then asks only for what that kind of component has.' ?></p>
    </div>

    <form class="form-panel" method="post" action="<?= e(url('admin/component-form.php')) ?>" data-validate>
        <?= csrf_field() ?>
        <?php if ($editing): ?>
            <input type="hidden" name="id" value="<?= (int) $id ?>">
            <input type="hidden" name="stock_seen" value="<?= e($stockSeen) ?>">
        <?php endif; ?>

        <div class="form-grid">
            <?= select_field('category_id', 'Category', $categoryOptions, $values['category_id'], 'Choose a category', [
                'required' => true, 'data-error-required' => 'Choose a category.',
            ], $errors['category_id'] ?? '', '', ['class' => 'span-2']) ?>

            <?= input_field('name', 'Name', [
                'required' => true, 'maxlength' => 120,
                'data-error-required' => "Enter the component's name.",
            ], $values['name'], $errors['name'] ?? '', 'As the shop lists it, without the brand.', ['class' => 'span-2']) ?>

            <?= input_field('brand', 'Brand', [
                'required' => true, 'maxlength' => 50, 'data-error-required' => 'Enter the brand.',
            ], $values['brand'], $errors['brand'] ?? '') ?>

            <?= input_field('price', 'Price (RM)', [
                'type' => 'number', 'required' => true, 'min' => 0, 'max' => '99999999.99', 'step' => '0.01', 'inputmode' => 'decimal',
                'data-error-required' => 'Enter the price.',
                'data-error-min' => 'The price cannot be negative.',
                'data-error-step' => 'Use at most two decimal places.',
            ], $values['price'], $errors['price'] ?? '') ?>

            <?= input_field('stock_qty', 'Stock', [
                'type' => 'number', 'required' => true, 'min' => $reserved, 'max' => MAX_STOCK, 'step' => 1, 'inputmode' => 'numeric',
                'data-error-required' => 'Enter the stock quantity.',
                'data-error-min' => $reserved > 0 ? "Stock cannot go below the $reserved units reserved by pending orders." : 'Stock cannot be negative.',
                'data-error-step' => 'Enter a whole number.',
            ], $values['stock_qty'], $errors['stock_qty'] ?? '', $editing
                ? "$reserved reserved by pending orders. For a delivery use Add stock below; type over this figure only after a count."
                : '') ?>

            <?= input_field('wattage', $chosenFields['wattage'] ?? 'Wattage (W)', [
                'type' => 'number', 'required' => true, 'min' => 0, 'max' => MAX_WATTAGE, 'step' => 1, 'inputmode' => 'numeric',
                'data-error-required' => 'Enter the wattage.',
                'data-error-min' => 'The wattage cannot be negative.',
                'data-error-step' => 'Enter a whole number of watts.',
            ], $values['wattage'], $errors['wattage'] ?? '') ?>

            <?= input_field('capacity_gb', $chosenFields['capacity_gb'] ?? 'Capacity (GB)', [
                'type' => 'number', 'required' => true, 'min' => 1, 'max' => MAX_CAPACITY, 'step' => 1, 'inputmode' => 'numeric',
                'disabled' => !isset($chosenFields['capacity_gb']),
                'data-error-required' => 'Enter the capacity.',
                'data-error-min' => 'The capacity must be at least 1 GB.',
                'data-error-step' => 'Enter a whole number of gigabytes.',
            ], $values['capacity_gb'], $errors['capacity_gb'] ?? '', 'In gigabytes: 2 TB is 2000.', optional_wrapper('capacity_gb', $chosenFields)) ?>

            <?= input_field('socket', $chosenFields['socket'] ?? 'Socket', [
                'required' => true, 'maxlength' => CODE_LENGTH['socket'], 'pattern' => CODE_PATTERN, 'list' => 'socket-options',
                'autocapitalize' => 'characters', 'disabled' => !isset($chosenFields['socket']),
                'data-error-required' => 'Enter the socket.',
                'data-error-pattern' => 'Use letters, digits or dashes, such as AM5.',
            ], $values['socket'], $errors['socket'] ?? '', 'Compared with the motherboard by the socket rule.', optional_wrapper('socket', $chosenFields)) ?>

            <?= input_field('memory_type', $chosenFields['memory_type'] ?? 'Memory type', [
                'required' => true, 'maxlength' => CODE_LENGTH['memory_type'], 'pattern' => CODE_PATTERN, 'list' => 'memory-options',
                'autocapitalize' => 'characters', 'disabled' => !isset($chosenFields['memory_type']),
                'data-error-required' => 'Enter the memory type.',
                'data-error-pattern' => 'Use letters, digits or dashes, such as DDR5.',
            ], $values['memory_type'], $errors['memory_type'] ?? '', 'Compared with the motherboard by the memory rule.', optional_wrapper('memory_type', $chosenFields)) ?>

            <?php foreach ([
                'memory_slots' => 'On a motherboard, how many it has. For memory, how many sticks it is.',
                'm2_slots'     => 'On a motherboard, how many it has. For a drive, 1 if it is an M.2 drive, else 0.',
                'sata_ports'   => 'On a motherboard, how many it has. For a drive, 1 if it plugs into one, else 0.',
                'drive_bays'   => 'In a case, how many 3.5-inch bays. For a drive, 1 if it is a 3.5-inch hard disk, else 0.',
            ] as $field => $hint): ?>
                <?= input_field($field, $chosenFields[$field] ?? ucfirst(ATTRIBUTE_LABELS[$field]), [
                    'type' => 'number', 'required' => true, 'min' => 0, 'max' => MAX_COUNT, 'step' => 1, 'inputmode' => 'numeric',
                    'disabled' => !isset($chosenFields[$field]),
                    'data-error-required' => 'Enter a number, 0 if none.',
                    'data-error-min' => 'The number cannot be negative.',
                    'data-error-max' => 'Enter a number up to ' . MAX_COUNT . '.',
                    'data-error-step' => 'Enter a whole number.',
                ], $values[$field], $errors[$field] ?? '', $hint, optional_wrapper($field, $chosenFields)) ?>
            <?php endforeach; ?>

            <?= select_field('has_integrated_graphics', 'Integrated graphics',
                ['1' => 'Yes', '0' => 'No, it needs a graphics card'], $values['has_integrated_graphics'], 'Choose', [
                'required' => true, 'disabled' => !isset($chosenFields['has_integrated_graphics']),
                'data-error-required' => 'Choose yes or no.',
            ], $errors['has_integrated_graphics'] ?? '', 'Without it, a build must include a graphics card.', optional_wrapper('has_integrated_graphics', $chosenFields)) ?>

            <?= select_field('includes_cooler', 'Cooler in the box',
                ['1' => 'Yes', '0' => 'No, sold without one'], $values['includes_cooler'], 'Choose', [
                'required' => true, 'disabled' => !isset($chosenFields['includes_cooler']),
                'data-error-required' => 'Choose yes or no.',
            ], $errors['includes_cooler'] ?? '', 'Without one, a build must include a CPU cooler.', optional_wrapper('includes_cooler', $chosenFields)) ?>

            <?= input_field('image_url', 'Photograph (optional)', [
                'maxlength' => 255,
            ], $values['image_url'], $errors['image_url'] ?? '', "Leave empty to show the category's icon.", ['class' => 'span-2']) ?>
        </div>

        <datalist id="socket-options">
            <?php foreach (distinct_values('socket') as $socket): ?><option value="<?= e($socket) ?>"></option><?php endforeach; ?>
        </datalist>
        <datalist id="memory-options">
            <?php foreach (distinct_values('memory_type') as $type): ?><option value="<?= e($type) ?>"></option><?php endforeach; ?>
        </datalist>

        <div class="form-actions">
            <a class="btn btn-ghost" href="<?= e(url('admin/components.php')) ?>">Cancel</a>
            <button type="submit" class="btn btn-primary"><?= $editing ? 'Save changes' : 'Add component' ?></button>
        </div>
    </form>

    <?php if ($editing): ?>
        <?php
        $current = find_component($id);
        $holding = reserved_by($id);
        $history = part_movements($id);
        ?>
        <section class="panel part-stock" aria-labelledby="stock-title" data-part-stock>
            <div class="chart-head">
                <h2 class="section-title" id="stock-title">Stock</h2>
                <?= add_stock_button($current, 'component', 'btn-sm') ?>
            </div>
            <dl class="order-facts stock-facts">
                <div><dt>In stock</dt><dd data-in-stock><?= (int) $current['stock_qty'] ?></dd></div>
                <div><dt>Reserved</dt><dd data-reserved><?= (int) $current['reserved_qty'] ?></dd></div>
                <div><dt>Available to order</dt><dd><strong><?= (int) $current['stock_qty'] - (int) $current['reserved_qty'] ?></strong></dd></div>
            </dl>

            <h3 class="sub-title">Reserved by pending orders</h3>
            <?php if ($holding === []): ?>
                <p class="muted" data-no-reservations>No pending order holds this part.</p>
            <?php else: ?>
                <p class="muted">Still on the shelf: they leave the stock when the order is approved, and return to it if it is rejected or cancelled.</p>
                <div class="table-wrap">
                    <table class="data-table" id="reserved-by">
                        <thead><tr><th scope="col">Order</th><th scope="col">Customer</th><th scope="col">Placed</th><th scope="col" class="num">Holds</th></tr></thead>
                        <tbody>
                            <?php foreach ($holding as $order): ?>
                                <tr data-order="<?= (int) $order['order_id'] ?>">
                                    <td class="cell-order"><a href="<?= e(url('admin/order.php?id=' . (int) $order['order_id'])) ?>"><strong><?= e(order_ref((int) $order['order_id'])) ?></strong></a></td>
                                    <td><?= e($order['username']) ?></td>
                                    <td><?= when_html((string) $order['created_at']) ?></td>
                                    <td class="num"><?= (int) $order['quantity'] ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>

            <h3 class="sub-title">Stock history</h3>
            <?php if ($history === []): ?>
                <p class="muted">Nothing recorded yet.</p>
            <?php else: ?>
                <?php render_movements($history, 'part-history', false); ?>
                <p class="muted history-more"><a href="<?= e(url('admin/inventory.php?component=' . $id)) ?>">All of this part's stock history in the Inventory log</a></p>
            <?php endif; ?>
        </section>
        <?php render_add_stock_dialog('component'); ?>
    <?php endif; ?>
</div>
<?php
render_footer(['component-form.js', 'inventory.js']);
