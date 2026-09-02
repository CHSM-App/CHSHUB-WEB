// Website API — access/refresh token issuing and verification.
//
// Refresh tokens are opaque random strings persisted via the existing
// ManageRefreshToken proc (the same store the mobile API uses). Access tokens
// are short-lived JWTs. Rotation on refresh: the presented token is revoked and
// a new one issued, so a stolen token is usable at most once.
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { exec, query, sql } = require('./db');
const { ApiError } = require('./http');

const ACCESS_TTL = process.env.WEB_ACCESS_TOKEN_TTL || '15m';
const REFRESH_TTL_DAYS = Number(process.env.WEB_REFRESH_TOKEN_DAYS || 7);

function secret() {
  const key = process.env.JWT_SECRET_KEY;
  if (!key) {
    // Fail loudly at use time rather than signing with `undefined`, which
    // jsonwebtoken would reject anyway but with a far less obvious message.
    throw new Error('JWT_SECRET_KEY is not configured');
  }
  return key;
}

/**
 * The JWT payload. Deliberately minimal — enough to authorise a request without
 * a DB round-trip, and no PII beyond what the client already holds.
 */
function accessTokenFor(user) {
  return jwt.sign(
    {
      sub: String(user.user_id),
      scope: 'web',
      society_id: user.society_id || null,
      village_id: user.village_id || null,
      user_type_id: user.user_type_id ?? null,
      owner_id: user.owner_id ?? null,
    },
    secret(),
    { expiresIn: ACCESS_TTL },
  );
}

function verifyAccessToken(token) {
  try {
    return jwt.verify(token, secret());
  } catch {
    throw ApiError.unauthorized('Token is invalid or has expired');
  }
}

function newRefreshToken() {
  return crypto.randomBytes(64).toString('hex');
}

function refreshExpiry() {
  return new Date(Date.now() + REFRESH_TTL_DAYS * 24 * 3600 * 1000);
}

/**
 * Persist a refresh token.
 *
 * ManageRefreshToken keys rows by `user_mobile`. The web client logs in by
 * username, so we store a scoped identity ("web:<user_id>") to keep website
 * sessions from colliding with the mobile app's rows for the same person.
 */
async function issueRefreshToken(user, deviceInfo) {
  const token = newRefreshToken();
  const expiresAt = refreshExpiry();

  await exec('ManageRefreshToken', {
    operation: 'insert',
    user_mobile: { type: sql.NVarChar(50), value: `web:${user.user_id}` },
    refresh_token: { type: sql.NVarChar(sql.MAX), value: token },
    device_info: { type: sql.NVarChar(500), value: deviceInfo || null },
    expires_at: { type: sql.DateTime2, value: expiresAt },
  });

  return { token, expiresAt };
}

/** Look up a refresh token; returns the stored row or null if invalid/expired/revoked. */
async function findRefreshToken(token) {
  const rows = await query('ManageRefreshToken', {
    operation: 'get',
    refresh_token: { type: sql.NVarChar(sql.MAX), value: token },
  });
  return rows.length ? rows[0] : null;
}

async function revokeRefreshToken(token) {
  await exec('ManageRefreshToken', {
    operation: 'revoke',
    refresh_token: { type: sql.NVarChar(sql.MAX), value: token },
  });
}

/**
 * End every live session for one person. Called after a password change or
 * reset.
 *
 * A password change that leaves the old sessions running defeats its own
 * purpose: the session someone changes their password to get rid of is exactly
 * the one that would otherwise keep refreshing for the full 7 days. Access
 * tokens cannot be recalled — they are stateless JWTs — so revoking the refresh
 * tokens is what bounds an old session, to at most one access-token lifetime
 * (15 minutes) instead of a week.
 *
 * Revokes across BOTH apps. RefreshTokens.user_mobile holds a phone number for
 * the mobile API and 'web:<user_id>' for this one; a password belongs to the
 * person rather than to one of their devices, so signing them out of the
 * website while leaving the mobile app running would be a half-measure.
 * `contactNo` is therefore the user's phone number, not a second web identity.
 *
 * @param {object}  user           row carrying user_id and contact_no
 * @param {string?} exceptToken    refresh token to spare — the session doing
 *                                 the changing, so the user is not signed out
 *                                 of the device they are typing on. Omit on a
 *                                 reset, where there is no session to keep.
 * @returns {Promise<number>} how many sessions were actually ended
 */
async function revokeAllRefreshTokensForUser(user, exceptToken = null) {
  const contactNo = String(user?.contact_no ?? '').trim();

  const rows = await query('ManageRefreshToken', {
    operation: 'revoke_all_for_user',
    user_mobile: { type: sql.NVarChar(50), value: `web:${user.user_id}` },
    // Empty string would match no row anyway, but NULL is what the proc's
    // "skip this key" branch tests for.
    contact_no: { type: sql.NVarChar(50), value: contactNo || null },
    except_token: { type: sql.NVarChar(sql.MAX), value: exceptToken || null },
  });

  return Number(rows?.[0]?.revoked_count ?? 0);
}

/** Extract the user_id encoded by issueRefreshToken. */
function userIdFromStoredMobile(userMobile) {
  const m = /^web:(\d+)$/.exec(String(userMobile || ''));
  return m ? Number(m[1]) : null;
}

module.exports = {
  accessTokenFor,
  verifyAccessToken,
  issueRefreshToken,
  findRefreshToken,
  revokeRefreshToken,
  revokeAllRefreshTokensForUser,
  userIdFromStoredMobile,
  REFRESH_TTL_DAYS,
};
