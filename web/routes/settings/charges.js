// Website API — Maintenance charges. Replaces Society2024/Charges.aspx.
// Backed by sp_maintenance_charges.
//
// charges_type distinguishes the two billing runs:
//   0 = add-on / ad-hoc charges (sp_new_maintenance)
//   1 = regular monthly maintenance (gen_bill)
// Each charge's amount is divided across the society's flats at bill time.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, int, num, bool, oneOf } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

async function listCharges(societyId) {
  return query('sp_maintenance_charges', {
    operation: 'grid_show',
    society_id: SOC(societyId),
  });
}

/** GET /api/web/settings/charges?chargesType=0|1 */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const chargesType = req.query.chargesType;
    let rows = await listCharges(req.societyId);

    if (chargesType !== undefined && chargesType !== '') {
      const wanted = oneOf(String(chargesType), 'chargesType', ['0', '1']);
      rows = rows.filter((r) => String(r.charges_type === true ? 1 : Number(r.charges_type)) === wanted);
    }

    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/settings/charges/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_maintenance_charges', {
      operation: 'select',
      society_id: SOC(req.societyId),
      charge_id: { type: sql.Int, value: id },
    });
    if (!rows[0]) throw ApiError.notFound('Charge not found');
    return ok(res, { charge: rows[0] });
  }),
);

function chargeParams(body, userId) {
  return {
    charges: { type: sql.NVarChar(200), value: str(body?.name, 'name', { max: 200 }) },
    amount: { type: sql.Decimal(18, 2), value: num(body?.amount, 'amount', { min: 0 }) },
    charges_type: {
      type: sql.Bit,
      // 1 = regular monthly, 0 = add-on. Default to regular.
      value: Number(oneOf(String(body?.chargesType ?? '1'), 'chargesType', ['0', '1'])),
    },
    status: { type: sql.Bit, value: bool(body?.active, 'active', { default: true }) },
    user_id: { type: sql.Int, value: userId },
  };
}

/**
 * POST /api/web/settings/charges
 *
 * The SP's 'insert' operation branches on @charge_id: 0 inserts, non-zero
 * updates. maintenance_charges.charge_id is an IDENTITY column, so unlike most
 * masters here there is no MAX(id)+1 race.
 */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    await exec('sp_maintenance_charges', {
      operation: 'insert',
      charge_id: { type: sql.Int, value: 0 },
      society_id: SOC(req.societyId),
      ...chargeParams(req.body, req.user.userId),
    });

    const rows = await listCharges(req.societyId); // ordered charge_id DESC
    return ok(res, { charge: rows[0] ?? null }, 201);
  }),
);

/** PUT /api/web/settings/charges/:id */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = (await listCharges(req.societyId)).find((r) => Number(r.charge_id) === id);
    if (!existing) throw ApiError.notFound('Charge not found');

    await exec('sp_maintenance_charges', {
      operation: 'insert', // same branch; non-zero charge_id updates
      charge_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      ...chargeParams(req.body, req.user.userId),
    });

    const charge = (await listCharges(req.societyId)).find((r) => Number(r.charge_id) === id) ?? null;
    return ok(res, { charge });
  }),
);

/**
 * DELETE /api/web/settings/charges/:id
 *
 * sp_maintenance_charges has no delete branch, and maintenance_charges has no
 * active_status column — the schema models retirement as status = 0, which also
 * excludes the charge from the next bill run. So "delete" deactivates.
 */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = (await listCharges(req.societyId)).find((r) => Number(r.charge_id) === id);
    if (!existing) throw ApiError.notFound('Charge not found');

    await exec('sp_maintenance_charges', {
      operation: 'insert',
      charge_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      charges: { type: sql.NVarChar(200), value: existing.NatureOfCharge },
      amount: { type: sql.Decimal(18, 2), value: existing.amount },
      charges_type: { type: sql.Bit, value: existing.charges_type ? 1 : 0 },
      status: { type: sql.Bit, value: 0 }, // retire
      user_id: { type: sql.Int, value: req.user.userId },
    });

    return ok(res, { deactivated: true, charge_id: id });
  }),
);

module.exports = router;
