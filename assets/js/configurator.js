/*
 * The configurator, live (FR3.4 to FR3.7, FR3.10, FR3.13). Each time a part or
 * a quantity changes:
 *   - the totals are added up here at once, from the price and figures each
 *     part carries on the page: the price, the power drawn, and the memory and
 *     storage in total, each times its quantity (FR3.4, FR3.5, FR3.13);
 *   - the choice is sent to api/check.php, which answers with every rule's
 *     verdict and with the parts that would not fit, and why. Those are
 *     greyed out with the reason in brackets under them; a chosen part that
 *     no longer fits is marked instead (FR3.6, FR3.7).
 * Until the first slot (the motherboard) is filled, the others stay locked.
 * Save and order stays disabled until the latest answer says the
 * configuration is valid (section 9.3), and from the moment anything changes
 * until the answer to that change arrives.
 * An answer that arrives after a newer one was asked for is ignored, and the
 * server checks everything again when the configuration is saved.
 *
 * The page starts from the fit the server worked out for it (data-fit), so
 * nothing moves when the script takes over.
 */
(function () {
    'use strict';

    var form = document.querySelector('form[data-configurator]');
    if (!form) return;
    var address = form.getAttribute('data-check-url');
    var firstSlot = form.getAttribute('data-first-slot');
    var firstName = form.getAttribute('data-first-name');
    var verdicts = form.querySelector('[data-verdicts]');
    var orderButton = form.querySelector('[data-order-button]');
    var slots = Array.prototype.slice.call(form.querySelectorAll('[data-slot]'));
    var fit = JSON.parse(form.getAttribute('data-fit') || '{}');
    var latest = 0;

    // Check is for browsers without this script; here every change is checked as it happens.
    form.querySelectorAll('[data-no-script]').forEach(function (button) { button.hidden = true; });

    /** RM 3,048.21, from a whole number of cents, as the server writes it. */
    function money(cents) {
        var whole = String(Math.floor(cents / 100)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        var rest = cents % 100;
        return 'RM ' + whole + '.' + (rest < 10 ? '0' : '') + rest;
    }
    function capacity(gigabytes) {
        return gigabytes >= 1000 && gigabytes % 1000 === 0 ? (gigabytes / 1000) + ' TB' : gigabytes + ' GB';
    }
    function number(value) {
        return String(Math.round(value * 10) / 10);
    }

    function chosenOption(slot) {
        var input = slot.querySelector('input[type=radio]:checked');
        return input && input.value !== '' ? input.closest('[data-part]') : null;
    }
    function quantitySelect(slot) {
        return slot.querySelector('select[data-quantity]');
    }
    function quantityOf(slot) {
        var select = quantitySelect(slot);
        return select && chosenOption(slot) ? parseInt(select.value, 10) || 1 : 1;
    }
    function reasonFor(slotId, partId, quantity) {
        var byPart = fit[slotId] && fit[slotId][partId];
        return (byPart && byPart[String(quantity)]) || '';
    }
    function isUnlocked() {
        return !!chosenOption(form.querySelector('[data-slot="' + firstSlot + '"]'));
    }

    /** Greys out, marks and locks every part and quantity as the choice and the latest fit say. */
    function paint() {
        var unlocked = isUnlocked();
        slots.forEach(function (slot) {
            var id = slot.getAttribute('data-slot');
            var anchor = id === firstSlot;
            var locked = !unlocked && !anchor;
            var chosen = chosenOption(slot);
            var quantity = quantityOf(slot);
            var clash = '';

            slot.querySelectorAll('.option').forEach(function (option) {
                var input = option.querySelector('input');
                var partId = option.getAttribute('data-part');
                if (!partId) {                      // "None"
                    input.disabled = locked;
                    return;
                }
                var isChosen = option === chosen;
                // A board chosen is never the one marked: the parts after it are what to change.
                var why = isChosen && anchor ? '' : reasonFor(id, partId, isChosen ? quantity : 1);
                // The first slot is where everything starts, so it is never closed off:
                // a board that clashes with later parts can still be chosen, and those
                // parts are then marked where they are.
                var closed = !isChosen && why !== '' && !anchor;
                option.classList.toggle('is-chosen', isChosen);
                option.classList.toggle('is-unfit', closed);
                option.classList.toggle('is-clash', isChosen && why !== '');
                input.disabled = locked || closed;
                var note = option.querySelector('[data-reason]');
                note.textContent = why ? '(' + why + ')' : '';
                note.hidden = !why;
                if (isChosen) clash = why;
            });

            var select = quantitySelect(slot);
            if (select) {
                select.disabled = locked || !chosen;
                Array.prototype.forEach.call(select.options, function (option) {
                    var n = parseInt(option.value, 10);
                    var why = chosen && n !== quantity ? reasonFor(id, chosen.getAttribute('data-part'), n) : '';
                    option.disabled = why !== '';
                    option.textContent = '× ' + n + (why ? ' (' + why + ')' : '');
                });
            }

            slot.classList.toggle('is-locked', locked);
            slot.classList.toggle('is-filled', !!chosen);
            slot.classList.toggle('is-clash', clash !== '');
            var head = slot.querySelector('[data-slot-choice]');
            if (locked) {
                head.textContent = 'Choose a ' + firstName + ' first';
            } else if (chosen) {
                head.textContent = chosen.getAttribute('data-name') + ' · '
                    + money(Math.round(parseFloat(chosen.getAttribute('data-price')) * 100))
                    + (quantity > 1 ? ' × ' + quantity : '');
            } else {
                head.textContent = 'Nothing chosen yet';
            }
        });
    }

    /** The totals, added up here the moment a part or a quantity changes. */
    function totals() {
        var cents = 0, draw = 0, safe = null;
        slots.forEach(function (slot) {
            var chosen = chosenOption(slot);
            var box = form.querySelector('[data-total="capacity-' + slot.getAttribute('data-slot') + '"]');
            var gigabytes = 0;
            if (chosen && !slot.classList.contains('is-locked')) {
                var quantity = quantityOf(slot);
                var watts = parseInt(chosen.getAttribute('data-wattage'), 10) * quantity;
                cents += Math.round(parseFloat(chosen.getAttribute('data-price')) * 100) * quantity;
                if (slot.getAttribute('data-power-limit') === 'yes') {
                    // A power supply supplies: its output is the limit, not part of the draw.
                    if (slot.hasAttribute('data-power-share')) safe = watts * parseFloat(slot.getAttribute('data-power-share')) / 100;
                } else {
                    draw += watts;
                }
                gigabytes = parseInt(chosen.getAttribute('data-capacity'), 10) * quantity;
            }
            if (box) box.textContent = gigabytes > 0 ? capacity(gigabytes) : '–';
        });
        form.querySelector('[data-total="price"]').textContent = money(cents);
        form.querySelector('[data-total="power"]').textContent = draw + ' W' + (safe !== null ? ' (safe up to ' + number(safe) + ' W)' : '');
    }

    /** A new part keeps its slot's quantity if that still fits, else the most that does. */
    function adjustQuantity(slot) {
        var chosen = chosenOption(slot), select = quantitySelect(slot);
        if (!chosen || !select) return;
        var quantity = parseInt(select.value, 10) || 1;
        while (quantity > 1 && reasonFor(slot.getAttribute('data-slot'), chosen.getAttribute('data-part'), quantity)) quantity--;
        select.value = String(quantity);
    }

    /**
     * After a part is chosen: close its slot and open the next one that needs a
     * choice. A slot that also asks how many stays open for the quantity.
     */
    function advance(from) {
        if (quantitySelect(from)) return;
        var start = slots.indexOf(from);
        for (var i = start + 1; i < slots.length; i++) {
            var slot = slots[i];
            if (slot.classList.contains('is-locked')) break;
            if (slot.classList.contains('is-clash') || (!chosenOption(slot) && slot.getAttribute('data-required') === 'yes')) {
                from.querySelector('details').open = false;
                slot.querySelector('details').open = true;
                slot.scrollIntoView({ block: 'nearest' });
                return;
            }
        }
        from.querySelector('details').open = false;
    }

    function note(text) {
        var p = document.createElement('p');
        p.className = 'field-error';
        p.textContent = text;
        verdicts.replaceChildren(p);
    }

    function check() {
        var ticket = ++latest;
        var params = new URLSearchParams();
        new FormData(form).forEach(function (value, key) {
            if (/^[cq]\[/.test(key)) params.append(key, value);
        });
        params.append('view', 'configurator');
        verdicts.setAttribute('aria-busy', 'true');
        fetch(address + '?' + params.toString(), { headers: { Accept: 'application/json' } })
            .then(function (response) {
                return response.json().then(function (data) { return { ok: response.ok, data: data }; });
            })
            .then(function (answer) {
                if (ticket !== latest) return;
                if (!answer.ok) {
                    note((answer.data.errors || [answer.data.error || 'The check was refused.']).join(' '));
                    return;
                }
                verdicts.innerHTML = answer.data.html;          // rendered and escaped by the server
                if (orderButton) orderButton.disabled = !answer.data.valid;
                fit = answer.data.fit || {};
                paint();
                totals();
            })
            .catch(function () {
                if (ticket === latest) note('The check could not be completed. Reload the page and try again.');
            })
            .then(function () {
                if (ticket === latest) verdicts.removeAttribute('aria-busy');
            });
    }

    form.addEventListener('change', function (event) {
        var slot = event.target.closest && event.target.closest('[data-slot]');
        if (!slot) return;                                  // the name field
        var pickedPart = event.target.type === 'radio' && event.target.value !== '';
        if (orderButton) orderButton.disabled = true;      // until the check of this change says it is valid
        if (pickedPart) adjustQuantity(slot);
        paint();
        totals();
        if (pickedPart) advance(slot);
        check();
    });
})();
