// Website API — vendor bills, full parity with Society2024/VendorBill.aspx.
//
// That page carries four distinct workflows behind one screen:
//
//   1. Create bill — service type drives which sub-form applies:
//        0 Staff Payment            -> pick staff, per-head salary, payment required
//        1 Daily Expense            -> free-text description + cost
//        2 Vendor-Inventory Payment -> line items, each becomes an inventory row
//        3 Vendor-Service Payment   -> description + cost against a vendor
//   2. Quick-add vendor without leaving the page.
//   3. Approvers — pick committee members, then approve/reject with remarks.
//   4. Payment — cheque / online / cash, against one or more bills.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, oneOf } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** Service types, matching ddlSevice on the legacy page. */
const SERVICE_TYPES = [
  { id: 0, name: 'Staff Payment' },
  { id: 1, name: 'Daily Expense' },
  { id: 2, name: 'Vendor-Inventory Payment' },
  { id: 3, name: 'Vendor-Service Payment' },
];

/** GET /accounts/vendor-bills/service-types */
router.get(
  '/service-types',
  asyncHandler(async (_req, res) => ok(res, { items: SERVICE_TYPES })),
);

/**
 * GET /accounts/vendor-bills/form-data
 * Everything the create form needs in one call: vendors, staff (with salary),
 * staff roles, approver candidates and maintenance charge heads.
 */
router.get(
  '/form-data',
  asyncHandler(async (req, res) => {
    const soc = SOC(req.societyId);
    const safe = (p) => p.catch(() => []);

    const [vendors, staff, roles, approvers, charges] = await Promise.all([
      safe(query('sp_vendor_bills', { operation: 'vendor_fill', society_id: soc })),
      safe(query('sp_staff_master', {
        operation: 'Grid_Show',
        society_id: { type: sql.NVarChar(50), value: req.societyId },
      })),
      safe(query('sp_staff_master', { operation: 'Role_Show' })),
      safe(query('sp_vendor_bills', {
        operation: 'add_approver',
        society_id: soc,
        user_id: { type: sql.Int, value: req.user.userId },
      })),
      safe(query('sp_vendor_bills', { operation: 'exfetch', society_id: soc })),
    ]);

    return ok(res, {
      serviceTypes: SERVICE_TYPES,
      vendors,
      staff,
      staffRoles: roles,
      approvers,
      chargeHeads: charges,
    });
  }),
);

/** GET /accounts/vendor-bills/staff?roleId= — staff for the salary sub-form. */
router.get(
  '/staff',
  asyncHandler(async (req, res) => {
    const roleId = int(req.query.roleId, 'roleId', { min: 1, required: false });

    const rows = roleId
      ? await query('sp_staff_master', {
          operation: 'FetchStaffData',
          role_id: { type: sql.Int, value: roleId },
          society_id: { type: sql.NVarChar(50), value: req.societyId },
        })
      : await query('sp_staff_master', {
          operation: 'Grid_Show',
          society_id: { type: sql.NVarChar(50), value: req.societyId },
        });

    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /accounts/vendor-bills — the bill grid. */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_vendor_bills', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /accounts/vendor-bills/:id — bill, its items and its approvals. */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const rows = await query('sp_vendor_bills', {
      operation: 'SELECT',
      bill_id: { type: sql.Int, value: id },
    });
    const bill = rows.find((r) => String(r.society_id) === String(req.societyId));
    if (!bill) throw ApiError.notFound('Vendor bill not found');

    const [items, approvals, payments] = await Promise.all([
      query('sp_vendor_bills', { operation: 'GET_BILL_ITEMS', bill_id: { type: sql.Int, value: id } }),
      query('sp_vendor_bills', { operation: 'GET_APPROVALS', bill_id: { type: sql.Int, value: id } }),
      query('sp_Vendor_Bill_Payments', {
        operation: 'getreceipt',
        bill_id: { type: sql.NVarChar(sql.MAX), value: String(id) },
        society_id: SOC(req.societyId),
      }).catch(() => []),
    ]);

    return ok(res, { bill, items, approvals, payments });
  }),
);

/**
 * POST /accounts/vendor-bills — create a bill.
 *
 * FINANCIAL WRITE. Mirrors btnSave_Click:
 *  - staff payment (service 0) requires payment details and rejects a duplicate
 *    salary for the same month (the SP returns bill_id = -1 with a message);
 *  - inventory payment (service 2) writes each line item to inventory_master;
 *  - selected approvers become vendor_bill_approval rows.
 */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const serviceType = int(req.body?.serviceType, 'serviceType', { min: 0, max: 3 });
    const billNumber = str(req.body?.billNumber, 'billNumber', { max: 50 });
    const billDate = date(req.body?.billDate, 'billDate');

    // vendor_id holds a comma-separated list: staff ids for service 0,
    // otherwise a single vendor id. Matches how the SP parses it.
    const vendorIds = Array.isArray(req.body?.vendorIds)
      ? req.body.vendorIds.map((v) => String(v).trim()).filter(Boolean).join(',')
      : str(req.body?.vendorIds, 'vendorIds', { max: 100 });
    if (!vendorIds) throw ApiError.badRequest('Select at least one vendor or staff member');

    const subtotal = num(req.body?.subtotal, 'subtotal', { min: 0, required: false, default: 0 });
    const taxAmount = num(req.body?.taxAmount, 'taxAmount', { min: 0, required: false, default: 0 });
    const totalAmount = num(req.body?.totalAmount, 'totalAmount', { min: 0 });

    if (serviceType === 0 && !req.body?.payment) {
      throw ApiError.badRequest('Payment details are mandatory for a staff payment');
    }

    const created = await exec('sp_vendor_bills', {
      operation: 'INSERT',
      society_id: SOC(req.societyId),
      bill_number: { type: sql.NVarChar(50), value: billNumber },
      bill_date: { type: sql.Date, value: billDate },
      vendor_id: { type: sql.NVarChar(50), value: vendorIds },
      subtotal: { type: sql.Decimal(12, 2), value: subtotal },
      tax_amount: { type: sql.Decimal(12, 2), value: taxAmount },
      total_amount: { type: sql.Decimal(12, 2), value: totalAmount },
      status: { type: sql.Int, value: int(req.body?.status, 'status', { required: false, default: 1 }) },
      notes: { type: sql.NVarChar(500), value: optionalStr(req.body?.notes, 'notes', { max: 500 }) },
      created_by: { type: sql.Int, value: req.user.userId },
      service: { type: sql.Int, value: serviceType },
      desc: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.description, 'description') },
    });

    // -1 signals a duplicate staff salary for the month.
    if (created && Number(created.bill_id) === -1) {
      throw ApiError.conflict(created.error_message, {
        duplicateStaff: created.duplicate_staff,
        existingBillNumbers: created.existing_bill_numbers,
      });
    }
    const billId = created?.bill_id;
    if (!billId) throw ApiError.badRequest('The bill could not be created');

    // Inventory line items (service 2).
    const items = Array.isArray(req.body?.items) ? req.body.items : [];
    const itemErrors = [];
    for (const item of items) {
      try {
        await exec('sp_inventory_master', {
          operation: 'UPDATE',
          item_id: { type: sql.Int, value: 0 },
          item_name: { type: sql.NVarChar(100), value: str(item?.name, 'item.name', { max: 100 }) },
          quantity: { type: sql.Int, value: int(item?.quantity, 'item.quantity', { min: 0, required: false, default: 0 }) },
          unit: { type: sql.NVarChar(20), value: optionalStr(item?.unit, 'item.unit', { max: 20 }) },
          total_amount: { type: sql.Decimal(18, 2), value: num(item?.totalAmount, 'item.totalAmount', { min: 0, required: false, default: 0 }) },
          tax: { type: sql.Decimal(18, 2), value: num(item?.tax, 'item.tax', { min: 0, required: false, default: 0 }) },
          purchase_cost: { type: sql.Decimal(18, 2), value: num(item?.purchaseCost, 'item.purchaseCost', { min: 0, required: false, default: 0 }) },
          purchase_date: { type: sql.Date, value: date(item?.purchaseDate, 'item.purchaseDate', { required: false }) || billDate },
          warranty: { type: sql.Int, value: int(item?.warrantyMonths, 'item.warrantyMonths', { min: 0, required: false, default: 0 }) },
          vendor_id: { type: sql.Int, value: int(vendorIds.split(',')[0], 'vendorId', { min: 0, required: false, default: 0 }) },
          vendor_bill_id: { type: sql.Int, value: billId },
          // 1 = New. Stock received against a bill has just been bought, and
          // 0 is the condition list's "Select" — i.e. nothing recorded, which
          // is what the inventory grid showed for every item a bill created.
          condition_status: {
            type: sql.Int,
            value: int(item?.conditionStatus, 'item.conditionStatus', {
              min: 0,
              max: 4,
              required: false,
              default: 1,
            }),
          },
          remarks: { type: sql.NVarChar(sql.MAX), value: optionalStr(item?.remarks, 'item.remarks') },
          society_id: SOC(req.societyId),
        });
      } catch (err) {
        itemErrors.push({ item: item?.name, error: err.message });
      }
    }

    // Approvers.
    const approverIds = Array.isArray(req.body?.approverIds) ? req.body.approverIds : [];
    const approverErrors = [];
    for (const userId of approverIds) {
      try {
        await exec('sp_approvar', {
          operation: 'Update',
          approver_id: { type: sql.Int, value: 0 },
          user_id: { type: sql.Int, value: Number(userId) },
          bill_id: { type: sql.Int, value: billId },
          approval_status: { type: sql.Int, value: 1 },
        });
      } catch (err) {
        approverErrors.push({ userId, error: err.message });
      }
    }

    // Payment taken on the create form. This was validated as mandatory for a
    // staff bill and then never written — the amount the user entered was
    // dropped, leaving the bill fully outstanding.
    let paymentId = null;
    let paymentError = null;
    if (req.body?.payment) {
      try {
        paymentId = await insertPayment({
          billId,
          vendorId: int(vendorIds.split(',')[0], 'vendorId', { min: 0, required: false, default: 0 }),
          societyId: req.societyId,
          userId: req.user.userId,
          payment: req.body.payment,
        });
      } catch (err) {
        // The bill exists by now; report the failure rather than 500 over a
        // record the caller can retry from the bill's own Pay action.
        paymentError = err.message;
      }
    }

    return ok(res, { bill_id: billId, paymentId, paymentError, itemErrors, approverErrors }, 201);
  }),
);

/** PUT /accounts/vendor-bills/:id */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_vendor_bills', {
      operation: 'UPDATE',
      bill_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      bill_number: { type: sql.NVarChar(50), value: str(req.body?.billNumber, 'billNumber', { max: 50 }) },
      bill_date: { type: sql.Date, value: date(req.body?.billDate, 'billDate') },
      vendor_id: { type: sql.NVarChar(50), value: str(req.body?.vendorIds, 'vendorIds', { max: 50 }) },
      subtotal: { type: sql.Decimal(12, 2), value: num(req.body?.subtotal, 'subtotal', { min: 0, required: false, default: 0 }) },
      tax_amount: { type: sql.Decimal(12, 2), value: num(req.body?.taxAmount, 'taxAmount', { min: 0, required: false, default: 0 }) },
      total_amount: { type: sql.Decimal(12, 2), value: num(req.body?.totalAmount, 'totalAmount', { min: 0 }) },
      status: { type: sql.Int, value: int(req.body?.status, 'status', { required: false, default: 1 }) },
      notes: { type: sql.NVarChar(500), value: optionalStr(req.body?.notes, 'notes', { max: 500 }) },
      service: { type: sql.Int, value: int(req.body?.serviceType, 'serviceType', { min: 0, max: 3 }) },
    });
    return ok(res, { bill_id: id });
  }),
);

router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_vendor_bills', { operation: 'DELETE', bill_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, bill_id: id });
  }),
);

/* --------------------------------------------------------------- approvals */

/** GET /accounts/vendor-bills/:id/approvals */
router.get(
  '/:id/approvals',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_vendor_bills', {
      operation: 'GET_APPROVALS',
      bill_id: { type: sql.Int, value: id },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** POST /accounts/vendor-bills/:id/approvers — attach approvers to a bill. */
router.post(
  '/:id/approvers',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const userIds = Array.isArray(req.body?.userIds) ? req.body.userIds : [];
    if (!userIds.length) throw ApiError.badRequest('Select at least one approver');

    for (const userId of userIds) {
      await exec('sp_approvar', {
        operation: 'Update',
        approver_id: { type: sql.Int, value: 0 },
        user_id: { type: sql.Int, value: Number(userId) },
        bill_id: { type: sql.Int, value: id },
        approval_status: { type: sql.Int, value: 1 },
      });
    }
    return ok(res, { added: userIds.length }, 201);
  }),
);

/**
 * POST /accounts/vendor-bills/:id/approvals/:approvalId — approve or reject.
 * status 2 = approved, 4 = rejected. When every approval is done the SP moves
 * the bill itself to approved; a rejection rejects the bill immediately.
 *
 * A decision may only be recorded by the approver it was asked of. Without
 * that, any member of the society could approve in someone else's name, which
 * defeats the point of asking for approval at all and writes the wrong person
 * into the audit trail. The bill is in the path so its approvals can be read
 * and the row matched against the caller — the SP offers no lookup by
 * approval_id alone.
 */
router.post(
  '/:id/approvals/:approvalId',
  asyncHandler(async (req, res) => {
    const billId = int(req.params.id, 'id', { min: 1 });
    const approvalId = int(req.params.approvalId, 'approvalId', { min: 1 });
    const decision = oneOf(req.body?.decision, 'decision', ['approve', 'reject']);
    const remarks = optionalStr(req.body?.remarks, 'remarks', { max: 500 });

    if (decision === 'reject' && !remarks) {
      throw ApiError.badRequest('A remark is required when rejecting a bill');
    }

    // SELECT ignores society_id, so the bill is matched here — same as GET /:id.
    const bills = await query('sp_vendor_bills', {
      operation: 'SELECT',
      bill_id: { type: sql.Int, value: billId },
    });
    if (!bills.some((r) => String(r.society_id) === String(req.societyId))) {
      throw ApiError.notFound('Vendor bill not found');
    }

    const approvals = await query('sp_vendor_bills', {
      operation: 'GET_APPROVALS',
      bill_id: { type: sql.Int, value: billId },
    });
    const approval = approvals.find(
      (a) => String(a.approval_id) === String(approvalId),
    );
    if (!approval) throw ApiError.notFound('Approval not found on this bill');

    if (String(approval.user_id) !== String(req.user.userId)) {
      throw ApiError.forbidden('This approval was asked of someone else');
    }

    // Already decided. Re-deciding would overwrite the recorded answer and,
    // on a bill the SP has already settled, move it back out of that state.
    if (Number(approval.approval_status) !== 1) {
      throw ApiError.conflict('This approval has already been answered');
    }

    await exec('sp_vendor_bills', {
      operation: 'UPDATE_STATUS',
      approval_id: { type: sql.Int, value: approvalId },
      status: { type: sql.Int, value: decision === 'approve' ? 2 : 4 },
      notes: { type: sql.NVarChar(500), value: remarks },
    });
    return ok(res, { decision, approval_id: approvalId });
  }),
);

/**
 * Records one payment against a bill and lets the SP settle it.
 *
 * sp_Vendor_Bill_Payments' INSERT allocates the receipt number and then calls
 * sp_SettleVendorBills, which is what moves paid_amount / remaining_amount and
 * the bill's status — so nothing here recalculates those.
 */
async function insertPayment({ billId, vendorId, societyId, userId, payment }) {
  const mode = oneOf(payment?.mode, 'payment.mode', ['Cheque', 'Online', 'Cash']);
  const amount = num(payment?.amount, 'payment.amount', { min: 0.01 });

  // Each mode carries its own reference fields, as the legacy panels did.
  if (mode === 'Cheque' && !payment?.chequeNo) {
    throw ApiError.badRequest('A cheque number is required for a cheque payment');
  }
  if (mode === 'Online' && !payment?.transactionRef) {
    throw ApiError.badRequest('A transaction reference is required for an online payment');
  }

  const inserted = await exec('sp_Vendor_Bill_Payments', {
    operation: 'INSERT',
    society_id: { type: sql.NVarChar(10), value: societyId },
    vendor_id: { type: sql.Int, value: vendorId },
    pay_mode: { type: sql.NVarChar(20), value: mode },
    cheque_no: { type: sql.NVarChar(30), value: mode === 'Cheque' ? String(payment.chequeNo).trim() : null },
    cheque_date: {
      type: sql.Date,
      value: mode === 'Cheque' ? date(payment?.chequeDate, 'payment.chequeDate', { required: false }) : null,
    },
    bank_name: { type: sql.NVarChar(100), value: mode === 'Cheque' ? optionalStr(payment?.bankName, 'payment.bankName', { max: 100 }) : null },
    transaction_ref: { type: sql.NVarChar(100), value: mode === 'Online' ? String(payment.transactionRef).trim() : null },
    paid_amount: { type: sql.Decimal(10, 2), value: amount },
    remarks: { type: sql.NVarChar(255), value: optionalStr(payment?.remarks, 'payment.remarks', { max: 255 }) },
    status: { type: sql.Int, value: 1 },
    created_by: { type: sql.NVarChar(50), value: String(userId) },
    // The payments table links back through bill_details, not a bill_id column.
    bill_details: { type: sql.NVarChar(20), value: String(billId) },
    file_path: { type: sql.NVarChar(sql.MAX), value: optionalStr(payment?.filePath, 'payment.filePath') },
  });

  return inserted?.payment_id ?? null;
}

/**
 * POST /:id/payments — pay against an existing bill.
 *
 * VendorBill.aspx's per-row "Pay" button, which opened a modal for cheque,
 * online or cash and posted against the bill. Nothing in this API could do
 * that: a payment could only be attached while first creating the bill, so an
 * outstanding balance could never be settled afterwards.
 */
router.post(
  '/:id/payments',
  asyncHandler(async (req, res) => {
    const billId = int(req.params.id, 'id', { min: 1 });

    // SELECT ignores society_id, so the row is matched here — same as GET /:id.
    const rows = await query('sp_vendor_bills', {
      operation: 'SELECT',
      bill_id: { type: sql.Int, value: billId },
    });
    const bill = rows.find((r) => String(r.society_id) === String(req.societyId));
    if (!bill) throw ApiError.notFound('Vendor bill not found');

    // A rejected bill is not payable. sp_Vendor_Bill_Payments' own fill_bills
    // excludes status 4 from what can be settled, but nothing stopped a
    // payment being posted straight at one through this route.
    if (Number(bill.status) === 4) {
      throw ApiError.conflict('This bill was rejected and cannot be paid');
    }

    // vendor_id is a comma-separated list for staff bills; the payment row
    // takes a single id, and the legacy handler took the first likewise.
    //
    // The SELECT operation returns that column as `original_vendor_ids` — it
    // reserves `vendor_name` for the resolved names. Reading `bill.vendor_id`
    // yielded undefined, which `String()` turned into the literal "undefined";
    // that is not empty, so `|| 0` did not catch it and int() threw on every
    // payment against a bill that had a vendor at all.
    const rawVendorIds = String(bill.original_vendor_ids ?? bill.vendor_id ?? '');
    const firstVendorId = rawVendorIds.split(',')[0].trim();
    const vendorId = int(firstVendorId || 0, 'vendorId', {
      min: 0,
      required: false,
      default: 0,
    });

    const paymentId = await insertPayment({
      billId,
      vendorId,
      societyId: req.societyId,
      userId: req.user.userId,
      payment: req.body,
    });

    return ok(res, { bill_id: billId, payment_id: paymentId }, 201);
  }),
);

module.exports = router;
