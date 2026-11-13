<?php
/*
 * The stock ledger (3 November 2026): every change to a part's stock is
 * recorded in stock_movement, so that the administrator can see on the
 * admin pages how each figure came about, without opening phpMyAdmin.
 *
 * Stock changes in three places, and each records its row in the same
 * transaction as the change:
 *   - applyStockTransition() (orders.php), when an order is approved: "sold";
 *   - add_stock() here, the Add stock button, when goods arrive: "received";
 *   - the component form, when the administrator types over the stock figure
 *     after a count ("correction"), or adds a part with stock ("opening").
 * components.sql writes each part's "opening" row when the catalogue is loaded.
 *
 * The latest row of a part must equal its stock_qty. The dashboard checks it,
 * which catches a figure changed outside the system, in phpMyAdmin for instance.
 */

declare(strict_types=1);

/** The most a part may hold: the component form's limit too. */
const MAX_STOCK = 1000000;

/** The longest note a movement keeps. */
const MOVEMENT_NOTE_MAX = 255;

/** The four reasons, as the pages name them. */
const MOVEMENT_REASONS = [
    'opening'    => 'Opening stock',
    'received'   => 'Received',
    'sold'       => 'Sold',
    'correction' => 'Correction',
];

/** How many rows the Inventory log shows at most; the filters narrow it. */
const LOG_ROWS_SHOWN = 300;

/** Stock that could not be added, with the reason to show. */
final class StockRefused extends RuntimeException
{
}

/**
 * Writes one row of the ledger. Called inside the transaction of the change it
 * records; who made it is the user logged in, if any.
 */
function record_movement(int $componentId, int $change, int $stockAfter, string $reason, ?int $orderId = null, ?string $note = null): void
{
    $user = current_user();
    db()->prepare('INSERT INTO stock_movement (component_id, change_qty, stock_after, reason, order_id, user_id, note)
                   VALUES (?, ?, ?, ?, ?, ?, ?)')
        ->execute([$componentId, $change, $stockAfter, $reason, $orderId, $user !== null ? (int) $user['user_id'] : null,
                   $note !== null && $note !== '' ? $note : null]);
}

/** What is wrong with a quantity received as typed, or '' if nothing. */
function quantity_problem(string $quantity): string
{
    if ($quantity === '') {
        return 'Enter how many arrived.';
    }
    if (!ctype_digit($quantity) || (int) $quantity < 1 || (int) $quantity > MAX_STOCK) {
        return 'Enter a whole number, 1 or more.';
    }
    return '';
}

/** What is wrong with a note as typed, or '' if nothing. */
function note_problem(string $note): string
{
    return mb_strlen($note) > MOVEMENT_NOTE_MAX ? 'Use no more than ' . MOVEMENT_NOTE_MAX . ' characters.' : '';
}

/**
 * Goods received: adds $quantity to a part's stock and records it. The part is
 * locked while it is read, so two deliveries booked at once add up, and an
 * approval at the same moment waits. Returns [name, stock before, stock after].
 */
function add_stock(int $componentId, int $quantity, string $note = ''): array
{
    if ($quantity < 1 || $quantity > MAX_STOCK) {
        throw new StockRefused('Enter a whole number, 1 or more.');
    }
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('SELECT name, stock_qty FROM component WHERE component_id = ?' . for_update());
        $stmt->execute([$componentId]);
        $part = $stmt->fetch();
        if ($part === false) {
            throw new StockRefused('That component no longer exists.');
        }
        $before = (int) $part['stock_qty'];
        $after = $before + $quantity;
        if ($after > MAX_STOCK) {
            throw new StockRefused('That would take the stock past ' . number_format(MAX_STOCK) . ', the most a part may hold.');
        }
        $pdo->prepare('UPDATE component SET stock_qty = stock_qty + ? WHERE component_id = ?')->execute([$quantity, $componentId]);
        record_movement($componentId, $quantity, $after, 'received', null, $note);
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
    return [(string) $part['name'], $before, $after];
}


/* ---------------------------------------------------------------------------
 * Reading the ledger
 * ------------------------------------------------------------------------- */

const MOVEMENT_COLUMNS = 'SELECT m.*, c.name, c.brand, c.is_active, cat.category_id, cat.category_name, u.username
     FROM stock_movement m
     JOIN component c ON c.component_id = m.component_id
     JOIN category cat ON cat.category_id = c.category_id
     LEFT JOIN `user` u ON u.user_id = m.user_id';

/**
 * The Inventory log's filters as the address gives them, each checked:
 * component and category are numbers, reason one of the four, month a month.
 * Anything else is ignored.
 */
function movement_filter(array $query): array
{
    $number = static fn (string $key): ?int => is_string($query[$key] ?? null) && ctype_digit($query[$key]) && (int) $query[$key] > 0 ? (int) $query[$key] : null;
    $reason = is_string($query['reason'] ?? null) && isset(MOVEMENT_REASONS[$query['reason']]) ? $query['reason'] : '';
    $month = is_string($query['month'] ?? null) && is_month($query['month']) ? $query['month'] : '';
    return ['component' => $number('component'), 'category' => $number('category'), 'reason' => $reason, 'month' => $month];
}

/** The WHERE of a filter, and its values. */
function movement_where(array $filter): array
{
    $where = [];
    $values = [];
    if ($filter['component'] !== null) {
        $where[] = 'm.component_id = ?';
        $values[] = $filter['component'];
    }
    if ($filter['category'] !== null) {
        $where[] = 'c.category_id = ?';
        $values[] = $filter['category'];
    }
    if ($filter['reason'] !== '') {
        $where[] = 'm.reason = ?';
        $values[] = $filter['reason'];
    }
    if ($filter['month'] !== '') {
        $where[] = 'm.created_at >= ? AND m.created_at < ?';
        $values[] = $filter['month'] . '-01 00:00:00';
        $values[] = shift_month($filter['month'], 1) . '-01 00:00:00';
    }
    return [$where === [] ? '' : ' WHERE ' . implode(' AND ', $where), $values];
}

/** The latest movements that pass the filter, at most $limit of them, the latest first. */
function movements(array $filter, int $limit = LOG_ROWS_SHOWN): array
{
    [$where, $values] = movement_where($filter);
    $stmt = db()->prepare(MOVEMENT_COLUMNS . $where . ' ORDER BY m.created_at DESC, m.movement_id DESC LIMIT ' . max(1, $limit));
    $stmt->execute($values);
    return $stmt->fetchAll();
}

/** How many movements pass the filter, and what they add up to: [rows, received, sold, corrected, opening]. */
function movement_totals(array $filter): array
{
    [$where, $values] = movement_where($filter);
    $stmt = db()->prepare("SELECT COUNT(*) AS n,
            COALESCE(SUM(CASE WHEN m.reason = 'received' THEN m.change_qty END), 0) AS received,
            COALESCE(SUM(CASE WHEN m.reason = 'sold' THEN m.change_qty END), 0) AS sold,
            COALESCE(SUM(CASE WHEN m.reason = 'correction' THEN m.change_qty END), 0) AS corrected,
            COALESCE(SUM(CASE WHEN m.reason = 'opening' THEN m.change_qty END), 0) AS opening
         FROM stock_movement m
         JOIN component c ON c.component_id = m.component_id" . $where);
    $stmt->execute($values);
    return array_map('intval', $stmt->fetch());
}

/** The months that have a movement, the latest first. */
function months_with_movements(): array
{
    return db()->query('SELECT DISTINCT SUBSTR(created_at, 1, 7) FROM stock_movement ORDER BY 1 DESC')->fetchAll(PDO::FETCH_COLUMN);
}

/** A part's latest movements, the latest first. */
function part_movements(int $componentId, int $limit = 20): array
{
    return movements(['component' => $componentId, 'category' => null, 'reason' => '', 'month' => ''], $limit);
}

/**
 * The pending orders holding some of a part, the oldest first: why its
 * reserved quantity is what it is. Reserved goods are still on the shelf.
 */
function reserved_by(int $componentId): array
{
    $stmt = db()->prepare("SELECT o.order_id, o.created_at, u.username, oi.quantity
         FROM order_item oi
         JOIN orders o ON o.order_id = oi.order_id
         JOIN `user` u ON u.user_id = o.user_id
         WHERE oi.component_id = ? AND o.status = 'pending'
         ORDER BY o.created_at, o.order_id");
    $stmt->execute([$componentId]);
    return $stmt->fetchAll();
}

/**
 * The stock check: every part whose stock differs from what its ledger says,
 * the stock after its latest movement (0 for a part with none). Nothing here
 * unless a figure was changed outside the system.
 */
function ledger_mismatches(): array
{
    return db()->query(
        'SELECT * FROM (
             SELECT c.component_id, c.name, cat.category_name, cat.display_order, c.stock_qty,
                    (SELECT m.stock_after FROM stock_movement m WHERE m.component_id = c.component_id
                     ORDER BY m.movement_id DESC LIMIT 1) AS ledger
             FROM component c JOIN category cat ON cat.category_id = c.category_id
         ) parts
         WHERE COALESCE(parts.ledger, 0) <> parts.stock_qty
         ORDER BY parts.display_order, parts.name'
    )->fetchAll();
}


/* ---------------------------------------------------------------------------
 * Showing it
 * ------------------------------------------------------------------------- */

/** A change as the log writes it: +5, −2 (a true minus sign). */
function change_text(int $change): string
{
    return ($change > 0 ? '+' : '−') . number_format(abs($change));
}

/** A reason as a small label. */
function reason_badge(string $reason): string
{
    return '<span class="reason reason-' . e($reason) . '">' . e(MOVEMENT_REASONS[$reason] ?? $reason) . '</span>';
}

/** What a movement was about: the order it sold to, and the note. */
function movement_detail(array $movement): string
{
    $parts = [];
    if ($movement['order_id'] !== null) {
        $id = (int) $movement['order_id'];
        $parts[] = '<a href="' . e(url('admin/order.php?id=' . $id)) . '">Order ' . e(order_ref($id)) . '</a>';
    }
    if ((string) ($movement['note'] ?? '') !== '') {
        $parts[] = '<span class="muted">' . e($movement['note']) . '</span>';
    }
    return implode(' ', $parts);
}

/**
 * The ledger as a table. $withPart leaves out the part's own columns, on the
 * part's own page.
 */
function render_movements(array $rows, string $tableId, bool $withPart = true): void
{
    ?>
    <div class="table-wrap">
        <table class="data-table movements" id="<?= e($tableId) ?>">
            <thead>
                <tr>
                    <th scope="col">When</th>
                    <?php if ($withPart): ?><th scope="col">Component</th><th scope="col">Category</th><?php endif; ?>
                    <th scope="col">Reason</th>
                    <th scope="col" class="num">Change</th>
                    <th scope="col" class="num">Stock after</th>
                    <th scope="col">By</th>
                    <th scope="col">About</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($rows as $row): ?>
                    <tr data-movement="<?= (int) $row['movement_id'] ?>" data-reason="<?= e($row['reason']) ?>">
                        <td><?= when_html((string) $row['created_at']) ?></td>
                        <?php if ($withPart): ?>
                            <td><a href="<?= e(url('admin/component-form.php?id=' . (int) $row['component_id'])) ?>"><?= e($row['name']) ?></a></td>
                            <td><?= e($row['category_name']) ?></td>
                        <?php endif; ?>
                        <td><?= reason_badge((string) $row['reason']) ?></td>
                        <td class="num change <?= (int) $row['change_qty'] > 0 ? 'change-in' : 'change-out' ?>"><?= e(change_text((int) $row['change_qty'])) ?></td>
                        <td class="num"><?= (int) $row['stock_after'] ?></td>
                        <td><?= $row['username'] !== null ? e($row['username']) : '<span class="muted">System</span>' ?></td>
                        <td><?= movement_detail($row) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php
}

/** The two tabs of the components pages: the list, and the stock ledger. */
function render_stock_tabs(string $current): void
{
    $tabs = ['components' => ['Components', 'admin/components.php'], 'inventory' => ['Inventory log', 'admin/inventory.php']];
    echo '<nav class="tabs" aria-label="Components and their stock">';
    foreach ($tabs as $key => [$label, $page]) {
        echo '<a href="' . e(url($page)) . '"' . ($key === $current ? ' class="is-current" aria-current="page"' : '') . '>' . e($label) . '</a>';
    }
    echo '</nav>';
}

/**
 * The Add stock button for a part: a link to the form, which the page's
 * script opens in a dialog instead (inventory.js). $back is where to return.
 */
function add_stock_button(array $part, string $back, string $size = 'btn-sm'): string
{
    $id = (int) $part['component_id'];
    return '<a class="btn btn-ghost ' . e($size) . '" href="' . e(url('admin/stock.php?id=' . $id . '&back=' . rawurlencode($back))) . '"'
        . ' data-add-stock="' . $id . '" data-name="' . e($part['name']) . '" data-stock="' . (int) $part['stock_qty'] . '">Add stock</a>';
}

/** Where Add stock may send the administrator back to: the list, the dashboard, or the part's page. */
function stock_back(string $back, int $componentId): string
{
    return match ($back) {
        'dashboard' => 'admin/dashboard.php',
        'component' => 'admin/component-form.php?id=' . $componentId,
        'inventory' => 'admin/inventory.php',
        default     => 'admin/components.php',
    };
}

/**
 * The dialog Add stock opens: one on each page that offers the button. Filled
 * in by inventory.js with the part chosen; without a script the button opens
 * the same form as a page of its own (admin/stock.php).
 */
function render_add_stock_dialog(string $back): void
{
    ?>
    <dialog class="stock-dialog" id="add-stock-dialog" aria-labelledby="add-stock-title">
        <form method="post" action="<?= e(url('admin/stock.php')) ?>" data-validate data-stock-form>
            <?= csrf_field() ?>
            <input type="hidden" name="id" value="">
            <input type="hidden" name="back" value="<?= e($back) ?>">
            <h2 class="stock-title" id="add-stock-title">Add stock</h2>
            <p class="stock-text" data-stock-now></p>
            <?= input_field('quantity', 'Quantity received', [
                'type' => 'number', 'required' => true, 'min' => 1, 'max' => MAX_STOCK, 'step' => 1, 'inputmode' => 'numeric',
                'id' => 'f-dialog-quantity',
                'data-error-required' => 'Enter how many arrived.',
                'data-error-type' => 'Enter a whole number, 1 or more.',
                'data-error-min' => 'Enter a whole number, 1 or more.',
                'data-error-max' => 'Enter a whole number, 1 or more.',
                'data-error-step' => 'Enter a whole number, 1 or more.',
            ]) ?>
            <?= input_field('note', 'Note (optional)', [
                'maxlength' => MOVEMENT_NOTE_MAX, 'id' => 'f-dialog-note', 'placeholder' => 'Supplier, delivery number…',
                'data-error-maxlength' => 'Use no more than ' . MOVEMENT_NOTE_MAX . ' characters.',
            ]) ?>
            <div class="stock-actions">
                <button type="button" class="btn btn-ghost" data-stock-cancel>Cancel</button>
                <button type="submit" class="btn btn-primary" data-stock-save>Add to stock</button>
            </div>
        </form>
    </dialog>
    <?php
}
