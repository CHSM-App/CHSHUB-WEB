// Website API — Bill generation.
//
// FINANCIAL WRITE PATH. These endpoints create maintenance_cal rows — real
// charges against residents. Two safeguards apply:
//
//   1. A preview endpoint (GET /preview) reports exactly what would be billed,
//      reading only. Call it first.
//   2. The POST requires an explicit `confirm: true` in the body. Without it the
//      request is rejected, so a stray click or replayed URL cannot raise bills.
//
// Neither procedure is transactional and neither is idempotent by itself:
//   * gen_bill guards internally — it skips a society that already has a
//     bill_type=1 run in the current month — so a second call in the same month
//     is a no-op for regular bills.
//   * sp_new_maintenance ('generate') has NO such guard: every call creates a
//     new add-on bill run. The API therefore refuses a second add-on run within
//     the same calendar day unless `allowDuplicate: true` is passed. A regular
//     run earlier the same day does not count — different charges, not a repeat.
const express = require('express');

const { query, exec, sql, getPool } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { int, num, bool } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** Bills already generated for this society. */
async function billRuns(societyId) {
  return query('sp_maintanance_cal', { operation: 'Grid_Show', society_id: SOC(societyId) });
}

const sameMonth = (d, ref) =>
  d && d.getFullYear() === ref.getFullYear() && d.getMonth() === ref.getMonth();

/**
 * GET /api/web/billing/generate/preview
 *
 * Read-only. Reports what a run would charge: the active charge heads, the
 * per-flat division, the configured rates, and whether a run already exists
 * this month. Nothing is written.
 */
router.get(
  '/preview',
  asyncHandler(async (req, res) => {
    const [settingsRows, chargeRows, flatCountRows, runs] = await Promise.all([
      query('sp_account_setting', { operation: 'select', society_id: SOC(req.societyId) }),
      query('sp_maintenance_charges', { operation: 'grid_show', society_id: SOC(req.societyId) }),
      query('sp_flat_master', {
        operation: 'check_count',
        society_id: { type: sql.NVarChar(50), value: req.societyId },
      }),
      billRuns(req.societyId),
    ]);

    const settings = settingsRows[0] ?? null;
    const flatCount = Number(flatCountRows[0]?.flat ?? 0);

    const active = chargeRows.filter((c) => c.status === true || Number(c.status) === 1);
    const isRegular = (c) => c.charges_type === true || Number(c.charges_type) === 1;

    const summarise = (list) => {
      const total = list.reduce((sum, c) => sum + Number(c.amount || 0), 0);
      return {
        charges: list.map((c) => ({
          charge_id: c.charge_id,
          name: c.NatureOfCharge,
          amount: Number(c.amount || 0),
          perFlat: flatCount ? Number((Number(c.amount || 0) / flatCount).toFixed(2)) : null,
        })),
        totalAmount: total,
        perFlatTotal: flatCount ? Number((total / flatCount).toFixed(2)) : null,
      };
    };

    const now = new Date();
    const alreadyThisMonth = runs.some(
      (r) => sameMonth(r.gen_date ? new Date(r.gen_date) : null, now) && Number(r.month) === now.getMonth() + 1,
    );

    return ok(res, {
      flatCount,
      settings: settings && {
        ratePerSqFt: settings.rate_per_sqfeet,
        twoWheelerRate: settings.two_wheeler_rate,
        fourWheelerRate: settings.four_wheeler_rate,
        interestRate: settings.interest_rate,
        billGenerationDay: settings.bill_gen_date,
        billDuePeriodDays: settings.bill_due_period,
        autoBillGeneration: Boolean(settings.auto_bill_generation),
      },
      regular: summarise(active.filter(isRegular)),
      addOn: summarise(active.filter((c) => !isRegular(c))),
      existingRuns: runs.length,
      alreadyGeneratedThisMonth: alreadyThisMonth,
      warnings: [
        ...(flatCount === 0 ? ['No active flats — nothing would be billed.'] : []),
        ...(!settings ? ['No account settings configured for this society.'] : []),
        ...(alreadyThisMonth
          ? ['A bill run already exists for the current month; gen_bill will skip regular billing.']
          : []),
      ],
    });
  }),
);

/**
 * POST /api/web/billing/generate/regular
 * Body: { confirm: true }
 *
 * Runs gen_bill with @bill_type = 1 (manual trigger) scoped to this society.
 * gen_bill itself skips societies that already have a run this month.
 */
router.post(
  '/regular',
  asyncHandler(async (req, res) => {
    if (bool(req.body?.confirm, 'confirm', { default: false }) !== true) {
      throw ApiError.badRequest(
        'Bill generation must be confirmed. Send { "confirm": true } after reviewing GET /billing/generate/preview.',
      );
    }

    const before = (await billRuns(req.societyId)).length;

    // @bill_type = 1 means "manual run"; gen_bill then ignores the
    // auto_bill_generation flag and the day-of-month check.
    await exec('gen_bill', {
      bill_type: { type: sql.Int, value: 1 },
      society_id: SOC(req.societyId),
    });

    const runs = await billRuns(req.societyId);
    const generated = runs.length > before;

    return ok(res, {
      generated,
      runsBefore: before,
      runsAfter: runs.length,
      latestRun: runs[0] ?? null,
      message: generated
        ? 'Bill run created.'
        : 'No bills generated — a run already exists for this month, or there are no eligible flats.',
    });
  }),
);

/**
 * POST /api/web/billing/generate/addon
 * Body: { confirm: true, duePeriodMonths?, interestRate?, allowDuplicate? }
 *
 * Runs sp_new_maintenance ('generate') for add-on charges (charges_type = 0).
 * Unlike gen_bill this has no duplicate guard, so we add one.
 */
router.post(
  '/addon',
  asyncHandler(async (req, res) => {
    if (bool(req.body?.confirm, 'confirm', { default: false }) !== true) {
      throw ApiError.badRequest(
        'Bill generation must be confirmed. Send { "confirm": true } after reviewing GET /billing/generate/preview.',
      );
    }

    const runs = await billRuns(req.societyId);

    // Only a previous *add-on* run counts as a duplicate. Grid_Show does not
    // return bill_type, so asking it would have blocked an add-on whenever a
    // regular bill had gone out the same day — two different charges, and the
    // second is not a repeat of the first.
    const pool = await getPool();
    const todays = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .query(`
        SELECT TOP 1 bill_id
        FROM   dbo.maintenance_cal
        WHERE  society_id = @society_id
          AND  bill_type = 0
          AND  gen_date >= CAST(GETDATE() AS DATE)
          AND  gen_date <  DATEADD(DD, 1, CAST(GETDATE() AS DATE))
        ORDER BY bill_id DESC
      `);
    const todaysAddOn = todays.recordset?.[0] ?? null;

    if (todaysAddOn && bool(req.body?.allowDuplicate, 'allowDuplicate', { default: false }) !== true) {
      throw ApiError.conflict(
        'An add-on run already exists for today. sp_new_maintenance does not guard against duplicates, so this would raise a second set of the same charges. Send { "allowDuplicate": true } only if that is intended.',
        { existingBillId: todaysAddOn.bill_id },
      );
    }

    const before = runs.length;

    await exec('sp_new_maintenance', {
      operation: 'generate',
      society_id: SOC(req.societyId),
      bill_type: { type: sql.Int, value: 0 },
      due_period: {
        type: sql.Int,
        value: int(req.body?.duePeriodMonths, 'duePeriodMonths', {
          min: 0,
          max: 12,
          required: false,
          default: 1,
        }),
      },
      interest: {
        type: sql.Decimal(18, 0),
        value: num(req.body?.interestRate, 'interestRate', { min: 0, required: false, default: 0 }),
      },
    });

    const after = await billRuns(req.societyId);
    return ok(res, {
      generated: after.length > before,
      runsBefore: before,
      runsAfter: after.length,
      latestRun: after[0] ?? null,
    });
  }),
);

module.exports = router;
