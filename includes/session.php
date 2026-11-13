<?php
/*
 * The session, and the two things kept in it besides the logged-in user:
 * the form token and the one-time messages shown after an action.
 */

declare(strict_types=1);

function start_session(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }

    // Refuse a session id the server did not issue itself, so an attacker
    // cannot hand a victim a session id of their own choosing.
    ini_set('session.use_strict_mode', '1');

    session_name('pcbuild_session');
    session_set_cookie_params([
        'lifetime' => 0,                                     // until the browser closes
        'path'     => BASE_URL . '/',                        // this application only
        'httponly' => true,                                  // not readable by JavaScript
        'secure'   => is_https(),
        'samesite' => 'Lax',                                 // not sent with another site's forms
    ]);
    session_start();
}

function is_https(): bool
{
    return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (int) ($_SERVER['SERVER_PORT'] ?? 0) === 443;
}


/* ---------------------------------------------------------------------------
 * Form token
 *
 * Every form carries a random token that is also kept in the session. A form
 * built by another website cannot know it, so a request that arrives without
 * the right token did not come from one of our own pages and is refused.
 * ------------------------------------------------------------------------- */

function csrf_token(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/** The hidden field every form must include. */
function csrf_field(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrf_token()) . '">';
}

/**
 * Called first thing when a form arrives. A missing or wrong token most often
 * means the session ran out while the form sat open, so the answer is a
 * polite message and a fresh copy of the page, not an error screen.
 */
function csrf_verify(): void
{
    $sent = $_POST['csrf_token'] ?? '';
    if (is_string($sent) && hash_equals(csrf_token(), $sent)) {
        return;
    }
    flash('error', 'This form had expired, so nothing was changed. Please try again.');

    // Back to the same page, fetched afresh. Built from the script's own path
    // with its leading slashes collapsed, so it can only ever point at this site.
    $self  = '/' . ltrim((string) ($_SERVER['SCRIPT_NAME'] ?? ''), '/');
    $query = (string) ($_SERVER['QUERY_STRING'] ?? '');
    header('Location: ' . $self . ($query === '' ? '' : '?' . $query), true, 303);
    exit;
}


/* ---------------------------------------------------------------------------
 * One-time messages
 *
 * An action stores a message, redirects, and the next page shows it once.
 * ------------------------------------------------------------------------- */

/** $type is 'success', 'error' or 'info'. */
function flash(string $type, string $message): void
{
    $_SESSION['flash'][] = ['type' => $type, 'message' => $message];
}

/** The waiting messages, removed from the session as they are read. */
function take_flashes(): array
{
    $messages = $_SESSION['flash'] ?? [];
    unset($_SESSION['flash']);
    return $messages;
}
