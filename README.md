# PC Build Configurator and Inventory Management System

A web system for a shop that sells custom-built desktop PCs. Customers assemble
a configuration from the shop's components and the system checks, as they go,
that the parts work together: the processor fits the motherboard, the memory
suits it, and the power supply can carry the load. The checks are rules held in
the database, so the shop can add or change one without touching the code. A
configuration that passes can be ordered: its parts are reserved until the shop
approves the order, when they leave the stock, or rejects it with a remark. A
customer the configurator cannot serve asks the shop's consultant, who replies
on the request. The administrator's dashboard shows what needs attention, and
checks that every reserved quantity is accounted for by an order; the Sales
page shows what was sold, month by month, by category and by part. Every change
to the stock is kept in an Inventory log, and administrators look after
deliveries, counts and customers' passwords from the pages themselves, without
opening phpMyAdmin.

Built with HTML, CSS, JavaScript, PHP and MySQL, and runs on XAMPP.

## Running it on XAMPP

Needs XAMPP with PHP 8.1 or newer.

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Copy this `app` folder into `C:\xampp\htdocs\` and name it `pcbuild`.
   Any name works; the links adapt to it.
3. Open <http://localhost/phpmyadmin>, choose **Import**, and import
   `sql/schema.sql`, then `sql/components.sql`. The first file creates the
   database itself. Importing it again deletes everything in the database and
   starts fresh.
4. Open <http://localhost/pcbuild/>.

**Optional: demonstration sales.** A fresh database has sold nothing, so the
administrator's Sales page is empty. To show it working, import
`sql/demo-sales.sql` as well, after the other two: 18 made-up customers
(password **Demo@1234**) and a year of orders, counted back from the moment
it is imported. It touches no stock. Importing it again replaces the earlier
import; importing `schema.sql` again removes it with everything else. It is
written by `tools/make-demo-sales.php`, which picks every configuration with
the system's own rule engine.

Customers register themselves. The administrator account comes with the
database: **admin@pcbuild.local**, password **Admin@123**. Change that password
before the system is shown to anyone.

If MySQL has a password on your machine, put it in `DB_PASS` in
`includes/config.php`. Nothing else there needs changing.

If a page says the database is not running or has not been created, it also
says what to do: start MySQL, or import the two SQL files.

## Running it without XAMPP

PHP's own development server works too. From the repository root:

    php -S 127.0.0.1:8080 -t app tests/e2e/router.php

The router makes the development server answer like Apache. Point it at a
database elsewhere with the `DB_DSN`, `DB_USER` and `DB_PASS` environment
variables.

## Tests

Browser tests live in `tests/e2e`. They drive a real Chromium against a running
copy of the system:

    cd tests/e2e
    npm install
    BASE_URL=http://127.0.0.1:8080 node run.js

Each test has an id, such as T1.14, that matches the test record in
`docs/testing/test-record.md`.
