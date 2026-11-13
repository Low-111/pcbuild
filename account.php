<?php
/*
 * My account (3 November 2026): anyone logged in changes their own password
 * here, the administrator included, without phpMyAdmin. The current password
 * is asked first, so a browser left logged in cannot have its owner locked
 * out. The new one is checked as registration checks it, stored as a bcrypt
 * hash, and the session starts afresh.
 *
 * Reached from the name in the header. A customer who was given a temporary
 * password by the shop (admin/customers.php) changes it here.
 */

declare(strict_types=1);

require __DIR__ . '/includes/bootstrap.php';

$user = require_login();
$errors = [];

if (is_post()) {
    csrf_verify();
    $current = posted('current_password', false);
    $password = posted('password', false);
    $confirm = posted('password_confirm', false);

    $stmt = db()->prepare('SELECT password_hash FROM `user` WHERE user_id = ?');
    $stmt->execute([(int) $user['user_id']]);
    $hash = (string) $stmt->fetchColumn();

    if ($current === '') {
        $errors['current_password'] = 'Enter your current password.';
    } elseif (!password_verify($current, $hash)) {
        $errors['current_password'] = 'That is not your current password.';
    }
    $errors += new_password_problems($password, $confirm);
    if (!isset($errors['password']) && $errors === [] && password_verify($password, $hash)) {
        $errors['password'] = 'Choose a password different from the current one.';
    }

    if ($errors === []) {
        db()->prepare('UPDATE `user` SET password_hash = ? WHERE user_id = ?')->execute([hash_password($password), (int) $user['user_id']]);
        session_regenerate_id(true);          // a new session id, as at login: the old one is worthless now
        flash('success', 'Your password was changed. Use the new one next time you log in.');
        redirect('account.php');
    }
}

render_header('My account', 'account');
?>
<div class="container page narrow-page">
    <div class="page-head">
        <h1 class="page-title">My account</h1>
        <p class="page-lead"><?= e($user['username']) ?> · <?= e($user['email']) ?> · <?= $user['role'] === 'admin' ? 'Administrator' : 'Customer' ?></p>
    </div>

    <form class="form-panel" method="post" action="<?= e(url('account.php')) ?>" data-validate data-password-form>
        <?= csrf_field() ?>
        <h2 class="section-title">Change your password</h2>
        <?= input_field('current_password', 'Current password', [
            'type' => 'password', 'required' => true, 'autocomplete' => 'current-password',
            'data-error-required' => 'Enter your current password.',
        ], '', $errors['current_password'] ?? '') ?>
        <?= input_field('password', 'New password', [
            'type' => 'password', 'required' => true, 'minlength' => PASSWORD_MIN_LENGTH, 'maxlength' => PASSWORD_MAX_BYTES,
            'autocomplete' => 'new-password',
            'data-error-required' => 'Choose a password.',
            'data-error-minlength' => 'Use at least ' . PASSWORD_MIN_LENGTH . ' characters.',
        ], '', $errors['password'] ?? '', 'At least ' . PASSWORD_MIN_LENGTH . ' characters.') ?>
        <?= input_field('password_confirm', 'Confirm new password', [
            'type' => 'password', 'required' => true, 'autocomplete' => 'new-password', 'data-match' => 'password',
            'data-error-required' => 'Type the new password again.',
            'data-error-match' => 'The two passwords do not match.',
        ], '', $errors['password_confirm'] ?? '') ?>
        <div class="form-actions">
            <button type="submit" class="btn btn-primary">Change password</button>
        </div>
    </form>
</div>
<?php
render_footer();
