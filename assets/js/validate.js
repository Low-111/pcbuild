/*
 * Form checking in the browser (FR11.1).
 *
 * The rules are read from each form's own markup (required, type="email",
 * minlength, maxlength, pattern, min, max), so a new form needs no new
 * script. A problem is shown under the field it belongs to, in the same
 * place the server puts its own messages.
 *
 * The server checks everything again regardless (FR11.2). This is here so a
 * customer hears about a mistake at once, not to keep anything safe: a
 * browser can always be made to skip it.
 *
 * A form opts in with data-validate. Optional attributes on a field:
 *   data-match="password"         must equal the field named "password"
 *   data-error-required="..."     the wording for an empty field, and likewise
 *   data-error-type / -minlength / -maxlength / -pattern / -min / -max / -match
 *
 * Without JavaScript the browser falls back to its own built-in checks,
 * because novalidate is only switched on from here.
 */
(function () {
    'use strict';

    function problemWith(field) {
        var v = field.validity;
        var d = field.dataset;

        if (v.valueMissing)    return d.errorRequired  || 'This field is required.';
        if (v.typeMismatch)    return d.errorType      || (field.type === 'email' ? 'Enter a valid email address.' : 'Enter a valid value.');
        if (v.badInput)        return d.errorType      || 'Enter a number.';
        if (v.tooShort)        return d.errorMinlength || 'Use at least ' + field.minLength + ' characters.';
        if (v.tooLong)         return d.errorMaxlength || 'Use no more than ' + field.maxLength + ' characters.';
        if (v.patternMismatch) return d.errorPattern   || 'This is not in the expected format.';
        if (v.rangeUnderflow)  return d.errorMin       || 'The lowest value allowed is ' + field.min + '.';
        if (v.rangeOverflow)   return d.errorMax       || 'The highest value allowed is ' + field.max + '.';
        if (v.stepMismatch)    return d.errorStep      || 'Enter a valid number.';

        // The browser enforces minlength only on text the user typed, so a
        // value filled in some other way is measured here as well.
        if (field.minLength > 0 && field.value.length > 0 && field.value.length < field.minLength) {
            return d.errorMinlength || 'Use at least ' + field.minLength + ' characters.';
        }

        if (d.match) {
            var other = field.form.elements.namedItem(d.match);
            if (other && other.value !== field.value) {
                return d.errorMatch || 'The two values do not match.';
            }
        }
        return '';
    }

    function show(field, message) {
        var wrapper = field.closest('.field');
        if (!wrapper) return;

        var box = wrapper.querySelector('.field-error');
        if (!box) {
            box = document.createElement('div');
            box.className = 'field-error';
            wrapper.appendChild(box);
        }
        box.textContent = message;
        wrapper.classList.toggle('has-error', message !== '');
        if (message) {
            field.setAttribute('aria-invalid', 'true');
        } else {
            field.removeAttribute('aria-invalid');
        }
    }

    function check(field) {
        var message = problemWith(field);
        show(field, message);
        return message === '';
    }

    function isShowingProblem(field) {
        var wrapper = field.closest('.field');
        return wrapper !== null && wrapper.classList.contains('has-error');
    }

    function checkableFields(form) {
        return Array.prototype.filter.call(form.elements, function (el) {
            return /^(INPUT|SELECT|TEXTAREA)$/.test(el.tagName) && el.willValidate;
        });
    }

    function inValidatedForm(el) {
        return el.form instanceof HTMLFormElement && el.form.hasAttribute('data-validate');
    }

    document.querySelectorAll('form[data-validate]').forEach(function (form) {
        form.noValidate = true;
    });

    // On sending: check every field, and stop at the first problem. A button
    // marked formnovalidate sends without the checks, as the browser's own do.
    document.addEventListener('submit', function (event) {
        var form = event.target;
        if (!(form instanceof HTMLFormElement) || !form.hasAttribute('data-validate')) return;
        if (event.submitter && event.submitter.formNoValidate) return;

        var firstProblem = null;
        checkableFields(form).forEach(function (field) {
            if (!check(field) && firstProblem === null) firstProblem = field;
        });
        if (firstProblem !== null) {
            event.preventDefault();
            firstProblem.focus();
        }
    });

    // On leaving a field the user has filled in: check it, without scolding
    // them for fields they have merely tabbed through.
    document.addEventListener('focusout', function (event) {
        var field = event.target;
        if (!inValidatedForm(field) || field.value === '') return;
        check(field);
    });

    // While typing: a message that is showing clears as soon as the problem
    // is put right. Fields that must match this one are re-checked too.
    document.addEventListener('input', function (event) {
        var field = event.target;
        if (!inValidatedForm(field)) return;

        if (isShowingProblem(field)) check(field);

        var matching = field.form.querySelectorAll('[data-match="' + CSS.escape(field.name) + '"]');
        matching.forEach(function (other) {
            if (isShowingProblem(other)) check(other);
        });
    });
})();
