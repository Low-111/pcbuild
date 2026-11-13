<?php
/*
 * The administrator's dashboard (FR10.1 to FR10.5): what needs attention
 * today. The six figures, the parts running short, and the data check that
 * compares each part's reserved quantity with what pending orders actually
 * hold, which must always find nothing.
 */

declare(strict_types=1);

/**
 * The six figures at the top of the dashboard (FR10.1, FR10.3, FR10.4).
 * "This month" is read off the database's own clock (this_month(), in
 * sales.php), the one every time in the tables was written by, so the PHP
 * time zone cannot shift the boundary.
 */
function dashboard_figures(): array
{
    $count = static function (string $sql, array $values = []): int {
        $stmt = db()->prepare($sql);
        $stmt->execute($values);
        return (int) $stmt->fetchColumn();
    };
    $monthStart = this_month() . '-01 00:00:00';        // the same month the Sales page starts from
    return [
        'components' => $count('SELECT COUNT(*) FROM component WHERE is_active = 1'),
        'customers'  => $count("SELECT COUNT(*) FROM `user` WHERE role = 'customer'"),
        'pending'    => $count("SELECT COUNT(*) FROM orders WHERE status = 'pending'"),
        'approved'   => $count("SELECT COUNT(*) FROM orders WHERE status = 'approved' AND updated_at >= ?", [$monthStart]),
        'builds'     => $count('SELECT COUNT(*) FROM build'),
        'unanswered' => $count("SELECT COUNT(*) FROM quotation_request WHERE status = 'new'"),
    ];
}

/**
 * The parts on sale of which fewer than LOW_STOCK_BELOW can still be ordered
 * (FR10.2), the shortest first: the same threshold, set once in catalogue.php,
 * at which the catalogue calls a part low in stock. A part taken off sale is
 * left out: nobody restocks what the shop no longer sells.
 */
function low_stock(): array
{
    $stmt = db()->prepare(
        'SELECT c.component_id, c.name, c.stock_qty, c.reserved_qty, c.stock_qty - c.reserved_qty AS available, cat.category_name
         FROM component c
         JOIN category cat ON cat.category_id = c.category_id
         WHERE c.is_active = 1 AND c.stock_qty - c.reserved_qty < ?
         ORDER BY available, cat.display_order, c.name'
    );
    $stmt->execute([LOW_STOCK_BELOW]);
    return $stmt->fetchAll();
}

/**
 * The data check (FR10.5): every part whose reserved quantity differs from
 * the quantity its pending orders hold. applyStockTransition() keeps the two
 * equal, so this finds nothing unless a figure was changed by hand, in
 * phpMyAdmin for instance. It is the reconciliation query of the design, with
 * each part's name and category added so the panel can say which part.
 */
function reservation_mismatches(): array
{
    return db()->query(
        "SELECT c.component_id, c.name, cat.category_name, c.reserved_qty,
                COALESCE(SUM(CASE WHEN o.status = 'pending' THEN oi.quantity END), 0) AS actual_reserved
         FROM component c
         JOIN category cat ON cat.category_id = c.category_id
         LEFT JOIN order_item oi ON oi.component_id = c.component_id
         LEFT JOIN orders o ON o.order_id = oi.order_id
         GROUP BY c.component_id, c.name, cat.category_name, cat.display_order, c.reserved_qty
         HAVING c.reserved_qty <> actual_reserved
         ORDER BY cat.display_order, c.name"
    )->fetchAll();
}
