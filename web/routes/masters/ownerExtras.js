// Website API — owner sub-resources from Society2024/owner_search.aspx that
// sit outside the main owner form: hobbies, areas of work, uploaded documents,
// vehicles, and the notify/privacy toggles.
//
// Each corresponds to a repeater or command button on the legacy page.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, oneOf, bool } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });
// The SP treats 'family' as "this id is an o_ex_id"; anything else means owner.
const OWNER_KIND = ['owner', 'family'];

/* ---------------------------------------------------------------- hobbies */

/** GET /masters/owner-extras/hobbies?ownerId=&kind=owner|family */
router.get(
  '/hobbies',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.query.kind ?? 'owner', 'kind', OWNER_KIND);

    const rows = await query('sp_owner_master', {
      operation: 'Select_Hobby',
      owner_id: { type: sql.Int, value: ownerId },
      type: { type: sql.NVarChar(10), value: kind },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** POST /masters/owner-extras/hobbies */
router.post(
  '/hobbies',
  asyncHandler(async (req, res) => {
    const kind = oneOf(req.body?.kind ?? 'owner', 'kind', OWNER_KIND);
    const id = int(req.body?.ownerId, 'ownerId', { min: 1 });

    await exec('sp_owner_master', {
      operation: 'Add_Hobby',
      hobby: { type: sql.NVarChar(50), value: str(req.body?.hobby, 'hobby', { max: 50 }) },
      // The SP writes both columns; the unused one must be 0.
      owner_id: { type: sql.Int, value: kind === 'family' ? 0 : id },
      o_ex_id: { type: sql.Int, value: kind === 'family' ? id : 0 },
    });
    return ok(res, { added: true }, 201);
  }),
);

/**
 * DELETE /masters/owner-extras/hobbies?ownerId=&kind=
 * The SP has no per-row delete — it clears every hobby for the person.
 */
router.delete(
  '/hobbies',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.query.kind ?? 'owner', 'kind', OWNER_KIND);

    await exec('sp_owner_master', {
      operation: 'Delete_Hobby',
      owner_id: { type: sql.Int, value: ownerId },
      type: { type: sql.NVarChar(10), value: kind },
    });
    return ok(res, { cleared: true });
  }),
);

/* ---------------------------------------------------------- areas of work */

router.get(
  '/work-areas',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.query.kind ?? 'owner', 'kind', OWNER_KIND);

    const rows = await query('sp_owner_master', {
      operation: 'Select_Work',
      owner_id: { type: sql.Int, value: ownerId },
      type: { type: sql.NVarChar(10), value: kind },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/work-areas',
  asyncHandler(async (req, res) => {
    const kind = oneOf(req.body?.kind ?? 'owner', 'kind', OWNER_KIND);
    const id = int(req.body?.ownerId, 'ownerId', { min: 1 });

    await exec('sp_owner_master', {
      operation: 'Add_Work',
      area_of_work: { type: sql.NVarChar(50), value: str(req.body?.areaOfWork, 'areaOfWork', { max: 50 }) },
      owner_id: { type: sql.Int, value: kind === 'family' ? 0 : id },
      o_ex_id: { type: sql.Int, value: kind === 'family' ? id : 0 },
    });
    return ok(res, { added: true }, 201);
  }),
);

router.delete(
  '/work-areas',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.query.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.query.kind ?? 'owner', 'kind', OWNER_KIND);

    await exec('sp_owner_master', {
      operation: 'Delete_Work',
      owner_id: { type: sql.Int, value: ownerId },
      type: { type: sql.NVarChar(10), value: kind },
    });
    return ok(res, { cleared: true });
  }),
);

/* -------------------------------------------------------------- documents */

/** GET /masters/owner-extras/documents?flatId= */
router.get(
  '/documents',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });
    const rows = await query('sp_doc_master', {
      operation: 'GetOwnerDocs',
      flat_id: { type: sql.Int, value: flatId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * DELETE /masters/owner-extras/documents/:documentId
 * Only uploaded rows can be removed; the agreement and ID-proof entries come
 * from owner_master columns and carry document_id = 0.
 */
router.delete(
  '/documents/:documentId',
  asyncHandler(async (req, res) => {
    const documentId = int(req.params.documentId, 'documentId', { min: 1 });
    await exec('sp_doc_master', {
      operation: 'deleteDocuments',
      document_id: { type: sql.Int, value: documentId },
    });
    return ok(res, { deleted: true, document_id: documentId });
  }),
);

/* --------------------------------------------------------------- vehicles */

/** GET /masters/owner-extras/vehicles?flatId= */
router.get(
  '/vehicles',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });
    const rows = await query('sp_parking', {
      operation: 'VehicleList',
      flat_id: { type: sql.Int, value: flatId },
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

router.post(
  '/vehicles',
  asyncHandler(async (req, res) => {
    await exec('sp_parking', {
      operation: 'Insertfamilyvehicle',
      flat_id: { type: sql.Int, value: int(req.body?.flatId, 'flatId', { min: 1 }) },
      vehicle_no: { type: sql.NVarChar(50), value: str(req.body?.vehicleNo, 'vehicleNo', { max: 50 }) },
      // 0 = two-wheeler, 1 = four-wheeler, matching the parking rates.
      vehicle_type: { type: sql.Int, value: int(req.body?.vehicleType, 'vehicleType', { min: 0, max: 1 }) },
      model_name: { type: sql.NVarChar(50), value: optionalStr(req.body?.modelName, 'modelName', { max: 50 }) },
      society_id: SOC(req.societyId),
    });
    return ok(res, { added: true }, 201);
  }),
);

router.delete(
  '/vehicles/:vehicleId',
  asyncHandler(async (req, res) => {
    const vehicleId = int(req.params.vehicleId, 'vehicleId', { min: 1 });
    await exec('sp_parking', {
      operation: 'deleteFamilyVehicle',
      vehicle_id: { type: sql.Int, value: vehicleId },
    });
    return ok(res, { deleted: true, vehicle_id: vehicleId });
  }),
);

/* --------------------------------------------------- privacy & notify flags */

/** PUT /masters/owner-extras/:ownerId/settings — masking and gate sharing. */
router.put(
  '/:ownerId/settings',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.params.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.body?.kind ?? 'owner', 'kind', OWNER_KIND);

    await exec('sp_owner_master', {
      operation: kind === 'family' ? 'UpdateOwnerExtensionSetting' : 'UpdateOwnerSetting',
      owner_id: { type: sql.Int, value: ownerId },
      mask_phone: { type: sql.Bit, value: bool(req.body?.maskPhone, 'maskPhone', { default: false }) },
      mask_email: { type: sql.Bit, value: bool(req.body?.maskEmail, 'maskEmail', { default: false }) },
      share_gate: { type: sql.Bit, value: bool(req.body?.shareGate, 'shareGate', { default: false }) },
    });
    return ok(res, { updated: true, owner_id: ownerId });
  }),
);

/** PUT /masters/owner-extras/:ownerId/notifications — app and call toggles. */
router.put(
  '/:ownerId/notifications',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.params.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.body?.kind ?? 'owner', 'kind', OWNER_KIND);
    const type = { type: sql.NVarChar(10), value: kind };

    if (req.body?.appNotify !== undefined) {
      await exec('sp_owner_master', {
        operation: 'NotifyApp',
        owner_id: { type: sql.Int, value: ownerId },
        notify_app: { type: sql.Int, value: bool(req.body.appNotify, 'appNotify') ? 1 : 0 },
        type,
      });
    }
    if (req.body?.callNotify !== undefined) {
      await exec('sp_owner_master', {
        operation: 'NotifyCall',
        owner_id: { type: sql.Int, value: ownerId },
        notify_app: { type: sql.Int, value: bool(req.body.callNotify, 'callNotify') ? 1 : 0 },
        type,
      });
    }
    return ok(res, { updated: true, owner_id: ownerId });
  }),
);

/** POST /masters/owner-extras/:ownerId/deactivate — the legacy Deactivate action. */
router.post(
  '/:ownerId/deactivate',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.params.ownerId, 'ownerId', { min: 1 });
    const kind = oneOf(req.body?.kind ?? 'owner', 'kind', OWNER_KIND);

    await exec('sp_owner_master', {
      operation: 'Deactivate',
      owner_id: { type: sql.Int, value: ownerId },
      type: { type: sql.NVarChar(10), value: kind },
    });
    return ok(res, { deactivated: true, owner_id: ownerId });
  }),
);

/** GET /masters/owner-extras/directory — the residence directory export. */
router.get(
  '/directory',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'GetResidenceDirectory',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /masters/owner-extras/owner-list — name/unit/type list used by exports. */
router.get(
  '/owner-list',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_owner_master', {
      operation: 'GetOwnerList',
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/** GET /masters/owner-extras/dues?flatId= — outstanding per resident. */
router.get(
  '/dues',
  asyncHandler(async (req, res) => {
    const flatId = int(req.query.flatId, 'flatId', { min: 1 });
    const rows = await query('sp_owner_master', {
      operation: 'ownerDue',
      flat_id: { type: sql.Int, value: flatId },
      society_id: SOC(req.societyId),
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

module.exports = router;
