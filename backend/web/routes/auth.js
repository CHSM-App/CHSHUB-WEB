// Website API — authentication.
//
// NOTE ON PASSWORDS
// `validateuser` declares @password but never references it in its WHERE clause,
// so it returns the matching user row — password column included — for any
// username. The legacy WebForms app did the comparison itself, after the call.
// We keep the SP untouched (it is shared with the mobile API and the legacy app)
// and verify here instead, against the PBKDF2 format the legacy app writes.
// See lib/password.js.
const express = require('express');

const { query, sql } = require('../lib/db');
const { ApiError, ok, asyncHandler } = require('../lib/http');
const { str, optionalStr } = require('../lib/validate');
const { verifyPassword } = require('../lib/password');
const {
  accessTokenFor,
  issueRefreshToken,
  findRefreshToken,
  revokeRefreshToken,
  userIdFromStoredMobile,
} = require('../lib/tokens');
const { authenticate } = require('../middleware/authenticate');

const router = express.Router();

/**
 * `validateuser` selects UserLogin.password twice in its column list, so the
 * mssql driver surfaces it as an array of two identical values rather than a
 * string. Collapse it before verifying.
 */
function storedPassword(row) {
  const p = row.password;
  return Array.isArray(p) ? p[0] : p;
}

/** Strip secrets before a user row is ever sent to a client. */
function publicUser(row) {
  return {
    user_id: row.user_id,
    name: row.name,
    username: row.username,
    user_type_id: row.user_type_id,
    user_type: row.UserTypeName ?? null,
    society_id: row.society_id ?? null,
    society_name: row.Society_name ?? null,
    village_id: row.village_id ?? null,
    village_name: row.village_name ?? null,
    tenant_type: row.type ?? null, // 'Society' | 'Village'
    owner_id: row.owner_id ?? null,
    email: row.email ?? null,
    contact_no: row.contact_no ?? null,
  };
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
 * POST /api/web/auth/login
 * Body: { username, password, deviceInfo? }
 */
router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const username = str(req.body?.username, 'username', { max: 250 });
    const password = str(req.body?.password, 'password', { max: 200 });
    const deviceInfo = optionalStr(req.body?.deviceInfo, 'deviceInfo', { max: 500 });

    const user = await findUserByUsername(username);

    // Same message and shape whether the user is unknown or the password is
    // wrong, so the endpoint cannot be used to enumerate valid usernames. When
    // the user is unknown we still run a verification against a dummy hash so
    // the response time does not reveal which case it was.
    const invalid = ApiError.unauthorized('Invalid username or password');
    if (!user) {
      verifyPassword(password, Buffer.alloc(36).toString('base64'));
      throw invalid;
    }
    if (!verifyPassword(password, storedPassword(user))) throw invalid;
    if (user.active_status !== 0) throw ApiError.forbidden('This account is inactive');

    const accessToken = accessTokenFor(user);
    const refresh = await issueRefreshToken(user, deviceInfo);

    return ok(res, {
      accessToken,
      refreshToken: refresh.token,
      expiresAt: refresh.expiresAt,
      user: publicUser(user),
    });
  }),
);

/**
 * POST /api/web/auth/refresh
 * Body: { refreshToken }
 * Rotates: the presented token is revoked and replaced.
 */
router.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const presented = str(req.body?.refreshToken, 'refreshToken', { max: 512 });

    const stored = await findRefreshToken(presented);
    if (!stored) throw ApiError.unauthorized('Refresh token is invalid or has expired');

    const userId = userIdFromStoredMobile(stored.user_mobile);
    if (!userId) throw ApiError.unauthorized('Refresh token is not valid for the website API');

    const user = await findUserById(userId);
    if (!user) throw ApiError.unauthorized('Account no longer exists');
    if (user.active_status !== 0) throw ApiError.forbidden('This account is inactive');

    await revokeRefreshToken(presented);

    const accessToken = accessTokenFor(user);
    const refresh = await issueRefreshToken(user, stored.device_info);

    return ok(res, {
      accessToken,
      refreshToken: refresh.token,
      expiresAt: refresh.expiresAt,
      user: publicUser(user),
    });
  }),
);

/** POST /api/web/auth/logout — revokes the presented refresh token. */
router.post(
  '/logout',
  asyncHandler(async (req, res) => {
    const presented = str(req.body?.refreshToken, 'refreshToken', { max: 512 });
    await revokeRefreshToken(presented);
    return ok(res, { loggedOut: true });
  }),
);

/** GET /api/web/auth/me — current user, re-read so role/tenant changes are picked up. */
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req, res) => {
    const user = await findUserById(req.user.userId);
    if (!user) throw ApiError.unauthorized('Account no longer exists');
    return ok(res, { user: publicUser(user) });
  }),
);

module.exports = router;
