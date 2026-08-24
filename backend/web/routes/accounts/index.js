// Website API — Accounts.
// Replaces society_expense, ledger_form, shop_maintenance, other_credits,
// cashbook, society_receipt, VendorBill and vendor_bill_payments.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const SOC50 = (v) => ({ type: sql.NVarChar(50), value: v });

/* ---------------------------------------------------------------- expenses */

router.get(
  '/expenses',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_society_expense', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/expenses/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_society_expense', {
      operation: 'Select',
      expense_id: { type: sql.Int, value: id },
    });
    if (!rows[0] || String(rows[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Expense not found');
    }
    // Approvers live in vendor_bill_approval keyed by the expense id — see
    // saveExpenseApprovers — so the same GET_APPROVALS read serves both.
    const approvals = await query('sp_vendor_bills', {
      operation: 'GET_APPROVALS',
      bill_id: { type: sql.Int, value: id },
    });
    return ok(res, { expense: rows[0], approvals });
  }),
);

/** Shared field mapping. The SP generates the invoice number on insert. */
function expenseParams(body) {
  return {
    date: { type: sql.SmallDateTime, value: date(body?.date, 'date', { required: false }) },
    ex_type: { type: sql.NVarChar(50), value: optionalStr(body?.expenseType, 'expenseType', { max: 50 }) },
    ex_name: { type: sql.NVarChar(50), value: str(body?.name, 'name', { max: 50 }) },
    ex_details: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.details, 'details') },
    comments: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.comments, 'comments') },
    amount: { type: sql.Float, value: num(body?.amount, 'amount', { min: 0 }) },
    tax: { type: sql.Float, value: num(body?.tax, 'tax', { min: 0, required: false, default: 0 }) },
    tds: { type: sql.Float, value: num(body?.tds, 'tds', { min: 0, required: false, default: 0 }) },
    f_amount: { type: sql.Float, value: num(body?.finalAmount, 'finalAmount', { min: 0 }) },
    regular: { type: sql.Int, value: int(body?.regular, 'regular', { min: 0, max: 1, required: false, default: 0 }) },
  };
}

/*
 * Approvers for an expense. society_expense.aspx.cs looped the approver grid
 * after saving and called sp_approvar for each row, passing the expense id in
 * the SP's bill_id parameter (see DA_Society_Expense.Update_Approver) — the
 * same vendor_bill_approval table vendor bills use. Kept that way so both
 * pages read back through the one GET_APPROVALS path.
 */
async function saveExpenseApprovers(expenseId, body) {
  const ids = Array.isArray(body?.approverIds) ? body.approverIds : [];
  const errors = [];
  for (const userId of ids) {
    try {
      await exec('sp_approvar', {
        operation: 'Update',
        approver_id: { type: sql.Int, value: 0 },
        user_id: { type: sql.Int, value: int(userId, 'approverIds', { min: 1 }) },
        bill_id: { type: sql.Int, value: Number(expenseId) },
        approval_status: { type: sql.Int, value: 1 },
      });
    } catch (err) {
      errors.push({ userId, error: err.message });
    }
  }
  return errors;
}

router.post(
  '/expenses',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_society_expense', {
      operation: 'Update',
      expense_id: { type: sql.Int, value: 0 },
      user_id: { type: sql.Int, value: req.user.userId },
      society_id: SOC(req.societyId),
      ...expenseParams(req.body),
    });
    const expenseId = created?.expense_id ?? null;
    const approverErrors = expenseId ? await saveExpenseApprovers(expenseId, req.body) : [];
    return ok(res, { expense_id: expenseId, approverErrors }, 201);
  }),
);

router.put(
  '/expenses/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const existing = await query('sp_society_expense', {
      operation: 'Select',
      expense_id: { type: sql.Int, value: id },
    });
    if (!existing[0] || String(existing[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Expense not found');
    }

    await exec('sp_society_expense', {
      operation: 'Update',
      expense_id: { type: sql.Int, value: id },
      invoice_no: { type: sql.NVarChar(50), value: existing[0].invoice_no },
      user_id: { type: sql.Int, value: req.user.userId },
      society_id: SOC(req.societyId),
      ...expenseParams(req.body),
    });
    const approverErrors = await saveExpenseApprovers(id, req.body);
    return ok(res, { expense_id: id, approverErrors });
  }),
);

router.delete(
  '/expenses/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_society_expense', {
      operation: 'Delete',
      expense_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, expense_id: id });
  }),
);

/* ------------------------------------------------------------------ ledger */

router.get(
  '/ledger',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_ledger', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC50(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/ledger',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_ledger', {
      operation: 'Update',
      led_id: { type: sql.Int, value: 0 },
      led_description: { type: sql.NVarChar(sql.MAX), value: str(req.body?.description, 'description') },
      led_status: { type: sql.NVarChar(50), value: optionalStr(req.body?.status, 'status', { max: 50 }) },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { led_id: created?.led_id ?? null }, 201);
  }),
);

router.put(
  '/ledger/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_ledger', {
      operation: 'Update',
      led_id: { type: sql.Int, value: id },
      led_description: { type: sql.NVarChar(sql.MAX), value: str(req.body?.description, 'description') },
      led_status: { type: sql.NVarChar(50), value: optionalStr(req.body?.status, 'status', { max: 50 }) },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { led_id: id });
  }),
);

router.delete(
  '/ledger/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_ledger', { operation: 'Delete', led_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, led_id: id });
  }),
);

/* -------------------------------------------------------- shop maintenance */

router.get(
  '/shop-maintenance',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_shop_maintenance', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC50(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

function shopParams(body) {
  return {
    // shop_maintenance.mrep_no is nvarchar(50) — declaring 200 here let a
    // longer receipt no. through validation and silently truncated it.
    mrep_no: { type: sql.NVarChar(50), value: str(body?.reportNo, 'reportNo', { max: 50 }) },
    m_date: { type: sql.SmallDateTime, value: date(body?.date, 'date', { required: false }) },
    led_id: { type: sql.Int, value: int(body?.ledgerId, 'ledgerId', { min: 1 }) },
    other_details: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.details, 'details') },
    amt: { type: sql.Int, value: int(body?.amount, 'amount', { min: 0 }) },
    pay_method: { type: sql.NVarChar(50), value: optionalStr(body?.payMethod, 'payMethod', { max: 50 }) },
    cheq_no: { type: sql.NVarChar(50), value: optionalStr(body?.chequeNo, 'chequeNo', { max: 50 }) },
    cheq_date: { type: sql.SmallDateTime, value: date(body?.chequeDate, 'chequeDate', { required: false }) },
  };
}

router.post(
  '/shop-maintenance',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_shop_maintenance', {
      operation: 'Update',
      shop_maint_id: { type: sql.Int, value: 0 },
      society_id: SOC50(req.societyId),
      ...shopParams(req.body),
    });
    return ok(res, { shop_maint_id: created?.shop_maint_id ?? null }, 201);
  }),
);

router.put(
  '/shop-maintenance/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_shop_maintenance', {
      operation: 'Update',
      shop_maint_id: { type: sql.Int, value: id },
      society_id: SOC50(req.societyId),
      ...shopParams(req.body),
    });
    return ok(res, { shop_maint_id: id });
  }),
);

// The legacy page's delete wrote to shop_vw — a three-table join, which SQL
// Server refuses — so it never worked and no route was ported. FIX_shop_
// maintenance.sql points the soft delete at the base table.
router.delete(
  '/shop-maintenance/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_shop_maintenance', {
      operation: 'Delete',
      shop_maint_id: { type: sql.Int, value: id },
      society_id: SOC50(req.societyId),
    });
    return ok(res, { deleted: true, shop_maint_id: id });
  }),
);

/* ---------------------------------------------------------- other credits */

router.get(
  '/other-credits',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_ManageOtherCredits', {
      Operation: 'SELECT',
      society_id: { type: sql.NVarChar(20), value: req.societyId },
    });
    const total = rows.reduce((s, r) => s + Number(r.Amount || 0), 0);
    return ok(res, { items: rows, count: rows.length, total });
  }),
);

router.post(
  '/other-credits',
  asyncHandler(async (req, res) => {
    const result = await exec('sp_ManageOtherCredits', {
      Operation: 'INSERT',
      Description: { type: sql.NVarChar(255), value: str(req.body?.description, 'description', { max: 255 }) },
      Amount: { type: sql.Decimal(18, 2), value: num(req.body?.amount, 'amount', { min: 0.01 }) },
      payment_date: { type: sql.DateTime, value: date(req.body?.paymentDate, 'paymentDate', { required: false }) },
      society_id: { type: sql.NVarChar(20), value: req.societyId },
    });
    // The SP returns { Result, Status, Message } rather than throwing.
    if (result && result.Status === 'Error') throw ApiError.badRequest(result.Message);
    return ok(res, { id: result?.Result ?? null }, 201);
  }),
);

router.put(
  '/other-credits/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const result = await exec('sp_ManageOtherCredits', {
      Operation: 'UPDATE',
      Id: { type: sql.Int, value: id },
      Description: { type: sql.NVarChar(255), value: str(req.body?.description, 'description', { max: 255 }) },
      Amount: { type: sql.Decimal(18, 2), value: num(req.body?.amount, 'amount', { min: 0.01 }) },
      payment_date: { type: sql.DateTime, value: date(req.body?.paymentDate, 'paymentDate', { required: false }) },
      society_id: { type: sql.NVarChar(20), value: req.societyId },
    });
    if (result && result.Status === 'Error') throw ApiError.badRequest(result.Message);
    return ok(res, { id });
  }),
);

router.delete(
  '/other-credits/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const result = await exec('sp_ManageOtherCredits', {
      Operation: 'DELETE',
      Id: { type: sql.Int, value: id },
      society_id: { type: sql.NVarChar(20), value: req.societyId },
    });
    if (result && result.Status === 'Error') throw ApiError.badRequest(result.Message);
    return ok(res, { deleted: true, id });
  }),
);

/* ---------------------------------------------------------------- cashbook */

router.get(
  '/cashbook',
  asyncHandler(async (req, res) => {
    const from = date(req.query.from, 'from');
    const to = date(req.query.to, 'to');

    const rows = await query('sp_cashbook', {
      operation: 'cashbook',
      society_id: SOC(req.societyId),
      date1: { type: sql.SmallDateTime, value: from },
      date2: { type: sql.SmallDateTime, value: to },
    });
    // seq 1 = opening, 2 = transactions, 3 = closing.
    return ok(res, {
      items: rows,
      opening: rows.find((r) => Number(r.seq) === 1) ?? null,
      closing: rows.find((r) => Number(r.seq) === 3) ?? null,
      transactions: rows.filter((r) => Number(r.seq) === 2),
    });
  }),
);

/* -------------------------------------------------------- society receipts */

router.get(
  '/society-receipts',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_SocietyReceipt', {
      operation: 'show_history',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

module.exports = router;
