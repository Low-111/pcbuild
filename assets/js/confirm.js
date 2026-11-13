/*
 * Confirmation before an action that takes something away (FR11.4). A form
 * carrying data-confirm="question" is held back and the question shown in a
 * dialog on the page; only the confirm button lets the form go.
 *
 *   data-confirm          the question
 *   data-confirm-title    the dialog's heading          (default "Are you sure?")
 *   data-confirm-button   the confirm button's wording  (default "Confirm")
 *   data-confirm-dismiss  the other button's wording    (default "Cancel"), for
 *                         when the action is itself a cancelling: "Cancel" beside
 *                         "Cancel order" would leave the customer guessing
 *
 * Deliberately not window.confirm(). Some embedded browsers answer confirm()
 * with "cancel" at once without showing it, so an action guarded by it could
 * never be carried out there; an in-page dialog works everywhere.
 */
(function () {
    'use strict';

    var dialog = null;
    var pending = null;

    function build() {
        dialog = document.createElement('dialog');
        dialog.className = 'confirm-dialog';
        dialog.setAttribute('aria-labelledby', 'confirm-title');
        dialog.innerHTML =
            '<h2 class="confirm-title" id="confirm-title"></h2>' +
            '<p class="confirm-text"></p>' +
            '<div class="confirm-actions">' +
            '<button type="button" class="btn btn-ghost" data-answer="cancel">Cancel</button>' +
            '<button type="button" class="btn btn-primary" data-answer="confirm"></button>' +
            '</div>';
        document.body.appendChild(dialog);

        dialog.addEventListener('click', function (event) {
            var button = event.target.closest && event.target.closest('[data-answer]');
            if (button) dialog.close(button.getAttribute('data-answer'));
        });
        dialog.addEventListener('close', function () {
            var form = pending;
            pending = null;
            if (form && dialog.returnValue === 'confirm') {
                form.dataset.confirmed = 'yes';
                form.requestSubmit();          // fires submit again, so the page's other handlers see it
            }
        });
    }

    document.addEventListener('submit', function (event) {
        var form = event.target;
        if (!(form instanceof HTMLFormElement) || !form.hasAttribute('data-confirm')) return;
        if (form.dataset.confirmed === 'yes') {   // the answer was yes: let it through, once
            delete form.dataset.confirmed;
            return;
        }
        event.preventDefault();
        if (!dialog) build();
        pending = form;
        dialog.returnValue = '';
        dialog.querySelector('.confirm-title').textContent = form.getAttribute('data-confirm-title') || 'Are you sure?';
        dialog.querySelector('.confirm-text').textContent = form.getAttribute('data-confirm');
        dialog.querySelector('[data-answer="confirm"]').textContent = form.getAttribute('data-confirm-button') || 'Confirm';
        dialog.querySelector('[data-answer="cancel"]').textContent = form.getAttribute('data-confirm-dismiss') || 'Cancel';
        dialog.showModal();
        dialog.querySelector('[data-answer="cancel"]').focus();   // the safe choice has the focus
    });
})();
