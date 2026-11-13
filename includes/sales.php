<?php
/*
 * The sales report (asked for by the lecturer, 2 Nov): what the shop has sold,
 * for the administrator only.
 *
 * A sale is an approved order. Pending orders have not been sold yet, and
 * rejected or cancelled ones never were. An order is counted in the month it
 * was approved: approved is final (applyStockTransition() moves it no
 * further), so the time its status last changed, updated_at, is the time of
 * the sale and stays put. The dashboard's "Approved this month" counts the
 * same orders the same way.
 *
 * Every amount is what the customer was charged: the price recorded on each of
 * the order's lines when it was placed (order_item.unit_price_snapshot), so a
 * price changed in the catalogue later never rewrites what was sold.
 *
 * A period is one month, written 2026-11, or ALL_TIME. Nothing here writes to
 * the database.
 */

declare(strict_types=1);

/** The period that covers every sale ever made. */
const ALL_TIME = 'all';

/** How many months the chart shows, ending with this one. */
const SALES_MONTHS_SHOWN = 12;

/** The three measures the chart can show, as the page names them. */
const SALES_MEASURES = [
    'revenue' => 'Revenue',
    'units'   => 'Parts sold',
    'orders'  => 'Orders',
];

/**
 * This month, by the database's clock, as 2026-11: the clock every time in the
 * tables was written by, so the PHP time zone cannot move a sale into the
 * wrong month.
 */
function this_month(): string
{
    return substr((string) db()->query('SELECT CURRENT_TIMESTAMP')->fetchColumn(), 0, 7);
}

/** Whether $month is a month written as 2026-11. */
function is_month(string $month): bool
{
    return preg_match('/^(19|20|21)\d\d-(0[1-9]|1[0-2])$/', $month) === 1;
}

/**
 * The period asked for in the address: a month, ALL_TIME, or, for anything
 * else (nothing, or something that is not a month), this month.
 */
function sales_period(mixed $requested): string
{
    $requested = is_string($requested) ? $requested : '';
    return $requested === ALL_TIME || is_month($requested) ? $requested : this_month();
}

/** The month $steps months after $month (before it, if negative). */
function shift_month(string $month, int $steps): string
{
    return (new DateTimeImmutable($month . '-01'))->modify(($steps >= 0 ? '+' : '') . $steps . ' month')->format('Y-m');
}

/** A month as people read it: "November 2026", or "Nov" when $short. */
function month_label(string $month, bool $short = false): string
{
    return (new DateTimeImmutable($month . '-01'))->format($short ? 'M' : 'F Y');
}

/** A period as its heading names it. */
function period_label(string $period): string
{
    return $period === ALL_TIME ? 'All time' : month_label($period);
}

/**
 * The condition that keeps an approved order (alias o) inside $period, and its
 * values: from the first of the month up to, not including, the first of the
 * next, or $until if that comes sooner. Compared as text, which MySQL and
 * SQLite agree on.
 */
function period_condition(string $period, ?string $until = null): array
{
    if ($period === ALL_TIME) {
        return ['', []];
    }
    $end = shift_month($period, 1) . '-01 00:00:00';
    return [' AND o.updated_at >= ? AND o.updated_at < ?', [$period . '-01 00:00:00', $until !== null ? min($until, $end) : $end]];
}

/** Runs a query on the lines of the approved orders in $period (up to $until). $select and $after surround the shared joins and conditions. */
function sold_lines(string $select, string $period, string $after = '', string $joins = '', ?string $until = null): array
{
    [$condition, $values] = period_condition($period, $until);
    $stmt = db()->prepare($select . '
         FROM orders o
         JOIN order_item oi ON oi.order_id = o.order_id' . $joins . "
         WHERE o.status = 'approved'" . $condition . $after);
    $stmt->execute($values);
    return $stmt->fetchAll();
}


/* ---------------------------------------------------------------------------
 * The figures
 * ------------------------------------------------------------------------- */

/** Revenue (in cents), orders, parts sold and the average order (in cents) in $period, up to $until if given. */
function sales_figures(string $period, ?string $until = null): array
{
    $row = sold_lines('SELECT COUNT(DISTINCT o.order_id) AS orders, SUM(oi.quantity) AS units,
                              SUM(oi.quantity * oi.unit_price_snapshot) AS revenue', $period, '', '', $until)[0];
    $orders = (int) $row['orders'];
    $revenue = amount_cents($row['revenue'] ?? 0);
    return [
        'revenue' => $revenue,
        'orders'  => $orders,
        'units'   => (int) ($row['units'] ?? 0),
        'average' => $orders > 0 ? intdiv($revenue + intdiv($orders, 2), $orders) : 0,
    ];
}

/**
 * How a figure moved since the month before: ['up' | 'down' | 'same' | 'new', percent],
 * or null when there is nothing to compare (all time, or no sales in either month).
 */
function figure_change(int $now, int $before): ?array
{
    if ($before === 0) {
        return $now === 0 ? null : ['new', null];
    }
    $percent = (int) round(($now - $before) * 100 / $before);
    return [$percent > 0 ? 'up' : ($percent < 0 ? 'down' : 'same'), abs($percent)];
}

/**
 * The sales of each of the SALES_MONTHS_SHOWN months up to and including
 * $last, oldest first, every month listed, those without a sale at nothing.
 */
function sales_by_month(string $last): array
{
    $first = shift_month($last, 1 - SALES_MONTHS_SHOWN);
    $months = [];
    for ($i = 0; $i < SALES_MONTHS_SHOWN; $i++) {
        $key = shift_month($first, $i);
        $months[$key] = ['month' => $key, 'short' => month_label($key, true),
                         'label' => month_label($key) . ($key === $last ? ' so far' : ''),
                         'revenue' => 0, 'units' => 0, 'orders' => 0];
    }
    $stmt = db()->prepare("SELECT SUBSTR(o.updated_at, 1, 7) AS month, COUNT(DISTINCT o.order_id) AS orders,
                                  SUM(oi.quantity) AS units, SUM(oi.quantity * oi.unit_price_snapshot) AS revenue
         FROM orders o
         JOIN order_item oi ON oi.order_id = o.order_id
         WHERE o.status = 'approved' AND o.updated_at >= ? AND o.updated_at < ?
         GROUP BY SUBSTR(o.updated_at, 1, 7)");
    $stmt->execute([$first . '-01 00:00:00', shift_month($last, 1) . '-01 00:00:00']);
    foreach ($stmt->fetchAll() as $row) {
        $months[$row['month']]['revenue'] = amount_cents($row['revenue']);
        $months[$row['month']]['units'] = (int) $row['units'];
        $months[$row['month']]['orders'] = (int) $row['orders'];
    }
    return array_values($months);
}

/**
 * The sales of each category in $period, every category listed, the largest
 * revenue first; categories that sold nothing follow in the configurator's order.
 */
function sales_by_category(string $period): array
{
    $sold = [];
    foreach (sold_lines('SELECT c.category_id, SUM(oi.quantity) AS units, SUM(oi.quantity * oi.unit_price_snapshot) AS revenue',
                        $period, ' GROUP BY c.category_id', ' JOIN component c ON c.component_id = oi.component_id') as $row) {
        $sold[(int) $row['category_id']] = $row;
    }
    $categories = [];
    foreach (db()->query('SELECT category_id, category_name FROM category ORDER BY display_order, category_id')->fetchAll() as $order => $category) {
        $id = (int) $category['category_id'];
        $categories[] = [
            'id'      => $id,
            'name'    => $category['category_name'],
            'revenue' => isset($sold[$id]) ? amount_cents($sold[$id]['revenue']) : 0,
            'units'   => isset($sold[$id]) ? (int) $sold[$id]['units'] : 0,
            'order'   => $order,
        ];
    }
    usort($categories, fn (array $a, array $b) => [$b['revenue'], $a['order']] <=> [$a['revenue'], $b['order']]);
    return array_map(function (array $category) {
        unset($category['order']);
        return $category;
    }, $categories);
}

/** Each part sold in $period, with how many and for how much, the largest revenue first. */
function sales_by_part(string $period): array
{
    $parts = sold_lines('SELECT c.component_id, c.name, c.brand, cat.category_id, cat.category_name,
                                SUM(oi.quantity) AS units, SUM(oi.quantity * oi.unit_price_snapshot) AS revenue',
        $period,
        ' GROUP BY c.component_id, c.name, c.brand, cat.category_id, cat.category_name, cat.display_order',
        ' JOIN component c ON c.component_id = oi.component_id JOIN category cat ON cat.category_id = c.category_id');
    foreach ($parts as &$part) {
        $part['revenue'] = amount_cents($part['revenue']);
        $part['units'] = (int) $part['units'];
    }
    unset($part);
    usort($parts, fn (array $a, array $b) => [$b['revenue'], $a['name']] <=> [$a['revenue'], $b['name']]);
    return $parts;
}

/** The approved orders in $period, the latest sale first. */
function sales_orders(string $period): array
{
    $orders = sold_lines('SELECT o.order_id, o.updated_at, u.username, b.build_name,
                                 SUM(oi.quantity) AS units, SUM(oi.quantity * oi.unit_price_snapshot) AS revenue',
        $period,
        ' GROUP BY o.order_id, o.updated_at, u.username, b.build_name ORDER BY o.updated_at DESC, o.order_id DESC',
        ' JOIN `user` u ON u.user_id = o.user_id JOIN build b ON b.build_id = o.build_id');
    foreach ($orders as &$order) {
        $order['revenue'] = amount_cents($order['revenue']);
        $order['units'] = (int) $order['units'];
    }
    unset($order);
    return $orders;
}

/** The months that have at least one sale, the latest first: the periods the filter offers besides this month. */
function months_with_sales(): array
{
    return db()->query("SELECT DISTINCT SUBSTR(updated_at, 1, 7) FROM orders WHERE status = 'approved' ORDER BY 1 DESC")
        ->fetchAll(PDO::FETCH_COLUMN);
}

/**
 * The month before $period to compare it with, and how to name it. This month
 * is not over yet, so it is compared with the same stretch of last month, up
 * to the same day and hour: two days of November against the whole of
 * October would show every figure falling. Returns [month, up to, name], or
 * nulls for all time.
 */
function comparison(string $period): array
{
    if ($period === ALL_TIME) {
        return [null, null, null];
    }
    $before = shift_month($period, -1);
    $now = (string) db()->query('SELECT CURRENT_TIMESTAMP')->fetchColumn();
    if (substr($now, 0, 7) !== $period) {
        return [$before, null, month_label($before, true) . ' ' . substr($before, 0, 4)];
    }
    $start = new DateTimeImmutable($before . '-01 00:00:00');
    $gone = (new DateTimeImmutable($period . '-01 00:00:00'))->diff(new DateTimeImmutable($now));
    $until = min($start->add($gone)->format('Y-m-d H:i:s'), $period . '-01 00:00:00');
    $lastDay = (int) (new DateTimeImmutable($until))->modify('-1 second')->format('j');
    return [$before, $until, ($lastDay === 1 ? '1' : '1–' . $lastDay) . ' ' . $start->format('M Y')];
}

/**
 * Everything the page shows for $period. The chart's months end with this
 * month whatever the period, so that the bar of the month shown can be picked
 * out among the months around it.
 */
function sales_report(string $period): array
{
    $figures = sales_figures($period);
    [$before, $until, $beforeName] = comparison($period);
    $previous = $before !== null ? sales_figures($before, $until) : null;
    $changes = [];
    foreach (array_keys($figures) as $key) {
        $changes[$key] = $previous !== null ? figure_change($figures[$key], $previous[$key]) : null;
    }
    return [
        'period'     => $period,
        'label'      => period_label($period),
        'heading'    => period_label($period) . ($period === this_month() ? ', so far' : ''),
        'before'     => $beforeName,
        'figures'    => $figures,
        'changes'    => $changes,
        'months'     => sales_by_month(this_month()),
        'categories' => sales_by_category($period),
        'parts'      => sales_by_part($period),
        'orders'     => sales_orders($period),
    ];
}

/** The periods the filter offers: this month, every month with a sale, the one shown, and all time. */
function period_options(string $period): array
{
    $months = array_unique(array_merge([this_month()], months_with_sales(), $period !== ALL_TIME ? [$period] : []));
    rsort($months);
    $options = [];
    foreach ($months as $month) {
        $options[$month] = month_label($month);
    }
    return $options + [ALL_TIME => 'All time'];
}


/* ---------------------------------------------------------------------------
 * The parts of the page that change with the period
 * ------------------------------------------------------------------------- */

/** Money from whole cents, as the shop shows it. */
function money_cents(int $cents): string
{
    return money(cents_amount($cents));
}

/** How a figure moved, as a line under it: an arrow and words, never colour alone. */
function change_html(?array $change, ?string $before): string
{
    if ($change === null || $before === null) {
        return '';
    }
    [$direction, $percent] = $change;
    $text = match ($direction) {
        'up'   => '▲ ' . $percent . '% vs ' . $before,
        'down' => '▼ ' . $percent . '% vs ' . $before,
        'same' => 'Same as ' . $before,
        'new'  => '▲ from none in ' . $before,
    };
    return '<span class="figure-change change-' . e($direction) . '">' . e($text) . '</span>';
}

/** The four figures. */
function render_sales_figures(array $report): string
{
    $figures = $report['figures'];
    $tiles = [
        'revenue' => ['Revenue', money_cents($figures['revenue'])],
        'orders'  => ['Orders', (string) $figures['orders']],
        'average' => ['Average order', money_cents($figures['average'])],
        'units'   => ['Parts sold', (string) $figures['units']],
    ];
    $html = '';
    foreach ($tiles as $key => [$label, $value]) {
        $html .= '<div class="figure sales-figure" data-sales-figure="' . e($key) . '">'
            . '<span class="figure-label">' . e($label) . '</span>'
            . '<span class="figure-number">' . e($value) . '</span>'
            . change_html($report['changes'][$key], $report['before'])
            . '</div>';
    }
    return $html;
}

/** The categories as a table: the chart's numbers, for anyone who cannot see the chart. */
function render_sales_categories(array $report): string
{
    $total = $report['figures']['revenue'];
    ob_start();
    ?>
    <table class="data-table" id="category-table">
        <thead>
            <tr>
                <th scope="col">Category</th>
                <th scope="col" class="num">Parts sold</th>
                <th scope="col" class="num">Revenue</th>
                <th scope="col" class="num">Share</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($report['categories'] as $category): ?>
                <tr data-category="<?= (int) $category['id'] ?>">
                    <td><?= e($category['name']) ?></td>
                    <td class="num"><?= (int) $category['units'] ?></td>
                    <td class="num"><?= e(money_cents($category['revenue'])) ?></td>
                    <td class="num"><?= $total > 0 ? (int) round($category['revenue'] * 100 / $total) . '%' : '–' ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
    <?php
    return (string) ob_get_clean();
}

/** The parts sold, the largest revenue first; the page's script sorts it again when a heading is clicked. */
function render_sales_parts(array $report): string
{
    if ($report['parts'] === []) {
        return '<p class="muted" data-no-sales>Nothing was sold in ' . e($report['period'] === ALL_TIME ? 'any month' : $report['label']) . '.</p>';
    }
    ob_start();
    ?>
    <div class="table-wrap">
        <table class="data-table sortable" id="parts-sold">
            <thead>
                <tr>
                    <th scope="col" data-sort="text">Component</th>
                    <th scope="col" data-sort="text">Category</th>
                    <th scope="col" class="num" data-sort="number">Sold</th>
                    <th scope="col" class="num" data-sort="number" aria-sort="descending">Revenue</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($report['parts'] as $part): ?>
                    <tr data-part="<?= (int) $part['component_id'] ?>" data-category="<?= (int) $part['category_id'] ?>">
                        <td data-value="<?= e($part['name']) ?>"><a href="<?= e(url('admin/component-form.php?id=' . (int) $part['component_id'])) ?>"><?= e($part['name']) ?></a> <span class="muted"><?= e($part['brand']) ?></span></td>
                        <td data-value="<?= e($part['category_name']) ?>"><?= e($part['category_name']) ?></td>
                        <td class="num" data-value="<?= (int) $part['units'] ?>"><?= (int) $part['units'] ?></td>
                        <td class="num" data-value="<?= (int) $part['revenue'] ?>"><?= e(money_cents($part['revenue'])) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php
    return (string) ob_get_clean();
}

/** The approved orders of the period, each leading to the order. */
function render_sales_orders(array $report): string
{
    if ($report['orders'] === []) {
        return '<p class="muted">No order was approved in ' . e($report['period'] === ALL_TIME ? 'any month' : $report['label']) . '.</p>';
    }
    ob_start();
    ?>
    <div class="table-wrap">
        <table class="data-table" id="sales-orders">
            <thead>
                <tr>
                    <th scope="col">Order</th>
                    <th scope="col">Customer</th>
                    <th scope="col">Configuration</th>
                    <th scope="col">Approved</th>
                    <th scope="col" class="num">Parts</th>
                    <th scope="col" class="num">Total</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($report['orders'] as $order): ?>
                    <?php $id = (int) $order['order_id']; ?>
                    <tr data-order="<?= $id ?>">
                        <td class="cell-order"><a href="<?= e(url('admin/order.php?id=' . $id)) ?>"><strong><?= e(order_ref($id)) ?></strong></a></td>
                        <td><?= e($order['username']) ?></td>
                        <td><?= e($order['build_name']) ?></td>
                        <td><?= when_html((string) $order['updated_at']) ?></td>
                        <td class="num"><?= (int) $order['units'] ?></td>
                        <td class="num"><?= e(money_cents($order['revenue'])) ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php
    return (string) ob_get_clean();
}

/**
 * What the page's script needs to draw the charts and to swap in another
 * period without loading the page again: the numbers, and the parts of the
 * page that change with the period, rendered here so that the page shows
 * exactly what the server counted.
 */
function sales_payload(array $report): array
{
    return [
        'period'     => $report['period'],
        'label'      => $report['label'],
        'heading'    => $report['heading'],
        'months'     => $report['months'],
        'categories' => $report['categories'],
        'total'      => $report['figures']['revenue'],
        'html'       => [
            'figures'    => render_sales_figures($report),
            'categories' => render_sales_categories($report),
            'parts'      => render_sales_parts($report),
            'orders'     => render_sales_orders($report),
        ],
    ];
}
