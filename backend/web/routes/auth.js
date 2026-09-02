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
// Shared with the registration route, which signs the new account in directly.
const { publicUser } = require('../lib/publicUser');
// Shared with the password routes, which need the same rows to revoke sessions.
const {
  storedPassword,
  findUserByUsername,
  findUserById,
} = require('../lib/users');

const router = express.Router();

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

    /*
     * Re-read through the same path /auth/me uses before answering.
     *
     * `validateuser` is a login-verification proc: it returns what is needed to
     * check a password, and its column list is not the one publicUser expects.
     * photo_path is the field that exposed this — absent there, so a freshly
     * signed-in session carried no avatar until something happened to call
     * /auth/me, which is why the photo appeared in the app (it calls loadMe on
     * open) and not in the website's header.
     *
     * Falls back to the login row if the re-read comes back empty, so a
     * mismatch can never turn a successful sign-in into a failed one.
     */
    const full = (await findUserById(user.user_id)) ?? user;

    return ok(res, {
      accessToken,
      refreshToken: refresh.token,
      expiresAt: refresh.expiresAt,
      user: publicUser(full),
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
