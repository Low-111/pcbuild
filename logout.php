<?php
/*
 * Log out (FR1.7). Accepts only a form sent from the menu, with its token.
 * A plain link would let any other website log a user out by embedding it,
 * so typing this address into the browser does nothing.
 */

declare(strict_types=1);

require __DIR__ . '/includes/bootstrap.php';

if (!is_post()) {
    redirect('index.php');
}

csrf_verify();
log_out();
flash('success', 'You have been logged out.');
redirect('index.php');
