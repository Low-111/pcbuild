<?php
/*
 * The administrator's dashboard (section 9.5; FR10.1 to FR10.5), the first
 * page an administrator sees. It answers what needs attention today: six
 * figures, the parts running short, the orders waiting for review, and the
 * data check, which compares each part's reserved quantity with what pending
 * orders actually hold and must always find nothing.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

$figures = dashboard_figures();
$short = low_stock();
$waiting = all_orders('pending');
$mismatches = reservation_mismatches();
$unledgered = ledger_mismatches();

// Each figure, and where it leads: the page that lists what it counts, if there is one.
$tiles = [
    ['components', 'Active components',     'admin/components.php'],
    ['customers',  'Registered customers',  'admin/customers.php'],
    ['pending',    'Awaiting review',       'admin/orders.php?status=pending'],
    ['approved',   'Approved this month',   'admin/sales.php'],
    ['builds',     'Saved configurations',  null],
    ['unanswered', 'Unanswered quotations', 'admin/quotations.php?status=new'],
];

render_header('Dashboard', 'dashboard');
?>
<div class="container page">
    <div class="page-head">
        <h1 class="page-title">Dashboard</h1>
        <p class="page-lead">What needs attention today.</p>
    </div>

    <div class="figures" data-figures>
        <?php foreach ($tiles as [$key, $label, $page]): ?>
            <?php $tag = $page !== null ? 'a' : 'div'; ?>
            <<?= $tag ?> class="figure<?= $page !== null ? ' figure-link' : '' ?>" data-figure="<?= e($key) ?>"<?= $page !== null ? ' href="' . e(url($page)) . '"' : '' ?>>
                <span class="figure-number"><?= (int) $figures[$key] ?></span>
                <span class="figure-label"><?= e($label) ?></span>
            </<?= $tag ?>>
        <?php endforeach; ?>
    </div>

    <div class="dashboard-panels">
        <section class="panel" aria-labelledby="low-title" data-low-stock>
            <h2 class="section-title" id="low-title">Low stock: fewer than <?= LOW_STOCK_BELOW ?> available</h2>
            <?php if ($short === []): ?>
                <p class="muted">Every part on sale has at least <?= LOW_STOCK_BELOW ?> available.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="data-table" id="low-stock">
                        <thead>
                            <tr>
                                <th scope="col">Component</th>
                                <th scope="col">Category</th>
                                <th scope="col" class="num">Stock</th>
                                <th scope="col" class="num">Reserved</th>
                                <th scope="col" class="num">Available</th>
                                <th scope="col"><span class="sr-only">Actions</span></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($short as $part): ?>
                                <tr data-component="<?= (int) $part['component_id'] ?>">
                                    <td><a href="<?= e(url('admin/component-form.php?id=' . (int) $part['component_id'])) ?>"><?= e($part['name']) ?></a></td>
                                    <td><?= e($part['category_name']) ?></td>
                                    <td class="num"><?= (int) $part['stock_qty'] ?></td>
                                    <td class="num"><?= (int) $part['reserved_qty'] ?></td>
                                    <td class="num"><strong><?= (int) $part['available'] ?></strong></td>
                                    <td class="actions"><?= add_stock_button($part, 'dashboard') ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>

        <section class="panel" aria-labelledby="waiting-title" data-waiting-orders>
            <h2 class="section-title" id="waiting-title">Orders awaiting review</h2>
            <?php if ($waiting === []): ?>
                <p class="muted">No order is waiting for review.</p>
            <?php else: ?>
                <div class="table-wrap">
                    <table class="data-table" id="waiting-orders">
                        <thead>
                            <tr>
                                <th scope="col">Order</th>
                                <th scope="col">Customer</th>
                                <th scope="col" class="num">Total</th>
                                <th scope="col">Placed</th>
                                <th scope="col"><span class="sr-only">Actions</span></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($waiting as $order): ?>
                                <?php $id = (int) $order['order_id']; ?>
                                <tr data-order="<?= $id ?>">
                                    <td class="cell-order"><a href="<?= e(url('admin/order.php?id=' . $id)) ?>"><strong><?= e(order_ref($id)) ?></strong></a></td>
                                    <td><?= e($order['username']) ?></td>
                                    <td class="num"><?= e(money($order['total_price'])) ?></td>
                                    <td><?= when_html((string) $order['created_at']) ?></td>
                                    <td class="actions"><a class="btn btn-primary btn-sm" href="<?= e(url('admin/order.php?id=' . $id)) ?>">Review</a></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>
    </div>

    <section class="panel consistency<?= $mismatches === [] ? '' : ' consistency-fault' ?>" aria-labelledby="check-title" data-consistency>
        <h2 class="section-title" id="check-title">Data consistency</h2>
        <?php if ($mismatches === []): ?>
            <p class="consistency-ok" data-consistent>✓ Every reserved quantity matches the quantity reserved by pending orders.</p>
        <?php else: ?>
            <p class="consistency-bad" role="alert">
                <?= count($mismatches) === 1 ? '1 part has' : count($mismatches) . ' parts have' ?> a reserved quantity that pending orders do not account for.
                It was changed outside the system, in phpMyAdmin for instance. Set it to the quantity held by pending orders:
                until then, approving, rejecting or cancelling an order that holds the part may be refused, and so may new orders for it.
            </p>
            <div class="table-wrap">
                <table class="data-table" id="mismatches">
                    <thead>
                        <tr>
                            <th scope="col">Component</th>
                            <th scope="col">Category</th>
                            <th scope="col" class="num">Reserved, as recorded</th>
                            <th scope="col" class="num">Held by pending orders</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($mismatches as $part): ?>
                            <tr data-component="<?= (int) $part['component_id'] ?>">
                                <td><?= e($part['name']) ?></td>
                                <td><?= e($part['category_name']) ?></td>
                                <td class="num"><?= (int) $part['reserved_qty'] ?></td>
                                <td class="num"><?= (int) $part['actual_reserved'] ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </section>

    <section class="panel consistency<?= $unledgered === [] ? '' : ' consistency-fault' ?>" aria-labelledby="ledger-title" data-ledger-check>
        <h2 class="section-title" id="ledger-title">Stock check</h2>
        <?php if ($unledgered === []): ?>
            <p class="consistency-ok" data-ledger-ok>✓ Every part's stock matches its history in the <a href="<?= e(url('admin/inventory.php')) ?>">Inventory log</a>.</p>
        <?php else: ?>
            <p class="consistency-bad" role="alert">
                <?= count($unledgered) === 1 ? '1 part has' : count($unledgered) . ' parts have' ?> a stock figure its history does not account for.
                It was changed outside the system, in phpMyAdmin for instance. Open the part and type the counted figure into Stock:
                the change is then recorded as a correction, and the history accounts for it again.
            </p>
            <div class="table-wrap">
                <table class="data-table" id="ledger-mismatches">
                    <thead>
                        <tr>
                            <th scope="col">Component</th>
                            <th scope="col">Category</th>
                            <th scope="col" class="num">Stock, as recorded</th>
                            <th scope="col" class="num">By its history</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($unledgered as $part): ?>
                            <tr data-component="<?= (int) $part['component_id'] ?>">
                                <td><a href="<?= e(url('admin/component-form.php?id=' . (int) $part['component_id'])) ?>"><?= e($part['name']) ?></a></td>
                                <td><?= e($part['category_name']) ?></td>
                                <td class="num"><?= (int) $part['stock_qty'] ?></td>
                                <td class="num"><?= (int) ($part['ledger'] ?? 0) ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </section>
    <?php render_add_stock_dialog('dashboard'); ?>
</div>
<?php
render_footer(['inventory.js']);
