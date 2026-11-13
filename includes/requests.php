<?php
/*
 * Consultant requests (FR9.1 to FR9.6): the way out for a customer the
 * configurator cannot serve, or who wants something it does not sell: a
 * second set of parts already ordered, a part the shop does not list, advice.
 *
 * A request names one of the customer's saved configurations, or none, a
 * telephone number and a message. The consultant replies on the request,
 * which marks it answered (FR9.4), and the customer reads the reply under My
 * Requests (FR9.5). The consultant closes it once the conversation is over; a
 * customer may withdraw one that has not been answered yet.
 *
 *   new ──(reply)──→ answered ──(reply again)──→ answered
 *    │                  └──(close)──→ closed      [final]
 *    ├──(close)──→ closed
 *    └──(customer withdraws)──→ deleted
 *
 * A request is not an order. Nothing here reads or writes stock or
 * reservations (FR9.6), which keeps applyStockTransition() the one place
 * where stock moves.
 */

declare(strict_types=1);

/** The three statuses, as the pages name them. */
const REQUEST_STATUSES = [
    'new'      => 'New',
    'answered' => 'Answered',
    'closed'   => 'Closed',
];

/** The longest message, and the longest reply, accepted. */
const REQUEST_TEXT_MAX = 2000;

/** The longest telephone number the column holds. */
const PHONE_MAX = 20;

/**
 * A telephone number: 7 to 15 digits, with spaces, dashes and brackets
 * between them and a + in front allowed, as people write them. The same
 * pattern goes into the form's markup, so the brackets and the dash are
 * escaped as a browser's pattern attribute requires.
 */
const PHONE_PATTERN = '\+?(?:[ \-\(\)]*[0-9]){7,15}[ \-\(\)]*';

/** A request moved on, or not found, so nothing was changed. */
final class RequestRefused extends RuntimeException
{
}

/** How a request is referred to on every page: Q-0007, so that it is never taken for order #0007. */
function request_ref(int $requestId): string
{
    return 'Q-' . str_pad((string) $requestId, 4, '0', STR_PAD_LEFT);
}

/** A status as a labelled badge, coloured as an order's are: waiting, done well, finished. */
function request_status_badge(string $status): string
{
    return '<span class="status status-' . e($status) . '">' . e(REQUEST_STATUSES[$status] ?? $status) . '</span>';
}

/** What is wrong with a telephone number as given, or '' if nothing. */
function phone_problem(string $phone): string
{
    if ($phone === '') {
        return 'Give a number the consultant can call you on.';
    }
    if (mb_strlen($phone) > PHONE_MAX) {
        return 'Use no more than ' . PHONE_MAX . ' characters.';
    }
    if (preg_match('/^' . PHONE_PATTERN . '$/', $phone) !== 1) {
        return 'Enter a telephone number: 7 to 15 digits, with spaces or dashes if you like.';
    }
    return '';
}

/** What is wrong with a message or a reply as given, or '' if nothing. $empty is what to say when there is none. */
function request_text_problem(string $text, string $empty): string
{
    if ($text === '') {
        return $empty;
    }
    if (mb_strlen($text) > REQUEST_TEXT_MAX) {
        return 'Use no more than ' . REQUEST_TEXT_MAX . ' characters.';
    }
    return '';
}


/* ---------------------------------------------------------------------------
 * Reading requests
 * ------------------------------------------------------------------------- */

/** A request with its customer and the name of its configuration, if it still has one. */
const REQUEST_COLUMNS = 'SELECT r.*, u.username, u.email, b.build_name
     FROM quotation_request r
     JOIN `user` u ON u.user_id = r.user_id
     LEFT JOIN build b ON b.build_id = r.build_id';

function find_request(int $requestId): ?array
{
    $stmt = db()->prepare(REQUEST_COLUMNS . ' WHERE r.request_id = ?');
    $stmt->execute([$requestId]);
    return $stmt->fetch() ?: null;
}

/** A request, but only if it belongs to the customer asking. */
function find_own_request(int $requestId, int $userId): ?array
{
    $stmt = db()->prepare(REQUEST_COLUMNS . ' WHERE r.request_id = ? AND r.user_id = ?');
    $stmt->execute([$requestId, $userId]);
    return $stmt->fetch() ?: null;
}

/** A customer's requests, the latest first. */
function own_requests(int $userId): array
{
    $stmt = db()->prepare(REQUEST_COLUMNS . ' WHERE r.user_id = ? ORDER BY r.created_at DESC, r.request_id DESC');
    $stmt->execute([$userId]);
    return $stmt->fetchAll();
}

/** Every request, the latest first (FR9.3), all or those in one status. */
function all_requests(string $status = ''): array
{
    $stmt = db()->prepare(REQUEST_COLUMNS . ($status !== '' ? ' WHERE r.status = ?' : '')
        . ' ORDER BY r.created_at DESC, r.request_id DESC');
    $stmt->execute($status !== '' ? [$status] : []);
    return $stmt->fetchAll();
}

/** How many requests are in each status, every status listed. */
function request_counts(): array
{
    $counts = array_fill_keys(array_keys(REQUEST_STATUSES), 0);
    foreach (db()->query('SELECT status, COUNT(*) FROM quotation_request GROUP BY status')->fetchAll(PDO::FETCH_KEY_PAIR) as $status => $count) {
        $counts[$status] = (int) $count;
    }
    return $counts;
}

/** The number a customer gave with their last request, to offer it again: '' if none. */
function last_phone(int $userId): string
{
    $stmt = db()->prepare('SELECT contact_phone FROM quotation_request WHERE user_id = ? ORDER BY request_id DESC LIMIT 1');
    $stmt->execute([$userId]);
    return (string) ($stmt->fetchColumn() ?: '');
}


/* ---------------------------------------------------------------------------
 * Changing requests
 * ------------------------------------------------------------------------- */

/** A customer's new request (FR9.2). $buildId must be one of theirs, or null; the page checks it. */
function create_request(int $userId, ?int $buildId, string $phone, string $message): int
{
    db()->prepare('INSERT INTO quotation_request (user_id, build_id, contact_phone, message) VALUES (?, ?, ?, ?)')
        ->execute([$userId, $buildId, $phone, $message]);
    return (int) db()->lastInsertId();
}

/**
 * Records the consultant's reply and marks the request answered (FR9.4). A
 * reply given again replaces the first. A closed request is final, so it is
 * refused; the request is locked while that is judged, so a close sent at the
 * same moment cannot slip in between.
 */
function answer_request(int $requestId, string $reply): void
{
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare('SELECT status FROM quotation_request WHERE request_id = ?' . for_update());
        $stmt->execute([$requestId]);
        $status = $stmt->fetchColumn();
        if ($status === false) {
            throw new RequestRefused('That request could not be found.');
        }
        if ($status === 'closed') {
            throw new RequestRefused('Request ' . request_ref($requestId) . ' is closed, so nothing was changed.');
        }
        $pdo->prepare("UPDATE quotation_request SET admin_reply = ?, status = 'answered' WHERE request_id = ?")
            ->execute([$reply, $requestId]);
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        throw $e;
    }
}

/** Closes a request that is new or answered. A closed request is final. */
function close_request(int $requestId): void
{
    $stmt = db()->prepare("UPDATE quotation_request SET status = 'closed' WHERE request_id = ? AND status IN ('new', 'answered')");
    $stmt->execute([$requestId]);
    if ($stmt->rowCount() !== 1) {
        throw new RequestRefused('Request ' . request_ref($requestId) . ' is closed already, or no longer there, so nothing was changed.');
    }
}

/**
 * Removes a customer's own request, as long as nobody has answered it yet:
 * once there is a reply, the request stays, so that the reply is not lost.
 */
function withdraw_request(int $requestId, int $userId): void
{
    $stmt = db()->prepare("DELETE FROM quotation_request WHERE request_id = ? AND user_id = ? AND status = 'new'");
    $stmt->execute([$requestId, $userId]);
    if ($stmt->rowCount() !== 1) {
        throw new RequestRefused('Request ' . request_ref($requestId) . ' has been answered or closed already, so it was kept.');
    }
}


/* ---------------------------------------------------------------------------
 * The invitation
 * ------------------------------------------------------------------------- */

/**
 * The invitation to talk to a consultant (FR9.1), as the proposal's
 * wireframes place it under the configurator and under an order. It leads to
 * the request form with the configuration chosen: $buildId if it is saved,
 * and $orderId when the request is about an order.
 */
function render_consult_invitation(?int $buildId, ?int $orderId = null, string $lead = 'Send it to us with a note, and a consultant will come back to you.'): void
{
    $query = http_build_query(array_filter(['build' => $buildId, 'order' => $orderId]));
    ?>
    <aside class="consult" data-consult aria-labelledby="consult-title">
        <div class="consult-text">
            <strong id="consult-title">Not satisfied with this build?</strong>
            <span><?= e($lead) ?></span>
        </div>
        <a class="btn btn-primary" href="<?= e(url('consult.php' . ($query !== '' ? '?' . $query : ''))) ?>">Talk to a consultant</a>
    </aside>
    <?php
}
