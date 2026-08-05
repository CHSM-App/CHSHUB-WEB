// Website API — Building master. Replaces Society2024/building_search.aspx.
// Backed by sp_building_master.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** Shared field mapping for create and update. */
function buildingParams(body) {
  return {
    name: { type: sql.NVarChar(50), value: str(body?.name, 'name', { max: 50 }) },
    address1: { type: sql.NVarChar(150), value: optionalStr(body?.address1, 'address1', { max: 150 }) },
    address2: { type: sql.NVarChar(150), value: optionalStr(body?.address2, 'address2', { max: 150 }) },
    no_of_floore: { type: sql.Int, value: int(body?.floors, 'floors', { min: 0, max: 500, required: false, default: 0 }) },
    print_name: { type: sql.NVarChar(250), value: optionalStr(body?.printName, 'printName', { max: 250 }) },
    registration_no: { type: sql.NVarChar(50), value: optionalStr(body?.registrationNo, 'registrationNo', { max: 50 }) },
    bank_name: { type: sql.NVarChar(50), value: optionalStr(body?.bankName, 'bankName', { max: 50 }) },
    bank_add: { type: sql.NVarChar(50), value: optionalStr(body?.bankAddress, 'bankAddress', { max: 50 }) },
    branch: { type: sql.NVarChar(50), value: optionalStr(body?.branch, 'branch', { max: 50 }) },
    ifsc_code: { type: sql.NVarChar(50), value: optionalStr(body?.ifscCode, 'ifscCode', { max: 50 }) },
    acc_no: { type: sql.NVarChar(50), value: optionalStr(body?.accountNo, 'accountNo', { max: 50 }) },
    email: { type: sql.NVarChar(50), value: optionalStr(body?.email, 'email', { max: 50 }) },
  };
}

/**
 * Registration numbers must be unique within a society. sp_building_master's
 * own 'check_no' branch is unreliable — for a non-zero build_id its WHERE ends
 * in `build_id = @build_id AND build_id <> @build_id`, which is never true, so
 * edits always look unique. We do the check here instead.
 */
async function assertRegistrationFree(societyId, registrationNo, currentId = 0) {
  if (!registrationNo) return;
  const rows = await query('sp_building_master', {
    operation: 'Grid_Show',
    society_id: SOC(societyId),
  });
  const clash = rows.find(
    (r) =>
      String(r.registration_no || '').trim().toLowerCase() === registrationNo.toLowerCase() &&
      Number(r.build_id) !== Number(currentId),
  );
  if (clash) {
    throw ApiError.conflict('A building with this registration number already exists', {
      field: 'registrationNo',
      conflictingId: clash.build_id,
    });
  }
}

/** GET /api/web/masters/buildings?search= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 200 });

    const rows = search
      ? await query('sp_building_master', {
          operation: 'Search',
          society_id: SOC(req.societyId),
          search: { type: sql.NVarChar(200), value: search },
        })
      : await query('sp_building_master', {
          operation: 'Grid_Show',
          society_id: SOC(req.societyId),
        });

    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /api/web/masters/buildings/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const rows = await query('sp_building_master', {
      operation: 'Select',
      build_id: { type: sql.Int, value: id },
    });
    const building = rows[0];

    // sp_building_master's 'Select' ignores society_id, so enforce the tenant
    // boundary here rather than leaking another society's building.
    if (!building || String(building.society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Building not found');
    }
    return ok(res, { building });
  }),
);

/** POST /api/web/masters/buildings */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const fields = buildingParams(req.body);
    await assertRegistrationFree(req.societyId, fields.registration_no.value, 0);

    await exec('sp_building_master', {
      operation: 'Update',
      build_id: { type: sql.Int, value: 0 }, // 0 => insert
      society_id: SOC(req.societyId),
      ...fields,
    });

    // The SP does not return the new id, so read it back from the grid, which
    // is ordered build_id DESC.
    const rows = await query('sp_building_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    return ok(res, { building: rows[0] || null }, 201);
  }),
);

/** PUT /api/web/masters/buildings/:id */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await query('sp_building_master', {
      operation: 'Select',
      build_id: { type: sql.Int, value: id },
    });
    if (!existing[0] || String(existing[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Building not found');
    }

    const fields = buildingParams(req.body);
    await assertRegistrationFree(req.societyId, fields.registration_no.value, id);

    await exec('sp_building_master', {
      operation: 'Update',
      build_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      ...fields,
    });

    const rows = await query('sp_building_master', {
      operation: 'Select',
      build_id: { type: sql.Int, value: id },
    });
    return ok(res, { building: rows[0] });
  }),
);

/** DELETE /api/web/masters/buildings/:id — soft delete (active_status = 1). */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    const existing = await query('sp_building_master', {
      operation: 'Select',
      build_id: { type: sql.Int, value: id },
    });
    if (!existing[0] || String(existing[0].society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Building not found');
    }

    // Refuse to orphan wings: wing_master.build_id has an FK to this row and
    // the SP would happily hide a building that still has live wings under it.
    const wings = await query('sp_wing_master', {
      operation: 'Grid_Show',
      society_id: SOC(req.societyId),
    });
    const liveWings = wings.filter((w) => Number(w.build_id) === id);
    if (liveWings.length) {
      throw ApiError.conflict('Delete the wings in this building first', {
        wingCount: liveWings.length,
      });
    }

    await exec('sp_building_master', {
      operation: 'Delete',
      build_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, build_id: id });
  }),
);

module.exports = router;
