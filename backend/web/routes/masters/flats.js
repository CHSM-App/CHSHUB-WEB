// Website API — Flat master. Replaces Society2024/flat_search.aspx.
// Backed by sp_flat_master; listing comes from the `flat` view.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(50), value: v });

async function listFlats(societyId) {
  return query('sp_flat_master', { operation: 'Grid_Show', society_id: SOC(societyId) });
}

async function findFlat(societyId, flatId) {
  // 'Select' reads flat_master directly and ignores society_id — scope it here.
  const rows = await query('sp_flat_master', {
    operation: 'Select',
    flat_id: { type: sql.Int, value: flatId },
  });
  const flat = rows[0];
  if (!flat || String(flat.society_id) !== String(societyId)) return null;
  return flat;
}

/** Flat numbers must be unique within a wing. */
async function assertFlatNoFree(societyId, wingId, flatNo, currentId = 0) {
  const rows = await query('sp_flat_master', {
    operation: 'check_no',
    flat_id: { type: sql.Int, value: 0 }, // force the branch that filters by wing
    flat_no: { type: sql.NVarChar(10), value: flatNo },
    wing_id: { type: sql.Int, value: wingId },
    society_id: SOC(societyId),
  });
  const clash = rows.find((r) => Number(r.flat_id) !== Number(currentId));
  if (clash) {
    throw ApiError.conflict('A flat with this number already exists in the wing', {
      field: 'flatNo',
      conflictingId: clash.flat_id,
    });
  }
}

async function assertWing(societyId, wingId) {
  const rows = await query('sp_wing_master', {
    operation: 'Grid_Show',
    society_id: { type: sql.NVarChar(10), value: societyId },
  });
  if (!rows.some((w) => Number(w.wing_id) === wingId)) {
    throw ApiError.badRequest('wingId does not refer to a wing in this society');
  }
}

function flatParams(body) {
  return {
    wing_id: { type: sql.Int, value: int(body?.wingId, 'wingId', { min: 1 }) },
    flat_no: { type: sql.NVarChar(10), value: str(body?.flatNo, 'flatNo', { max: 10 }) },
    flat_type_id: { type: sql.Int, value: int(body?.flatTypeId, 'flatTypeId', { min: 1 }) },
    bed_id: { type: sql.Int, value: int(body?.bedroomId, 'bedroomId', { min: 1 }) },
    usage_id: { type: sql.Int, value: int(body?.usageId, 'usageId', { min: 1 }) },
    sq_ft: { type: sql.NVarChar(10), value: optionalStr(body?.sqFt, 'sqFt', { max: 10 }) },
    terrace_sq_ft: { type: sql.NVarChar(10), value: optionalStr(body?.terraceSqFt, 'terraceSqFt', { max: 10 }) },
    intercom_no: { type: sql.NVarChar(50), value: optionalStr(body?.intercomNo, 'intercomNo', { max: 50 }) },
  };
}

/** GET /api/web/masters/flats?search=&wingId=&buildingId= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const wingId = int(req.query.wingId, 'wingId', { min: 1, required: false });
    const buildingId = int(req.query.buildingId, 'buildingId', { min: 1, required: false });

    let rows = search
      ? await query('sp_flat_master', {
          operation: 'Search',
          society_id: SOC(req.societyId),
          search: { type: sql.VarChar(200), value: search },
        })
      : await listFlats(req.societyId);

    if (wingId) rows = rows.filter((r) => Number(r.wing_id) === wingId);
    if (buildingId) rows = rows.filter((r) => Number(r.build_id) === buildingId);

    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/masters/flats/lookups — dropdown data for the flat form. */
router.get(
  '/lookups',
  asyncHandler(async (req, res) => {
    const forType = (type) =>
      query('sp_flat_master', {
        operation: 'Fill_list',
        type: { type: sql.VarChar(50), value: type },
        society_id: SOC(req.societyId),
      });

    const [wings, flatTypes, usages, bedrooms] = await Promise.all([
      forType('wing'),
      forType('flat_types'),
      forType('flat_usage'),
      forType('flat_bedroom'),
    ]);

    return ok(res, { wings, flatTypes, usages, bedrooms });
  }),
);

/** GET /api/web/masters/flats/count — live flat count, used by billing. */
router.get(
  '/count',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_flat_master', {
      operation: 'check_count',
      society_id: SOC(req.societyId),
    });
    return ok(res, { count: rows[0]?.flat ?? 0 });
  }),
);

/** GET /api/web/masters/flats/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const flat = await findFlat(req.societyId, id);
    if (!flat) throw ApiError.notFound('Flat not found');
    return ok(res, { flat });
  }),
);

/** POST /api/web/masters/flats */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const fields = flatParams(req.body);
    await assertWing(req.societyId, fields.wing_id.value);
    await assertFlatNoFree(req.societyId, fields.wing_id.value, fields.flat_no.value, 0);

    await exec('sp_flat_master', {
      operation: 'Update',
      flat_id: { type: sql.Int, value: 0 }, // 0 => insert
      society_id: SOC(req.societyId),
      flat_status: { type: sql.Int, value: 0 },
      ...fields,
    });

    const rows = await listFlats(req.societyId); // ordered flat_id DESC
    return ok(res, { flat: rows[0] || null }, 201);
  }),
);

/**
 * PUT /api/web/masters/flats/:id
 *
 * sp_flat_master's update branch contains `@flat_type_id = @flat_type_id` in its
 * SET list — it assigns to the variable, so the flat_type_id column is never
 * written. We cannot fix the SP (shared with the mobile API and the legacy app),
 * so detect that specific case and report it rather than silently accepting a
 * change we know will be dropped.
 */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await findFlat(req.societyId, id);
    if (!existing) throw ApiError.notFound('Flat not found');

    const fields = flatParams(req.body);
    await assertWing(req.societyId, fields.wing_id.value);
    await assertFlatNoFree(req.societyId, fields.wing_id.value, fields.flat_no.value, id);

    if (Number(existing.flat_type_id) !== Number(fields.flat_type_id.value)) {
      throw ApiError.conflict(
        'Flat type cannot be changed: stored procedure sp_flat_master does not persist flat_type_id on update (see docs/MIGRATION-MAP.md §5.6). Delete and recreate the flat, or patch the procedure.',
        { field: 'flatTypeId', current: existing.flat_type_id, requested: fields.flat_type_id.value },
      );
    }

    await exec('sp_flat_master', {
      operation: 'Update',
      flat_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      flat_status: { type: sql.Int, value: existing.flat_status ?? 0 },
      ...fields,
    });

    return ok(res, { flat: await findFlat(req.societyId, id) });
  }),
);

/** DELETE /api/web/masters/flats/:id — soft delete. */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const flat = await findFlat(req.societyId, id);
    if (!flat) throw ApiError.notFound('Flat not found');

    // A flat with an owner/tenant still attached must not be hidden — the owner
    // row would keep pointing at an invisible flat and break owner_search_vw.
    const owners = await query('sp_owner_master', {
      operation: 'Grid_Show',
      type: { type: sql.NVarChar(10), value: 'Owner' },
      society_id: { type: sql.NVarChar(10), value: req.societyId },
    });
    if (owners.some((o) => Number(o.flat_id) === id)) {
      throw ApiError.conflict('This flat has an owner assigned; remove the owner first');
    }

    await exec('sp_flat_master', {
      operation: 'Delete',
      flat_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, flat_id: id });
  }),
);

module.exports = router;
