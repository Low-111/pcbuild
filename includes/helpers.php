<?php
/*
 * Small functions used on almost every page.
 */

declare(strict_types=1);

/**
 * Makes a value safe to place inside HTML. Everything that came from a user
 * or from the database goes through this before it is printed, so a name
 * holding "<script>" is shown as text instead of being run.
 */
function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/**
 * The URL path the application is served from, without a trailing slash:
 * "" at the root of the web server, "/pcbuild" inside htdocs/pcbuild. Worked
 * out from the running script, so the folder can be given any name.
 */
function base_url(): string
{
    $root   = str_replace('\\', '/', (string) realpath(__DIR__ . '/..'));
    $script = str_replace('\\', '/', (string) realpath($_SERVER['SCRIPT_FILENAME'] ?? ''));
    if ($root === '' || !str_starts_with($script, $root . '/')) {
        return '';
    }
    $relative = substr($script, strlen($root));        // "/admin/dashboard.php"
    $path     = (string) ($_SERVER['SCRIPT_NAME'] ?? '');
    $length   = strlen($path) - strlen($relative);
    return $length > 0 ? rtrim(substr($path, 0, $length), '/') : '';
}

/** A link to a page of this application, e.g. url('admin/dashboard.php'). */
function url(string $path = ''): string
{
    return BASE_URL . '/' . ltrim($path, '/');
}

/**
 * A link to a stylesheet or script, carrying the file's modification time so
 * that a browser never keeps showing yesterday's copy after it changes.
 */
function asset(string $path): string
{
    $file = __DIR__ . '/../assets/' . $path;
    $version = is_file($file) ? (string) filemtime($file) : '0';
    return url('assets/' . $path) . '?v=' . $version;
}

/** Sends the browser to another page of this application and stops. */
function redirect(string $path): never
{
    header('Location: ' . url($path));
    exit;
}

/** A price as the shop shows it: RM 3,048.21. */
function money(mixed $amount): string
{
    return 'RM ' . number_format((float) $amount, 2);
}

/**
 * Ends the request with a JSON answer, for a script on a page rather than a
 * page itself. Anything held back in the page buffer is dropped first.
 */
function send_json(array $data, int $status = 200): never
{
    while (ob_get_level() > 0) {
        ob_end_clean();
    }
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    exit;
}

function is_post(): bool
{
    return ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST';
}

/**
 * A posted text field. Trimmed, unless $trim is false, as it must be for a
 * password, where a space is part of the secret. Anything that is not a plain
 * string, such as an array smuggled in as name[]=, reads as empty.
 */
function posted(string $name, bool $trim = true): string
{
    $value = $_POST[$name] ?? '';
    if (!is_string($value)) {
        return '';
    }
    return $trim ? trim($value) : $value;
}
