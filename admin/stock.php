<?php
/*
 * Add stock: goods received for one part (3 November 2026). The quantity is
 * added to the stock, never typed over it, and recorded in the stock ledger
 * as "received" with an optional note (add_stock(), includes/inventory.php).
 *
 * The Add stock buttons on the components list, the dashboard and a part's
 * page open this form in a dialog (inventory.js); without a script they open
 * it here, as a page. Either way it is sent here, checked again, and the
 * administrator is taken back where they came from.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

$source = is_post() ? $_POST : $_GET;
$id = (int) (is_string($source['id'] ?? null) && ctype_digit($source['id']) ? $source['id'] : 0);
$back = is_string($source['back'] ?? null) ? $source['back'] : 'components';
$part = $id > 0 ? find_component($id) : null;
if ($part === null) {
    flash('error', 'That component no longer exists.');
    redirect('admin/components.php');
}

$quantity = '';
$note = '';
$errors = [];

if (is_post()) {
    csrf_verify();
    $quantity = posted('quantity');
    $note = posted('note');
    $errors = array_filter(['quantity' => quantity_problem($quantity), 'note' => note_problem($note)]);
    if ($errors === []) {
        try {
            [$name, $before, $after] = add_stock($id, (int) $quantity, $note);
            flash('success', 'Added ' . number_format((int) $quantity) . ' to “' . $name . '”: stock ' . $before . ' → ' . $after . '.');
            redirect(stock_back($back, $id));
        } catch (StockRefused $e) {
            $errors['quantity'] = $e->getMessage();
        }
    }
}

render_header('Add stock', 'components');
?>
<div class="container page narrow-page">
    <a class="back-link" href="<?= e(url(stock_back($back, $id))) ?>">← Back</a>
    <div class="page-head">
        <h1 class="page-title">Add stock</h1>
        <p class="page-lead"><?= e($part['name']) ?>: <?= (int) $part['stock_qty'] ?> in stock now. What arrives is added to it.</p>
    </div>
    <form class="form-panel" method="post" action="<?= e(url('admin/stock.php')) ?>" data-validate data-stock-page>
        <?= csrf_field() ?>
        <input type="hidden" name="id" value="<?= $id ?>">
        <input type="hidden" name="back" value="<?= e($back) ?>">
        <?= input_field('quantity', 'Quantity received', [
            'type' => 'number', 'required' => true, 'min' => 1, 'max' => MAX_STOCK, 'step' => 1, 'inputmode' => 'numeric',
            'data-error-required' => 'Enter how many arrived.',
            'data-error-type' => 'Enter a whole number, 1 or more.',
            'data-error-min' => 'Enter a whole number, 1 or more.',
            'data-error-max' => 'Enter a whole number, 1 or more.',
            'data-error-step' => 'Enter a whole number, 1 or more.',
        ], $quantity, $errors['quantity'] ?? '') ?>
        <?= input_field('note', 'Note (optional)', [
            'maxlength' => MOVEMENT_NOTE_MAX, 'placeholder' => 'Supplier, delivery number…',
            'data-error-maxlength' => 'Use no more than ' . MOVEMENT_NOTE_MAX . ' characters.',
        ], $note, $errors['note'] ?? '', 'Kept in the Inventory log beside the delivery.') ?>
        <div class="form-actions">
            <a class="btn btn-ghost" href="<?= e(url(stock_back($back, $id))) ?>">Cancel</a>
            <button type="submit" class="btn btn-primary">Add to stock</button>
        </div>
    </form>
</div>
<?php
render_footer();
