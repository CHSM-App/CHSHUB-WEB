// Website API — Maintenance bills.
// Replaces Society2024/maintenance_search.aspx and maintanance_report.aspx.
// Backed by sp_maintanance_cal.
const express = require('express');

const { query, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { int, optionalStr } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** One row per generated bill run (bill_id), not per flat. */
async function listBillRuns(societyId) {
  return query('sp_maintanance_cal', {
    operation: 'Grid_Show',
    society_id: SOC(societyId),
  });
}

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
