<?php
/*
 * Who is logged in, and which pages they may reach.
 *
 * The session holds only the user's id. Their name and role are read from
 * the database on every request, so an account that is removed or has its
 * role changed takes effect at once rather than at the next login.
 */

declare(strict_types=1);

function current_user(): ?array
{
    static $user = false;                  // false: not looked up yet in this request

    if ($user === false) {
        $user = null;
        if (isset($_SESSION['user_id'])) {
            $stmt = db()->prepare('SELECT user_id, username, email, role FROM `user` WHERE user_id = ?');
            $stmt->execute([$_SESSION['user_id']]);
            $user = $stmt->fetch() ?: null;
            if ($user === null) {
                unset($_SESSION['user_id']);   // the account no longer exists
            }
        }
    }

    return $user;
}

function hash_password(string $password): string
{
    return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
}

/**
 * What is wrong with a new password and its confirmation, as registration
 * judges them: [field => message], empty if nothing.
 */
function new_password_problems(string $password, string $confirm): array
{
    if ($password === '') {
        return ['password' => 'Choose a password.'];
    }
    if (mb_strlen($password) < PASSWORD_MIN_LENGTH) {
        return ['password' => 'Use at least ' . PASSWORD_MIN_LENGTH . ' characters.'];
    }
    if (strlen($password) > PASSWORD_MAX_BYTES) {
        return ['password' => 'Use no more than ' . PASSWORD_MAX_BYTES . ' characters.'];
    }
    return $confirm !== $password ? ['password_confirm' => 'The two passwords do not match.'] : [];
}

/**
 * A password the administrator hands to a customer after resetting theirs: 12
 * characters in three groups, from letters and digits that cannot be mistaken
 * for one another (no 0 and O, 1, l and I), drawn by random_int().
 */
function temporary_password(): string
{
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    $groups = [];
    for ($g = 0; $g < 3; $g++) {
        $group = '';
        for ($i = 0; $i < 4; $i++) {
            $group .= $alphabet[random_int(0, strlen($alphabet) - 1)];
        }
        $groups[] = $group;
    }
    return implode('-', $groups);
}

/** Opens the session for a user whose password has just been checked. */
function log_in(int $userId): void
{
    // A new session id, so any id someone managed to plant in this browser
    // before the login is worthless afterwards, and a new form token with it.
    session_regenerate_id(true);
    unset($_SESSION['csrf_token']);
    $_SESSION['user_id'] = $userId;
}

function log_out(): void
{
    $_SESSION = [];
    session_regenerate_id(true);
}

/** Where each kind of user starts: the page they are sent to after logging in. */
function home_for(?array $user): string
{
    if ($user === null) {
        return 'index.php';
    }
    return $user['role'] === 'admin' ? 'admin/dashboard.php' : 'catalogue.php';
}


/* ---------------------------------------------------------------------------
 * Page guards. A page calls one of these before doing anything else.
 * ------------------------------------------------------------------------- */

/** Any logged-in user. A visitor is sent to the login page and returned afterwards. */
function require_login(): array
{
    $user = current_user();
    if ($user === null) {
        if (!is_post()) {
            $_SESSION['after_login'] = (string) ($_SERVER['REQUEST_URI'] ?? '');
        }
        flash('info', 'Please log in to continue.');
        redirect('login.php');
    }
    return $user;
}

/** Administrators only (FR1.6). Anyone else goes back to their own home page. */
function require_admin(): array
{
    return require_role('admin', 'That page is for administrators only.');
}

/** Customers only. An administrator does not build or order machines. */
function require_customer(): array
{
    return require_role('customer', 'That page is for customers only.');
}

function require_role(string $role, string $refusal): array
{
    $user = require_login();
    if ($user['role'] !== $role) {
        flash('error', $refusal);
        redirect(home_for($user));
    }
    return $user;
}

/**
 * The guard for a script's request rather than a page: a visitor gets a JSON
 * refusal with status 401, because a redirect to the login page would reach
 * the script as HTML it cannot read.
 */
function require_login_json(): array
{
    $user = current_user();
    if ($user === null) {
        send_json(['error' => 'Please log in to continue.'], 401);
    }
    return $user;
}

/** The same for an administrator's script: 401 to a visitor, 403 to a customer. */
function require_admin_json(): array
{
    $user = require_login_json();
    if ($user['role'] !== 'admin') {
        send_json(['error' => 'That is for administrators only.'], 403);
    }
    return $user;
}

/** Login and registration are for visitors; a logged-in user is sent home. */
function require_visitor(): void
{
    $user = current_user();
    if ($user !== null) {
        redirect(home_for($user));
    }
}

/**
 * The page a visitor was trying to reach when they were asked to log in,
 * taken once. Only a path inside this application is accepted, so the value
 * can never send anyone to another website.
 */
function take_page_after_login(): ?string
{
    $target = $_SESSION['after_login'] ?? '';
    unset($_SESSION['after_login']);

    $inside = is_string($target)
        && str_starts_with($target, BASE_URL . '/')
        && !str_starts_with($target, '//');

    return $inside ? $target : null;
}
