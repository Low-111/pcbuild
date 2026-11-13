/*
 * Add stock in a dialog (3 November 2026). Each Add stock button is a link to
 * the form as a page of its own (admin/stock.php); here it opens the page's
 * one dialog instead, filled in with the part chosen, so a delivery is booked
 * without leaving the list. The form inside is checked by validate.js and
 * again by the server, like any other.
 */
(function () {
    'use strict';

    var dialog = document.getElementById('add-stock-dialog');
    if (!dialog || typeof dialog.showModal !== 'function') return;     // the links still work as links
    var form = dialog.querySelector('form');
    var said = dialog.querySelector('[data-stock-now]');

    document.querySelectorAll('[data-add-stock]').forEach(function (button) {
        button.addEventListener('click', function (event) {
            event.preventDefault();
            form.elements.id.value = button.getAttribute('data-add-stock');
            form.elements.quantity.value = '';
            form.elements.note.value = '';
            form.querySelectorAll('.field-error').forEach(function (message) { message.textContent = ''; });
            form.querySelectorAll('[aria-invalid]').forEach(function (field) { field.removeAttribute('aria-invalid'); });
            form.querySelectorAll('.has-error').forEach(function (field) { field.classList.remove('has-error'); });
            said.textContent = button.getAttribute('data-name') + ': ' + button.getAttribute('data-stock')
                + ' in stock now. What arrives is added to it.';
            dialog.showModal();
            form.elements.quantity.focus();
        });
    });

    dialog.querySelector('[data-stock-cancel]').addEventListener('click', function () { dialog.close(); });
})();
