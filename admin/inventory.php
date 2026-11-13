<?php
/*
 * The Inventory log (3 November 2026): every change to every part's stock,
 * the latest first, from the stock ledger (stock_movement). Goods received,
 * sold on an approved order, a count typed over, and each part's opening
 * stock, with who did it and the order or note it was about. Filtered by
 * category, reason and month, and by one part when a part's page links here.
 *
 * It only reads. Stock changes through Add stock, the component form and an
 * order's approval, each of which writes its row (includes/inventory.php).
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

$filter = movement_filter($_GET);
$rows = movements($filter);
$totals = movement_totals($filter);
$part = $filter['component'] !== null ? find_component($filter['component']) : null;

$categoryOptions = ['' => 'All categories'];
foreach (categories() as $category) {
    $categoryOptions[(string) $category['category_id']] = $category['category_name'];
}
$reasonOptions = ['' => 'All reasons'] + MOVEMENT_REASONS;
$monthOptions = ['' => 'All months'];
foreach (months_with_movements() as $month) {
    $monthOptions[$month] = month_label($month);
}

render_header('Inventory log', 'components');
?>
<div class="container page">
    <div class="page-head">
        <h1 class="page-title">Inventory log</h1>
        <p class="page-lead">Every change to the stock, the latest first: what arrived, what left on an approved order, and every count typed over. Reserved parts are still on the shelf, so they appear here only once their order is approved.</p>
    </div>
    <?php render_stock_tabs('inventory'); ?>

    <form class="filter-bar" method="get" action="<?= e(url('admin/inventory.php')) ?>" data-movement-filter>
        <?php if ($filter['component'] !== null): ?>
            <input type="hidden" name="component" value="<?= (int) $filter['component'] ?>">
        <?php endif; ?>
        <?= select_field('category', 'Category', $categoryOptions, (string) ($filter['category'] ?? '')) ?>
        <?= select_field('reason', 'Reason', $reasonOptions, $filter['reason']) ?>
        <?= select_field('month', 'Month', $monthOptions, $filter['month']) ?>
        <button type="submit" class="btn btn-ghost">Show</button>
    </form>

    <?php if ($filter['component'] !== null): ?>
        <p class="part-filter" data-log-part>
            <span>Showing <?= $part !== null ? '“' . e($part['name']) . '”' : 'one part' ?> only.</span>
            <a class="btn btn-ghost btn-sm" href="<?= e(url('admin/inventory.php?' . http_build_query(array_filter(['category' => $filter['category'], 'reason' => $filter['reason'], 'month' => $filter['month']])))) ?>">Show every part</a>
        </p>
    <?php endif; ?>

    <div class="figures movement-figures" data-movement-totals>
        <div class="figure"><span class="figure-label">Received</span><span class="figure-number" data-total="received"><?= $totals['received'] > 0 ? e(change_text($totals['received'])) : '0' ?></span></div>
        <div class="figure"><span class="figure-label">Sold</span><span class="figure-number" data-total="sold"><?= $totals['sold'] < 0 ? e(change_text($totals['sold'])) : '0' ?></span></div>
        <div class="figure"><span class="figure-label">Corrections</span><span class="figure-number" data-total="corrected"><?= $totals['corrected'] !== 0 ? e(change_text($totals['corrected'])) : '0' ?></span></div>
        <div class="figure"><span class="figure-label">Movements</span><span class="figure-number" data-total="rows"><?= number_format($totals['n']) ?></span></div>
    </div>

    <?php if ($rows === []): ?>
        <p class="muted" data-no-movements>No stock movement matches these filters.</p>
    <?php else: ?>
        <?php if ($totals['n'] > count($rows)): ?>
            <p class="muted" data-log-cut>Showing the latest <?= count($rows) ?> of <?= number_format($totals['n']) ?>. Choose a month or a category to see the rest.</p>
        <?php endif; ?>
        <?php render_movements($rows, 'movement-log'); ?>
    <?php endif; ?>
</div>
<?php
render_footer();
