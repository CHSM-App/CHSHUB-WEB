// Website API — Account settings. Replaces Society2024/account_setting.aspx.
// Backed by sp_account_setting (one row per society in account_setting).
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ok, asyncHandler } = require('../../lib/http');
const { int, num, bool } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/**
 * The account_setting row drives billing: rate per sq.ft., parking rates,
 * whether bills auto-generate, and the billing/due day-of-month.
 */
async function readSettings(societyId) {
  const rows = await query('sp_account_setting', {
    operation: 'select',
    society_id: SOC(societyId),
  });
  return rows[0] ?? null;
}

/** GET /api/web/settings/account */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const settings = await readSettings(req.societyId);
    return ok(res, { settings });
  }),
);

/**
 * PUT /api/web/settings/account
 *
 * Uses @operation='Insert', which despite the name is an upsert: it updates
 * when a row exists for the society and inserts otherwise. The 'Update' branch
 * is not used — it keys off @acc_set_id and writes a different column set that
 * omits the billing fields this screen edits.
 */
router.put(
  '/',
  asyncHandler(async (req, res) => {
    const body = req.body ?? {};

    await exec('sp_account_setting', {
      operation: 'Insert',
      society_id: SOC(req.societyId),
      rate_per_sqf: {
        type: sql.Decimal(10, 2),
        value: num(body.ratePerSqFt, 'ratePerSqFt', { min: 0, required: false, default: 0 }),
      },
      two_w_rate: {
        type: sql.Decimal(10, 2),
        value: num(body.twoWheelerRate, 'twoWheelerRate', { min: 0, required: false, default: 0 }),
      },
      four_w_rate: {
        type: sql.Decimal(10, 2),
        value: num(body.fourWheelerRate, 'fourWheelerRate', { min: 0, required: false, default: 0 }),
      },
      auto_bill_generation: {
        type: sql.Bit,
        value: bool(body.autoBillGeneration, 'autoBillGeneration', { default: false }),
      },
      // Day of month the bill is raised, and how many days later it falls due.
      bill_gen_date: {
        type: sql.Int,
        value: int(body.billGenerationDay, 'billGenerationDay', {
          min: 1,
          max: 31,
          required: false,
          default: 1,
        }),
      },
      bill_due_period: {
        type: sql.Int,
        value: int(body.billDuePeriodDays, 'billDuePeriodDays', {
          min: 0,
          max: 365,
          required: false,
          default: 0,
        }),
      },
      // Annual rate gen_bill charges on arrears. Capped at 21%, the ceiling
      // the Co-operative Societies Act allows. It was hardcoded to 21 in the
      // procedure's INSERT and never written on update, so a society that had
      // resolved on a different rate — or none — could not apply it.
      interest_rate: {
        type: sql.Decimal(18, 2),
        value: num(body.interestRate, 'interestRate', { min: 0, max: 21, required: false }),
      },
    });

    return ok(res, { settings: await readSettings(req.societyId) });
  }),
);

module.exports = router;
