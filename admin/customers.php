<?php
/*
 * Customers (3 November 2026): everyone registered, the latest first, with
 * what each has saved and ordered, searchable by name or email. A customer
 * who has forgotten their password gets a new one here, without phpMyAdmin:
 * Reset password, asked first, sets a temporary password, shown once on the
 * next page for the shop to hand over; the customer changes it under My
 * account. Only a hash is stored, so nobody, the administrator included, can
 * read a password back.
 *
 * Administrators are not listed: each changes their own under My account.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_admin();

if (is_post()) {
    csrf_verify();
    $id = (int) (ctype_digit(posted('id')) ? posted('id') : 0);
    if (posted('action') !== 'reset') {
        flash('error', 'That action is not one this page can do.');
        redirect('admin/customers.php');
    }
    $stmt = db()->prepare("SELECT username FROM `user` WHERE user_id = ? AND role = 'customer'");
    $stmt->execute([$id]);
    $name = $stmt->fetchColumn();
    if ($name === false) {
        flash('error', 'That customer could not be found.');
        redirect('admin/customers.php');
    }
    $password = temporary_password();
    db()->prepare("UPDATE `user` SET password_hash = ? WHERE user_id = ? AND role = 'customer'")->execute([hash_password($password), $id]);
    // Shown once, on the page this redirect leads to, and then forgotten.
    $_SESSION['reset_password'] = ['user_id' => $id, 'username' => (string) $name, 'password' => $password];
    redirect('admin/customers.php');
}

$reset = $_SESSION['reset_password'] ?? null;
unset($_SESSION['reset_password']);

$search = is_string($_GET['q'] ?? null) ? trim($_GET['q']) : '';
$sql = "SELECT u.user_id, u.username, u.email, u.created_at,
               (SELECT COUNT(*) FROM build b WHERE b.user_id = u.user_id) AS builds,
               (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.user_id) AS orders,
               (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.user_id AND o.status = 'approved') AS approved
        FROM `user` u
        WHERE u.role = 'customer'" . ($search !== '' ? " AND (u.username LIKE ? ESCAPE '!' OR u.email LIKE ? ESCAPE '!')" : '') . '
        ORDER BY u.created_at DESC, u.user_id DESC';
$stmt = db()->prepare($sql);
// % and _ typed in the search are looked for as themselves, on MySQL and on SQLite alike.
$like = '%' . strtr($search, ['!' => '!!', '%' => '!%', '_' => '!_']) . '%';
$stmt->execute($search !== '' ? [$like, $like] : []);
$customers = $stmt->fetchAll();
$total = (int) db()->query("SELECT COUNT(*) FROM `user` WHERE role = 'customer'")->fetchColumn();

render_header('Customers', 'customers');
?>
<div class="container page">
    <a class="back-link" href="<?= e(url('admin/dashboard.php')) ?>">← Dashboard</a>
    <div class="page-head">
        <h1 class="page-title">Customers</h1>
        <p class="page-lead"><?= $total ?> registered. A customer who forgot their password gets a temporary one here, and changes it under My account.</p>
    </div>

    <?php if ($reset !== null): ?>
        <div class="flash flash-success reset-shown" role="status" data-reset-shown>
            <strong>The password of <?= e($reset['username']) ?> was reset.</strong>
            Their temporary password is <code class="temporary" data-temporary><?= e($reset['password']) ?></code>.
            Give it to them; it is shown only this once. They log in with it and change it under My account.
        </div>
    <?php endif; ?>

    <form class="filter-bar" method="get" action="<?= e(url('admin/customers.php')) ?>" role="search">
        <?= input_field('q', 'Name or email', ['type' => 'search', 'maxlength' => 100], $search, '', '', ['class' => 'field-grow']) ?>
        <button type="submit" class="btn btn-ghost">Search</button>
    </form>

    <?php if ($customers === []): ?>
        <p class="muted" data-no-customers><?= $search !== '' ? 'No customer matches “' . e($search) . '”.' : 'Nobody has registered yet.' ?></p>
    <?php else: ?>
        <div class="table-wrap">
            <table class="data-table" id="customer-list">
                <thead>
                    <tr>
                        <th scope="col">Customer</th>
                        <th scope="col">Registered</th>
                        <th scope="col" class="num">Configurations</th>
                        <th scope="col" class="num">Orders</th>
                        <th scope="col" class="num">Approved</th>
                        <th scope="col"><span class="sr-only">Actions</span></th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($customers as $customer): ?>
                        <?php $id = (int) $customer['user_id']; ?>
                        <tr data-customer="<?= $id ?>">
                            <td><strong><?= e($customer['username']) ?></strong><br><span class="muted"><?= e($customer['email']) ?></span></td>
                            <td><?= when_html((string) $customer['created_at']) ?></td>
                            <td class="num"><?= (int) $customer['builds'] ?></td>
                            <td class="num"><?= (int) $customer['orders'] ?></td>
                            <td class="num"><?= (int) $customer['approved'] ?></td>
                            <td class="actions">
                                <form method="post" action="<?= e(url('admin/customers.php')) ?>"
                                      data-confirm="<?= e('Their current password stops working at once. You will see the new one on the next page, once, to give to them.') ?>"
                                      data-confirm-title="<?= e('Reset the password of ' . $customer['username'] . '?') ?>"
                                      data-confirm-button="Reset password">
                                    <?= csrf_field() ?>
                                    <input type="hidden" name="action" value="reset">
                                    <input type="hidden" name="id" value="<?= $id ?>">
                                    <button type="submit" class="btn btn-ghost btn-sm" data-reset>Reset password</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</div>
<?php
render_footer(['confirm.js']);
