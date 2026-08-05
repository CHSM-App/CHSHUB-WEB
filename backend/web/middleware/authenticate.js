// Website API — authentication and tenant scoping.
const { ApiError, asyncHandler } = require('../lib/http');
const { verifyAccessToken } = require('../lib/tokens');

/**
 * Require a valid website access token.
 *
 * Rejects tokens minted for the mobile app: those carry no `scope`, and the
 * mobile issuer (`/login/Createlogin`) performs no password check, so honouring
 * them here would inherit that weakness into the admin surface.
 */
const authenticate = asyncHandler(async (req, _res, next) => {
  const header = req.get('Authorization') || '';
  const [scheme, token] = header.split(' ');

  if (!header || !/^Bearer$/i.test(scheme || '') || !token) {
    throw ApiError.unauthorized('Missing Bearer token');
  }

  const claims = verifyAccessToken(token);
  if (claims.scope !== 'web') {
    throw ApiError.unauthorized('Token is not valid for the website API');
  }

  req.user = {
    userId: Number(claims.sub),
    societyId: claims.society_id || null,
    villageId: claims.village_id || null,
    userTypeId: claims.user_type_id ?? null,
    ownerId: claims.owner_id ?? null,
  };

  next();
});

/**
 * Resolve the society for this request.
 *
 * The society always comes from the token, never from client input — otherwise
 * any authenticated user could read another society's data by changing a query
 * parameter. If a request does supply one, it must match.
 */
function requireSociety(req, _res, next) {
  const claimed = req.query.society_id || req.body?.society_id;
  const societyId = req.user?.societyId;

  if (!societyId) {
    return next(ApiError.forbidden('This account is not linked to a society'));
  }
  if (claimed && String(claimed) !== String(societyId)) {
    return next(ApiError.forbidden('Cannot access another society'));
  }

  req.societyId = societyId;
  next();
}

/** Same rule for Village (Gram Panchayat) users. */
function requireVillage(req, _res, next) {
  const claimed = req.query.village_id || req.body?.village_id;
  const villageId = req.user?.villageId;

  if (!villageId) {
    return next(ApiError.forbidden('This account is not linked to a village'));
  }
  if (claimed && String(claimed) !== String(villageId)) {
    return next(ApiError.forbidden('Cannot access another village'));
  }

  req.villageId = villageId;
  next();
}

module.exports = { authenticate, requireSociety, requireVillage };
