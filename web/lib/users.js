// Website API — user lookups shared between routes.
//
// These lived in routes/auth.js while it was the only caller. The password
// routes in routes/onboarding.js now need the same rows — to read contact_no
// when revoking sessions across both apps, and to re-issue tokens for the
// device that changed the password — so they moved here rather than being
// duplicated or imported across route modules.
const { query, getPool, sql } = require('./db');

/**
 * `validateuser` selects UserLogin.password twice in its column list, so the
 * mssql driver surfaces it as an array of two identical values rather than a
 * string. Collapse it before verifying.
 */
function storedPassword(row) {
  const p = row.password;
  return Array.isArray(p) ? p[0] : p;
}

async function findUserByUsername(username) {
  const rows = await query('validateuser', {
    operation: 'login',
    username: { type: sql.VarChar(250), value: username },
  });
  return rows.length ? rows[0] : null;
}

async function findUserById(userId) {
  const rows = await query('sp_UserLogin', {
    operation: 'Select',
    user_id: { type: sql.Int, value: userId },
  });
  return rows.length ? rows[0] : null;
}

/**
 * Look up an account by email — the identity the password reset flow uses.
 *
 * Deliberately NOT sp_UserLogin's 'check_email' branch, which answers
 * `SELECT email` and nothing else. That is enough to decide whether an address
 * is taken, but it carries no user_id, so a caller that needs to act on the
 * account — revoking its sessions after a reset, say — would be reading
 * `undefined` and silently doing nothing.
 *
 * `active_status = 0` matches what check_email tested: a disabled account is
 * not a match.
 */
async function findUserByEmail(email) {
  const pool = await getPool();
  const result = await pool
    .request()
    .input('email', sql.NVarChar(100), email)
    .query(
      `SELECT TOP 1 user_id, name, username, email, contact_no, owner_id,
              user_type_id, society_id, village_id, active_status
         FROM dbo.UserLogin
        WHERE email = @email AND active_status = 0`,
    );
  const rows = result.recordset || [];
  return rows.length ? rows[0] : null;
}

module.exports = {
  storedPassword,
  findUserByUsername,
  findUserById,
  findUserByEmail,
};
