// Website API — post-dated cheques.
// Replaces pdc_reminder_search and pdc_clearing.
const express = require('express');

const { query, exec, sql, getPool } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, optionalStr, int, num, date, bool } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOC = (v) => ({ type: sql.NVarChar(10), value: v });

/**
 * GET /billing/pdc?search=
 *
 * Grid_Show and Search both omit wing_id, which the edit form has to send back
 * — absent, pdcParams defaults it to 0 and the cheque loses its wing. It is
 * read here per row rather than through the SP, which cannot be changed
 * without disturbing the legacy page.
 */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const search = optionalStr(req.query.search, 'search', { max: 50 });
    const rows = await query('sp_pdc_reminder', {
      operation: search ? 'Search' : 'Grid_Show',
      society_id: SOC(req.societyId),
      ...(search ? { search: { type: sql.NVarChar(50), value: search } } : {}),
    });

    if (rows.length) {
      const pool = await getPool();
      const wings = await pool
        .request()
        .input('society_id', sql.NVarChar(10), req.societyId)
        .query('SELECT pdc_rem_id, wing_id FROM pdc_reminder WHERE society_id = @society_id');
      const byId = new Map(wings.recordset.map((w) => [Number(w.pdc_rem_id), w.wing_id]));
      rows.forEach((r) => {
        r.wing_id = byId.get(Number(r.pdc_rem_id)) ?? null;
      });
    }

    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /billing/pdc/clearing?from=&to=
 * Cheques falling due in a window, for the clearing screen.
 */
router.get(
  '/clearing',
  asyncHandler(async (req, res) => {
    const rows = await query('sp_pdc_reminder', {
      operation: 'pdc_clear_grid_show',
      society_id: SOC(req.societyId),
      startdate: { type: sql.Date, value: date(req.query.from, 'from') },
      enddate: { type: sql.Date, value: date(req.query.to, 'to') },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

/**
 * GET /billing/pdc/owner/:ownerId/details — the resident's contact block.
 *
 * pdc_reminder_search.aspx filled building-wing, mobile, alternate mobile,
 * address and email from the owner as soon as one was picked, and left every
 * one of them disabled. This is the same sp_pdc_reminder branch it used.
 */
router.get(
  '/owner/:ownerId/details',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.params.ownerId, 'ownerId', { min: 1 });
    const rows = await query('sp_pdc_reminder', {
      operation: 'owner_select',
      owner_id: { type: sql.Int, value: ownerId },
    });
    const owner = rows[0];
    if (!owner) throw ApiError.notFound('Owner not found');
    return ok(res, { owner });
  }),
);

/** GET /billing/pdc/owner/:ownerId — cheques on file for one resident. */
router.get(
  '/owner/:ownerId',
  asyncHandler(async (req, res) => {
    const ownerId = int(req.params.ownerId, 'ownerId', { min: 1 });
    const rows = await query('sp_pdc_reminder', {
      operation: 'ownerwise_cheq',
      owner_id: { type: sql.Int, value: ownerId },
    });
    return ok(res, { items: rows, count: rows.length });
  }),
);

function pdcParams(body) {
  return {
    owner_id: { type: sql.Int, value: int(body?.ownerId, 'ownerId', { min: 1 }) },
    wing_id: { type: sql.Int, value: int(body?.wingId, 'wingId', { min: 0, required: false, default: 0 }) },
    chqno: { type: sql.NVarChar(10), value: str(body?.chequeNo, 'chequeNo', { max: 10 }) },
    che_amount: { type: sql.Float, value: num(body?.amount, 'amount', { min: 0 }) },
    che_date: { type: sql.Date, value: date(body?.chequeDate, 'chequeDate') },
    che_dep: { type: sql.Int, value: bool(body?.deposited, 'deposited', { default: false }) ? 1 : 0 },
    che_ret: { type: sql.Int, value: bool(body?.returned, 'returned', { default: false }) ? 1 : 0 },
    che_can: { type: sql.Int, value: bool(body?.cancelled, 'cancelled', { default: false }) ? 1 : 0 },
  };
}

/** POST /billing/pdc — record a cheque. */
router.post(
  '/',
  asyncHandler(async (req, res) => {
    const created = await exec('sp_pdc_reminder', {
      operation: 'Update',
      pdc_rem_id: { type: sql.Int, value: 0 },
      society_id: SOC(req.societyId),
      ...pdcParams(req.body),
    });
    return ok(res, { pdc_rem_id: created?.p_id ?? null }, 201);
  }),
);

/** PUT /billing/pdc/:id */
router.put(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    await exec('sp_pdc_reminder', {
      operation: 'Update',
      pdc_rem_id: { type: sql.Int, value: id },
      society_id: SOC(req.societyId),
      ...pdcParams(req.body),
    });
    return ok(res, { pdc_rem_id: id });
  }),
);

/**
 * POST /billing/pdc/:id/clear — FINANCIAL WRITE.
 *
 * Marks the cheque deposited/returned/cancelled. When `deposited` is set,
 * sp_pdc_reminder's save_change_rem branch additionally calls sp_receipt to
 * raise a receipt for the cheque amount — so this creates financial records.
 * Requires an explicit confirm, matching the bill-generation endpoints.
 */
router.post(
  '/:id/clear',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const deposited = bool(req.body?.deposited, 'deposited', { default: false });

    if (deposited && bool(req.body?.confirm, 'confirm', { default: false }) !== true) {
      throw ApiError.badRequest(
        'Marking a cheque deposited also raises a receipt. Send { "confirm": true } to proceed.',
      );
    }

    await exec('sp_pdc_reminder', {
      operation: 'save_change_rem',
      pdc_rem_id: { type: sql.Int, value: id },
      che_dep: { type: sql.Int, value: deposited ? 1 : 0 },
      che_ret: { type: sql.Int, value: bool(req.body?.returned, 'returned', { default: false }) ? 1 : 0 },
      che_can: { type: sql.Int, value: bool(req.body?.cancelled, 'cancelled', { default: false }) ? 1 : 0 },
    });

    return ok(res, { updated: true, pdc_rem_id: id });
  }),
);

/**
 * DELETE /billing/pdc/:id — written here, because sp_pdc_reminder's own Delete
 * does not delete.
 *
 * It runs `active_status = 0`, and Grid_Show lists exactly the rows where
 * active_status = 0 — so the cheque came straight back. Every other soft
 * delete in this database sets 1; sp_pdc_reminder and sp_loan are the two that
 * set 0, which is what those branches were meant to say. The SPs are left
 * alone because the legacy pages still call them.
 */
router.delete(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });
    const pool = await getPool();
    const result = await pool
      .request()
      .input('pdc_rem_id', sql.Int, id)
      .input('society_id', sql.NVarChar(10), req.societyId)
      .query(
        'UPDATE pdc_reminder SET active_status = 1 WHERE pdc_rem_id = @pdc_rem_id AND society_id = @society_id',
      );

    if (!result.rowsAffected?.[0]) throw ApiError.notFound('Cheque not found');
    return ok(res, { deleted: true, pdc_rem_id: id });
  }),
);

module.exports = router;
