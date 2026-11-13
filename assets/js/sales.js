/*
 * The Sales page, live (admin/sales.php). Everything it shows is already on
 * the page as tables; this script adds:
 *   - the chart of the last twelve months, drawn here as SVG from the numbers
 *     the page carries (#sales-data). It shows revenue, parts sold or orders,
 *     switched with the buttons above it, the bars growing to their new
 *     heights. Pointing at a month, or moving to it with the keyboard, shows
 *     its figures; clicking it, or pressing Enter, shows that month;
 *   - the categories as bars, the largest first; clicking one lists only its
 *     parts in the table below, clicking it again lists them all;
 *   - sorting the parts table by any column, by clicking its heading;
 *   - choosing another period without loading the page again: the filter, or
 *     a bar, asks api/sales.php, which answers with the numbers and with the
 *     parts of the page that change, rendered as the page renders them. The
 *     address follows, so Back returns to the month before.
 * An answer that arrives after a newer one was asked for is ignored. If the
 * server cannot be asked, the page is simply loaded for that period instead.
 */
(function () {
    'use strict';

    var root = document.querySelector('[data-sales]');
    if (!root) return;

    var SVG = 'http://www.w3.org/2000/svg';
    var data = JSON.parse(document.getElementById('sales-data').textContent);
    var measure = 'revenue';
    var shownCategory = null;              // the category whose parts alone are listed, or null for all
    var sortColumn = 3, sortDescending = true;
    var asked = 0;                         // the number of the latest request, so older answers are ignored
    var heights = null;                    // the bars' heights as last drawn, to grow from
    var still = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    var monthChart = root.querySelector('[data-month-chart]');
    var categoryChart = root.querySelector('[data-category-chart]');
    var filter = root.querySelector('[data-sales-filter]');
    var select = filter.querySelector('select');
    var partFilter = root.querySelector('[data-part-filter]');

    var tip = document.createElement('div');
    tip.className = 'chart-tip';
    tip.hidden = true;
    monthChart.appendChild(tip);


    /* ---- Numbers as the page writes them ------------------------------- */

    var amount = new Intl.NumberFormat('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

    function money(cents) { return 'RM ' + amount.format(cents / 100); }

    /** A value of the measure shown, in words: "RM 1,234.00", "12 parts", "3 orders". */
    function said(value, which) {
        if (which === 'revenue') return money(value);
        var noun = which === 'units' ? 'part' : 'order';
        return value + ' ' + noun + (value === 1 ? '' : 's');
    }

    /** An axis tick, short: "RM 25K", "RM 2.5K", "40". */
    function tick(value) {
        if (measure !== 'revenue') return String(value);
        var ringgit = value / 100;
        if (ringgit >= 1000) return 'RM ' + (Math.round(ringgit / 100) / 10) + 'K';
        return 'RM ' + ringgit;
    }

    /** A round step for the axis: 1, 2, 2.5 or 5 times a power of ten, giving about four lines. */
    function step(top) {
        var rough = top / 4;
        var power = Math.pow(10, Math.floor(Math.log10(rough)));
        var nice = [1, 2, 2.5, 5, 10].filter(function (n) { return n * power >= rough; })[0];
        var size = nice * power;
        return measure === 'revenue' ? size : Math.max(1, Math.ceil(size));
    }

    function make(name, attributes, parent) {
        var element = document.createElementNS(SVG, name);
        for (var key in attributes) element.setAttribute(key, attributes[key]);
        if (parent) parent.appendChild(element);
        return element;
    }

    /** A bar from the baseline up, its top corners rounded by 4px and its foot square. */
    function barPath(x, width, base, height) {
        if (height <= 0) return '';
        var r = Math.min(4, width / 2, height);
        var top = base - height;
        return 'M' + x + ',' + base + 'V' + (top + r) + 'Q' + x + ',' + top + ' ' + (x + r) + ',' + top
            + 'H' + (x + width - r) + 'Q' + (x + width) + ',' + top + ' ' + (x + width) + ',' + (top + r) + 'V' + base + 'Z';
    }


    /* ---- The chart of the months ---------------------------------------- */

    function drawMonths(grow) {
        var months = data.months;
        var width = Math.max(280, monthChart.clientWidth);
        var narrow = width < 520;
        var height = narrow ? 220 : 260;
        var left = narrow ? 50 : 62, right = 6, top = 26, bottom = 28;
        var plotWidth = width - left - right, plotHeight = height - top - bottom, base = top + plotHeight;

        var values = months.map(function (m) { return m[measure]; });
        var highest = Math.max.apply(null, values);
        var size = highest > 0 ? step(highest) : (measure === 'revenue' ? 100000 : 1);
        var ceiling = Math.max(size, Math.ceil(highest / size) * size);

        var old = monthChart.querySelector('svg');
        if (old) old.remove();
        var svg = make('svg', { viewBox: '0 0 ' + width + ' ' + height, width: width, height: height,
            role: 'img', 'aria-labelledby': 'months-title', class: 'month-svg' });
        monthChart.insertBefore(svg, tip);

        for (var line = 0; line <= ceiling + size / 2; line += size) {
            var y = base - (line / ceiling) * plotHeight;
            make('line', { x1: left, x2: width - right, y1: y, y2: y, class: line === 0 ? 'axis-base' : 'axis-grid' }, svg);
            make('text', { x: left - 8, y: y + 4, 'text-anchor': 'end', class: 'axis-label' }, svg).textContent = tick(line);
        }

        var slot = plotWidth / months.length;
        var barWidth = Math.min(24, slot * 0.6);
        var everyOther = slot < 34;
        var picked = months.map(function (m) { return m.month; }).indexOf(data.period);
        var labelled = picked >= 0 ? picked : values.indexOf(highest);
        var targets = values.map(function (v) { return (v / ceiling) * plotHeight; });
        var paths = [];

        months.forEach(function (month, i) {
            var x = left + slot * i + (slot - barWidth) / 2;
            var group = make('g', { class: 'bar' + (picked === -1 ? '' : i === picked ? ' is-picked' : ' is-context'),
                tabindex: '0', role: 'button', 'data-bar': month.month,
                'aria-label': month.label + ': ' + money(month.revenue) + ', ' + said(month.orders, 'orders') + ', '
                    + said(month.units, 'units') + '. Show this month.' }, svg);
            if (i === picked) group.setAttribute('aria-current', 'true');
            make('rect', { x: left + slot * i, y: top, width: slot, height: plotHeight, class: 'bar-hit' }, group);
            paths.push(make('path', { d: barPath(x, barWidth, base, targets[i]), class: 'bar-mark' }, group));

            if (!everyOther || (months.length - 1 - i) % 2 === 0) {
                make('text', { x: x + barWidth / 2, y: height - 8, 'text-anchor': 'middle', class: 'axis-label' }, svg)
                    .textContent = month.short;
            }
            if (i === labelled && values[i] > 0) {
                make('text', { x: x + barWidth / 2, y: base - targets[i] - 8, 'text-anchor': 'middle', class: 'bar-value', 'data-bar-value': '' }, svg)
                    .textContent = tick(values[i]);
            }

            group.addEventListener('pointerenter', function () { show(group, month, x + barWidth / 2, base - targets[i]); });
            group.addEventListener('pointerleave', hide);
            group.addEventListener('focus', function () { show(group, month, x + barWidth / 2, base - targets[i]); });
            group.addEventListener('blur', hide);
            group.addEventListener('click', function () { choose(month.month); });
            group.addEventListener('keydown', function (event) {
                if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault();
                    choose(month.month);
                }
            });
        });

        if (highest === 0) {
            make('text', { x: left + plotWidth / 2, y: top + plotHeight / 2, 'text-anchor': 'middle', class: 'chart-empty' }, svg)
                .textContent = 'Nothing sold in these months.';
        }

        // Grow from where the bars were (from nothing the first time) to where they are now.
        var from = grow ? (heights || targets.map(function () { return 0; })) : targets;
        heights = targets;
        if (still || from === targets) return;
        var start = null;
        function frame(now) {
            if (start === null) start = now;
            var t = Math.min(1, (now - start) / 450);
            var eased = 1 - Math.pow(1 - t, 3);
            paths.forEach(function (path, i) {
                var x = left + slot * i + (slot - barWidth) / 2;
                path.setAttribute('d', barPath(x, barWidth, base, from[i] + (targets[i] - from[i]) * eased));
            });
            if (t < 1) requestAnimationFrame(frame);
        }
        requestAnimationFrame(frame);
    }

    /** The month's figures beside its bar: the measure shown first and largest, the others under it. */
    function show(group, month, x, y) {
        group.classList.add('is-hover');
        tip.textContent = '';
        var value = document.createElement('strong');
        value.textContent = said(month[measure], measure);
        var name = document.createElement('span');
        name.className = 'tip-month';
        name.textContent = month.label;
        var others = document.createElement('span');
        others.className = 'tip-others';
        others.textContent = ['revenue', 'orders', 'units']
            .filter(function (key) { return key !== measure; })
            .map(function (key) { return said(month[key], key); }).join(' · ');
        tip.appendChild(value);
        tip.appendChild(name);
        tip.appendChild(others);
        tip.hidden = false;
        var half = tip.offsetWidth / 2;
        tip.style.left = Math.max(half, Math.min(monthChart.clientWidth - half, x)) + 'px';
        tip.style.top = Math.max(0, y - tip.offsetHeight - 12) + 'px';
    }

    function hide() {
        tip.hidden = true;
        monthChart.querySelectorAll('.bar.is-hover').forEach(function (bar) { bar.classList.remove('is-hover'); });
    }

    root.querySelectorAll('[data-measure]').forEach(function (button) {
        button.addEventListener('click', function () {
            if (measure === button.getAttribute('data-measure')) return;
            measure = button.getAttribute('data-measure');
            root.querySelectorAll('[data-measure]').forEach(function (other) {
                other.setAttribute('aria-pressed', other === button ? 'true' : 'false');
            });
            hide();
            drawMonths(true);
        });
    });


    /* ---- The categories -------------------------------------------------- */

    function drawCategories() {
        categoryChart.textContent = '';
        var highest = Math.max.apply(null, data.categories.map(function (c) { return c.revenue; }));
        if (highest === 0) {
            var none = document.createElement('p');
            none.className = 'muted';
            none.textContent = 'Nothing was sold in ' + (data.period === 'all' ? 'any month' : data.label) + '.';
            categoryChart.appendChild(none);
            return;
        }
        var bars = [];
        data.categories.forEach(function (category) {
            var share = data.total > 0 ? Math.round(category.revenue * 100 / data.total) : 0;
            var row = document.createElement('button');
            row.type = 'button';
            row.className = 'category-row';
            row.setAttribute('data-category', category.id);
            row.setAttribute('aria-pressed', String(shownCategory === category.id));
            row.disabled = category.revenue === 0;
            row.setAttribute('aria-label', category.name + ': ' + money(category.revenue) + ', ' + share + '% of revenue, '
                + said(category.units, 'units') + '.' + (category.revenue > 0 ? ' List only its parts.' : ''));

            var name = document.createElement('span');
            name.className = 'category-name';
            name.textContent = category.name;
            var track = document.createElement('span');
            track.className = 'category-track';
            var bar = document.createElement('span');
            bar.className = 'category-bar';
            track.appendChild(bar);
            var value = document.createElement('span');
            value.className = 'category-value';
            value.textContent = category.revenue > 0 ? money(category.revenue) + ' · ' + share + '%' : '–';

            row.appendChild(name);
            row.appendChild(track);
            row.appendChild(value);
            categoryChart.appendChild(row);
            bars.push([bar, (category.revenue / highest) * 100]);

            row.addEventListener('click', function () {
                showCategory(shownCategory === category.id ? null : category.id);
            });
        });
        // Set the widths a frame later, so that they grow (the style sheet eases the change).
        requestAnimationFrame(function () {
            bars.forEach(function (pair) { pair[0].style.width = pair[1] + '%'; });
        });
        if (still) bars.forEach(function (pair) { pair[0].style.width = pair[1] + '%'; });
    }

    /** Lists only the parts of one category (or of all, given null). */
    function showCategory(id) {
        shownCategory = id;
        var name = '';
        categoryChart.querySelectorAll('[data-category]').forEach(function (row) {
            var on = Number(row.getAttribute('data-category')) === id;
            row.setAttribute('aria-pressed', String(on));
            if (on) name = row.querySelector('.category-name').textContent;
        });
        categoryChart.classList.toggle('has-choice', id !== null);
        root.querySelectorAll('#parts-sold tbody tr').forEach(function (row) {
            row.hidden = id !== null && Number(row.getAttribute('data-category')) !== id;
        });
        partFilter.hidden = id === null;
        partFilter.querySelector('[data-part-filter-text]').textContent = id === null ? '' : 'Showing ' + name + ' only.';
    }

    partFilter.querySelector('[data-show-all]').addEventListener('click', function () { showCategory(null); });


    /* ---- Sorting the parts ------------------------------------------------ */

    function sortable() {
        var table = root.querySelector('#parts-sold');
        if (!table) return;
        var headings = table.querySelectorAll('th[data-sort]');
        headings.forEach(function (heading, column) {
            var label = heading.textContent;
            heading.textContent = '';
            var button = document.createElement('button');
            button.type = 'button';
            button.className = 'sort-button';
            button.textContent = label;
            heading.appendChild(button);
            button.addEventListener('click', function () {
                // A new column starts with the largest (or A first, for words); the same column turns round.
                if (sortColumn === column) sortDescending = !sortDescending;
                else sortDescending = heading.getAttribute('data-sort') === 'number';
                sortColumn = column;
                sort();
            });
        });
        sort();
    }

    function sort() {
        var table = root.querySelector('#parts-sold');
        if (!table) return;
        var headings = table.querySelectorAll('th[data-sort]');
        var numeric = headings[sortColumn].getAttribute('data-sort') === 'number';
        var body = table.tBodies[0];
        var rows = Array.prototype.slice.call(body.rows);
        rows.sort(function (a, b) {
            var x = a.cells[sortColumn].getAttribute('data-value'), y = b.cells[sortColumn].getAttribute('data-value');
            var order = numeric ? Number(x) - Number(y) : x.localeCompare(y);
            if (sortDescending) order = -order;
            // Equal values keep to the name, A first, whichever way the column runs.
            return order || a.cells[0].getAttribute('data-value').localeCompare(b.cells[0].getAttribute('data-value'));
        });
        rows.forEach(function (row) { body.appendChild(row); });
        headings.forEach(function (heading, column) {
            if (column === sortColumn) heading.setAttribute('aria-sort', sortDescending ? 'descending' : 'ascending');
            else heading.removeAttribute('aria-sort');
        });
    }


    /* ---- Another period ---------------------------------------------------- */

    function address(period) { return data.page + '?month=' + encodeURIComponent(period); }

    function remember(period, replace) {
        try {
            if (replace) history.replaceState({ period: period }, '', address(period));
            else history.pushState({ period: period }, '', address(period));
        } catch (e) { /* a page that cannot change its address still works */ }
    }

    function choose(period) {
        if (period === data.period) return;
        load(period, true);
    }

    function load(period, push) {
        var mine = ++asked;
        root.classList.add('is-loading');
        hide();
        fetch(data.api + '?month=' + encodeURIComponent(period), { headers: { Accept: 'application/json' } })
            .then(function (response) {
                if (!response.ok) throw new Error('status ' + response.status);
                return response.json();
            })
            .then(function (answer) {
                if (mine !== asked) return;
                answer.api = data.api;
                answer.page = data.page;
                data = answer;
                root.querySelector('[data-period-label]').textContent = data.heading;
                root.querySelector('[data-sales-figures]').innerHTML = data.html.figures;
                root.querySelector('[data-sales-categories]').innerHTML = data.html.categories;
                root.querySelector('[data-sales-parts]').innerHTML = data.html.parts;
                root.querySelector('[data-sales-orders]').innerHTML = data.html.orders;
                if (!Array.prototype.some.call(select.options, function (o) { return o.value === data.period; })) {
                    var option = document.createElement('option');
                    option.value = data.period;
                    option.textContent = data.label;
                    select.insertBefore(option, select.options[0]);
                }
                select.value = data.period;
                shownCategory = null;
                partFilter.hidden = true;
                categoryChart.classList.remove('has-choice');
                drawMonths(false);
                drawCategories();
                sortable();
                if (push) remember(data.period, false);
                root.classList.remove('is-loading');
            })
            .catch(function () {
                if (mine === asked) window.location.href = address(period);
            });
    }

    filter.addEventListener('submit', function (event) {
        event.preventDefault();
        choose(select.value);
    });
    select.addEventListener('change', function () { choose(select.value); });
    window.addEventListener('popstate', function (event) {
        var period = event.state && event.state.period;
        if (period && period !== data.period) load(period, false);
    });


    /* ---- Start ------------------------------------------------------------- */

    // The charts now show what the tables show, so the tables fold away (one click opens them).
    root.querySelectorAll('[data-numbers]').forEach(function (details) { details.open = false; });
    root.querySelectorAll('[data-js-only]').forEach(function (element) { element.hidden = false; });
    remember(data.period, true);
    drawMonths(true);
    drawCategories();
    sortable();

    var waiting = null;
    if (window.ResizeObserver) {
        var lastWidth = monthChart.clientWidth;
        new ResizeObserver(function () {
            if (monthChart.clientWidth === lastWidth) return;
            lastWidth = monthChart.clientWidth;
            cancelAnimationFrame(waiting);
            waiting = requestAnimationFrame(function () { drawMonths(false); });
        }).observe(monthChart);
    }
})();
