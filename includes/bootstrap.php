<?php
/*
 * The first thing every page loads. It pulls in the shared code, works out
 * which URL the application is served from, and starts the session.
 */

declare(strict_types=1);

// Hold the page back until it is finished, so that a redirect can still be
// sent late and a failure halfway through replaces the page instead of
// appearing in the middle of it.
ob_start();

// Treat every warning as an error. A mistake then stops the page where it
// happened instead of carrying on with a wrong value. Set before the shared
// code is loaded, so that a warning while loading it (a constant declared
// twice, for instance) stops the page too, rather than being printed above
// it where errors are shown, as XAMPP shows them, or passing unseen where
// they are not (finding 6 of step 6).
set_error_handler(function (int $severity, string $message, string $file, int $line): bool {
    if (!(error_reporting() & $severity)) {
        return false;
    }
    throw new ErrorException($message, 0, $severity, $file, $line);
});

require __DIR__ . '/config.php';
require __DIR__ . '/helpers.php';
require __DIR__ . '/db.php';
require __DIR__ . '/session.php';
require __DIR__ . '/auth.php';
require __DIR__ . '/forms.php';
require __DIR__ . '/icons.php';
require __DIR__ . '/catalogue.php';
require __DIR__ . '/rules.php';
require __DIR__ . '/builds.php';
require __DIR__ . '/orders.php';
require __DIR__ . '/requests.php';
require __DIR__ . '/dashboard.php';
require __DIR__ . '/sales.php';
require __DIR__ . '/inventory.php';
require __DIR__ . '/layout.php';

set_exception_handler('render_failure');

define('BASE_URL', base_url());

start_session();
