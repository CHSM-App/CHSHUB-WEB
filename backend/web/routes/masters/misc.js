// Website API — remaining master screens.
// staff, staff roles, caretakers, helpers, useful contacts, document types,
// inventory, parking, parking allotment, car pooling, loans, society profile
// and committee members.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, time } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const SOC50 = (v) => ({ type: sql.NVarChar(50), value: v });

/**
 * Most of these screens are a list + upsert + soft delete over a single SP.
 * `simpleCrud` mounts that shape once rather than repeating it a dozen times.
 *
 *   path      route segment
 *   proc      stored procedure
 *   idField   SP parameter holding the primary key
 *   socParam  society parameter binding (SOC or SOC50)
 *   fields    (body) => SP parameters for insert/update
 *   ops       branch names, when they differ from the usual set
 */
function simpleCrud({
  path,
  proc,
  idField,
  socParam = SOC,
  fields,
  ops = {},
  searchable = true,
  socOnList = true,
  // Some SPs list through their Search branch, whose `LIKE @search + '%'`
  // matches nothing when @search is NULL. Those need '' sent for "everything".
  alwaysSendSearch = false,
}) {
  const op = {
    list: 'Grid_Show',
    search: 'Search',
    select: 'Select',
    upsert: 'Update',
    remove: 'Delete',
    ...ops,
  };

  router.get(
    `/${path}`,
    asyncHandler(async (req, res) => {
      const search = searchable ? optionalStr(req.query.search, 'search', { max: 200 }) : null;
      const sendSearch = search || (alwaysSendSearch ? '' : null);
      const rows = await query(proc, {
        operation: search ? op.search : op.list,
        ...(socOnList ? { society_id: socParam(req.societyId) } : {}),
        ...(sendSearch === null ? {} : { search: { type: sql.NVarChar(200), value: sendSearch } }),
      });
      return ok(res, { items: rows, count: rows.length });
    }),
  );

  router.get(
    `/${path}/:id`,
    asyncHandler(async (req, res) => {
      const id = int(req.params.id, 'id', { min: 1 });
      const rows = await query(proc, {
        operation: op.select,
        [idField]: { type: sql.Int, value: id },
      });
      const row = rows[0];
      // Most 'Select' branches ignore society, so scope here when the row carries it.
      if (!row || (row.society_id && String(row.society_id) !== String(req.societyId))) {
        throw ApiError.notFound('Not found');
      }
      return ok(res, { item: row });
    }),
  );

  router.post(
    `/${path}`,
    asyncHandler(async (req, res) => {
      const created = await exec(proc, {
        operation: op.upsert,
        [idField]: { type: sql.Int, value: 0 },
        society_id: socParam(req.societyId),
        ...fields(req.body, req),
      });
      return ok(res, { created: true, result: created ?? null }, 201);
    }),
  );

  router.put(
    `/${path}/:id`,
    asyncHandler(async (req, res) => {
      const id = int(req.params.id, 'id', { min: 1 });
      await exec(proc, {
        operation: op.upsert,
        [idField]: { type: sql.Int, value: id },
        society_id: socParam(req.societyId),
        ...fields(req.body, req),
      });
      return ok(res, { updated: true, id });
    }),
  );

  router.delete(
    `/${path}/:id`,
    asyncHandler(async (req, res) => {
      const id = int(req.params.id, 'id', { min: 1 });
      await exec(proc, { operation: op.remove, [idField]: { type: sql.Int, value: id } });
      return ok(res, { deleted: true, id });
    }),
  );
}

/* ------------------------------------------------------------------- staff */

simpleCrud({
  path: 'staff',
  proc: 'sp_staff_master',
  idField: 'staff_id',
  socParam: SOC50,
  fields: (b) => ({
    name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
    address: { type: sql.NVarChar(50), value: optionalStr(b?.address, 'address', { max: 50 }) },
    contact_no: { type: sql.NVarChar(10), value: optionalStr(b?.contactNo, 'contactNo', { max: 10 }) },
    email: { type: sql.NVarChar(50), value: optionalStr(b?.email, 'email', { max: 50 }) },
    date_of_join: { type: sql.SmallDateTime, value: date(b?.dateOfJoin, 'dateOfJoin', { required: false }) },
    role_id: { type: sql.Int, value: int(b?.roleId, 'roleId', { min: 0, required: false, default: 0 }) },
    role: { type: sql.NVarChar(50), value: optionalStr(b?.role, 'role', { max: 50 }) },
    image: { type: sql.NVarChar(500), value: optionalStr(b?.imagePath, 'imagePath', { max: 500 }) },
    id_proof: { type: sql.NVarChar(sql.MAX), value: optionalStr(b?.idProofPath, 'idProofPath') },
    salary: { type: sql.Decimal(18, 2), value: num(b?.salary, 'salary', { min: 0, required: false, default: 0 }) },
  }),
});

router.get(
  '/staff-roles',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_staff_master', { operation: 'Role_Show' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/staff/:id/attendance',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_staff_master', {
      operation: 'GetAttendace',
      staff_id: { type: sql.Int, value: id },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.get(
  '/staff-attendance/today',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_staff_attendance', {
      operation: 'GetStaffAttendance',
      society_id: SOC50(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/* -------------------------------------------------------------- caretakers */

simpleCrud({
  path: 'caretakers',
  proc: 'sp_caretaker_master',
  idField: 'caretaker_id',
  fields: (b) => ({
    c_name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
    doc_id: { type: sql.Int, value: int(b?.docId, 'docId', { min: 0, required: false, default: 0 }) },
    c_address: { type: sql.NVarChar(50), value: optionalStr(b?.address, 'address', { max: 50 }) },
    area: { type: sql.NVarChar(50), value: optionalStr(b?.area, 'area', { max: 50 }) },
    city: { type: sql.NVarChar(50), value: optionalStr(b?.city, 'city', { max: 50 }) },
    pincode: { type: sql.NVarChar(50), value: optionalStr(b?.pincode, 'pincode', { max: 50 }) },
    state_id: { type: sql.Int, value: int(b?.stateId, 'stateId', { min: 0, required: false, default: 0 }) },
    mobile_no: { type: sql.NVarChar(50), value: optionalStr(b?.mobile, 'mobile', { max: 50 }) },
    email: { type: sql.NVarChar(50), value: optionalStr(b?.email, 'email', { max: 50 }) },
    doc_executed: { type: sql.NVarChar(50), value: optionalStr(b?.docExecuted, 'docExecuted', { max: 50 }) },
    wing_id: { type: sql.Int, value: int(b?.wingId, 'wingId', { min: 0, required: false, default: 0 }) },
    flat_no: { type: sql.NVarChar(50), value: optionalStr(b?.flatNo, 'flatNo', { max: 50 }) },
  }),
});

/* ----------------------------------------------------------------- helpers */

/**
 * servent_search.aspx offers five services, each a checkbox plus a charge:
 * meal, cloth wash, plate/utensil wash, floor wash and baby-sitting. The
 * columns and SP parameters both exist, so they are sent here rather than
 * dropped — without them a helper's services and rates are lost on save.
 */
const HELPER_SERVICES = [
  { flag: 'meal', charge: 'meal_charge', body: 'meal' },
  { flag: 'cloth_wash', charge: 'cloth_wash_charge', body: 'clothWash' },
  { flag: 'b_wash', charge: 'b_wash_charge', body: 'utensilWash' },
  { flag: 'f_wash', charge: 'f_wash_charge', body: 'floorWash' },
  { flag: 'baby_set', charge: 'b_set_charge', body: 'babySitting' },
];

function helperServiceParams(b) {
  const out = {};
  for (const s of HELPER_SERVICES) {
    const on = Boolean(b?.[s.body]);
    out[s.flag] = { type: sql.Int, value: on ? 1 : 0 };
    // A charge is only meaningful when the service is selected.
    out[s.charge] = {
      type: sql.Float,
      value: on ? num(b?.[`${s.body}Charge`], `${s.body}Charge`, { min: 0, required: false, default: 0 }) : 0,
    };
  }
  return out;
}

simpleCrud({
  path: 'helpers',
  proc: 'sp_servent_maid_master',
  idField: 'servent_id',
  fields: (b) => ({
    s_name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
    s_address_1: { type: sql.NVarChar(250), value: optionalStr(b?.address1, 'address1', { max: 250 }) },
    s_address_2: { type: sql.NVarChar(250), value: optionalStr(b?.address2, 'address2', { max: 250 }) },
    mobile_no1: { type: sql.NVarChar(10), value: optionalStr(b?.mobile1, 'mobile1', { max: 10 }) },
    mobile_no2: { type: sql.NVarChar(10), value: optionalStr(b?.mobile2, 'mobile2', { max: 10 }) },
    remark: { type: sql.NVarChar(500), value: optionalStr(b?.remark, 'remark', { max: 500 }) },
    ...helperServiceParams(b),
  }),
});

/* ---------------------------------------------------------- useful contacts */

/*
 * Contacts list through 'Search' rather than 'Grid_Show', which returns
 * nothing. That branch matches `LIKE @search + '%'`, so an unset @search is
 * `LIKE NULL` and matches no row — the list came back empty even though the
 * society has 18 contacts. simpleCrud therefore sends '' when no term is
 * given, which the SP treats as "everything".
 */
simpleCrud({
  path: 'contacts',
  proc: 'sp_usefull_contact',
  idField: 'usefull_contact_id',
  ops: { list: 'Search', search: 'Search' },
  alwaysSendSearch: true,
  fields: (b) => ({
    p_name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
    p_type: { type: sql.Int, value: int(b?.typeId, 'typeId', { min: 0, required: false, default: 0 }) },
    org_name: { type: sql.NVarChar(50), value: optionalStr(b?.orgName, 'orgName', { max: 50 }) },
    contact_no: { type: sql.NVarChar(10), value: optionalStr(b?.contactNo, 'contactNo', { max: 10 }) },
    contact_address: { type: sql.NVarChar(250), value: optionalStr(b?.address, 'address', { max: 250 }) },
    address2: { type: sql.NVarChar(250), value: optionalStr(b?.address2, 'address2', { max: 250 }) },
    email: { type: sql.NVarChar(50), value: optionalStr(b?.email, 'email', { max: 50 }) },
    remark: { type: sql.NVarChar(50), value: optionalStr(b?.remark, 'remark', { max: 50 }) },
    id_path: { type: sql.NVarChar(sql.MAX), value: optionalStr(b?.idPath, 'idPath') },
  }),
});

router.get(
  '/contact-types',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_usefull_contact', { operation: 'fill_list' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/* ----------------------------------------------------------- document types */

simpleCrud({
  path: 'doc-types',
  proc: 'sp_doc_master',
  idField: 'doc_id',
  fields: (b) => ({
    doc_name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
  }),
});

/* --------------------------------------------------------------- inventory */

router.get(
  '/inventory',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_inventory_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/inventory',
  asyncHandler(async (req, res) => {
    await exec('sp_inventory_master', {
      operation: 'UPDATE',
      item_id: { type: sql.Int, value: int(req.body?.itemId, 'itemId', { required: false, default: 0 }) },
      item_name: { type: sql.NVarChar(100), value: str(req.body?.name, 'name', { max: 100 }) },
      total_amount: { type: sql.Decimal(18, 2), value: num(req.body?.totalAmount, 'totalAmount', { min: 0, required: false, default: 0 }) },
      tax: { type: sql.Decimal(18, 2), value: num(req.body?.tax, 'tax', { min: 0, required: false, default: 0 }) },
      quantity: { type: sql.Int, value: int(req.body?.quantity, 'quantity', { min: 0, required: false, default: 0 }) },
      unit: { type: sql.NVarChar(20), value: optionalStr(req.body?.unit, 'unit', { max: 20 }) },
      purchase_date: { type: sql.Date, value: date(req.body?.purchaseDate, 'purchaseDate', { required: false }) },
      purchase_cost: { type: sql.Decimal(18, 2), value: num(req.body?.purchaseCost, 'purchaseCost', { min: 0, required: false, default: 0 }) },
      vendor_id: { type: sql.Int, value: int(req.body?.vendorId, 'vendorId', { min: 0, required: false, default: 0 }) },
      vendor_bill_id: { type: sql.Int, value: int(req.body?.vendorBillId, 'vendorBillId', { min: 0, required: false, default: 0 }) },
      condition_status: { type: sql.Int, value: int(req.body?.conditionStatus, 'conditionStatus', { min: 0, required: false, default: 0 }) },
      warranty: { type: sql.Int, value: int(req.body?.warrantyMonths, 'warrantyMonths', { min: 0, required: false, default: 0 }) },
      remarks: { type: sql.NVarChar(sql.MAX), value: optionalStr(req.body?.remarks, 'remarks') },
      society_id: SOC(req.societyId),
    });
    return ok(res, { saved: true }, 201);
  }),
);

router.delete(
  '/inventory/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_inventory_master', { operation: 'DELETE', item_id: { type: sql.Int, value: id } });
    return ok(res, { deleted: true, item_id: id });
  }),
);

/* ----------------------------------------------------------------- parking */

simpleCrud({
  path: 'parking-places',
  proc: 'sp_parking',
  idField: 'place_id',
  fields: (b) => ({
    parking_no: { type: sql.NVarChar(50), value: str(b?.parkingNo, 'parkingNo', { max: 50 }) },
    park_for: { type: sql.Int, value: int(b?.parkFor, 'parkFor', { min: 0, max: 1, required: false, default: 0 }) },
  }),
});

/**
 * GET /masters/parking-allotment
 *
 * Grid_Show joins `owner_master ON o.flat_id = v.flat_id`, which yields one row
 * per *occupant* of the flat rather than one per allotment. A flat with an
 * owner and a tenant therefore lists each of its vehicles twice, under both
 * names — it looks as if the same vehicle and place were allotted to two
 * people, when `Vehicle` holds a single row.
 *
 * The SP is shared with the legacy app, so the duplicates are collapsed here:
 * one row per vehicle, preferring the owner over a tenant for the name shown.
 * The preference is resolved against owner_master rather than by trusting row
 * order, which the SP does not guarantee.
 */
router.get(
  '/parking-allotment',
  asyncHandler(async (req, res) => {
    const pool = await require('../../lib/db').getPool();

    const [rows, residents, allotted] = await Promise.all([
      query('sp_parking_master', { operation: 'Grid_Show', society_id: SOC(req.societyId) }),
      query('sp_owner_master', {
        operation: 'Grid_Show',
        type: { type: sql.NVarChar(10), value: 'Owner' },
        society_id: SOC(req.societyId),
      }).catch(() => []),
      // Grid_Show returns parking_no (the label) but not place_id (the value),
      // so Edit had nothing to preselect the place dropdown with.
      pool
        .request()
        .input('society_id', sql.NVarChar(10), req.societyId)
        .query(`
          SELECT vehicle_id, park_place_id
          FROM   Vehicle
          WHERE  society_id = @society_id AND park_place_id > 0`)
        .then((r) => r.recordset)
        .catch(() => []),
    ]);

    const placeByVehicle = new Map(
      allotted.map((v) => [Number(v.vehicle_id), Number(v.park_place_id)]),
    );

    // The owner of each flat, which is the name an allotment belongs to.
    const ownerByFlat = new Map(
      residents.map((r) => [Number(r.flat_id), String(r.name).trim()]),
    );

    const byVehicle = new Map();
    for (const row of rows) {
      if (byVehicle.has(row.vehicle_id)) continue;
      byVehicle.set(row.vehicle_id, {
        ...row,
        // Overwrite rather than pick a row: Grid_Show may hand back the tenant
        // first, and the allotment is the owner's either way.
        name: ownerByFlat.get(Number(row.flat_id)) ?? row.name,
        place_id: placeByVehicle.get(Number(row.vehicle_id)) ?? null,
      });
    }

    let items = [...byVehicle.values()];

    /*
     * The SP's own 'Search' branch cannot be used: it queries `parking_master`,
     * which holds no rows, while the grid comes from `Vehicle` — so it matches
     * nothing whatever the term. Filtered here instead, across every column the
     * grid actually shows, so searching for what is on screen works: owner,
     * vehicle, parking number, model, type (Car/Bike) and contact.
     */
    const search = optionalStr(req.query.search, 'search', { max: 100 });
    if (search) {
      const needle = search.toLowerCase();
      const matches = (v) => String(v ?? '').toLowerCase().includes(needle);
      items = items.filter(
        (r) =>
          matches(r.name) ||
          matches(r.vehicle_no) ||
          matches(r.parking_no) ||
          matches(r.model_name) ||
          // park_for is the Type column — 'Car' or 'Bike'.
          matches(r.park_for) ||
          matches(r.pre_mob),
      );
    }

    return ok(res, { items, count: items.length });
  }),
);

/**
 * GET /masters/parking-allotment/lookups?flatId=&parkFor=
 *
 * The three pickers on parking_allotment_search.aspx.
 *
 * The vehicle list matters more than it looks: 'AssignPlace' is only an
 * `UPDATE vehicle SET park_place_id … WHERE vehicle_no = @vehicle_no AND
 * flat_id = @flat_id`. It never inserts. A vehicle number that does not
 * already exist for that flat matches no row, and the assignment silently does
 * nothing — which is why the vehicle has to be *chosen*, not typed.
 *
 * `fill_vehicle` returns that flat's vehicles with no place yet, and
 * `fill_place` the places still free **for that vehicle's type** — a bike
 * cannot take a car bay. Note the branch filters `park_for = @vehicle_id`:
 * despite the name, that parameter carries the *vehicle type* (0 bike, 1 car),
 * not a vehicle id. Passing @park_for instead returns everything.
 */
router.get(
  '/parking-allotment/lookups',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 0, required: false, default: 0 });
    const vehicleType = int(req.query.vehicleType, 'vehicleType', {
      min: 0,
      max: 1,
      required: false,
      default: 0,
    });

    const [ownerRows, residents, vehicles, places] = await Promise.all([
      query('sp_parking_master', { operation: 'fill_owner', society_id: SOC(req.societyId) }),
      // fill_owner does not expose `type`, so the owner/tenant split comes from
      // the resident list.
      query('sp_owner_master', {
        operation: 'Grid_Show',
        type: { type: sql.NVarChar(10), value: 'Owner' },
        society_id: SOC(req.societyId),
      }).catch(() => []),
      // Only meaningful once a resident is chosen.
      flatId
        ? query('sp_parking_master', {
            operation: 'fill_vehicle',
            society_id: SOC(req.societyId),
            flat_id: { type: sql.Int, value: flatId },
          })
        : Promise.resolve([]),
      query('sp_parking_master', {
        operation: 'fill_place',
        society_id: SOC(req.societyId),
        vehicle_id: { type: sql.Int, value: vehicleType },
      }),
    ]);

    /*
     * fill_owner selects every row in owner_master for the society, without
     * filtering on `type` — so a flat with an owner and a tenant produced two
     * entries carrying the same flat_id, which a dropdown cannot tell apart.
     *
     * Parking belongs to the flat and the flat belongs to its owner, so the
     * owner is the name to show. Resolved against owner_master by type rather
     * than by picking whichever row came first.
     */
    // sp_owner_master/Grid_Show is already scoped to type='Owner' above.
    const ownersByFlat = new Map(
      residents.map((r) => [Number(r.flat_id), String(r.name).trim()]),
    );

    const seen = new Set();
    const owners = [];
    for (const row of ownerRows) {
      const flatId = Number(row.flat_id);
      if (seen.has(flatId)) continue;
      seen.add(flatId);
      owners.push({
        flat_id: flatId,
        // Fall back to whatever fill_owner gave if a flat has no Owner row.
        name: ownersByFlat.get(flatId) ?? String(row.name).trim(),
      });
    }

    return ok(res, { owners, vehicles, places });
  }),
);

/**
 * POST /masters/parking-allotment/assign
 *
 * 'AssignPlace' updates the vehicle row and reports nothing back, so a vehicle
 * number that does not belong to that flat used to look like a successful save
 * while changing nothing. Check first and say so instead.
 */
router.post(
  '/parking-allotment/assign',
  asyncHandler(async (req, res) => {
    const placeId = int(req.body?.placeId, 'placeId', { min: 1 });
    const vehicleNo = str(req.body?.vehicleNo, 'vehicleNo', { max: 20 });
    const flatId = int(req.body?.flatId, 'flatId', { min: 1 });

    const pool = await require('../../lib/db').getPool();
    const check = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .input('flat_id', sql.Int, flatId)
      .input('vehicle_no', sql.NVarChar(20), vehicleNo)
      .query(`
        SELECT vehicle_id, park_place_id
        FROM   Vehicle
        WHERE  society_id = @society_id AND flat_id = @flat_id AND vehicle_no = @vehicle_no`);

    const vehicle = check.recordset[0];
    if (!vehicle) {
      throw ApiError.badRequest(
        `No vehicle "${vehicleNo}" is registered against this flat. Register the vehicle first, then allot a place.`,
      );
    }

    /*
     * AssignPlace writes park_place_id without checking whether another
     * vehicle already holds that place, so two vehicles can end up on one
     * bay. The dropdown only offers free places, but nothing stopped a stale
     * form or a direct call, so the check belongs here.
     */
    const clash = await pool
      .request()
      .input('society_id', sql.NVarChar(10), req.societyId)
      .input('place_id', sql.Int, placeId)
      .input('vehicle_id', sql.Int, vehicle.vehicle_id)
      .query(`
        SELECT TOP 1 v.vehicle_no, p.parking_no
        FROM   Vehicle v
        JOIN   parking p ON p.place_id = v.park_place_id
        WHERE  v.society_id = @society_id
          AND  v.park_place_id = @place_id
          AND  v.vehicle_id <> @vehicle_id`);

    if (clash.recordset[0]) {
      const { vehicle_no: holder, parking_no } = clash.recordset[0];
      throw ApiError.badRequest(
        `Parking place ${parking_no} is already allotted to ${holder}. Release it first, or pick another place.`,
      );
    }

    await exec('sp_parking_master', {
      operation: 'AssignPlace',
      place_id: { type: sql.Int, value: placeId },
      vehicle_no: { type: sql.NVarChar(20), value: vehicleNo },
      flat_id: { type: sql.Int, value: flatId },
      society_id: SOC(req.societyId),
    });
    return ok(res, { assigned: true, vehicle_id: vehicle.vehicle_id, place_id: placeId });
  }),
);

router.delete(
  '/parking-allotment/:vehicleId',
  asyncHandler(async (req, res) => {
    const id = int(req.params.vehicleId, 'vehicleId', { min: 1 });
    await exec('sp_parking_master', { operation: 'Delete', vehicle_id: { type: sql.Int, value: id } });
    return ok(res, { released: true, vehicle_id: id });
  }),
);

/* ------------------------------------------------------------- car pooling */

simpleCrud({
  path: 'car-pooling',
  proc: 'sp_car_polling',
  idField: 'car_id',
  fields: (b) => ({
    c_name: { type: sql.NVarChar(50), value: str(b?.name, 'name', { max: 50 }) },
    vehical_no: { type: sql.NVarChar(50), value: optionalStr(b?.vehicleNo, 'vehicleNo', { max: 50 }) },
    seat: { type: sql.NVarChar(50), value: optionalStr(b?.seats, 'seats', { max: 50 }) },
    time: { type: sql.SmallDateTime, value: time(b?.time, 'time', { required: false }) },
    date: { type: sql.SmallDateTime, value: date(b?.date, 'date', { required: false }) },
    destination: { type: sql.NVarChar(50), value: optionalStr(b?.destination, 'destination', { max: 50 }) },
    charges: { type: sql.NVarChar(50), value: optionalStr(b?.charges, 'charges', { max: 50 }) },
  }),
});

/* ------------------------------------------------------------------- loans */

simpleCrud({
  path: 'loans',
  proc: 'sp_loan',
  idField: 'loan_id',
  fields: (b) => ({
    bank: { type: sql.NVarChar(50), value: str(b?.bank, 'bank', { max: 50 }) },
    flat_id: { type: sql.Int, value: int(b?.flatId, 'flatId', { min: 1 }) },
    type_id: { type: sql.Int, value: int(b?.typeId, 'typeId', { min: 0, required: false, default: 0 }) },
    cert_id: { type: sql.Int, value: int(b?.certificateId, 'certificateId', { min: 0, required: false, default: 0 }) },
    noc_issued: { type: sql.NVarChar(50), value: optionalStr(b?.nocIssued, 'nocIssued', { max: 50 }) },
    society_noc: { type: sql.Date, value: date(b?.societyNocDate, 'societyNocDate', { required: false }) },
    loan_clearance: { type: sql.Date, value: date(b?.loanClearanceDate, 'loanClearanceDate', { required: false }) },
  }),
});

/* -------------------------------------------------------- society profile */

router.get(
  '/society',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_society_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { society: rows[0] ?? null });
  }),
);

router.get(
  '/society/flat-count',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_society_master', {
      operation: 'TotalFlats',
      society_id: SOC(req.societyId),
    });
    return ok(res, { flats: rows[0]?.flats ?? 0 });
  }),
);

/* --------------------------------------------------------- committee users */

router.get(
  '/members',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_UserLogin', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });
    // Never expose password hashes through a list endpoint.
    return ok(res, {
      items: rows.map(({ password, token, web_token, ...rest }) => rest),
      count: rows.length,
    });
  }),
);

/**
 * GET /masters/regions?stateId=&districtId= — the cascading state → district →
 * division lists behind society_search.aspx's three dropdowns.
 *
 * The legacy page built these queries by string concatenation
 * (`"... Where state_id=" + ddl_state.SelectedValue`, society_search.aspx.cs:391).
 * There is no stored procedure for them, so the tables are read directly here —
 * with bound parameters, not concatenation.
 */
router.get(
  '/regions',
  asyncHandler(async (req, res) => {
    const stateId = int(req.query.stateId, 'stateId', { min: 0, required: false, default: 0 });
    const districtId = int(req.query.districtId, 'districtId', { min: 0, required: false, default: 0 });

    const pool = await require('../../lib/db').getPool();
    const request = pool.request().input('state_id', sql.Int, stateId).input('district_id', sql.Int, districtId);

    const result = await request.query(`
      SELECT state_id, state FROM dbo.state ORDER BY state;
      SELECT district_id, district, state_id FROM dbo.district
      WHERE @state_id = 0 OR state_id = @state_id ORDER BY district;
      SELECT division_id, division, district_id FROM dbo.division
      WHERE @district_id = 0 OR district_id = @district_id ORDER BY division;`);

    const [states, districts, divisions] = result.recordsets;
    return ok(res, { states, districts, divisions });
  }),
);

/**
 * GET /masters/members/:id — one committee member.
 *
 * The list branch (`Grid_Show`) omits `owner_id`, so editing from the grid row
 * alone loses the resident the member is linked to. `Select` returns it.
 */
router.get(
  '/members/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const rows = await query('sp_UserLogin', {
      operation: 'Select',
      user_id: { type: sql.Int, value: id },
    });
    const row = rows[0];
    if (!row || String(row.society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Committee member not found');
    }
    // Never expose the hash.
    const { password, token, web_token, ...member } = row;
    return ok(res, { member });
  }),
);

/**
 * GET /masters/member-lookups — what society_member_search.aspx's two pickers
 * offered: the residents a committee member is chosen from (`fill_owner`) and
 * the designations (`fill_type`, i.e. UserType).
 *
 * `staff_role` is a different list entirely — it belongs to Staff_Master, not
 * to committee members.
 */
router.get(
  '/member-lookups',
  asyncHandler(async (req, res) => {
    const [owners, types] = await Promise.all([
      query('sp_UserLogin', { operation: 'fill_owner', society_id: SOC(req.societyId) }),
      query('sp_UserLogin', { operation: 'fill_type' }),
    ]);
    return ok(res, {
      // Only what the picker needs — this branch returns the whole owner row,
      // tokens and document paths included.
      owners: owners.map((o) => ({
        owner_id: o.owner_id,
        name: o.name,
        email: o.email,
        contact_no: o.pre_mob,
      })),
      types,
    });
  }),
);

/** GET /masters/member-types — committee designations (sp_UserLogin/fill_type). */
router.get(
  '/member-types',
  asyncHandler(async (_req, res) => {
    const rows = await query('sp_UserLogin', { operation: 'fill_type' });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * POST /masters/members — add a committee member.
 *
 * Backs the Society Member branch of society_search.aspx's Excel import, which
 * created the member *and* their login: username = email, password = the
 * contact number, hashed in the PBKDF2 format the legacy app writes.
 * `lib/password.js` produces the identical format, so imported members can sign
 * in exactly as they could before.
 *
 * 'chk_name' is used first, as the legacy import did, so re-running an import
 * skips members who already exist instead of duplicating them.
 */
router.post(
  '/members',
  asyncHandler(async (req, res) => {
    const name = str(req.body?.name, 'name', { max: 50 });
    const contactNo = str(req.body?.contactNo, 'contactNo', { max: 15 });
    const email = optionalStr(req.body?.email, 'email', { max: 50 });
    const userTypeId = int(req.body?.userTypeId, 'userTypeId', { min: 1 });

    // Duplicate probe — same branch and inputs the legacy import used.
    const existing = await query('sp_UserLogin', {
      operation: 'chk_name',
      society_id: SOC(req.societyId),
      Name: { type: sql.NVarChar(50), value: name },
      contact_no: { type: sql.NVarChar(15), value: contactNo },
    });
    if (existing.length) {
      throw ApiError.badRequest(`${name} is already a committee member`);
    }

    // The login the member signs in with. Username is the email, as before;
    // when the sheet has no email we fall back to the contact number rather
    // than creating an account with an empty username.
    const username = email || contactNo;
    const { hashPassword } = require('../../lib/password');

    await exec('sp_UserLogin', {
      operation: 'Update',
      user_id: { type: sql.Int, value: 0 },
      society_id: SOC(req.societyId),
      Name: { type: sql.NVarChar(50), value: name },
      user_type_id: { type: sql.Int, value: userTypeId },
      contact_no: { type: sql.NVarChar(15), value: contactNo },
      email: { type: sql.NVarChar(50), value: email },
      username: { type: sql.NVarChar(50), value: username },
      password: { type: sql.NVarChar(250), value: hashPassword(contactNo) },
      // The resident this committee member is. society_member_search.aspx
      // picked them from a list and stored the link.
      owner_id: { type: sql.Int, value: int(req.body?.ownerId, 'ownerId', { min: 0, required: false, default: 0 }) },
      active_status: { type: sql.Int, value: 0 },
    });

    return ok(res, { created: true, name, username }, 201);
  }),
);

/**
 * PUT /masters/members/:id — edit a committee member.
 *
 * The password is only rewritten when one is supplied, so an ordinary edit does
 * not silently reset the member's login. society_member_search.aspx always
 * hashed and wrote whatever was in the box, which meant editing a member with
 * the field blank replaced their password with the hash of an empty string.
 */
router.put(
  '/members/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await query('sp_UserLogin', {
      operation: 'check_delete',
      user_id: { type: sql.Int, value: id },
    });
    const current = existing[0];
    if (!current || String(current.society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Committee member not found');
    }

    const name = str(req.body?.name, 'name', { max: 50 });
    const contactNo = str(req.body?.contactNo, 'contactNo', { max: 15 });
    const email = optionalStr(req.body?.email, 'email', { max: 50 });
    const userTypeId = int(req.body?.userTypeId, 'userTypeId', { min: 1 });
    const username = optionalStr(req.body?.username, 'username', { max: 50 }) || email || contactNo;
    const newPassword = optionalStr(req.body?.password, 'password', { max: 100 });

    const { hashPassword } = require('../../lib/password');

    await exec('sp_UserLogin', {
      operation: 'Update',
      user_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      Name: { type: sql.NVarChar(50), value: name },
      user_type_id: { type: sql.Int, value: userTypeId },
      contact_no: { type: sql.NVarChar(15), value: contactNo },
      email: { type: sql.NVarChar(50), value: email },
      username: { type: sql.NVarChar(50), value: username },
      password: {
        type: sql.NVarChar(250),
        value: newPassword ? hashPassword(newPassword) : current.password,
      },
      owner_id: {
        type: sql.Int,
        value: int(req.body?.ownerId, 'ownerId', {
          min: 0,
          required: false,
          default: Number(current.owner_id) || 0,
        }),
      },
      active_status: { type: sql.Int, value: 0 },
    });

    return ok(res, { updated: true, user_id: id });
  }),
);

/** DELETE /masters/members/:id — soft delete (active_status = 1). */
router.delete(
  '/members/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await query('sp_UserLogin', {
      operation: 'check_delete',
      user_id: { type: sql.Int, value: id },
    });
    if (!existing[0] || String(existing[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Committee member not found');
    }

    await exec('sp_UserLogin', {
      operation: 'Delete',
      user_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, user_id: id });
  }),
);

module.exports = router;
