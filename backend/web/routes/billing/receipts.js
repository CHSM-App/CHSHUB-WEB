// Website API — Maintenance receipts.
// Replaces Society2024/maintenance_receipt.aspx and receipt_search_form.aspx.
// Backed by sp_MaintenanceReceipt.
//
// NOTE: this SP uses @Action (capitalised) rather than @operation, and its
// parameter names are PascalCase. Kept as-is; the API translates.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** GET /api/web/billing/receipts */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'Grid_Show',
      SocietyID: SOC(req.societyId),
    });
    const total = rows.reduce((sum, r) => sum + Number(r.paid_amount || 0), 0);
    return ok(res, { items: rows, count: rows.length, totalCollected: total });
  }),
);

/** GET /api/web/billing/receipts/residents — flats for the receipt form. */
router.get(
  '/residents',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'ResidentFill',
      SocietyID: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /api/web/billing/receipts/outstanding?flatId=
 * Unpaid/partly-paid bills for a flat, used to pick what a payment settles.
 */
router.get(
  '/outstanding',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });

    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'GetBills',
      FlatID: { type: sql.Int, value: flatId },
    });
    const total = rows.reduce((sum, r) => sum + Number(r.Amount || 0), 0);
    return ok(res, { items: rows, count: rows.length, totalOutstanding: total });
  }),
);

/**
 * GET /api/web/billing/receipts/advance?flatId=
 * Unapplied credit on a flat. sp_SettleMaintenancePayment parks any surplus
 * from a payment on maintenance_cal.advance, and nothing else surfaces it, so
 * without this an overpayment looks like money that vanished.
 */
router.get(
  '/advance',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });

    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'GetAdvance',
      FlatID: { type: sql.Int, value: flatId },
      SocietyID: SOC(req.societyId),
    });
    const row = rows[0] ?? {};
    return ok(res, {
      advanceAvailable: Number(row.AdvanceAvailable || 0),
      totalDue: Number(row.TotalDue || 0),
    });
  }),
);

/** GET /api/web/billing/receipts/pdc?flatId= — post-dated cheques on file. */
router.get(
  '/pdc',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });

    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'GetPDCCheque',
      FlatID: { type: sql.Int, value: flatId },
      SocietyID: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/billing/receipts/:id — receipt detail for viewing/printing. */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const rows = await query('sp_MaintenanceReceipt', {
      Action: 'GETRECEIPT',
      ReceiptID: { type: sql.Int, value: id },
    });
    const receipt = rows[0];
    if (!receipt || String(receipt.society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Receipt not found');
    }
    return ok(res, { receipt, lines: rows });
  }),
);

/**
 * POST /api/web/billing/receipts — record a payment.
 *
 * FINANCIAL WRITE. Inserts into `receipt` and then runs
 * sp_SettleMaintenancePayment, which allocates the amount across the selected
 * bills (interest first, then principal), marks them paid/partly paid, and
 * carries any surplus forward as advance.
 *
 * `bills` is the comma-separated list of bill_no values being settled — the
 * settlement proc splits it with STRING_SPLIT. The receipt table's bill_details
 * column is nvarchar(20), so the list is length-checked before insert to avoid
 * a silent truncation that would under-settle the payment.
 */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const flatId = int(req.body?.flatId, 'flatId', { min: 1 });
    const paidAmount = num(req.body?.paidAmount, 'paidAmount', { min: 0.01 });
    const payMode = str(req.body?.payMode, 'payMode', { max: 20 });

    const billNos = Array.isArray(req.body?.billNos) ? req.body.billNos : [];
    if (!billNos.length) throw ApiError.badRequest('At least one bill must be selected');
    const billList = billNos.map((b) => String(b).trim()).join(',');
    if (billList.length > 20) {
      throw ApiError.badRequest(
        'Too many bills selected to record in one receipt (receipt.bill_details holds 20 characters). Record the payment across several receipts.',
        { maxCharacters: 20, attempted: billList.length },
      );
    }

    const result = await exec('sp_MaintenanceReceipt', {
      Action: 'INSERT',
      SocietyID: SOC(req.societyId),
      FlatID: { type: sql.Int, value: flatId },
      PayMode: { type: sql.NVarChar(20), value: payMode },
      ChequeNo: { type: sql.NVarChar(30), value: optionalStr(req.body?.chequeNo, 'chequeNo', { max: 30 }) },
      ChequeDate: { type: sql.Date, value: date(req.body?.chequeDate, 'chequeDate', { required: false }) },
      BankName: { type: sql.NVarChar(100), value: optionalStr(req.body?.bankName, 'bankName', { max: 100 }) },
      TransactionRef: {
        type: sql.NVarChar(100),
        value: optionalStr(req.body?.transactionRef, 'transactionRef', { max: 100 }),
      },
      PaidAmount: { type: sql.Decimal(10, 2), value: paidAmount },
      Remarks: { type: sql.NVarChar(255), value: optionalStr(req.body?.remarks, 'remarks', { max: 255 }) },
      bills: { type: sql.NVarChar(20), value: billList },
      ReceiptDate: { type: sql.SmallDateTime, value: date(req.body?.receiptDate, 'receiptDate', { required: false }) },
      CreatedBy: { type: sql.NVarChar(50), value: String(req.user.userId) },
    });

    return ok(res, { receipt_id: result?.receipt_id ?? null }, 201);
  }),
);

/**
 * POST /api/web/billing/receipts/:id/cancel — reverse a receipt.
 * Sets status 2 (Cancelled) and clears the cheque number.
 */
router.post(
  '/:id/cancel',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await query('sp_MaintenanceReceipt', {
      Action: 'GETRECEIPT',
      ReceiptID: { type: sql.Int, value: id },
    });
    if (!existing[0] || String(existing[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Receipt not found');
    }

    await exec('sp_MaintenanceReceipt', {
      Action: 'CANCEL',
      ReceiptID: { type: sql.Int, value: id },
      Remarks: {
        type: sql.NVarChar(255),
        value: optionalStr(req.body?.remarks, 'remarks', { max: 255 }) || 'Cancelled',
      },
    });

    return ok(res, { cancelled: true, receipt_id: id });
  }),
);

module.exports = router;
