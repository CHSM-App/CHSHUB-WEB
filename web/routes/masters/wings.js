// Website API — Wing master. Replaces Society2024/wing_search.aspx.
// Backed by sp_wing_master; listing comes from global_society_view.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

async function listWings(societyId) {
  return query('sp_wing_master', { operation: 'Grid_Show', society_id: SOC(societyId) });
}

async function findWing(societyId, wingId) {
  // 'Select' joins building_master but does not filter by society, so scope the
  // result here before returning it.
  const rows = await query('sp_wing_master', {
    operation: 'Select',
    wing_id: { type: sql.Int, value: wingId },
  });
  const wing = rows[0];
  if (!wing || String(wing.society_id) !== String(societyId)) return null;
  return wing;
}

/** A wing name must be unique within its building. */
async function assertNameFree(societyId, buildId, name, currentId = 0) {
  const rows = await query('sp_wing_master', {
    operation: 'check_name',
    wing_id: { type: sql.Int, value: 0 }, // force the reliable branch
    w_name: { type: sql.NVarChar(50), value: name },
    build_id: { type: sql.Int, value: buildId },
    society_id: SOC(societyId),
  });
  const clash = rows.find((r) => Number(r.wing_id) !== Number(currentId));
  if (clash) {
    throw ApiError.conflict('A wing with this name already exists in the building', {
      field: 'name',
      conflictingId: clash.wing_id,
    });
  }
}

/** Confirm the building exists and belongs to this society. */
async function assertBuilding(societyId, buildId) {
  const rows = await query('sp_building_master', {
    operation: 'Select',
    build_id: { type: sql.Int, value: buildId },
  });
  if (!rows[0] || String(rows[0].society_id) !== String(societyId)) {
    throw ApiError.badRequest('buildingId does not refer to a building in this society');
  }
}

/** GET /api/web/masters/wings?search=&buildingId= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });
    const buildingId = int(req.query.buildingId, 'buildingId', { min: 1, required: false });

    let rows = search
      ? await query('sp_wing_master', {
          operation: 'Search',
          society_id: SOC(req.societyId),
          search: { type: sql.NVarChar(200), value: search },
        })
      : await listWings(req.societyId);

    if (buildingId) rows = rows.filter((r) => Number(r.build_id) === buildingId);

    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/masters/wings/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const wing = await findWing(req.societyId, id);
    if (!wing) throw ApiError.notFound('Wing not found');
    return ok(res, { wing });
  }),
);

/** POST /api/web/masters/wings */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const name = str(req.body?.name, 'name', { max: 50 });
    const buildingId = int(req.body?.buildingId, 'buildingId', { min: 1 });

    await assertBuilding(req.societyId, buildingId);
    await assertNameFree(req.societyId, buildingId, name, 0);

    await exec('sp_wing_master', {
      operation: 'Update',
      wing_id: { type: sql.Int, value: 0 }, // 0 => insert
      w_name: { type: sql.NVarChar(50), value: name },
      build_id: { type: sql.Int, value: buildingId },
      society_id: SOC(req.societyId),
    });

    const rows = await listWings(req.societyId); // ordered wing_id DESC
    return ok(res, { wing: rows[0] || null }, 201);
  }),
);

/** PUT /api/web/masters/wings/:id */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const name = str(req.body?.name, 'name', { max: 50 });
    const buildingId = int(req.body?.buildingId, 'buildingId', { min: 1 });

    if (!(await findWing(req.societyId, id))) throw ApiError.notFound('Wing not found');
    await assertBuilding(req.societyId, buildingId);
    await assertNameFree(req.societyId, buildingId, name, id);

    await exec('sp_wing_master', {
      operation: 'Update',
      wing_id: { type: sql.Int, value: id },
      w_name: { type: sql.NVarChar(50), value: name },
      build_id: { type: sql.Int, value: buildingId },
      society_id: SOC(req.societyId),
    });

    return ok(res, { wing: await findWing(req.societyId, id) });
  }),
);

/** DELETE /api/web/masters/wings/:id — soft delete. */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    if (!(await findWing(req.societyId, id))) throw ApiError.notFound('Wing not found');

    // Don't orphan flats hanging off this wing.
    const flats = await query('sp_flat_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    const liveFlats = flats.filter((f) => Number(f.wing_id) === id);
    if (liveFlats.length) {
      throw ApiError.conflict('Delete the flats in this wing first', { flatCount: liveFlats.length });
    }

    await exec('sp_wing_master', {
      operation: 'Delete',
      wing_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, wing_id: id });
  }),
);

module.exports = router;
