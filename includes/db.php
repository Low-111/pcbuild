<?php
/*
 * The database connection. One connection per request, opened the first time
 * it is needed.
 */

declare(strict_types=1);

function db(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $pdo = new PDO(DB_DSN, DB_USER, DB_PASS, [
            // A failed statement throws instead of returning false quietly.
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            // Real prepared statements: the query and its values travel to
            // MySQL separately, so a value can never change the query.
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
        // SQLite (supported as an alternative database) ignores foreign keys unless each
        // connection asks for them. Without this, deleting a configuration there
        // would leave its parts behind instead of removing them as MySQL does.
        if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite') {
            $pdo->exec('PRAGMA foreign_keys = ON');
        }
    }

    return $pdo;
}

/**
 * " FOR UPDATE", to end a SELECT whose rows are about to be checked and then
 * changed: MySQL locks them until the transaction ends, so another request
 * waits instead of acting on the same figures. SQLite
 * has no such clause; it lets only one transaction write at a time anyway.
 */
function for_update(): string
{
    return db()->getAttribute(PDO::ATTR_DRIVER_NAME) === 'sqlite' ? '' : ' FOR UPDATE';
}

/** True when an INSERT or UPDATE failed because it would repeat a UNIQUE value. */
function is_duplicate_key(PDOException $e): bool
{
    return ($e->errorInfo[1] ?? null) === 1062;
}
