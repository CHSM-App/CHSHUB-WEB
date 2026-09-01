#!/usr/bin/env node
/**
 * Bill-generation test harness — FOR A TEST / RESTORED DATABASE ONLY.
 *
 * Exercises the three financial write paths that must never be tried first on
 * production:
 *
 *   A  gen_bill                      regular monthly bill run
 *   B  sp_new_maintenance 'generate' add-on bill run
 *   C  sp_MaintenanceReceipt INSERT  -> sp_SettleMaintenancePayment
 *
 * It refuses to run unless BOTH are true:
 *   1. TEST_DB_CONNECTION is set (a separate connection string — it never uses
 *      the pool from routes/db.js, so it cannot touch production by accident).
 *   2. --i-understand-this-writes-data is passed.
 *
 * It additionally refuses if the target server/database looks like production.
 *
 * Usage:
 *   TEST_DB_CONNECTION="Server=localhost;Database=society_test;User Id=sa;Password=...;TrustServerCertificate=true" \
 *     node web/scripts/test-bill-generation.js --society C10001 --i-understand-this-writes-data
 *
 * Every step prints before/after row counts so the effect is auditable.
 */
const sql = require('mssql');

const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const value = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};

const CONN = process.env.TEST_DB_CONNECTION;
const SOCIETY = value('society', 'C10001');
const CONFIRMED = flag('i-understand-this-writes-data');

// Substrings that indicate the live server. Refuse if the target matches.
const PRODUCTION_MARKERS = ['winsome.grabweb.in'];

function refuse(message) {
  console.error(`\nREFUSING TO RUN\n  ${message}\n`);
  process.exit(1);
}

if (!CONN) {
  refuse(
    'TEST_DB_CONNECTION is not set.\n' +
      '  This harness writes financial data and must never run against production.\n' +
      '  Point it at a restored copy, e.g.\n' +
      '    TEST_DB_CONNECTION="Server=localhost;Database=society_test;User Id=sa;Password=...;TrustServerCertificate=true"',
  );
}
if (!CONFIRMED) {
  refuse('Pass --i-understand-this-writes-data to confirm. Nothing has been executed.');
}
for (const marker of PRODUCTION_MARKERS) {
  if (CONN.toLowerCase().includes(marker)) {
    refuse(`TEST_DB_CONNECTION points at "${marker}", which is the production server.`);
  }
}

const line = (s = '') => console.log(s);
const money = (v) => Number(v ?? 0).toFixed(2);

async function counts(pool, society) {
  const q = async (text) => (await pool.request().query(text)).recordset[0].c;
  return {
    bills: await q(`select count(*) c from maintenance_cal where society_id='${society}'`),
    runs: await q(`select count(distinct bill_id) c from maintenance_cal where society_id='${society}'`),
    receipts: await q(`select count(*) c from receipt where society_id='${society}'`),
    billed: await q(
      `select isnull(sum(total_amount),0) c from maintenance_cal where society_id='${society}'`,
    ),
    due: await q(`select isnull(sum(due),0) c from maintenance_cal where society_id='${society}'`),
  };
}

function report(label, before, after) {
  line(`\n  ${label}`);
  for (const key of Object.keys(before)) {
    const delta = Number(after[key]) - Number(before[key]);
    const arrow = delta === 0 ? '=' : delta > 0 ? '+' : '';
    line(
      `    ${key.padEnd(9)} ${String(money(before[key])).padStart(12)} -> ${String(money(after[key])).padStart(12)}  (${arrow}${money(delta)})`,
    );
  }
}

(async () => {
  line('Bill-generation test harness');
  line(`  target society : ${SOCIETY}`);
  line(`  connection     : ${CONN.replace(/Password=[^;]*/i, 'Password=***')}`);

  const pool = await new sql.ConnectionPool(CONN).connect();

  try {
    const dbName = (await pool.request().query('select db_name() n')).recordset[0].n;
    line(`  database       : ${dbName}`);
    if (/^society$/i.test(dbName)) {
      refuse(`Connected database is "${dbName}" — that is the production database name.`);
    }

    const start = await counts(pool, SOCIETY);
    line('\n  starting state:');
    Object.entries(start).forEach(([k, v]) => line(`    ${k.padEnd(9)} ${money(v)}`));

    // ---- A: regular bill run -------------------------------------------
    line('\n[A] gen_bill @bill_type=1 (regular monthly run)');
    let before = await counts(pool, SOCIETY);
    await pool
      .request()
      .input('bill_type', sql.Int, 1)
      .input('society_id', sql.NVarChar(10), SOCIETY)
      .execute('gen_bill');
    let after = await counts(pool, SOCIETY);
    report('effect:', before, after);

    // Re-run: gen_bill should skip, having already billed this month.
    line('\n[A2] gen_bill again — expect NO new bills (idempotence guard)');
    before = after;
    await pool
      .request()
      .input('bill_type', sql.Int, 1)
      .input('society_id', sql.NVarChar(10), SOCIETY)
      .execute('gen_bill');
    after = await counts(pool, SOCIETY);
    report('effect:', before, after);
    if (after.bills !== before.bills) {
      line('    WARNING: a second run created more bills — the month guard did not hold.');
    }

    // ---- C: receipt + settlement ---------------------------------------
    line('\n[C] sp_MaintenanceReceipt INSERT -> sp_SettleMaintenancePayment');
    const open = (
      await pool.request().query(
        `select top 1 flat_id, bill_no, due from maintenance_cal
         where society_id='${SOCIETY}' and due > 0 order by due_date asc`,
      )
    ).recordset[0];

    if (!open) {
      line('    no outstanding bill to settle — skipped.');
    } else {
      line(`    settling flat ${open.flat_id}, bill_no ${open.bill_no}, due ${money(open.due)}`);
      before = await counts(pool, SOCIETY);
      await pool
        .request()
        .input('Action', sql.NVarChar(20), 'INSERT')
        .input('SocietyID', sql.NVarChar(10), SOCIETY)
        .input('FlatID', sql.Int, open.flat_id)
        .input('PayMode', sql.NVarChar(20), 'Cash')
        .input('PaidAmount', sql.Decimal(10, 2), open.due)
        .input('bills', sql.NVarChar(20), String(open.bill_no))
        .input('Remarks', sql.NVarChar(255), 'test-harness')
        .input('CreatedBy', sql.NVarChar(50), '0')
        .execute('sp_MaintenanceReceipt');
      after = await counts(pool, SOCIETY);
      report('effect:', before, after);
      line('    expected: receipts +1, due decreased by the settled amount.');
    }

    // ---- B: add-on run --------------------------------------------------
    line('\n[B] sp_new_maintenance @operation=generate (add-on run)');
    before = await counts(pool, SOCIETY);
    await pool
      .request()
      .input('operation', sql.NVarChar(50), 'generate')
      .input('society_id', sql.NVarChar(10), SOCIETY)
      .input('bill_type', sql.Int, 0)
      .input('due_period', sql.Int, 1)
      .input('interest', sql.Decimal(18, 0), 0)
      .execute('sp_new_maintenance');
    after = await counts(pool, SOCIETY);
    report('effect:', before, after);
    line('    note: sp_new_maintenance has NO duplicate guard — each call bills again.');

    const end = await counts(pool, SOCIETY);
    line('\n  net change over the whole run:');
    Object.keys(start).forEach((k) =>
      line(`    ${k.padEnd(9)} ${money(start[k])} -> ${money(end[k])}`),
    );
    line('\nDone. Review the deltas above before enabling generation in the UI.');
  } finally {
    await pool.close();
  }
})().catch((err) => {
  console.error('\nHarness failed:', err.message);
  process.exit(1);
});
