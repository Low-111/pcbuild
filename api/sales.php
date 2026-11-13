<?php
/*
 * The sales report for one period, for the Sales page's script: the numbers
 * the charts are drawn from, and the parts of the page that change with the
 * period, rendered as the page renders them (includes/sales.php).
 *
 *   GET api/sales.php?month=2026-11      (or month=all)
 *
 * Administrators only: 401 to a visitor, 403 to a customer. Nothing is saved.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin_json();

send_json(sales_payload(sales_report(sales_period($_GET['month'] ?? null))));
