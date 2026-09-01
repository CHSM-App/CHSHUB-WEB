// Website API — Account settings. Replaces Society2024/account_setting.aspx.
// Backed by sp_account_setting (one row per society in account_setting).
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ok, asyncHandler } = require('../../lib/http');
const { int, num, bool, oneOf, optionalStr } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** Which officers sign the society's NOC certificate. */
const NOC_SIGNATORIES = ['Both', 'Secretary', 'Chairman'];

/**
 * How many of the society's officers have to approve a NOC request.
 *
 * A request goes to every office the society has — admin, secretary, chairman.
 * 'Any' settles it on the first approval; 'All' waits for every one of them.
 * Separate from the signatory setting: who signs the printed letter and who has
 * to agree before it is written are different questions.
 */
const NOC_APPROVAL_MODES = ['Any', 'All'];

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
 * The ON/OFF switches account_setting.aspx showed as OFF/ON dropdowns. Stored
 * as int 0/1, so they are read and written as numbers, not bits.
 *
 * Keyed by request field -> SP parameter, since the two names differ.
 */
const TOGGLES = [
  ['memberOpeningBalance', 'mem_open_bal'],
  ['memberChargesButton', 'mem_charge_btn'],
  ['memberChargeAllocation', 'mem_charge_allocation'],
  ['receiptsButton', 'receipt_btn'],
  ['gstRounding', 'gst_round'],
  ['chargesRounding', 'charge_round'],
  ['paymentVoucherMultiEntry', 'payment_voucher'],
  ['debitNoteVoucherMultiEntry', 'debit_note_voucher'],
  ['creditNoteVoucherMultiEntry', 'credit_note_voucher'],
  ['journalVoucherMultiEntry', 'general_voucher'],
  ['receiptVoucherMultiEntry', 'receipt_voucher'],
  ['buildingWisePayment', 'build_wise_payment'],
  ['reminderEmailForDues', 'remainder_email_dues'],
];

/**
 * PUT /api/web/settings/account
 *
 * Two SP calls, because neither branch of sp_account_setting covers the whole
 * screen and both are in use by the legacy app:
 *
 *   'Insert' — despite the name an upsert on society_id. Writes the rates,
 *              auto-generation flag, bill dates and interest rate.
 *   'Update' — writes the ON/OFF switches, but keys off @acc_set_id and does
 *              not touch auto_bill_generation / bill_gen_date / bill_due_period.
 *
 * 'Insert' runs first so a society with no row yet gets one, and the acc_set_id
 * to key the second call by is then guaranteed to exist. Sending only the
 * switches through 'Update' would blank the rates, since that branch writes
 * rate columns too — so the rates are passed to both.
 */
router.put(
  '/',
  asyncHandler(async (req, res) => {
    const body = req.body ?? {};

    // Parsed once: both SP calls write the rate columns, and they must agree.
    const rates = {
      ratePerSqFt: num(body.ratePerSqFt, 'ratePerSqFt', { min: 0, required: false, default: 0 }),
      twoWheelerRate: num(body.twoWheelerRate, 'twoWheelerRate', { min: 0, required: false, default: 0 }),
      fourWheelerRate: num(body.fourWheelerRate, 'fourWheelerRate', { min: 0, required: false, default: 0 }),
    };

    await exec('sp_account_setting', {
      operation: 'Insert',
      society_id: SOC(req.societyId),
      rate_per_sqf: { type: sql.Decimal(10, 2), value: rates.ratePerSqFt },
      two_w_rate: { type: sql.Decimal(10, 2), value: rates.twoWheelerRate },
      four_w_rate: { type: sql.Decimal(10, 2), value: rates.fourWheelerRate },
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
      /*
       * Who signs the society's NOC certificate, and what they are called on
       * it. Each society sets its own: how many officers sign is fixed by its
       * bye-laws and by whoever is being asked to act on the certificate, and
       * a chairman is a President in plenty of societies.
       *
       * Absent leaves the stored choice alone — the procedure treats NULL as
       * "unchanged" — so a client that does not know about these fields cannot
       * blank them.
       */
      noc_signatories: {
        type: sql.NVarChar(20),
        value: oneOf(body.nocSignatories, 'nocSignatories', NOC_SIGNATORIES, {
          required: false,
        }),
      },
      noc_secretary_label: {
        type: sql.NVarChar(60),
        value: optionalStr(body.nocSecretaryLabel, 'nocSecretaryLabel', { max: 60 }),
      },
      noc_chairman_label: {
        type: sql.NVarChar(60),
        value: optionalStr(body.nocChairmanLabel, 'nocChairmanLabel', { max: 60 }),
      },
      noc_approval_mode: {
        type: sql.NVarChar(10),
        value: oneOf(body.nocApprovalMode, 'nocApprovalMode', NOC_APPROVAL_MODES, {
          required: false,
        }),
      },
    });

    // Second pass for the switches. The row is guaranteed to exist now, so the
    // acc_set_id read back here always keys the UPDATE branch rather than
    // falling into its INSERT (which would create a duplicate row).
    const current = await readSettings(req.societyId);
    const accSetId = int(current?.acc_set_id, 'acc_set_id', { required: false, default: 0 });

    if (accSetId) {
      await exec('sp_account_setting', {
        operation: 'Update',
        acc_set_id: { type: sql.Int, value: accSetId },
        society_id: SOC(req.societyId),
        // Rates repeated: the 'Update' branch writes these columns too, and
        // omitting them would reset what the call above just saved.
        rate_per_sqf: { type: sql.Decimal(10, 2), value: rates.ratePerSqFt },
        two_w_rate: { type: sql.Decimal(10, 2), value: rates.twoWheelerRate },
        four_w_rate: { type: sql.Decimal(10, 2), value: rates.fourWheelerRate },
        ...Object.fromEntries(
          TOGGLES.map(([field, param]) => [
            param,
            {
              type: sql.Int,
              // Absent means "leave as-is": fall back to the stored value so a
              // partial payload cannot silently switch settings off.
              value: bool(body[field], field, { default: Boolean(current?.[param]) }) ? 1 : 0,
            },
          ]),
        ),
      });
    }

    return ok(res, { settings: await readSettings(req.societyId) });
  }),
);

module.exports = router;
