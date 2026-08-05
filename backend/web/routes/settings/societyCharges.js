// Website API — Society charges (the platform's per-unit fee to the society).
// Replaces Society2024/society_charges.aspx.
// Backed by sp_society_charges.
//
// Distinct from maintenance charges: this is what the society itself is billed,
// priced per unit and multiplied by total_unit.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ok, asyncHandler } = require('../../lib/http');
const { num, int } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** The society's own charge row, if one has been configured. */
async function current(societyId) {
  const rows = await query('sp_society_charges', {
    operation: 'society_exist',
    charge_id: { type: sql.Int, value: 0 },
    society_id: SOC(societyId),
  });
  return rows[0] ?? null;
}

/** GET /api/web/settings/society-charges */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    return ok(res, { charge: await current(req.societyId) });
  }),
);

/** PUT /api/web/settings/society-charges — upsert the society's charge row. */
router.put(
  '/',
  asyncHandler(async (req, res) => {
    const existing = await current(req.societyId);

    await exec('sp_society_charges', {
      operation: 'Update',
      charge_id: { type: sql.Int, value: existing ? Number(existing.charge_id) : 0 },
      // amount is declared NVARCHAR(50) on this SP even though the column is
      // decimal; pass the validated number as text so SQL Server converts once.
      amount: {
        type: sql.NVarChar(50),
        value: String(num(req.body?.amount, 'amount', { min: 0 })),
      },
      total_unit: {
        type: sql.Int,
        value: int(req.body?.totalUnits, 'totalUnits', { min: 0, required: false, default: 0 }),
      },
      society_id: SOC(req.societyId),
    });

    return ok(res, { charge: await current(req.societyId) });
  }),
);

module.exports = router;
