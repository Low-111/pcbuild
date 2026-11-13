<?php
/*
 * The sales report (asked for by the lecturer, 2 Nov): what the shop sold in
 * one month, or in all time, for the administrator only. A sale is an approved
 * order, counted in the month it was approved, at the prices it was placed at
 * (includes/sales.php).
 *
 * The page works whole without JavaScript: the filter is an ordinary form, and
 * every number is in a table. With it, sales.js draws the two charts from the
 * numbers below, and choosing a month (in the filter or by clicking its bar)
 * asks api/sales.php for that month and swaps it in without loading the page.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

$period = sales_period($_GET['month'] ?? null);
$report = sales_report($period);
$payload = sales_payload($report);

render_header('Sales', 'sales');
?>
<div class="container page" data-sales>
    <div class="page-head">
        <h1 class="page-title">Sales</h1>
        <p class="page-lead">Approved orders, at the prices they were placed at, counted in the month they were approved.</p>
    </div>

    <form class="filter-bar sales-filter" method="get" action="<?= e(url('admin/sales.php')) ?>" data-sales-filter>
        <?= select_field('month', 'Period', period_options($period), $period) ?>
        <button type="submit" class="btn btn-ghost">Show</button>
    </form>

    <h2 class="sales-period" data-period-label aria-live="polite"><?= e($report['heading']) ?></h2>

    <div class="figures sales-figures" data-sales-figures>
        <?= $payload['html']['figures'] ?>
    </div>

    <section class="panel chart-panel" aria-labelledby="months-title">
        <div class="chart-head">
            <div>
                <h2 class="section-title" id="months-title">The last <?= SALES_MONTHS_SHOWN ?> months</h2>
                <p class="muted chart-hint" data-js-only hidden>Point at a month for its figures; click it to show that month.</p>
            </div>
            <div class="measure-switch" role="group" aria-label="Show on the chart" data-js-only hidden>
                <?php foreach (SALES_MEASURES as $key => $label): ?>
                    <button type="button" class="measure" data-measure="<?= e($key) ?>" aria-pressed="<?= $key === 'revenue' ? 'true' : 'false' ?>"><?= e($label) ?></button>
                <?php endforeach; ?>
            </div>
        </div>
        <div class="chart" id="month-chart" data-month-chart></div>
        <details class="chart-numbers" data-numbers open>
            <summary>The numbers</summary>
            <div class="table-wrap">
                <table class="data-table" id="month-table">
                    <thead>
                        <tr>
                            <th scope="col">Month</th>
                            <th scope="col" class="num">Orders</th>
                            <th scope="col" class="num">Parts sold</th>
                            <th scope="col" class="num">Revenue</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($report['months'] as $month): ?>
                            <tr data-month="<?= e($month['month']) ?>">
                                <td><a href="<?= e(url('admin/sales.php?month=' . $month['month'])) ?>"><?= e($month['label']) ?></a></td>
                                <td class="num"><?= (int) $month['orders'] ?></td>
                                <td class="num"><?= (int) $month['units'] ?></td>
                                <td class="num"><?= e(money_cents($month['revenue'])) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </details>
    </section>

    <section class="panel chart-panel" aria-labelledby="categories-title">
        <div class="chart-head">
            <div>
                <h2 class="section-title" id="categories-title">By category</h2>
                <p class="muted chart-hint" data-js-only hidden>Click a category to list only its parts below.</p>
            </div>
        </div>
        <div class="category-chart" id="category-chart" data-category-chart></div>
        <details class="chart-numbers" data-numbers open>
            <summary>The numbers</summary>
            <div class="table-wrap" data-sales-categories>
                <?= $payload['html']['categories'] ?>
            </div>
        </details>
    </section>

    <section class="panel" aria-labelledby="parts-title">
        <div class="chart-head">
            <h2 class="section-title" id="parts-title">Parts sold</h2>
            <p class="part-filter" data-part-filter hidden>
                <span data-part-filter-text></span>
                <button type="button" class="btn btn-ghost btn-sm" data-show-all>Show every category</button>
            </p>
        </div>
        <div data-sales-parts>
            <?= $payload['html']['parts'] ?>
        </div>
    </section>

    <section class="panel" aria-labelledby="orders-title">
        <h2 class="section-title" id="orders-title">Approved orders</h2>
        <div data-sales-orders>
            <?= $payload['html']['orders'] ?>
        </div>
    </section>

    <script type="application/json" id="sales-data"><?= json_encode(
        array_diff_key($payload, ['html' => true]) + ['api' => url('api/sales.php'), 'page' => url('admin/sales.php')],
        JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR
    ) ?></script>
</div>
<?php
render_footer(['sales.js']);
