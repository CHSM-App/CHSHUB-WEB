// Website API — Owner and Tenant master.
// Replaces Society2024/owner_search.aspx and rental_search.aspx.
// Backed by sp_owner_master; listing comes from owner_search_vw.
//
// Owners and tenants are the same table distinguished by owner_master.type
// ('Owner' | 'Rent'), so one router serves both and the caller picks via ?type=.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, date, oneOf } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
const OWNER_TYPES = ['Owner', 'Rent'];

/** ?type=Owner|Rent, defaulting to Owner. */
function residentType(req) {
  return oneOf(req.query.type ?? req.body?.type ?? 'Owner', 'type', OWNER_TYPES);
}

/**
 * Field mapping shared by create and update.
 *
 * Tenants ('Rent') carry agreement and police-verification details; owners carry
 * possession date. Both sets are accepted and simply left null when not supplied,
 * matching how the legacy form posts.
 */
function ownerParams(body, type) {
  return {
    name: { type: sql.NVarChar(150), value: str(body?.name, 'name', { max: 150 }) },
    pre_mob: { type: sql.NVarChar(50), value: str(body?.mobile, 'mobile', { max: 50 }) },
    alter_mob: { type: sql.NVarChar(50), value: optionalStr(body?.altMobile, 'altMobile', { max: 50 }) },
    email: { type: sql.NVarChar(150), value: optionalStr(body?.email, 'email', { max: 150 }) },
    flat_id: { type: sql.Int, value: int(body?.flatId, 'flatId', { min: 1 }) },
    wing_id: { type: sql.Int, value: int(body?.wingId, 'wingId', { min: 1 }) },
    flat_type_id: { type: sql.Int, value: int(body?.flatTypeId, 'flatTypeId', { min: 1, required: false }) },
    married_id: { type: sql.Int, value: int(body?.marriedId, 'marriedId', { min: 1, required: false }) },
    dob: { type: sql.Date, value: date(body?.dob, 'dob', { required: false }) },
    occup: { type: sql.NVarChar(50), value: optionalStr(body?.occupation, 'occupation', { max: 50 }) },
    monthly_income: { type: sql.NVarChar(150), value: optionalStr(body?.monthlyIncome, 'monthlyIncome', { max: 150 }) },
    off_addr1: { type: sql.NVarChar(150), value: optionalStr(body?.officeAddress1, 'officeAddress1', { max: 150 }) },
    off_addr2: { type: sql.NVarChar(150), value: optionalStr(body?.officeAddress2, 'officeAddress2', { max: 150 }) },
    off_tel: { type: sql.NVarChar(150), value: optionalStr(body?.officeTel, 'officeTel', { max: 150 }) },
    doc_id: { type: sql.Int, value: int(body?.docId, 'docId', { min: 1, required: false }) },
    id_proof: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.idProofPath, 'idProofPath') },
    photo_name: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.photoPath, 'photoPath') },
    agreement_path: { type: sql.NVarChar(sql.MAX), value: optionalStr(body?.agreementPath, 'agreementPath') },
    police_verification_path: {
      type: sql.NVarChar(sql.MAX),
      value: optionalStr(body?.policeVerificationPath, 'policeVerificationPath'),
    },
    poss_date: { type: sql.Date, value: date(body?.possessionDate, 'possessionDate', { required: false }) },
    aggrement_date: { type: sql.Date, value: date(body?.agreementDate, 'agreementDate', { required: false }) },
    aggrement_period_from: {
      type: sql.Date,
      value: date(body?.agreementFrom, 'agreementFrom', { required: false }),
    },
    aggrement_period_to: { type: sql.Date, value: date(body?.agreementTo, 'agreementTo', { required: false }) },
    police_verification_date: {
      type: sql.Date,
      value: date(body?.policeVerificationDate, 'policeVerificationDate', { required: false }),
    },
    type: { type: sql.NVarChar(10), value: type },
  };
}

async function listResidents(societyId, type) {
  return query('sp_owner_master', {
    operation: 'Grid_Show',
    type: { type: sql.NVarChar(10), value: type },
    society_id: SOC(societyId),
  });
}

/** Read one resident, scoped to the society. */
async function findResident(societyId, ownerId) {
  const rows = await query('sp_owner_master', {
    operation: 'Select',
    owner_id: { type: sql.Int, value: ownerId },
  });
  const row = rows[0];
  if (!row || String(row.society_id) !== String(societyId)) return null;
  return row;
}

/**
 * A flat may hold one active owner and one active tenant, never two of a kind.
 * sp_owner_master's 'check_no' branch is unusable for edits — its else-branch
 * ends `owner_id = @owner_id AND owner_id <> @owner_id`, which is never true —
 * so the check is done here against the live grid.
 */
async function assertFlatFree(societyId, flatId, type, currentId = 0) {
  const rows = await listResidents(societyId, type);
  const clash = rows.find(
    (r) => Number(r.flat_id) === Number(flatId) && Number(r.owner_id) !== Number(currentId),
  );
  if (clash) {
    throw ApiError.conflict(
      type === 'Owner'
        ? 'This flat already has an owner assigned'
        : 'This flat already has a tenant assigned',
      { field: 'flatId', conflictingId: clash.owner_id, conflictingName: clash.name },
    );
  }
}

/** GET /api/web/masters/owners?type=Owner|Rent&search=&wingId=&buildingId= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const type = residentType(req);
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const wingId = int(req.query.wingId, 'wingId', { min: 1, required: false });
    const buildingId = int(req.query.buildingId, 'buildingId', { min: 1, required: false });

    let rows = search
      ? await query('sp_owner_master', {
          operation: 'Search',
          type: { type: sql.NVarChar(10), value: type },
          society_id: SOC(req.societyId),
          search: { type: sql.NVarChar(200), value: search },
        })
      : await listResidents(req.societyId, type);

    if (wingId) rows = rows.filter((r) => Number(r.wing_id) === wingId);
    if (buildingId) rows = rows.filter((r) => Number(r.build_id) === buildingId);

    return ok(res, { items: rows, count: rows.length, type });
  }),
);

/**
 * GET /api/web/masters/owners/lookups?type=Owner|Rent
 * Dropdown data for the resident form. Available flats differ by type:
 * owners pick from unallocated flats, tenants from owned-but-unrented ones.
 */
router.get(
  '/lookups',
  asyncHandler(async (req, res) => {
    const type = residentType(req);

    const [wings, docs, marital, flatsForType] = await Promise.all([
      query('sp_owner_master', { operation: 'Fill_wing', society_id: SOC(req.societyId) }),
      query('sp_owner_master', { operation: 'Fill_doc', society_id: SOC(req.societyId) }),
      query('sp_owner_master', { operation: 'married' }),
      query('sp_owner_master', {
        // 'flat_owners' lists flats with no owner; 'flat_types' lists flats
        // available to rent (is_rented = 0).
        operation: type === 'Owner' ? 'flat_owners' : 'flat_types',
        society_id: SOC(req.societyId),
      }),
    ]);

    return ok(res, { wings, docs, marital, availableFlats: flatsForType });
  }),
);

/** GET /api/web/masters/owners/defaulters — residents with outstanding dues. */
router.get(
  '/defaulters',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'getDefaulter',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/masters/owners/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const owner = await findResident(req.societyId, id);
    if (!owner) throw ApiError.notFound('Resident not found');
    return ok(res, { owner });
  }),
);

/** GET /api/web/masters/owners/:id/family — family members of a resident. */
router.get(
  '/:id/family',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    if (!(await findResident(req.societyId, id))) throw ApiError.notFound('Resident not found');

    const rows = await query('sp_owner_master', {
      operation: 'Grid_Show_Family',
      owner_id: { type: sql.Int, value: id },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * POST /api/web/masters/owners
 *
 * The SP also flips the flat's status: type 'rent' sets flat_master.is_rented,
 * anything else sets flat_status = 1. That behaviour is relied on by
 * owner_search_vw, so we let the SP own it rather than updating the flat here.
 */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const type = residentType(req);
    const fields = ownerParams(req.body, type);

    await assertFlatFree(req.societyId, fields.flat_id.value, type, 0);

    const inserted = await exec('sp_owner_master', {
      operation: 'Update',
      owner_id: { type: sql.Int, value: 0 }, // 0 => insert
      society_id: SOC(req.societyId),
      ...fields,
    });

    // This branch does `SELECT @new AS owner_id`, so we get the id back.
    const newId = inserted?.owner_id;
    const owner = newId ? await findResident(req.societyId, newId) : null;
    return ok(res, { owner, owner_id: newId ?? null }, 201);
  }),
);

/**
 * PUT /api/web/masters/owners/:id
 *
 * Note: the sp_owner_master script shared at project start contains
 * `@married_id = @married_id` in this SET list (a no-op variable assignment),
 * but the *deployed* procedure reads `married_id = @married_id` and persists
 * correctly. Verified against OBJECT_DEFINITION on 2026-08-04. No workaround
 * needed here.
 */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await findResident(req.societyId, id);
    if (!existing) throw ApiError.notFound('Resident not found');

    const type = residentType({ ...req, query: { type: req.body?.type ?? existing.type } });
    const fields = ownerParams(req.body, type);

    await assertFlatFree(req.societyId, fields.flat_id.value, type, id);

    await exec('sp_owner_master', {
      operation: 'Update',
      owner_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      ...fields,
    });

    return ok(res, { owner: await findResident(req.societyId, id) });
  }),
);

/**
 * DELETE /api/web/masters/owners/:id — soft delete.
 * The SP also releases the flat (flat_status = 0) and deactivates the resident's
 * family members, mirroring the legacy behaviour.
 */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    if (!(await findResident(req.societyId, id))) throw ApiError.notFound('Resident not found');

    await exec('sp_owner_master', {
      operation: 'Delete',
      owner_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, owner_id: id });
  }),
);

module.exports = router;
