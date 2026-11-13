/*
 * Dynamic form fields (section 9.6): the component form shows only the
 * attributes the chosen category uses, so it never asks for a socket on a
 * power supply, and it relabels the wattage for what it means in that
 * category. Each option of the category list carries its own fields and
 * labels, written there by the server from CATEGORY_FIELDS.
 *
 * A hidden field is also disabled, which keeps it out of the browser's
 * checks and out of the submitted form. The server applies the same rule on
 * its own, whatever arrives.
 */
(function () {
    'use strict';

    var select = document.getElementById('f-category_id');
    if (!select) return;

    var wattage = document.querySelector('label[for="f-wattage"]');

    function apply() {
        var option = select.options[select.selectedIndex];
        var fields = option ? (option.getAttribute('data-fields') || '').split(' ') : [];
        if (wattage) wattage.textContent = option && option.getAttribute('data-label-wattage') || 'Wattage (W)';
        document.querySelectorAll('[data-field]').forEach(function (wrapper) {
            var name = wrapper.getAttribute('data-field');
            var used = fields.indexOf(name) !== -1;
            wrapper.hidden = !used;
            wrapper.querySelectorAll('input, select').forEach(function (control) { control.disabled = !used; });
            // Every underscore: the server writes data-label-has-integrated-graphics.
            var label = option && option.getAttribute('data-label-' + name.replace(/_/g, '-'));
            if (label) wrapper.querySelector('label').textContent = label;
        });
    }

    select.addEventListener('change', apply);
    apply();
})();
