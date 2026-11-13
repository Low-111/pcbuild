<?php
/*
 * Form markup. Every field on every form is built here, so they all look the
 * same and all carry what validate.js needs: a wrapper, a label tied to the
 * input, an optional hint, and a place for the error message that both the
 * browser and the server write into.
 */

declare(strict_types=1);

/**
 * One labelled input. $attributes go onto the <input> as given, for example
 * ['type' => 'email', 'required' => true, 'maxlength' => 100]; true writes a
 * bare attribute and false or null leaves it out. $wrapper goes onto the
 * surrounding <div>, e.g. ['data-field' => 'socket', 'hidden' => true]. The
 * input's id is f-<name> unless $attributes gives one, as a page must when
 * it repeats a form, one per row.
 */
function input_field(
    string $name,
    string $label,
    array $attributes = [],
    string $value = '',
    string $error = '',
    string $hint = '',
    array $wrapper = []
): string {
    $id = (string) ($attributes['id'] ?? 'f-' . $name);
    $input = array_merge(['type' => 'text'], $attributes, [
        'id'               => $id,
        'name'             => $name,
        'value'            => $value,
        'aria-describedby' => described_by($id, $hint),
        'aria-invalid'     => $error !== '' ? 'true' : null,
    ]);
    return field_wrap($id, $label, '<input' . html_attributes($input) . '>', $error, $hint, $wrapper);
}

/**
 * One labelled <textarea>, for text that runs to a sentence or more, such as
 * the remark on a rejected order. Built like input_field(): the same wrapper,
 * hint and place for the error.
 */
function textarea_field(
    string $name,
    string $label,
    array $attributes = [],
    string $value = '',
    string $error = '',
    string $hint = '',
    array $wrapper = []
): string {
    $id = (string) ($attributes['id'] ?? 'f-' . $name);
    $textarea = array_merge(['rows' => 3], $attributes, [
        'id'               => $id,
        'name'             => $name,
        'aria-describedby' => described_by($id, $hint),
        'aria-invalid'     => $error !== '' ? 'true' : null,
    ]);
    return field_wrap($id, $label, '<textarea' . html_attributes($textarea) . '>' . e($value) . '</textarea>', $error, $hint, $wrapper);
}

/**
 * One labelled <select>. $options maps each value to its label, or to
 * ['label' => ..., 'attributes' => [...]] when an option needs attributes of
 * its own. An empty $placeholder adds no blank first option.
 */
function select_field(
    string $name,
    string $label,
    array $options,
    string $selected = '',
    string $placeholder = '',
    array $attributes = [],
    string $error = '',
    string $hint = '',
    array $wrapper = []
): string {
    $id = 'f-' . $name;
    $select = array_merge($attributes, [
        'id'               => $id,
        'name'             => $name,
        'aria-describedby' => described_by($id, $hint),
        'aria-invalid'     => $error !== '' ? 'true' : null,
    ]);
    $html = '<select' . html_attributes($select) . '>';
    if ($placeholder !== '') {
        $html .= '<option value=""' . ($selected === '' ? ' selected' : '') . '>' . e($placeholder) . '</option>';
    }
    foreach ($options as $value => $option) {
        $text  = is_array($option) ? $option['label'] : $option;
        $extra = is_array($option) ? ($option['attributes'] ?? []) : [];
        $html .= '<option' . html_attributes(['value' => (string) $value] + $extra)
               . ((string) $value === $selected ? ' selected' : '') . '>' . e($text) . '</option>';
    }
    $html .= '</select>';
    return field_wrap($id, $label, $html, $error, $hint, $wrapper);
}

function described_by(string $id, string $hint): string
{
    return $hint === '' ? $id . '-error' : $id . '-hint ' . $id . '-error';
}

function field_wrap(string $id, string $label, string $control, string $error, string $hint, array $wrapper): string
{
    $class = trim('field ' . ($wrapper['class'] ?? '') . ($error !== '' ? ' has-error' : ''));
    unset($wrapper['class']);
    return '<div' . html_attributes(['class' => $class] + $wrapper) . '>'
         . '<label for="' . e($id) . '">' . e($label) . '</label>'
         . $control
         . ($hint !== '' ? '<div class="field-hint" id="' . e($id) . '-hint">' . e($hint) . '</div>' : '')
         . '<div class="field-error" id="' . e($id) . '-error">' . e($error) . '</div>'
         . '</div>';
}

function html_attributes(array $attributes): string
{
    $html = '';
    foreach ($attributes as $name => $value) {
        if ($value === false || $value === null) {
            continue;
        }
        $html .= ' ' . e($name) . ($value === true ? '' : '="' . e($value) . '"');
    }
    return $html;
}
