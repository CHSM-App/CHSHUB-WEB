// Website API — Terms & conditions printed on bills.
// Replaces Society2024/Terms_and_Condition.aspx and t_n_c.aspx.
// Backed by sp_terms_condition.
const express = require('express');

const { query, exec, sql } = require('../../lib/db');
const { ApiError, ok, asyncHandler } = require('../../lib/http');
const { str, int } = require('../../lib/validate');
const { requireSociety } = require('../../middleware/authenticate');

const router = express.Router();
router.use(requireSociety);

const SOCLONG = (v) => ({ type: sql.NVarChar(50), value: v });

async function listTerms(societyId) {
  return query('sp_terms_condition', {
    operation: 'Grid_Show',
    society_id: SOCLONG(societyId),
  });
}

/** GET /api/web/settings/terms */
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const rows = await listTerms(req.societyId);
    // In practice a society keeps one active terms row; return it directly for
    // convenience alongside the full list.
    return ok(res, { items: rows, count: rows.length, current: rows[0] ?? null });
  }),
);

/**
 * PUT /api/web/settings/terms
 *
 * Upsert: the society's existing row is updated, or a first one created.
 * `terms` is a TEXT column, so it is bound as NVarChar(MAX).
 */
router.put(
  '/',
  asyncHandler(async (req, res) => {
    const text = str(req.body?.terms, 'terms');
    const existing = (await listTerms(req.societyId))[0];

    await exec('sp_terms_condition', {
      operation: 'Update',
      term_id: { type: sql.Int, value: existing ? Number(existing.term_id) : 0 },
      terms: { type: sql.NVarChar(sql.MAX), value: text },
      society_id: SOCLONG(req.societyId),
    });

    const rows = await listTerms(req.societyId);
    return ok(res, { current: rows[0] ?? null });
  }),
);

/** GET /api/web/settings/terms/:id */
router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const id = int(req.params.id, 'id', { min: 1 });

    // The SP's 'Select' does not filter by society, so scope it here.
    const rows = await query('sp_terms_condition', {
      operation: 'Select',
      term_id: { type: sql.Int, value: id },
    });
    const term = rows[0];
    if (!term || String(term.society_id) !== String(req.societyId)) {
      throw ApiError.notFound('Terms not found');
    }
    return ok(res, { term });
  }),
);

module.exports = router;
