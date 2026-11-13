<?php
/*
 * The live compatibility check (FR3.6). The rule tester and the configurator
 * send the parts chosen so far and get back every active rule's verdict as
 * JSON, together with the same verdicts rendered as HTML, so the page shows
 * exactly what the server decided. Nothing is saved.
 *
 *   GET api/check.php?c[<category id>]=<component id>&q[<category id>]=<quantity>
 *
 * With view=configurator the answer also carries fit: every part on sale that
 * would not fit the parts chosen, and why, as
 * {category id: {component id: {quantity: reason}}} (fit_report), and the
 * HTML leaves out the totals, which the configurator shows as parts are chosen.
 *
 * Answers 401 to a visitor and 422, with the reasons, to a selection that
 * names a part that does not exist, is not on sale or is in the wrong slot.
 */

declare(strict_types=1);

require __DIR__ . '/../includes/bootstrap.php';

require_login_json();

[$selection, $problems] = read_selection($_GET['c'] ?? [], $_GET['q'] ?? []);
if ($problems !== []) {
    send_json(['errors' => $problems], 422);
}

$context = rule_context();
$result = evaluate_selection($selection, $context);
if (($_GET['view'] ?? '') !== 'configurator') {
    send_json($result + ['html' => render_verdicts($result)]);
}

$candidates = [];
foreach (catalogue_components() as $part) {
    $candidates[(int) $part['category_id']][] = $part;
}
send_json($result + [
    'html' => render_verdicts($result, false),
    'fit'  => (object) fit_report($selection, $candidates, $context),
]);
