// Website API — Village (Gram Panchayat).
// Replaces village_master, village_owner_master, house_master, house_tax,
// house_tax_receipt, water_tax, square_feet_rate, v_resident, v_staff_management,
// v_payments, v_history_table and v_profite_loss.
//
// Village users are scoped by village_id rather than society_id.
const express = require('express');

const { query, queryMulti, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, bool, date, oneOf } = require('../../lib/validate');
const { requireVillage } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireVillage);

/*
 * village_id is nvarchar(50) on every table that stores it — house, house$ARC,
 * Village_staff, village_master and the rest — so the argument is declared at
 * that width too.
 *
 * VIL used to be NVarChar(10). The driver truncates to the declared width
 * before the value ever reaches SQL Server, so an id over ten characters was
 * cut short and then matched nothing: the page came back empty with no error.
 * sp_house and sp_Village_staff both take nvarchar(50) and were being handed
 * the narrow form.
 *
 * VIL50 stays as an alias rather than being renamed at 20-odd call sites; both
 * now describe the same thing.
 */
const VIL = (v) => ({ type: sql.NVarChar(50), value: v });
const VIL50 = VIL;

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
    /*
     * One payment can settle several bills — June and July together, say — and
     * they now share a receipt number, so the proc returns a row per bill.
     * `receipt` stays as the first for callers that only want the header;
     * `bills` and `total` are what the printed copy itemises.
     */
    return ok(res, {
      receipt: rows[0],
      bills: rows,
      total: rows.reduce((sum, r) => sum + Number(r.Amount_paid || 0), 0),
    });
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
    // Grid_Show joins village_staff_role for the role *name* but does not
    // select role_id, so an edit form has nothing to preselect its Role
    // dropdown with — and saving would silently blank the staff member's
    // role. Resolve the id from the same lookup the dropdown is built from.
    const roles = await query('sp_Village_staff', { operation: 'get_staff_role' });
    const idByRole = new Map(roles.map((r) => [String(r.role ?? '').trim().toLowerCase(), r.role_id]));
    const items = rows.map((r) => ({
      ...r,
      role_id: r.role_id ?? idByRole.get(String(r.role ?? '').trim().toLowerCase()) ?? null,
    }));
    return ok(res, { items, count: items.length });
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

/* ---------------------------------------------------------------- reports */

/*
 * The four questions Analytics & Reports is for: what was billed against what
 * came in, who owes, what was collected each month, and one house's history.
 *
 * All four read house_tax_receipt through sp_village_report, so they cannot
 * disagree about what "collected" means.
 */
function reportRange(req) {
  return {
    village_id: VIL(req.villageId),
    from: { type: sql.Date, value: date(req.query?.from, 'from', { required: false }) },
    to: { type: sql.Date, value: date(req.query?.to, 'to', { required: false }) },
  };
}

router.get(
  '/reports/collection',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_report', {
      operation: 'Collection',
      ...reportRange(req),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/reports/defaulters',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_report', {
      operation: 'Defaulters',
      ...reportRange(req),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/reports/monthly',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_report', {
      operation: 'Monthly',
      ...reportRange(req),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/reports/ledger/:houseId',
  asyncHandler(async (req, res) => {
    const houseId = int(req.params.houseId, 'houseId', { min: 1 });
    // Two recordsets: the entries, then the totals they add up to — so the
    // screen shows a total it did not have to re-derive.
    const [items = [], totals = []] = await queryMulti('sp_village_report', {
      operation: 'Ledger',
      village_id: VIL(req.villageId),
      house_id: { type: sql.Int, value: houseId },
    });
    return ok(res, {
      items,
      count: items.length,
      totals: totals[0] ?? { billed: 0, paid: 0, outstanding: 0 },
    });
  }),
);

/* ---------------------------------------------------------------- schemes */

/*
 * Government schemes the village runs. Previously these were posted as
 * announcements, which cannot hold what a scheme is actually asked about:
 * who qualifies, what they get, when applications close, and the GR behind it.
 */
router.get(
  '/schemes',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_scheme', {
      operation: 'Grid_Show',
      village_id: VIL(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

function schemeParams(body) {
  return {
    name: { type: sql.NVarChar(200), value: str(body?.name, 'name', { max: 200 }) },
    description: {
      type: sql.NVarChar(sql.MAX),
      value: optionalStr(body?.description, 'description'),
    },
    eligibility: {
      type: sql.NVarChar(sql.MAX),
      value: optionalStr(body?.eligibility, 'eligibility'),
    },
    /*
     * A scheme may be a payment, a benefit in kind, or both — a subsidy with a
     * cash component. Neither field is required and neither implies the other.
     */
    benefit_amount: {
      type: sql.Decimal(18, 2),
      value: num(body?.benefitAmount, 'benefitAmount', { min: 0, required: false, default: null }),
    },
    benefit_details: {
      type: sql.NVarChar(500),
      value: optionalStr(body?.benefitDetails, 'benefitDetails', { max: 500 }),
    },
    gr_number: { type: sql.NVarChar(100), value: optionalStr(body?.grNumber, 'grNumber', { max: 100 }) },
    gr_date: { type: sql.Date, value: date(body?.grDate, 'grDate', { required: false }) },
    apply_from: { type: sql.Date, value: date(body?.applyFrom, 'applyFrom', { required: false }) },
    apply_until: { type: sql.Date, value: date(body?.applyUntil, 'applyUntil', { required: false }) },
  };
}

router.post(
  '/schemes',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_scheme', {
      operation: 'Update',
      village_id: VIL(req.villageId),
      scheme_id: { type: sql.Int, value: 0 },
      ...schemeParams(req.body),
    });
    return ok(res, { created: true, scheme_id: rows[0]?.scheme_id ?? null }, 201);
  }),
);

router.put(
  '/schemes/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await query('sp_village_scheme', {
      operation: 'Update',
      village_id: VIL(req.villageId),
      scheme_id: { type: sql.Int, value: id },
      ...schemeParams(req.body),
    });
    return ok(res, { scheme_id: id });
  }),
);

router.delete(
  '/schemes/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    // Deactivated, not deleted: residents ask about schemes that have closed.
    await exec('sp_village_scheme', {
      operation: 'Delete',
      village_id: VIL(req.villageId),
      scheme_id: { type: sql.Int, value: id },
    });
    return ok(res, { removed: true, scheme_id: id });
  }),
);

/* -------------------------------------------------------------- bill runs */

/*
 * Raising a period's bills.
 *
 * Preview and generate run the same SELECT inside sp_village_bill_run, so what
 * the screen shows is exactly what would be written. A bill is what a
 * household is told it owes and cannot be quietly withdrawn, so nothing is
 * raised without someone seeing the list first.
 *
 * Re-running is safe: a charge already billed for the period is skipped, so a
 * second run raises only what is missing.
 */
function billRunParams(req) {
  const q = { ...req.query, ...req.body };
  const now = new Date();
  return {
    village_id: VIL(req.villageId),
    bill_year: {
      type: sql.SmallInt,
      value: int(q.year, 'year', { min: 2000, max: 2100, required: false, default: now.getFullYear() }),
    },
    bill_month: {
      type: sql.TinyInt,
      value: int(q.month, 'month', { min: 1, max: 12, required: false, default: now.getMonth() + 1 }),
    },
  };
}

router.get(
  '/bill-run/preview',
  asyncHandler(async (req, res) => {
    const result = await queryMulti('sp_village_bill_run', {
      operation: 'Preview',
      ...billRunParams(req),
    });
    /*
     * One bill per household, and the charges making it up. The screen lists
     * the bills; the lines are what a printed copy itemises.
     */
    const [bills = [], lines = [], totals = []] = result;
    return ok(res, {
      items: bills,
      lines,
      count: bills.length,
      lineCount: totals[0]?.lines ?? lines.length,
      total: totals[0]?.total ?? 0,
    });
  }),
);

router.post(
  '/bill-run',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_bill_run', {
      operation: 'Generate',
      ...billRunParams(req),
      audt_user: { type: sql.Int, value: req.user.userId },
    });
    return ok(
      res,
      { bills: rows[0]?.bills ?? 0, lines: rows[0]?.lines ?? 0, total: rows[0]?.total ?? 0 },
      201,
    );
  }),
);

/* ------------------------------------------------------------ charge types */

/*
 * The charges a village levies. Three come with the database — property tax,
 * water and waste — and a village can add its own: a street-light tax, a
 * market fee. Before this there was no way to add one short of an INSERT run
 * by hand.
 *
 * The three built-ins can be renamed but not removed, and their frequency and
 * basis are fixed: bills have already been raised under them, and changing
 * either would reinterpret history.
 */
router.get(
  '/charge-types',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_village_charge_type', { operation: 'Grid_Show' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

function chargeTypeParams(body) {
  return {
    name: { type: sql.NVarChar(50), value: str(body?.name, 'name', { max: 50 }) },
    frequency: { type: sql.Char(1), value: oneOf(body?.frequency, 'frequency', ['Y', 'M']) },
    basis: { type: sql.VarChar(4), value: oneOf(body?.basis, 'basis', ['AREA', 'TAP', 'FLAT']) },
  };
}

router.post(
  '/charge-types',
  asyncHandler(async (req, res) => {
    // payment_type 0 means "assign the next one" — the column has no IDENTITY,
    // because the legacy rows carry hand-picked values.
    const rows = await query('sp_village_charge_type', {
      operation: 'Update',
      payment_type: { type: sql.Int, value: 0 },
      ...chargeTypeParams(req.body),
    });
    return ok(res, { created: true, payment_type: rows[0]?.payment_type ?? null }, 201);
  }),
);

router.put(
  '/charge-types/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await query('sp_village_charge_type', {
      operation: 'Update',
      payment_type: { type: sql.Int, value: id },
      ...chargeTypeParams(req.body),
    });
    return ok(res, { payment_type: id });
  }),
);

router.delete(
  '/charge-types/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    // Deactivated, not deleted: bills already raised refer to the charge.
    await exec('sp_village_charge_type', {
      operation: 'Delete',
      payment_type: { type: sql.Int, value: id },
    });
    return ok(res, { deactivated: true, payment_type: id });
  }),
);

/* ----------------------------------------------------------- house charges */

/*
 * Which charges apply to which house — the house_charge table.
 *
 * The three columns on dbo.house said every house owed every charge, so a
 * house with no tap connection was still billed for water. A row here means
 * the charge applies; no row means it does not, and nothing is raised.
 *
 * Grid_Show returns every house crossed with every charge type, so a row comes
 * back for combinations that do not apply too, carrying applies = false.
 */
router.get(
  '/house-charges',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_house_charge', {
      operation: 'Grid_Show',
      village_id: VIL(req.villageId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.put(
  '/house-charges',
  asyncHandler(async (req, res) => {
    const body = req.body ?? {};
    const applies = bool(body.applies, 'applies', { default: false });
    await exec('sp_house_charge', {
      operation: 'Update',
      village_id: VIL(req.villageId),
      house_id: { type: sql.Int, value: int(body.houseId, 'houseId', { min: 1 }) },
      payment_type: { type: sql.Int, value: int(body.paymentType, 'paymentType', { min: 1 }) },
      /*
       * Amount is only meaningful when the charge applies. Sending it as NULL
       * on the way out leaves the stored figure alone, so switching a charge
       * off and back on does not silently blank what the house was charged.
       */
      amount: {
        type: sql.Decimal(18, 2),
        value: applies ? num(body.amount, 'amount', { min: 0, required: false, default: null }) : null,
      },
      applies: { type: sql.Bit, value: applies },
    });
    return ok(res, { saved: true });
  }),
);

/* ---------------------------------------------------------------- settings */

/*
 * Billing settings, one row per village — see village_setting in
 * SQL/ADD_village_billing_v2.sql. The SP creates the row from its defaults on
 * first read, so a village that has never opened this page still gets a
 * complete answer rather than an empty one.
 */
router.get(
  '/settings',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_village_setting', {
      operation: 'Select',
      village_id: VIL(req.villageId),
    });
    return ok(res, { settings: rows[0] ?? null });
  }),
);

router.put(
  '/settings',
  asyncHandler(async (req, res) => {
    const body = req.body ?? {};
    await exec('sp_village_setting', {
      operation: 'Update',
      village_id: VIL(req.villageId),
      auto_bill_generation: {
        type: sql.Bit,
        value: bool(body.autoBillGeneration, 'autoBillGeneration', { default: false }),
      },
      /*
       * Capped at 28 to match the CHECK on the column: a 29th, 30th or 31st
       * would skip February and that month's bills would never be raised.
       */
      bill_gen_day: {
        type: sql.TinyInt,
        value: int(body.billGenDay, 'billGenDay', { min: 1, max: 28, required: false, default: 1 }),
      },
      property_tax_month: {
        type: sql.TinyInt,
        value: int(body.propertyTaxMonth, 'propertyTaxMonth', { min: 1, max: 12, required: false, default: 4 }),
      },
      due_days: {
        type: sql.SmallInt,
        value: int(body.dueDays, 'dueDays', { min: 0, max: 365, required: false, default: 30 }),
      },
      interest_rate: {
        type: sql.Decimal(5, 2),
        value: num(body.interestRate, 'interestRate', { min: 0, max: 100, required: false, default: 0 }),
      },
      interest_after_days: {
        type: sql.SmallInt,
        value: int(body.interestAfterDays, 'interestAfterDays', { min: 0, max: 365, required: false, default: 30 }),
      },
    });
    return ok(res, { saved: true });
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

    /*
     * What the legacy modal actually asked for, per method. toggleTransactionRef()
     * showed Transaction Reference only for UPI (4) and only Cheque No. plus
     * Cheque Date for cheques (2); cash asked for nothing.
     *
     * Requiring a reference for cheques as well — which this used to — rejected
     * every cheque payment the form could produce, because the form never
     * offered that box for a cheque.
     */
    if (payMode === 4 && !transactionRef) {
      throw ApiError.badRequest('Transaction reference is required for a UPI payment');
    }
    if (payMode === 2 && (!chequeNo || !chequeDate)) {
      throw ApiError.badRequest('Cheque number and cheque date are required for a cheque payment');
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

/* ---------------------------------------------------------- announcements */

/*
 * v_announcement.aspx. Its three tabs — General, Meeting Updates, and Work &
 * Budget Information — are the `category` column; the legacy page had no table
 * behind it at all, filling each tab from a DataTable built in code and keeping
 * anything added in a static in-memory list.
 *
 * Every branch is scoped to req.villageId, which comes from the token.
 * See SQL/ADD_village_announcement.sql.
 */
const ANNOUNCEMENT_CATEGORIES = ['General', 'Meeting', 'WorkBudget'];

router.get(
  '/announcements',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const rows = await query('sp_village_announcement', {
      operation: search ? 'Search' : 'Grid_Show',
      village_id: VIL(req.villageId),
      ...(search ? { search: { type: sql.NVarChar(200), value: search } } : {}),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/announcements',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_village_announcement', {
      operation: 'Update',
      announcement_id: { type: sql.Int, value: 0 },
      village_id: VIL(req.villageId),
      category: {
        type: sql.NVarChar(20),
        value:
          oneOf(req.body?.category, 'category', ANNOUNCEMENT_CATEGORIES, { required: false }) ??
          'General',
      },
      title: { type: sql.NVarChar(150), value: str(req.body?.title, 'title', { max: 150 }) },
      description: {
        type: sql.NVarChar(500),
        value: optionalStr(req.body?.description, 'description', { max: 500 }),
      },
      date: { type: sql.Date, value: date(req.body?.date, 'date', { required: false }) },
      valid_to: { type: sql.Date, value: date(req.body?.validTo, 'validTo', { required: false }) },
    });
    return ok(res, { announcement_id: created?.announcement_id ?? null }, 201);
  }),
);

router.put(
  '/announcements/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_village_announcement', {
      operation: 'Update',
      announcement_id: { type: sql.Int, value: id },
      // The SP matches on village_id as well, so one village cannot edit
      // another's announcement by guessing an id.
      village_id: VIL(req.villageId),
      category: {
        type: sql.NVarChar(20),
        value: oneOf(req.body?.category, 'category', ANNOUNCEMENT_CATEGORIES, { required: false }),
      },
      title: { type: sql.NVarChar(150), value: str(req.body?.title, 'title', { max: 150 }) },
      description: {
        type: sql.NVarChar(500),
        value: optionalStr(req.body?.description, 'description', { max: 500 }),
      },
      date: { type: sql.Date, value: date(req.body?.date, 'date', { required: false }) },
      valid_to: { type: sql.Date, value: date(req.body?.validTo, 'validTo', { required: false }) },
    });
    return ok(res, { announcement_id: id });
  }),
);

router.delete(
  '/announcements/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_village_announcement', {
      operation: 'Delete',
      announcement_id: { type: sql.Int, value: id },
      village_id: VIL(req.villageId),
    });
    return ok(res, { deleted: true, announcement_id: id });
  }),
);

/* --------------------------------------------------------------- dashboard */

/**
 * GET /village/dashboard — the figures behind village_dashboard.aspx.
 *
 * The legacy page had no data source at all: every number on it was a literal
 * in village_dashboard.aspx.cs (`int waterTaxPaid = 27300;`,
 * `int malePopulation = 2845;`) and its "Recent Activities" list was written by
 * hand. There is no stored procedure for any of it, so the counts are computed
 * here from the tables the village screens already write.
 *
 * Every branch is scoped to req.villageId, which comes from the token.
 *
 * Property tax is billed yearly and water/waste monthly, matching the legacy
 * card titles: "Property Tax (Yearly)", "Water Tax (Monthly)",
 * "Waste Tax (Monthly)".
 *
 * `due` on a tax row is what is still owed, so paid = amount - due. Rows are
 * summed rather than counted because the cards show money, not bills.
 */
router.get(
  '/dashboard',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();
    const result = await pool
      .request()
      .input('village_id', sql.NVarChar(10), req.villageId)
      .query(`
        /*
         * All three cards read house_tax_receipt — the table bills are raised
         * into and payments are settled against.
         *
         * They used to read dbo.house_tax and dbo.water_tax, which nothing
         * writes: both are empty for every village, so the cards showed 0 no
         * matter how many bills existed. Waste read the per-house charge on
         * dbo.house, which is the rate rather than what was billed, and had no
         * collection figure at all.
         *
         * Amount_paid holds the bill's amount whether or not it has been
         * settled; payment_status says which. So total is every bill in the
         * period, and paid is the settled ones.
         */

        -- Property tax, this year. It is charged yearly, so the year is the
        -- period; bill_year is the year the bill is *for*, not when it was
        -- raised.
        SELECT
          ISNULL(SUM(ISNULL(r.Amount_paid, 0)), 0)                                    AS total,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN ISNULL(r.Amount_paid, 0) ELSE 0 END), 0) AS paid,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN 1 ELSE 0 END), 0)            AS paidCount,
          ISNULL(SUM(CASE WHEN r.payment_status = 0 THEN 1 ELSE 0 END), 0)            AS pendingCount
        FROM dbo.house_tax_receipt AS r
        JOIN dbo.Village_payment_type AS t ON t.payment_type = r.payment_type
        WHERE r.village_id = @village_id
          AND t.frequency = 'Y'
          AND r.bill_year = YEAR(GETDATE());

        -- Water, this month.
        SELECT
          ISNULL(SUM(ISNULL(r.Amount_paid, 0)), 0)                                    AS total,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN ISNULL(r.Amount_paid, 0) ELSE 0 END), 0) AS paid,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN 1 ELSE 0 END), 0)            AS paidCount,
          ISNULL(SUM(CASE WHEN r.payment_status = 0 THEN 1 ELSE 0 END), 0)            AS pendingCount
        FROM dbo.house_tax_receipt AS r
        WHERE r.village_id = @village_id
          AND r.payment_type = 2
          AND r.bill_year  = YEAR(GETDATE())
          AND r.bill_month = MONTH(GETDATE());

        -- Waste, this month. Now a billed figure like the other two, so it
        -- carries a collection total rather than "no collection record".
        SELECT
          ISNULL(SUM(ISNULL(r.Amount_paid, 0)), 0)                                    AS total,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN ISNULL(r.Amount_paid, 0) ELSE 0 END), 0) AS paid,
          ISNULL(SUM(CASE WHEN r.payment_status = 1 THEN 1 ELSE 0 END), 0)            AS paidCount,
          ISNULL(SUM(CASE WHEN r.payment_status = 0 THEN 1 ELSE 0 END), 0)            AS pendingCount
        FROM dbo.house_tax_receipt AS r
        WHERE r.village_id = @village_id
          AND r.payment_type = 3
          AND r.bill_year  = YEAR(GETDATE())
          AND r.bill_month = MONTH(GETDATE());

        -- Population. house_owner carries no gender column, so the legacy
        -- card's male/female split cannot be derived and only the total is
        -- reported.
        SELECT COUNT(*) AS residents
        FROM dbo.house_owner
        WHERE village_id = @village_id
          AND ISNULL(active_status, 0) = 0;

        SELECT COUNT(*) AS houses
        FROM dbo.house
        WHERE village_id = @village_id;

        -- Twelve months of collection, for the trend chart. Months with no
        -- receipts are absent here and zero-filled on the client, so the line
        -- runs flat rather than stopping short.
        SELECT
          YEAR(pay_date)                       AS y,
          MONTH(pay_date)                      AS m,
          ISNULL(SUM(ISNULL(Amount_paid, 0)), 0) AS collected,
          COUNT(*)                             AS receipts
        FROM dbo.house_tax_receipt
        WHERE village_id = @village_id
          AND pay_date IS NOT NULL
          AND pay_date >= DATEADD(MONTH, -11, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
        GROUP BY YEAR(pay_date), MONTH(pay_date)
        ORDER BY y, m;

        -- Collection split by what was being paid for. Village_payment_type
        -- names the codes (1 Property Tax, 2 Water Charges, 3 Waste Charges).
        SELECT
          t.payment_type_name                    AS label,
          ISNULL(SUM(ISNULL(r.Amount_paid, 0)), 0) AS amount,
          COUNT(*)                               AS receipts
        FROM dbo.house_tax_receipt r
        LEFT JOIN dbo.Village_payment_type t ON r.payment_type = t.payment_type
        WHERE r.village_id = @village_id
        GROUP BY t.payment_type_name
        ORDER BY amount DESC;

        -- Outstanding across both billed taxes, and the staff on the books.
        SELECT
          (SELECT ISNULL(SUM(ISNULL(due, 0)), 0) FROM dbo.house_tax
            WHERE village_id = @village_id AND ISNULL(active_status, 0) = 0)
          + (SELECT ISNULL(SUM(ISNULL(due, 0)), 0) FROM dbo.water_tax
            WHERE village_id = @village_id AND ISNULL(active_status, 0) = 0) AS outstanding,
          (SELECT COUNT(*) FROM dbo.Village_staff WHERE village_id = @village_id) AS staff;

        -- Recent activity: the last receipts, which is what the legacy list
        -- pretended to show.
        SELECT TOP 8
          r.receipt_no,
          r.pay_date,
          r.Amount_paid       AS amount,
          r.payment_type      AS typeCode,
          t.payment_type_name AS typeName,
          h.house_no,
          o.name              AS owner_name
        FROM dbo.house_tax_receipt r
        LEFT JOIN dbo.house h                  ON r.house_id = h.house_id
        LEFT JOIN dbo.house_owner o            ON o.house_id = h.house_id
                                              AND ISNULL(o.active_status, 0) = 0
        LEFT JOIN dbo.Village_payment_type t   ON r.payment_type = t.payment_type
        WHERE r.village_id = @village_id
        ORDER BY r.pay_date DESC, r.house_receipt_id DESC;
      `);

    const [propertyTax, waterTax, wasteTax, population, houses, trend, split, totals, activity] =
      result.recordsets;

    return ok(res, {
      propertyTax: propertyTax[0] ?? { total: 0, paid: 0, paidCount: 0, pendingCount: 0 },
      waterTax: waterTax[0] ?? { total: 0, paid: 0, paidCount: 0, pendingCount: 0 },
      // Waste is billed like the other two now, so it has the same shape —
      // paid is a figure rather than the null that meant "not recorded".
      wasteTax: wasteTax[0] ?? { total: 0, paid: 0, paidCount: 0, pendingCount: 0 },
      residents: population[0]?.residents ?? 0,
      houses: houses[0]?.houses ?? 0,
      outstanding: totals[0]?.outstanding ?? 0,
      staff: totals[0]?.staff ?? 0,
      trend,
      split,
      activity,
    });
  }),
);

module.exports = router;
