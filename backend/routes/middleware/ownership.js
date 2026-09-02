// Per-record ownership enforcement for the mobile API (IDOR fix).
//
// protect.js (→ auth.js) proves the caller holds a valid mobile token and sets
// req.user.mobile. It does NOT prove the record the URL names is theirs. Every
// handler that acts on a client-supplied id must run this first.
//
// The check lives in SQL (SQL/ADD_sp_owner_scope.sql): given the caller's
// mobile — from the verified token, never from the request — and a record kind
// + id, sp_owner_scope answers owned = 1|0. Owns → next(); not → 403.
//
// Kinds map a record to the owner_master row the caller must own:
//   flat | owner | ownerext | vehicle | parking | visitor | document | receipt
const db = require('../db');

/**
 * @param {string|function} kind  a kind sp_owner_scope understands, or (req) => kind
 *                                 for routes that choose the table by request (e.g. ?type=)
 * @param {function} getId         (req) => the record id to check (string/number)
 */
function requireOwnership(kind, getId) {
  return async function (req, res, next) {
    const mobile = req.user && req.user.mobile;
    if (!mobile) {
      // protect should have set this; if it didn't, fail closed.
      return res.status(401).json({ msg: 'No token, access denied' });
    }

    const resolvedKind = typeof kind === 'function' ? kind(req) : kind;
    const id = parseInt(getId(req), 10);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ error: 'Invalid or missing resource id' });
    }

    try {
      const result = await db.request()
        .input('pre_mob', String(mobile).trim())
        .input('kind', resolvedKind)
        .input('id', id)
        .execute('sp_owner_scope');

      const owned = result.recordset && result.recordset[0] && result.recordset[0].owned;
      if (!owned) {
        return res.status(403).json({ error: 'You do not have access to this resource' });
      }
      return next();
    } catch (err) {
      console.error('ownership check failed:', err.message);
      return res.status(500).json({ error: 'Authorization check failed' });
    }
  };
}

module.exports = { requireOwnership };
