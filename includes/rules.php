<?php
/*
 * The rule engine (FR3.6 to FR3.12, FR7.5).
 *
 * One function judges a configuration against every active row of the
 * compatibility_rule table, so the rule tester, the configurator and the order
 * check all get the same answer. A rule is data: a row inserted in phpMyAdmin
 * is applied at the next check with no change here, as long as it is one of
 * the three kinds this file knows.
 *
 *   ATTRIBUTE_MATCH    category_a's attribute must equal category_b's.
 *   CAPACITY_CHECK     a figure added up over everything else must stay within
 *                      category_a's own figure times headroom_pct / 100: the
 *                      watts drawn against a power supply's output, or the
 *                      M.2 slots the drives take against the slots a board has.
 *   REQUIRES_CATEGORY  when category_a's yes-or-no attribute is no (or empty),
 *                      category_b must hold a component.
 *
 * A rule is skipped while a category it looks at is empty (FR3.12). Whether a
 * configuration is complete is a separate question, answered by the required
 * flag on each category, and a configuration is valid only when it is complete
 * and no rule fails (FR3.11).
 *
 * fit_report() asks the same rules the configurator's question: which parts
 * on sale would not fit what has been chosen so far, and why.
 */

declare(strict_types=1);

/**
 * The columns each kind of rule may name in attribute_key. The engine reads
 * only these, so a rule can never make it read anything else; a rule naming
 * another column is reported as broken rather than quietly passed.
 */
const RULE_ATTRIBUTES = [
    'ATTRIBUTE_MATCH'   => ['socket', 'memory_type'],
    'CAPACITY_CHECK'    => ['wattage', 'memory_slots', 'm2_slots', 'sata_ports', 'drive_bays'],
    'REQUIRES_CATEGORY' => ['has_integrated_graphics', 'includes_cooler'],
];

/** Each kind of rule as the administrator sees it. */
const RULE_TYPES = [
    'ATTRIBUTE_MATCH'   => 'Two parts must match',
    'CAPACITY_CHECK'    => 'A total must stay within a limit',
    'REQUIRES_CATEGORY' => 'One part needs another',
];

/** The attributes in words. */
const ATTRIBUTE_LABELS = [
    'socket'                  => 'socket',
    'memory_type'             => 'memory type',
    'wattage'                 => 'wattage',
    'memory_slots'            => 'memory slots',
    'm2_slots'                => 'M.2 slots',
    'sata_ports'              => 'SATA ports',
    'drive_bays'              => 'drive bays',
    'has_integrated_graphics' => 'integrated graphics',
    'includes_cooler'         => 'cooler in the box',
];

/**
 * The figures a capacity rule counts rather than measures in watts, as one of
 * them and as many: "1 M.2 slot", "2 M.2 slots".
 */
const COUNT_UNITS = [
    'memory_slots' => ['memory slot', 'memory slots'],
    'm2_slots'     => ['M.2 slot', 'M.2 slots'],
    'sata_ports'   => ['SATA port', 'SATA ports'],
    'drive_bays'   => ['drive bay', 'drive bays'],
];

/** How a yes-or-no attribute reads in a sentence, for yes and for no. */
const FLAG_PHRASES = [
    'has_integrated_graphics' => ['has integrated graphics', 'has no integrated graphics'],
    'includes_cooler'         => ['comes with a cooler', 'comes without a cooler'],
];

/** Every rule, switched on or not, with the names of its categories, oldest first. */
function all_rules(): array
{
    return db()->query(
        'SELECT r.*, a.category_name AS category_a_name, b.category_name AS category_b_name
         FROM compatibility_rule r
         JOIN category a ON a.category_id = r.category_a
         LEFT JOIN category b ON b.category_id = r.category_b
         ORDER BY r.rule_id'
    )->fetchAll();
}

function find_rule(int $id): ?array
{
    foreach (all_rules() as $rule) {
        if ((int) $rule['rule_id'] === $id) {
            return $rule;
        }
    }
    return null;
}

/** Every category keyed by its id, in the configurator's order. */
function categories_by_id(): array
{
    $byId = [];
    foreach (categories() as $category) {
        $byId[(int) $category['category_id']] = $category;
    }
    return $byId;
}

/** One sentence saying what a rule checks, e.g. "CPU socket must equal Motherboard socket". */
function rule_summary(array $rule): string
{
    $a = (string) $rule['category_a_name'];
    $b = (string) ($rule['category_b_name'] ?? '');
    $what = ATTRIBUTE_LABELS[$rule['attribute_key']] ?? (string) $rule['attribute_key'];
    return match ($rule['rule_type']) {
        'ATTRIBUTE_MATCH'   => "$a $what must equal $b $what",
        'CAPACITY_CHECK'    => match (true) {
            $rule['attribute_key'] === 'wattage' => 'Everything else must draw at most ' . headroom_text($rule) . " of the $a's rated $what",
            $rule['headroom_pct'] === null       => "The parts must take no more $what than the $a has",
            default                              => 'The parts must take at most ' . headroom_text($rule) . " of the $a's $what",
        },
        'REQUIRES_CATEGORY' => "A $a that " . (FLAG_PHRASES[$rule['attribute_key']][1] ?? "has no $what") . " needs a $b",
        default             => 'Unknown kind of rule',
    };
}

/** A capacity rule's share of its limit, e.g. "80 %"; no share recorded means all of it. */
function headroom_text(array $rule): string
{
    if ($rule['headroom_pct'] === null) {
        return '100 %';
    }
    return rtrim(rtrim(number_format((float) $rule['headroom_pct'], 2, '.', ''), '0'), '.') . ' %';
}

/** A number as a sentence reads it: 440, 1.5, never 440.0. */
function number_text(float $number): string
{
    return rtrim(rtrim(number_format($number, 1, '.', ''), '0'), '.');
}

/** A count with its noun: "1 M.2 slot", "2 M.2 slots", "no M.2 slots". */
function count_text(string $figure, float $count): string
{
    [$one, $many] = COUNT_UNITS[$figure] ?? [$figure, $figure];
    if ($count == 0) {
        return "no $many";
    }
    return number_text($count) . ' ' . ($count == 1 ? $one : $many);
}

/**
 * What judging needs, read from the database once: the categories, every
 * rule, and for each figure a capacity rule adds up, the categories that hold
 * its limit. Those are left out of the total: a power supply supplies watts,
 * it does not draw them, and a board's M.2 slots are room, not demand. A
 * category counts as a limit whether its rule is switched on or not, so that
 * switching a rule off does not suddenly add a limit to the demand.
 */
function rule_context(): array
{
    $rules = all_rules();
    $limits = [];
    foreach ($rules as $rule) {
        if ($rule['rule_type'] === 'CAPACITY_CHECK') {
            $limits[(string) $rule['attribute_key']][(int) $rule['category_a']] = true;
        }
    }
    return ['categories' => categories_by_id(), 'rules' => $rules, 'limits' => $limits];
}

/** A figure times quantity, added up over the parts chosen, leaving out the ones that hold its limit. */
function figure_total(array $selection, string $figure, array $context): int
{
    $total = 0;
    foreach ($selection as $categoryId => $item) {
        if (!isset($context['limits'][$figure][$categoryId])) {
            $total += (int) ($item['component'][$figure] ?? 0) * $item['quantity'];
        }
    }
    return $total;
}

/**
 * Reads a selection sent by the rule tester or the configurator: component ids
 * and quantities, each keyed by category id. Nothing sent is trusted. The
 * component must exist, be on sale, and belong to the category it was sent
 * for, and the quantity must be a whole number from 1 to that category's cap.
 *
 * Returns [selection, problems], the selection keyed by category id as
 * ['component' => row, 'quantity' => n]. An empty slot is simply left out.
 */
function read_selection(mixed $componentIds, mixed $quantities): array
{
    $categories = categories_by_id();
    $componentIds = is_array($componentIds) ? $componentIds : [];
    $quantities = is_array($quantities) ? $quantities : [];
    $selection = [];
    $problems = [];

    foreach ($componentIds as $categoryId => $componentId) {
        if ($componentId === '') {
            continue;
        }
        $category = $categories[(int) $categoryId] ?? null;
        if ($category === null || !ctype_digit((string) $categoryId)) {
            $problems[] = 'A part was sent for a category that does not exist.';
            continue;
        }
        $component = is_string($componentId) && ctype_digit($componentId) ? find_component((int) $componentId) : null;
        if ($component === null || (int) $component['category_id'] !== (int) $categoryId) {
            $problems[] = 'The part chosen as ' . $category['category_name'] . ' is not one of the ' . $category['category_name'] . ' parts.';
            continue;
        }
        if ((int) $component['is_active'] !== 1) {
            $problems[] = '“' . $component['name'] . '” is no longer sold.';
            continue;
        }
        $quantity = $quantities[$categoryId] ?? '1';
        $max = (int) $category['max_quantity'];
        if (!is_string($quantity) || !ctype_digit($quantity) || (int) $quantity < 1 || (int) $quantity > $max) {
            $problems[] = $max === 1
                ? 'Only one ' . $category['category_name'] . ' can be chosen.'
                : 'Choose from 1 to ' . $max . ' of the ' . $category['category_name'] . '.';
            continue;
        }
        $selection[(int) $categoryId] = ['component' => $component, 'quantity' => (int) $quantity];
    }
    return [$selection, $problems];
}

/**
 * Judges a selection (from read_selection) against every active rule. The
 * context (rule_context) may be passed in when many selections are judged in
 * a row, as fit_report does; otherwise it is read here.
 *
 * Returns:
 *   rules          each active rule's verdict: status pass, fail, skip or error,
 *                  the rule's own message, and a detail naming the parts
 *   missing        required categories left empty, in the configurator's order
 *   complete       nothing required is missing
 *   valid          complete, and no rule fails or is broken
 *   total_price    the sum of price times quantity, as "1234.50"
 *   total_wattage  the draw: wattage times quantity over everything that does
 *                  not set a limit on it (a power supply supplies, it does not draw)
 *   capacity       capacity times quantity, per category a build may take more
 *                  than one of: the total memory and the total storage (FR3.13)
 */
function evaluate_selection(array $selection, ?array $context = null): array
{
    $context ??= rule_context();
    $categories = $context['categories'];

    $cents = 0;
    $capacity = [];
    foreach ($selection as $categoryId => $item) {
        $component = $item['component'];
        $cents += (int) round((float) $component['price'] * 100) * $item['quantity'];
        if ($component['capacity_gb'] !== null && (int) $categories[$categoryId]['max_quantity'] > 1) {
            $name = $categories[$categoryId]['category_name'];
            $capacity[$name] = ($capacity[$name] ?? 0) + (int) $component['capacity_gb'] * $item['quantity'];
        }
    }

    $verdicts = [];
    foreach ($context['rules'] as $rule) {
        if ((int) $rule['is_active'] === 1) {
            $verdicts[] = judge_rule($rule, $selection, $context);
        }
    }

    $missing = [];
    foreach ($categories as $categoryId => $category) {
        if ((int) $category['is_required'] === 1 && !isset($selection[$categoryId])) {
            $missing[] = (string) $category['category_name'];
        }
    }
    $failing = array_filter($verdicts, fn (array $v): bool => $v['status'] === 'fail' || $v['status'] === 'error');

    return [
        'rules'         => $verdicts,
        'missing'       => $missing,
        'complete'      => $missing === [],
        'valid'         => $missing === [] && $failing === [],
        'total_price'   => sprintf('%d.%02d', intdiv($cents, 100), $cents % 100),
        'total_wattage' => figure_total($selection, 'wattage', $context),
        'capacity'      => $capacity,
    ];
}

/** One rule's verdict on a selection. */
function judge_rule(array $rule, array $selection, array $context): array
{
    $type = (string) $rule['rule_type'];
    $key = (string) $rule['attribute_key'];
    $aName = (string) $rule['category_a_name'];
    $bName = (string) ($rule['category_b_name'] ?? '');
    $a = $selection[(int) $rule['category_a']] ?? null;
    $b = $rule['category_b'] === null ? null : ($selection[(int) $rule['category_b']] ?? null);

    $verdict = static fn (string $status, string $detail): array => [
        'id'      => (int) $rule['rule_id'],
        'name'    => (string) $rule['rule_name'],
        'type'    => $type,
        'status'  => $status,
        'message' => (string) $rule['error_message'],
        'detail'  => $detail,
    ];

    if (!in_array($key, RULE_ATTRIBUTES[$type] ?? [], true)) {
        return $verdict('error', 'This rule cannot be checked: it names “' . $key . '”, which a rule of this kind cannot read.');
    }
    $what = ATTRIBUTE_LABELS[$key];

    switch ($type) {
        case 'ATTRIBUTE_MATCH':
            if ($a === null || $b === null) {
                return $verdict('skip', "Checked once the $aName and the $bName are chosen.");
            }
            $left = strtoupper(trim((string) $a['component'][$key]));
            $right = strtoupper(trim((string) $b['component'][$key]));
            foreach ([[$left, $a], [$right, $b]] as [$value, $item]) {
                if ($value === '') {
                    // Unknown is not the same as compatible: a match that cannot be confirmed fails.
                    return $verdict('fail', 'The ' . $item['component']['name'] . " has no $what recorded, so the match cannot be confirmed.");
                }
            }
            if ($left !== $right) {
                return $verdict('fail', 'The ' . $a['component']['name'] . " is $left; the " . $b['component']['name'] . " is $right.");
            }
            return $verdict('pass', "Both are $left.");

        case 'CAPACITY_CHECK':
            if ($a === null) {
                return $verdict('skip', "Checked once the $aName is chosen.");
            }
            $used = figure_total($selection, $key, $context);
            $rated = (int) ($a['component'][$key] ?? 0) * $a['quantity'];
            $share = $rule['headroom_pct'] === null ? 100.0 : (float) $rule['headroom_pct'];
            $safe = $rated * $share / 100;
            $name = $a['component']['name'];
            if ($key === 'wattage') {
                $safeText = number_text($safe);
                if ($used > $safe) {
                    return $verdict('fail', "The parts draw $used W; the $name can safely supply $safeText W (" . headroom_text($rule) . " of $rated W).");
                }
                return $verdict('pass', "The parts draw $used W of the $safeText W the $name can safely supply.");
            }
            // A count: slots, ports or bays taken against the ones the limit holder has.
            $room = $rule['headroom_pct'] === null
                ? "has $rated"
                : 'allows ' . number_text($safe) . ' (' . headroom_text($rule) . " of $rated)";
            return $verdict($used > $safe ? 'fail' : 'pass', 'The parts take ' . count_text($key, $used) . "; the $name $room.");

        case 'REQUIRES_CATEGORY':
            if ($a === null) {
                return $verdict('skip', "Checked once the $aName is chosen.");
            }
            [$yes, $no] = FLAG_PHRASES[$key];
            $flag = $a['component'][$key];
            if ($flag !== null && (int) $flag === 1) {
                return $verdict('pass', 'The ' . $a['component']['name'] . " $yes, so no $bName is needed.");
            }
            if ($b !== null) {
                return $verdict('pass', 'The ' . $a['component']['name'] . " $no, and the " . $b['component']['name'] . ' is included.');
            }
            return $verdict('fail', 'The ' . $a['component']['name'] . " $no: add a $bName.");
    }
    return $verdict('error', 'This rule cannot be checked: its kind is unknown.');
}

/**
 * Which parts on sale would not fit the configuration as it stands, and why,
 * so that the configurator can grey them out with the reason (team decision,
 * 29 September 2026). Every part of every category is tried in its slot, at
 * each quantity the category allows, in place of whatever the slot holds now.
 * A part does not fit when
 *   - a matching or counting rule fails with it and did not fail with the slot
 *     empty, so a part is never blamed for a clash between two others; or
 *   - the rule is still waiting for a slot that is empty, and no part on sale
 *     for that slot could satisfy it with this part in, although one could
 *     without it. So three hard disks are refused before any case is chosen:
 *     no case sold holds more than two.
 * The rules that ask for another part (REQUIRES_CATEGORY) never make a part
 * unfit: they say what to add, not what to leave out. A broken rule is left
 * to the verdicts, which already stop every configuration.
 *
 * $candidates holds the parts on sale keyed by category id, as the page has
 * them already. Returns [category id => [component id => [quantity => reason]]],
 * naming only what does not fit; the reason is short, for the brackets under
 * the part. A part already chosen that no longer fits appears too.
 */
function fit_report(array $selection, array $candidates, ?array $context = null): array
{
    $context ??= rule_context();
    $rules = array_filter($context['rules'], static fn (array $rule): bool =>
        (int) $rule['is_active'] === 1
        && in_array($rule['rule_type'], ['ATTRIBUTE_MATCH', 'CAPACITY_CHECK'], true)
        && in_array($rule['attribute_key'], RULE_ATTRIBUTES[$rule['rule_type']], true));

    $report = [];
    foreach ($context['categories'] as $categoryId => $category) {
        if (empty($candidates[$categoryId])) {
            continue;
        }
        $without = $selection;
        unset($without[$categoryId]);

        // The rules this slot takes part in, and whether each is already blocked
        // with the slot empty, by the other parts alone.
        $concerned = [];
        foreach ($rules as $rule) {
            if (rule_concerns($rule, (int) $categoryId, $context)) {
                $concerned[] = [$rule, rule_blocked($rule, $without, $candidates, $context, (int) $categoryId)];
            }
        }
        if ($concerned === []) {
            continue;
        }

        foreach ($candidates[$categoryId] as $part) {
            for ($quantity = 1; $quantity <= (int) $category['max_quantity']; $quantity++) {
                $trial = $without;
                $trial[$categoryId] = ['component' => $part, 'quantity' => $quantity];
                foreach ($concerned as [$rule, $blockedWithout]) {
                    if ($blockedWithout) {
                        continue;               // already failing, or unsatisfiable, without this slot: not this part's doing
                    }
                    $reason = unfit_reason($rule, $trial, (int) $categoryId, $candidates, $context);
                    if ($reason !== null) {
                        $report[(int) $categoryId][(int) $part['component_id']][$quantity] = $reason;
                        break;
                    }
                }
            }
        }
    }
    return $report;
}

/** Whether a slot takes part in a matching or counting rule: as one side of a match, as a limit, or as something counted against it. */
function rule_concerns(array $rule, int $categoryId, array $context): bool
{
    if ($rule['rule_type'] === 'ATTRIBUTE_MATCH') {
        return (int) $rule['category_a'] === $categoryId || (int) $rule['category_b'] === $categoryId;
    }
    return (int) $rule['category_a'] === $categoryId
        || !isset($context['limits'][(string) $rule['attribute_key']][$categoryId]);
}

/** The empty slot a rule is waiting for before it can judge, or null when it is waiting for none (or for two). */
function rule_waits_for(array $rule, array $selection): ?int
{
    $a = (int) $rule['category_a'];
    if ($rule['rule_type'] === 'CAPACITY_CHECK') {
        return isset($selection[$a]) ? null : $a;
    }
    $b = (int) $rule['category_b'];
    if (isset($selection[$a]) === isset($selection[$b])) {
        return null;
    }
    return isset($selection[$a]) ? $b : $a;
}

/**
 * Whether a rule cannot be met by a selection as it stands: it fails, or it
 * waits for an empty slot and no part on sale there would let it pass. Waiting
 * for the slot named in $except does not count: that is the slot being tried.
 */
function rule_blocked(array $rule, array $selection, array $candidates, array $context, ?int $except = null): bool
{
    $status = judge_rule($rule, $selection, $context)['status'];
    if ($status === 'fail') {
        return true;
    }
    if ($status !== 'skip') {
        return false;
    }
    $slot = rule_waits_for($rule, $selection);
    if ($slot === null || $slot === $except || empty($candidates[$slot])) {
        return false;
    }
    foreach ($candidates[$slot] as $part) {
        $ahead = $selection;
        $ahead[$slot] = ['component' => $part, 'quantity' => 1];
        if (judge_rule($rule, $ahead, $context)['status'] !== 'fail') {
            return false;
        }
    }
    return true;
}

/** Why a part tried in a slot does not fit under one rule, or null when it does. */
function unfit_reason(array $rule, array $trial, int $categoryId, array $candidates, array $context): ?string
{
    if (!rule_blocked($rule, $trial, $candidates, $context)) {
        return null;
    }
    $key = (string) $rule['attribute_key'];
    $what = ATTRIBUTE_LABELS[$key];
    $a = (int) $rule['category_a'];
    $aName = (string) $rule['category_a_name'];
    $mine = $trial[$categoryId]['component'];
    $waiting = rule_waits_for($rule, $trial);

    if ($rule['rule_type'] === 'ATTRIBUTE_MATCH') {
        $other = $a === $categoryId ? (int) $rule['category_b'] : $a;
        $otherName = (string) $context['categories'][$other]['category_name'];
        $value = strtoupper(trim((string) $mine[$key]));
        if ($value === '') {
            return "no $what recorded";
        }
        if ($waiting !== null) {
            return "no $otherName sold has $what $value";
        }
        $theirs = strtoupper(trim((string) $trial[$other]['component'][$key]));
        return $theirs === ''
            ? "the $otherName has no $what recorded"
            : "its $what is $value, the $otherName's is $theirs";
    }

    // A capacity rule: this part is either the limit or something counted against it.
    $used = figure_total($trial, $key, $context);
    $wattage = $key === 'wattage';
    $amount = static fn (float $n): string => $wattage ? number_text($n) . ' W' : count_text($key, $n);
    if ($waiting !== null) {
        return $wattage
            ? "the parts would draw $used W, more than any $aName sold can safely supply"
            : 'the parts would take ' . count_text($key, $used) . ", more than any $aName sold has";
    }
    $limit = $trial[$a];
    $share = $rule['headroom_pct'] === null ? 100.0 : (float) $rule['headroom_pct'];
    $room = (int) ($limit['component'][$key] ?? 0) * $limit['quantity'] * $share / 100;
    if ($a === $categoryId) {
        return $wattage
            ? 'safely supplies ' . $amount($room) . ", the parts draw $used W"
            : 'has ' . $amount($room) . ", the parts take $used";
    }
    return $wattage
        ? "the parts would draw $used W, the $aName safely supplies " . $amount($room)
        : 'the parts would take ' . count_text($key, $used) . ", the $aName has " . number_text($room);
}

/**
 * The verdicts as the page shows them: the overall answer, what is missing,
 * the totals, then one line per rule. Returned as HTML so the rule tester and
 * the configurator print exactly what the server decided, with or without
 * JavaScript. Everything in it is escaped. The configurator shows its totals
 * above, as the parts are chosen, and asks for the verdicts without them.
 */
function render_verdicts(array $result, bool $withTotals = true): string
{
    $labels = ['pass' => 'Passes', 'fail' => 'Fails', 'skip' => 'Skipped', 'error' => 'Broken'];
    ob_start();
    ?>
    <div class="verdict-summary <?= $result['valid'] ? 'is-valid' : 'is-invalid' ?>">
        <strong><?= $result['valid'] ? 'Valid: this configuration could be ordered.' : 'Not valid: this configuration could not be ordered yet.' ?></strong>
        <?php if ($result['missing'] !== []): ?>
            <span>Still missing: <?= e(implode(', ', $result['missing'])) ?>.</span>
        <?php endif; ?>
    </div>
    <?php if ($withTotals): ?>
        <dl class="verdict-totals">
            <div><dt>Total price</dt><dd><?= e(money($result['total_price'])) ?></dd></div>
            <div><dt>Power drawn</dt><dd><?= (int) $result['total_wattage'] ?> W</dd></div>
            <?php foreach ($result['capacity'] as $category => $gigabytes): ?>
                <div><dt><?= e($category) ?> in total</dt><dd><?= e(capacity_text((int) $gigabytes)) ?></dd></div>
            <?php endforeach; ?>
        </dl>
    <?php endif; ?>
    <ul class="verdicts">
        <?php foreach ($result['rules'] as $verdict): ?>
            <li class="verdict verdict-<?= e($verdict['status']) ?>" data-rule="<?= (int) $verdict['id'] ?>">
                <span class="verdict-badge"><?= e($labels[$verdict['status']]) ?></span>
                <span class="verdict-text">
                    <span class="verdict-name"><?= e($verdict['name']) ?></span>
                    <?php if ($verdict['status'] === 'fail'): ?>
                        <span class="verdict-message"><?= e($verdict['message']) ?></span>
                    <?php endif; ?>
                    <span class="verdict-detail"><?= e($verdict['detail']) ?></span>
                </span>
            </li>
        <?php endforeach; ?>
        <?php if ($result['rules'] === []): ?>
            <li class="verdict verdict-skip"><span class="verdict-text">No rule is switched on.</span></li>
        <?php endif; ?>
    </ul>
    <?php
    return (string) ob_get_clean();
}
