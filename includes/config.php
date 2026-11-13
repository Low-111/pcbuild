<?php
/*
 * Settings. On a standard XAMPP install nothing here needs editing.
 *
 * The database settings can each be overridden by an environment variable of
 * the same name. That is how the development server is pointed at a database
 * listening on a socket instead of on localhost, without editing this file.
 */

declare(strict_types=1);

function env(string $name, string $default): string
{
    $value = getenv($name);
    return $value === false ? $default : $value;
}

define('DB_DSN',  env('DB_DSN',  'mysql:host=localhost;dbname=pc_build_configurator;charset=utf8mb4'));
define('DB_USER', env('DB_USER', 'root'));
define('DB_PASS', env('DB_PASS', ''));

// Error details are shown only to a browser on this same machine, so a copy
// put on the internet never prints its internals to a visitor.
define('APP_DEBUG', in_array($_SERVER['REMOTE_ADDR'] ?? '', ['127.0.0.1', '::1'], true));

// Passwords. bcrypt reads only the first 72 bytes of a password, so anything
// longer is refused rather than silently cut short.
define('PASSWORD_MIN_LENGTH', 8);
define('PASSWORD_MAX_BYTES', 72);

// The shop, as shown in the footer of every page.
define('SHOP_NAME',    'PC Build Configurator');
define('SHOP_ADDRESS', 'Penang, Malaysia');
define('SHOP_PHONE',   '+60 4-000 0000');
define('SHOP_HOURS',   'Monday to Saturday, 10am to 8pm');
