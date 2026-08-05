// Website API — Village (Gram Panchayat).
// Replaces village_master, village_owner_master, house_master, house_tax,
// house_tax_receipt, water_tax, square_feet_rate, v_resident, v_staff_management,
// v_payments, v_history_table and v_profite_loss.
//
// Village users are scoped by village_id rather than society_id.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date } = require('../../lib/validate');
const { requireVillage } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireVillage);

const VIL = (v) => ({ type: sql.NVarChar(10), value: v });
const VIL50 = (v) => ({ type: sql.NVarChar(50), value: v });

/* ------------------------------------------------------------------ houses */

router.get(
  '/houses',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house', { operation: 'Grid_Show', village_id: VIL(req.villageId) });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/houses/history',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house', { operation: 'house_history', village_id: VIL(req.villageId) });
    return ok(res, { items: rows, count: rows.length });
  }),
);

function houseParams(body, userId) {
  return {
    house_no: { type: sql.Int, value: int(body?.houseNo, 'houseNo', { min: 0 }) },
    house_type: { type: sql.Int, value: int(body?.houseType, 'houseType', { min: 1 }) },
    area: { type: sql.Decimal(18, 2), value: num(body?.area, 'area', { min: 0, required: false, default: 0 }) },
    gharpatti_charges: {
      type: sql.Decimal(18, 2),
      value: num(body?.propertyTax, 'propertyTax', { min: 0, required: false, default: 0 }),
    },
    no_of_tab: { type: sql.Int, value: int(body?.tapCount, 'tapCount', { min: 0, required: false, default: 0 }) },
    water_charges: {
      type: sql.Decimal(18, 2),
      value: num(body?.waterCharges, 'waterCharges', { min: 0, required: false, default: 0 }),
    },
    waste_charges: {
      type: sql.Decimal(18, 2),
      value: num(body?.wasteCharges, 'wasteCharges', { min: 0, required: false, default: 0 }),
    },
    audt_modify_id: { type: sql.Int, value: userId },
  };
}

router.post(
  '/houses',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_house', {
      operation: 'Update',
      house_id: { type: sql.Int, value: 0 },
      village_id: VIL(req.villageId),
      ...houseParams(req.body, req.user.userId),
    });
    return ok(res, { house_id: created?.house_id ?? null }, 201);
  }),
);

router.put(
  '/houses/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_house', {
      operation: 'Update',
      house_id: { type: sql.Int, value: id },
      village_id: VIL(req.villageId),
      ...houseParams(req.body, req.user.userId),
    });
    return ok(res, { house_id: id });
  }),
);

/* ------------------------------------------------------------ house owners */

router.get(
  '/owners',
  asyncHandler(async (req, res) => {
    // sp_house_owner has no grid branch; the house grid carries owner columns.
    const rows = await query('sp_house', { operation: 'Grid_Show', village_id: VIL(req.villageId) });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/owners/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_house_owner', {
      operation: 'Select',
      village_owner_id: { type: sql.Int, value: id },
    });
    if (!rows[0] || String(rows[0].village_id) !== String(req.villageId)) {
      throw ApiError.notFound('House owner not found');
    }
    return ok(res, { owner: rows[0] });
  }),
);

function houseOwnerParams(body) {
  return {
    name: { type: sql.NVarChar(150), value: str(body?.name, 'name', { max: 150 }) },
    house_id: { type: sql.Int, value: int(body?.houseId, 'houseId', { min: 1 }) },
    address: { type: sql.NVarChar(50), value: optionalStr(body?.address, 'address', { max: 50 }) },
    pre_mob: { type: sql.NVarChar(50), value: optionalStr(body?.mobile, 'mobile', { max: 50 }) },
    alter_mob: { type: sql.NVarChar(50), value: optionalStr(body?.altMobile, 'altMobile', { max: 50 }) },
    id_proof: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.idProofPath, 'idProofPath') },
  };
}

router.post(
  '/owners',
  asyncHandler(async (req, res) => {
    await exec('sp_house_owner', {
      operation: 'Update',
      village_owner_id: { type: sql.Int, value: 0 },
      village_id: VIL(req.villageId),
      ...houseOwnerParams(req.body),
    });
    return ok(res, { created: true }, 201);
  }),
);

router.put(
  '/owners/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_house_owner', {
      operation: 'Update',
      village_owner_id: { type: sql.Int, value: id },
      village_id: VIL(req.villageId),
      ...houseOwnerParams(req.body),
    });
    return ok(res, { village_owner_id: id });
  }),
);

router.delete(
  '/owners/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_house_owner', {
      operation: 'Delete',
      village_owner_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, village_owner_id: id });
  }),
);

/* --------------------------------------------------------------- house tax */

/**
 * GET /village/house-tax
 *
 * KNOWN SQL DEFECT (reported, not fixed — awaiting approval):
 *   house_owner has no `house_no` column (it has `house_id`), but both
 *   sp_house_tax's Grid_Show and the house_tax_vw view join on
 *   house_owner.house_no. Both therefore fail with "Invalid column name
 *   'house_no'". See docs/MIGRATION-MAP.md §7.
 *
 * Until that is resolved we read the house_tax table directly and join through
 * house_id, which is the column that actually exists. No SQL object is created
 * or altered by doing so.
 */
router.get(
  '/house-tax',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();
    try {
      const rows = await query('sp_house_tax', {
        operation: 'Grid_Show',
        village_id: VIL(req.villageId),
      });
      return ok(res, { items: rows, count: rows.length, source: 'sp_house_tax' });
    } catch (spError) {
      const result = await pool
        .request()
        .input('village_id', sql.NVarChar(10), req.villageId)
        .query(`
          SELECT ht.*, h.house_id, ho.name AS owner_name, ho.pre_mob
          FROM   house_tax ht
          LEFT   JOIN house h  ON h.house_no = ht.house_no AND h.village_id = ht.village_id
          LEFT   JOIN house_owner ho ON ho.house_id = h.house_id
          WHERE  ht.village_id = @village_id AND ISNULL(ht.active_status, 0) = 0
          ORDER  BY ht.house_tax_id DESC`);
      return ok(res, {
        items: result.recordset,
        count: result.recordset.length,
        source: 'house_tax (direct — sp_house_tax and house_tax_vw are both broken)',
        spError: spError.message,
      });
    }
  }),
);

router.get(
  '/house-tax/receipts',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house_tax_receipt', {
      operation: 'Grid_paid_charges',
      village_id: VIL50(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/house-tax/pending',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house_tax_receipt', {
      operation: 'Grid_pending_charges',
      village_id: VIL50(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/house-tax/receipts/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_house_tax_receipt', {
      operation: 'get_receipt_data',
      house_receipt_id: { type: sql.Int, value: id },
    });
    if (!rows[0]) throw ApiError.notFound('Receipt not found');
    return ok(res, { receipt: rows[0] });
  }),
);

/* --------------------------------------------------------------- water tax */

/**
 * GET /village/water-tax
 *
 * Same defect as house-tax: sp_water_tax's Grid_Show and water_tax_vw both join
 * house_owner.house_no, which does not exist. Read water_tax directly instead.
 */
router.get(
  '/water-tax',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();
    try {
      const rows = await query('sp_water_tax', {
        operation: 'Grid_Show',
        village_id: VIL(req.villageId),
      });
      return ok(res, { items: rows, count: rows.length, source: 'sp_water_tax' });
    } catch (spError) {
      const result = await pool
        .request()
        .input('village_id', sql.NVarChar(10), req.villageId)
        .query(`
          SELECT wt.*, ct.connection_type, h.house_id, ho.name AS owner_name
          FROM   water_tax wt
          LEFT   JOIN connection_type ct ON ct.con_type_id = wt.con_type_id
          LEFT   JOIN house h  ON h.house_no = wt.house_no AND h.village_id = wt.village_id
          LEFT   JOIN house_owner ho ON ho.house_id = h.house_id
          WHERE  wt.village_id = @village_id AND ISNULL(wt.active_status, 0) = 0
          ORDER  BY wt.water_tax_id DESC`);
      return ok(res, {
        items: result.recordset,
        count: result.recordset.length,
        source: 'water_tax (direct — sp_water_tax and water_tax_vw are both broken)',
        spError: spError.message,
      });
    }
  }),
);

/* ------------------------------------------------------------ square-ft rate */

router.get(
  '/rates',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_square_ft_rate', {
      operation: 'Grid_Show',
      village_id: VIL(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/rates',
  asyncHandler(async (req, res) => {
    await exec('sp_square_ft_rate', {
      operation: 'Update',
      sq_rate_id: { type: sql.Int, value: int(req.body?.rateId, 'rateId', { required: false, default: 0 }) },
      rate: { type: sql.Decimal(18, 2), value: num(req.body?.rate, 'rate', { min: 0 }) },
      applied_date: { type: sql.Date, value: date(req.body?.appliedDate, 'appliedDate', { required: false }) },
      house_type_id: { type: sql.NVarChar(50), value: str(req.body?.houseTypeId, 'houseTypeId', { max: 50 }) },
      bill_gen_date: { type: sql.Date, value: date(req.body?.billGenDate, 'billGenDate', { required: false }) },
      due_date: { type: sql.Date, value: date(req.body?.dueDate, 'dueDate', { required: false }) },
      village_id: VIL(req.villageId),
    });
    return ok(res, { saved: true }, 201);
  }),
);

/* ------------------------------------------------------------------- staff */

router.get(
  '/staff',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_Village_staff', {
      operation: 'Grid_Show',
      village_id: VIL(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/staff/roles',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_Village_staff', { operation: 'get_staff_role' });
    return ok(res, { items: rows });
  }),
);

function villageStaffParams(body) {
  return {
    staff_name: { type: sql.NVarChar(50), value: str(body?.name, 'name', { max: 50 }) },
    address: { type: sql.NVarChar(50), value: optionalStr(body?.address, 'address', { max: 50 }) },
    contact_no: { type: sql.NVarChar(10), value: optionalStr(body?.contactNo, 'contactNo', { max: 10 }) },
    email: { type: sql.NVarChar(50), value: optionalStr(body?.email, 'email', { max: 50 }) },
    joined_date: { type: sql.SmallDateTime, value: date(body?.joinedDate, 'joinedDate', { required: false }) },
    role_id: { type: sql.Int, value: int(body?.roleId, 'roleId', { min: 0, required: false, default: 0 }) },
    role: { type: sql.NVarChar(50), value: optionalStr(body?.role, 'role', { max: 50 }) },
    id_path: { type: sql.NVarChar(200), value: optionalStr(body?.idPath, 'idPath', { max: 200 }) },
    salary: { type: sql.Decimal(10, 2), value: num(body?.salary, 'salary', { min: 0, required: false, default: 0 }) },
  };
}

router.post(
  '/staff',
  asyncHandler(async (req, res) => {
    await exec('sp_Village_staff', {
      operation: 'Update',
      staff_id: { type: sql.Int, value: 0 },
      village_id: VIL(req.villageId),
      ...villageStaffParams(req.body),
    });
    return ok(res, { created: true }, 201);
  }),
);

router.put(
  '/staff/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_Village_staff', {
      operation: 'Update',
      staff_id: { type: sql.Int, value: id },
      village_id: VIL(req.villageId),
      ...villageStaffParams(req.body),
    });
    return ok(res, { staff_id: id });
  }),
);

router.delete(
  '/staff/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_Village_staff', { operation: 'Delete', staff_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, staff_id: id });
  }),
);

/* ----------------------------------------------------------- balance sheet */

router.get(
  '/balance-sheet',
  asyncHandler(async (req, res) => {
    const [heads, subPoints] = await Promise.all([
      query('sp_balancesheet', { operation: 'get_main_points', village_id: VIL(req.villageId) }),
      query('sp_balancesheet', { operation: 'get_sub_point', village_id: VIL(req.villageId) }),
    ]);
    return ok(res, { heads, subPoints });
  }),
);

/** GET /village/house-tax/pending-by-type?type=1|2|3 — 1 property, 2 water, 3 waste. */
router.get(
  '/house-tax/by-type',
  asyncHandler(async (req, res) => {
    const type = int(req.query.type, 'type', { min: 1, max: 3 });
    const paid = req.query.paid === 'true';
    const houseId = int(req.query.houseId, 'houseId', { min: 1, required: false, default: 0 });

    // The SP exposes one branch per payment type and paid/unpaid combination.
    const suffix = { 1: 'p', 2: 'W', 3: 'M' }[type];
    const rows = await query('sp_house_tax_receipt', {
      operation: paid ? `Grid_paid_${suffix}` : `Grid_not_paid_${suffix}`,
      village_id: VIL50(req.villageId),
      house_id: { type: sql.Int, value: houseId },
    });
    return ok(res, { items: rows, count: rows.length, type, paid });
  }),
);

/**
 * POST /village/house-tax/pay — settle one or more pending tax bills.
 *
 * Replaces the pay modal on v_tax_payment.aspx (btnPayModal_Click). The SP's
 * 'Update_Payment' branch takes a comma-separated list of house_receipt_id and
 * cursors over House_wise_payment_vw, paying each bill its full pending_amount
 * — there is no partial payment, exactly as the legacy page behaved.
 *
 * Payment modes come from the legacy dropdown: 1 Cash, 2 Cheque, 4 UPI.
 */
const PAY_MODES = { 1: 'Cash', 2: 'Cheque', 4: 'UPI' };

router.post(
  '/house-tax/pay',
  asyncHandler(async (req, res) => {
    const rawIds = Array.isArray(req.body?.receiptIds) ? req.body.receiptIds : [];
    const ids = rawIds
      .map((v) => Number(v))
      .filter((v) => Number.isInteger(v) && v > 0);

    if (!ids.length) throw ApiError.badRequest('Select at least one bill to pay');

    const payMode = int(req.body?.payMode, 'payMode', { min: 1, max: 4 });
    if (!PAY_MODES[payMode]) throw ApiError.badRequest('payMode must be 1 (Cash), 2 (Cheque) or 4 (UPI)');

    const transactionRef = optionalStr(req.body?.transactionRef, 'transactionRef', { max: 50 });
    const chequeNo = optionalStr(req.body?.chequeNo, 'chequeNo', { max: 50 });
    const chequeDate = date(req.body?.chequeDate, 'chequeDate', { required: false });
    const remark = optionalStr(req.body?.remark, 'remark', { max: 250 });

    // The legacy page made the reference mandatory for anything but cash, and
    // the cheque number mandatory for cheques.
    if (payMode !== 1 && !transactionRef) {
      throw ApiError.badRequest('Transaction reference is required for UPI and cheque payments');
    }
    if (payMode === 2 && !chequeNo) {
      throw ApiError.badRequest('Cheque number is required for a cheque payment');
    }

    // Only settle bills that belong to this village and are still unpaid —
    // the SP scopes by village_id but would otherwise accept any id.
    const pool = await require('../../lib/db').getPool();
    const check = await pool
      .request()
      .input('village_id', sql.NVarChar(50), req.villageId)
      .query(`
        SELECT house_receipt_id, pending_amount, payment_status
        FROM   House_wise_payment_vw
        WHERE  village_id = @village_id`);

    const byId = new Map(check.recordset.map((r) => [Number(r.house_receipt_id), r]));
    const unknown = ids.filter((id) => !byId.has(id));
    if (unknown.length) {
      throw ApiError.notFound(`No such bill for this village: ${unknown.join(', ')}`);
    }
    const alreadyPaid = ids.filter((id) => Number(byId.get(id).payment_status) === 1);
    if (alreadyPaid.length) {
      throw ApiError.badRequest(`Already paid: ${alreadyPaid.join(', ')}`);
    }

    await exec('sp_house_tax_receipt', {
      operation: 'Update_Payment',
      village_id: VIL50(req.villageId),
      all_housereceipt_id: { type: sql.NVarChar(sql.MAX), value: ids.join(',') },
      pay_mode: { type: sql.Int, value: payMode },
      chqno: { type: sql.NVarChar(50), value: chequeNo },
      chqdate: { type: sql.Date, value: chequeDate },
      Transation_ref: { type: sql.NVarChar(50), value: transactionRef },
      remark: { type: sql.NVarChar(250), value: remark },
    });

    const total = ids.reduce((s, id) => s + Number(byId.get(id).pending_amount || 0), 0);
    return ok(res, { paid: ids.length, receiptIds: ids, totalPaid: total, payMode: PAY_MODES[payMode] });
  }),
);

/** GET /village/houses/:id — one house owner record. */
router.get(
  '/owners/detail/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_house_owner', {
      operation: 'Select',
      village_owner_id: { type: sql.Int, value: id },
    });
    if (!rows[0] || String(rows[0].village_id) !== String(req.villageId)) {
      throw ApiError.notFound('House owner not found');
    }
    return ok(res, { owner: rows[0] });
  }),
);

/** GET /village/address — the village address block used on receipts. */
router.get(
  '/address',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house_owner', {
      operation: 'address_fetch',
      village_id: VIL(req.villageId),
    });
    return ok(res, { address: rows[0]?.address_line1 ?? null });
  }),
);

module.exports = router;
