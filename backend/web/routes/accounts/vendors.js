// Website API — Vendors, vendor bills and vendor payments.
// Replaces vendor_search, VendorBill and vendor_bill_payments.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/* ----------------------------------------------------------- vendor master */

router.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_vendor_master', {
      operation: search ? 'SEARCH' : 'Grid_Show',
      ...(search ? { search_text: { type: sql.NVarChar(200), value: search } } : {}),
    });
    // Neither Grid_Show nor SEARCH is society-scoped in the SP, so the rows
    // are filtered here.
    //
    // The society must match — a row with no society_id is not "shared", it
    // is unattributed, and letting it through showed one society's vendor to
    // every other, editable and deletable by all of them. sp_vendor_bills'
    // vendor_fill has always scoped this way, so the bill form's dropdown and
    // this list disagreed: a vendor visible here could not be billed against.
    const scoped = rows.filter(
      (r) => String(r.society_id) === String(req.societyId),
    );
    return ok(res, { items: scoped, count: scoped.length });
  }),
);

function vendorParams(body) {
  return {
    vendor_name: { type: sql.NVarChar(200), value: str(body?.name, 'name', { max: 200 }) },
    contact_person: {
      type: sql.NVarChar(100),
      value: optionalStr(body?.contactPerson, 'contactPerson', { max: 100 }),
    },
    contact_no: { type: sql.NVarChar(30), value: optionalStr(body?.contactNo, 'contactNo', { max: 30 }) },
    email: { type: sql.NVarChar(120), value: optionalStr(body?.email, 'email', { max: 120 }) },
    service_type: { type: sql.NVarChar(100), value: optionalStr(body?.serviceType, 'serviceType', { max: 100 }) },
    gst_no: { type: sql.NVarChar(50), value: optionalStr(body?.gstNo, 'gstNo', { max: 50 }) },
    address: { type: sql.NVarChar(300), value: optionalStr(body?.address, 'address', { max: 300 }) },
  };
}

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const result = await exec('sp_vendor_master', {
      operation: 'INSERT',
      society_id: SOC(req.societyId),
      ...vendorParams(req.body),
    });
    // The SP reports duplicates via { message, status } instead of raising.
    if (result && Number(result.status) === 0) throw ApiError.conflict(result.message);
    return ok(res, { created: true }, 201);
  }),
);

/**
 * The vendor, if it belongs to this society.
 *
 * Neither UPDATE nor DELETE is society-scoped in the SP — DELETE takes only a
 * vendor_id — so ownership is established here before either runs. Without
 * it, an id typed into the URL reached another society's vendor.
 */
async function requireOwnVendor(societyId, vendorId) {
  const rows = await query('sp_vendor_master', { operation: 'Grid_Show' });
  const vendor = rows.find((r) => String(r.vendor_id) === String(vendorId));
  if (!vendor || String(vendor.society_id) !== String(societyId)) {
    throw ApiError.notFound('Vendor not found');
  }
  return vendor;
}

router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await requireOwnVendor(req.societyId, id);

    await exec('sp_vendor_master', {
      operation: 'UPDATE',
      vendor_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      ...vendorParams(req.body),
    });
    return ok(res, { vendor_id: id });
  }),
);

router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await requireOwnVendor(req.societyId, id);

    await exec('sp_vendor_master', {
      operation: 'DELETE',
      vendor_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, vendor_id: id });
  }),
);

/* ------------------------------------------------------------ vendor bills */

router.get(
  '/bills/list',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_vendor_bills', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/bills/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_vendor_bills', {
      operation: 'SELECT',
      bill_id: { type: sql.Int, value: id },
    });
    const bill = rows.find((r) => String(r.society_id) === String(req.societyId));
    if (!bill) throw ApiError.notFound('Vendor bill not found');

    const [items, approvals] = await Promise.all([
      query('sp_vendor_bills', { operation: 'GET_BILL_ITEMS', bill_id: { type: sql.Int, value: id } }),
      query('sp_vendor_bills', { operation: 'GET_APPROVALS', bill_id: { type: sql.Int, value: id } }),
    ]);
    return ok(res, { bill, items, approvals });
  }),
);

/**
 * POST /bills — create a vendor bill.
 * For staff-salary bills (service=0) the SP returns bill_id = -1 with an
 * error_message when a salary has already been raised for that month.
 */
router.post(
  '/bills',
  asyncHandler(async (req, res) => {
    const result = await exec('sp_vendor_bills', {
      operation: 'INSERT',
      society_id: SOC(req.societyId),
      bill_number: { type: sql.NVarChar(50), value: str(req.body?.billNumber, 'billNumber', { max: 50 }) },
      bill_date: { type: sql.Date, value: date(req.body?.billDate, 'billDate') },
      vendor_id: { type: sql.NVarChar(50), value: str(req.body?.vendorIds, 'vendorIds', { max: 50 }) },
      subtotal: { type: sql.Decimal(12, 2), value: num(req.body?.subtotal, 'subtotal', { min: 0, required: false, default: 0 }) },
      tax_amount: { type: sql.Decimal(12, 2), value: num(req.body?.taxAmount, 'taxAmount', { min: 0, required: false, default: 0 }) },
      total_amount: { type: sql.Decimal(12, 2), value: num(req.body?.totalAmount, 'totalAmount', { min: 0 }) },
      status: { type: sql.Int, value: int(req.body?.status, 'status', { required: false, default: 1 }) },
      notes: { type: sql.NVarChar(500), value: optionalStr(req.body?.notes, 'notes', { max: 500 }) },
      created_by: { type: sql.Int, value: req.user.userId },
      service: { type: sql.Int, value: int(req.body?.serviceType, 'serviceType', { required: false, default: 1 }) },
      desc: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.description, 'description') },
    });

    if (result && Number(result.bill_id) === -1) {
      throw ApiError.conflict(result.error_message, {
        duplicateStaff: result.duplicate_staff,
        existingBills: result.existing_bill_numbers,
      });
    }
    return ok(res, { bill_id: result?.bill_id ?? null }, 201);
  }),
);

router.post(
  '/bills/:id/approve',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_vendor_bills', { operation: 'APPROVE', bill_id: { type: sql.Int, value: id } });
    return ok(res, { approved: true, bill_id: id });
  }),
);

router.post(
  '/bills/:id/reject',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_vendor_bills', { operation: 'REJECT', bill_id: { type: sql.Int, value: id } });
    return ok(res, { rejected: true, bill_id: id });
  }),
);

/* --------------------------------------------------------- vendor payments */

router.get(
  '/payments/list',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_Vendor_Bill_Payments', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * Unpaid bills available to settle, optionally narrowed to one vendor.
 *
 * KNOWN SQL DEFECT (reported, not fixed — awaiting approval):
 *   sp_Vendor_Bill_Payments 'fill_bills' joins
 *     LEFT JOIN vendor_bill_payments vp ON vb.bill_id = vp.bill_details
 *   but bill_details is nvarchar holding a COMMA-SEPARATED list (e.g. '2,14'),
 *   so SQL Server tries to convert '2,14' to int and fails:
 *     "Conversion failed when converting the nvarchar value '2,14' to data type int."
 *   The branch therefore fails whenever any payment settled more than one bill.
 *   See docs/MIGRATION-MAP.md §7.
 *
 * Fallback reads vendor_bills directly and matches payments by splitting
 * bill_details, which is what the SP intended. No SQL object is altered.
 */
router.get(
  '/payments/payable',
  asyncHandler(async (req, res) => {
    const vendorId = int(req.query.vendorId, 'vendorId', { min: 1, required: false });
    const pool = await require('../../lib/db').getPool();

    try {
      const rows = await query('sp_Vendor_Bill_Payments', {
        operation: 'fill_bills',
        society_id: SOC(req.societyId),
        ...(vendorId ? { vendor_id: { type: sql.Int, value: vendorId } } : {}),
      });
      return ok(res, { items: rows, count: rows.length, source: 'sp_Vendor_Bill_Payments' });
    } catch (spError) {
      const request = pool.request().input('society_id', sql.NVarChar(10), req.societyId);
      if (vendorId) request.input('vendor_id', sql.Int, vendorId);

      const result = await request.query(`
        SELECT vb.bill_id, vb.bill_number, vb.service_type, vb.bill_date,
               vb.due AS total_amount, vm.vendor_name, bs.bill_status AS status,
               ISNULL(paid.paid_amount, 0) AS paid_amount,
               vb.due - ISNULL(paid.paid_amount, 0) AS remaining_amount
        FROM   vendor_bills vb
        INNER  JOIN bill_status bs ON vb.status = bs.status_id
        LEFT   JOIN vendor_master vm ON vm.vendor_id = TRY_CAST(vb.vendor_id AS INT)
        OUTER  APPLY (
                 SELECT SUM(TRY_CAST(vp.paid_amount AS DECIMAL(18,2))) AS paid_amount
                 FROM   vendor_bill_payments vp
                 CROSS  APPLY STRING_SPLIT(ISNULL(vp.bill_details, ''), ',') s
                 WHERE  TRY_CAST(LTRIM(RTRIM(s.value)) AS INT) = vb.bill_id
                   AND  vp.society_id = vb.society_id
               ) paid
        WHERE  vb.society_id = @society_id
          AND  vb.status <> 4
          AND  ISNULL(vb.due, 0) <> 0
          ${vendorId ? 'AND TRY_CAST(vb.vendor_id AS INT) = @vendor_id' : ''}
        ORDER  BY vb.bill_id DESC`);

      return ok(res, {
        items: result.recordset,
        count: result.recordset.length,
        source: 'vendor_bills (direct — sp_Vendor_Bill_Payments/fill_bills is broken)',
        spError: spError.message,
      });
    }
  }),
);

/**
 * POST /payments — FINANCIAL WRITE.
 * Inserts vendor_bill_payments and runs sp_SettleVendorBills, which updates
 * vendor_bills.due and status.
 */
router.post(
  '/payments',
  asyncHandler(async (req, res) => {
    const result = await exec('sp_Vendor_Bill_Payments', {
      operation: 'INSERT',
      society_id: SOC(req.societyId),
      vendor_id: { type: sql.Int, value: int(req.body?.vendorId, 'vendorId', { min: 1 }) },
      pay_mode: { type: sql.NVarChar(20), value: str(req.body?.payMode, 'payMode', { max: 20 }) },
      cheque_no: { type: sql.NVarChar(30), value: optionalStr(req.body?.chequeNo, 'chequeNo', { max: 30 }) },
      cheque_date: { type: sql.Date, value: date(req.body?.chequeDate, 'chequeDate', { required: false }) },
      bank_name: { type: sql.NVarChar(100), value: optionalStr(req.body?.bankName, 'bankName', { max: 100 }) },
      transaction_ref: {
        type: sql.NVarChar(100),
        value: optionalStr(req.body?.transactionRef, 'transactionRef', { max: 100 }),
      },
      paid_amount: { type: sql.Decimal(10, 2), value: num(req.body?.paidAmount, 'paidAmount', { min: 0.01 }) },
      remarks: { type: sql.NVarChar(255), value: optionalStr(req.body?.remarks, 'remarks', { max: 255 }) },
      status: { type: sql.Int, value: int(req.body?.status, 'status', { required: false, default: 1 }) },
      created_by: { type: sql.NVarChar(50), value: String(req.user.userId) },
      bill_details: { type: sql.NVarChar(20), value: str(req.body?.billId, 'billId', { max: 20 }) },
      file_path: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.filePath, 'filePath') },
    });
    return ok(res, { payment_id: result?.payment_id ?? null }, 201);
  }),
);

module.exports = router;
