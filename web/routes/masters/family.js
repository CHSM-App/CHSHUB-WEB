// Website API — family members of a resident (owner_extension).
// Part of Society2024/owner_search.aspx's detail grid.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, date } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/** Confirm the parent resident exists in this society before touching family rows. */
async function assertResident(societyId, ownerId) {
  const rows = await query('sp_owner_master', {
    operation: 'Select',
    owner_id: { type: sql.Int, value: ownerId },
  });
  if (!rows[0] || String(rows[0].society_id) !== String(societyId)) {
    throw ApiError.notFound('Resident not found');
  }
  return rows[0];
}

async function listFamily(ownerId) {
  return query('sp_owner_master', {
    operation: 'Grid_Show_Family',
    owner_id: { type: sql.Int, value: ownerId },
  });
}

/** GET /api/web/masters/family?ownerId= */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    await assertResident(req.societyId, ownerId);

    const rows = await listFamily(ownerId);
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * POST /api/web/masters/family
 *
 * Two SP calls, because neither branch alone does the whole job:
 *
 *  - 'AddFamilyMember' allocates o_ex_id (owner_extension has no identity
 *    column) but its INSERT omits f_occu and f_dob entirely.
 *  - 'D_Update' writes those two columns but, with o_ex_id = 0, inserts without
 *    a key.
 *
 * So we insert with AddFamilyMember, then apply occupation/DOB through
 * D_Update against the id it allocated. owner_search.aspx captured both fields
 * (txt_f_occu, txt_f_dob), so skipping the second call would silently drop them.
 */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.body?.ownerId, 'ownerId', { min: 1 });
    await assertResident(req.societyId, ownerId);

    const name = str(req.body?.name, 'name', { max: 50 });
    const relation = str(req.body?.relation, 'relation', { max: 50 });
    const contact = optionalStr(req.body?.contact, 'contact', { max: 10 });
    const occupation = optionalStr(req.body?.occupation, 'occupation', { max: 50 });
    const dob = date(req.body?.dob, 'dob', { required: false });

    await exec('sp_owner_master', {
      operation: 'AddFamilyMember',
      owner_id: { type: sql.Int, value: ownerId },
      f_name: { type: sql.NVarChar(50), value: name },
      relation: { type: sql.NVarChar(50), value: relation },
      contact: { type: sql.NVarChar(10), value: contact },
      society_id: SOC(req.societyId),
    });

    let rows = await listFamily(ownerId);
    // owner_extension is keyed by MAX(o_ex_id)+1, so the newest row has the
    // highest id.
    let created = rows.reduce(
      (max, r) => (!max || Number(r.o_ex_id) > Number(max.o_ex_id) ? r : max),
      null,
    );

    if (created && (occupation || dob)) {
      await exec('sp_owner_master', {
        operation: 'D_Update',
        o_ex_id: { type: sql.Int, value: Number(created.o_ex_id) },
        owner_id: { type: sql.Int, value: ownerId },
        f_name: { type: sql.NVarChar(50), value: name },
        relation: { type: sql.NVarChar(50), value: relation },
        f_occu: { type: sql.NVarChar(50), value: occupation },
        f_dob: { type: sql.SmallDateTime, value: dob },
        society_id: SOC(req.societyId),
      });
      rows = await listFamily(ownerId);
      created = rows.find((r) => Number(r.o_ex_id) === Number(created.o_ex_id)) ?? created;
    }

    return ok(res, { member: created, items: rows }, 201);
  }),
);

/**
 * PUT /api/web/masters/family/:id
 * 'D_Update' with a non-zero o_ex_id updates in place.
 */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const ownerId = int(req.body?.ownerId, 'ownerId', { min: 1 });
    await assertResident(req.societyId, ownerId);

    const existing = (await listFamily(ownerId)).find((r) => Number(r.o_ex_id) === id);
    if (!existing) throw ApiError.notFound('Family member not found for this resident');

    await exec('sp_owner_master', {
      operation: 'D_Update',
      o_ex_id: { type: sql.Int, value: id },
      owner_id: { type: sql.Int, value: ownerId },
      f_name: { type: sql.NVarChar(50), value: str(req.body?.name, 'name', { max: 50 }) },
      relation: { type: sql.NVarChar(50), value: str(req.body?.relation, 'relation', { max: 50 }) },
      f_occu: { type: sql.NVarChar(50), value: optionalStr(req.body?.occupation, 'occupation', { max: 50 }) },
      f_dob: { type: sql.SmallDateTime, value: date(req.body?.dob, 'dob', { required: false }) },
      society_id: SOC(req.societyId),
    });

    const member = (await listFamily(ownerId)).find((r) => Number(r.o_ex_id) === id) ?? null;
    return ok(res, { member });
  }),
);

/** DELETE /api/web/masters/family/:id — soft delete (active_status = 1). */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    await assertResident(req.societyId, ownerId);

    const existing = (await listFamily(ownerId)).find((r) => Number(r.o_ex_id) === id);
    if (!existing) throw ApiError.notFound('Family member not found for this resident');

    // 'D_delete' updates owner_extension when the id exists there, and falls
    // back to owner_master otherwise — we have already confirmed it is a family
    // row, so the intended branch is taken.
    await exec('sp_owner_master', {
      operation: 'D_delete',
      o_ex_id: { type: sql.Int, value: id },
    });
    return ok(res, { deleted: true, o_ex_id: id });
  }),
);

module.exports = router;
