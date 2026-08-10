// Website API — Maintenance bills.
// Replaces Society2024/maintenance_search.aspx and maintanance_report.aspx.
// Backed by sp_maintanance_cal.
const express = require('express');

const { query, sql, getPool } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { int, optionalStr } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/**
 * One row per generated bill run (bill_id), not per flat.
 *
 * Grid_Show does not return bill_type, so a run's own rows are read for it:
 * a listing where the monthly bill and an ad-hoc levy both read "Bill
 * Generated" gives no way to tell which is which, and the two are raised by
 * different buttons over different charge heads.
 */
async function listBillRuns(societyId) {
  const runs = await query('sp_maintanance_cal', {
    operation: 'Grid_Show',
    society_id: SOC(societyId),
  });
  if (!runs.length) return runs;

  const pool = await getPool();
  const types = await pool
    .request()
    .input('society_id', sql.NVarChar(10), societyId)
    .query(`
      SELECT   bill_id, MIN(bill_type) AS bill_type
      FROM     dbo.maintenance_cal
      WHERE    society_id = @society_id
      GROUP BY bill_id
    `);

  const byId = new Map(types.recordset.map((r) => [Number(r.bill_id), Number(r.bill_type)]));
  return runs
    .map((r) => {
      const billType = byId.get(Number(r.bill_id));
      return {
        ...r,
        bill_type: billType ?? null,
        // 1 = gen_bill's monthly run, 0 = sp_new_maintenance's add-on run.
        bill_type_label: billType === 1 ? 'Regular' : billType === 0 ? 'Add-on' : null,
      };
    })
    // Newest first, by the date the run was raised. Grid_Show has no ORDER BY
    // at all, so the order was whatever the engine returned — which grouped
    // the regular runs above the add-on ones and buried February's add-on
    // below July's monthly bill.
    .sort((a, b) => {
      const byDate = new Date(b.gen_date) - new Date(a.gen_date);
      // Two runs can share a date when an add-on goes out alongside the
      // monthly bill; the later bill_id is the later run.
      return byDate !== 0 ? byDate : Number(b.bill_id) - Number(a.bill_id);
    });
}

/**
 * GET /api/web/billing/bills/charges — this month's add-on charge heads.
 *
 * These are what the New Maintenance modal is about to bill: Nature of
 * Charges / Amount / Amount Per Flat, each divided by the society's flat
 * count. Scoped to the current month, as maintenance_search.aspx was — the
 * panel is empty until a charge is raised.
 *
 * Not sp_society_expense's exfetch, which selects `charges` alone: the legacy
 * page then read row["amount"] off that result, a column the query never
 * returned. The window below is the one exfetch uses, with the amount kept.
 */
router.get(
  '/charges',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const monthly = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .query(`
        SELECT charge_id, charges, amount, created_at
        FROM   dbo.maintenance_charges
        -- 0 is add-on. This panel sits in the Add modal, which runs
        -- sp_new_maintenance over exactly these; charges_type 1 is the
        -- regular monthly set that gen_bill raises instead.
        --
        -- status = 1 for the same reason the procedure asks for it: an add-on
        -- is charged once, and the run switches its heads off afterwards.
        -- Listing them regardless showed parking and water at 846.15 per flat
        -- when both were already spent, so the modal promised charges the
        -- generate would raise at zero.
        --
        -- No window on created_at. sp_new_maintenance bills every active
        -- add-on head whenever it runs, with no month of its own, so a head
        -- raised on the 31st and billed on the 1st was charged to residents
        -- while this panel showed nothing. status = 1 already means "not yet
        -- billed" — the run switches heads off afterwards — which is the
        -- distinction the month filter was reaching for.
        WHERE  charges_type = 0
          AND  status = 1
          AND  society_id = @society_id
        ORDER BY created_at
      `);

    const charges = monthly.recordset ?? [];
    const totals = await query('sp_society_master', {
      operation: 'TotalFlats',
      society_id: SOC(req.societyId),
    });

    // Guard the divisor: the legacy page fell back to 1 rather than dividing
    // by zero for a society with no flats on file.
    const flats = Number(totals[0]?.flats) || 1;

    return ok(res, {
      flats,
      items: charges.map((c) => ({
        ...c,
        amount_per_flat: Math.round((Number(c.amount ?? 0) / flats) * 100) / 100,
      })),
      count: charges.length,
    });
  }),
);

/** GET /api/web/billing/bills?year=&month= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const year = int(req.query.year, 'year', { min: 2000, max: 2100, required: false });
    const month = int(req.query.month, 'month', { min: 1, max: 12, required: false });

    let rows = await listBillRuns(req.societyId);
    if (year) rows = rows.filter((r) => Number(r.year) === year);
    if (month) rows = rows.filter((r) => Number(r.month) === month);

    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /api/web/billing/bills/:billId?flatId=
 *
 * Full bill detail: one row per flat in the run, or a single flat when flatId
 * is supplied. The SP builds this with dynamic SQL that pivots each society's
 * charge heads into col*_name / col*_amount pairs, so the column set varies by
 * society — the client renders whatever pairs come back.
 */
router.get(
  '/:billId',
  asyncHandler(async (req, res) => {
    const billId = int(req.params.billId, 'billId', { min: 1 });
    const flatId = int(req.query.flatId, 'flatId', { min: 1, required: false, default: 0 });

    // Confirm the run belongs to this society before returning anything.
    const runs = await listBillRuns(req.societyId);
    const run = runs.find((r) => Number(r.bill_id) === billId);
    if (!run) throw ApiError.notFound('Bill not found');

    const rows = await query('sp_maintanance_cal', {
      operation: 'Select',
      bill_id: { type: sql.Int, value: billId },
      flat_id: { type: sql.Int, value: flatId },
      society_id: SOC(req.societyId),
    });

    // Charge columns are dynamic; surface the pairs present so the UI can render
    // them without hardcoding a society's chart of charges.
    const chargeColumns = rows[0]
      ? Object.keys(rows[0])
          .filter((k) => /^col\d+_name$/.test(k))
          .map((nameKey) => ({ nameKey, amountKey: nameKey.replace('_name', '_amount') }))
          .filter((pair) => pair.amountKey in rows[0])
      : [];

    return ok(res, { run, items: rows, count: rows.length, chargeColumns });
  }),
);

/** GET /api/web/billing/bills/:billId/flat/:flatId — a single flat's bill. */
router.get(
  '/:billId/flat/:flatId',
  asyncHandler(async (req, res) => {
    const billId = int(req.params.billId, 'billId', { min: 1 });
    const flatId = int(req.params.flatId, 'flatId', { min: 1 });

    const runs = await listBillRuns(req.societyId);
    if (!runs.some((r) => Number(r.bill_id) === billId)) throw ApiError.notFound('Bill not found');

    const rows = await query('sp_maintanance_cal', {
      operation: 'Select',
      bill_id: { type: sql.Int, value: billId },
      flat_id: { type: sql.Int, value: flatId },
      society_id: SOC(req.societyId),
    });
    if (!rows[0]) throw ApiError.notFound('No bill for that flat in this run');

    return ok(res, { bill: rows[0] });
  }),
);

/** GET /api/web/billing/defaulters — flats with dues past their due date. */
router.get(
  '/reports/defaulters',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_dashboard', {
      operation: 'defaulter_show',
      society_id: { type: sql.NVarChar(50), value: req.societyId },
    });
    const total = rows.reduce((sum, r) => sum + Number(r.due || 0), 0);
    return ok(res, { items: rows, count: rows.length, totalDue: total });
  }),
);

module.exports = router;
