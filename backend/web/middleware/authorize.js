// Website/admin API — role-based authorization (user_type_id).
//
// Separate from tenant scoping (requireSociety/requireVillage/requireTenant in
// authenticate.js): tenant answers "which society/village", role answers "what
// may this user do". Both must pass. Frontend hiding is UX only — this is the
// enforcement point, so a hidden sidebar item is still rejected here if called.
const logger = require('../../lib/logger');
const { ApiError } = require('../lib/http');
const roles = require('../lib/roles');

let warnedOnce = false;

/**
 * requireUserType(allowedRoleNames) — allow the request only if the caller's
 * user_type_id (from the verified token) maps to one of the named roles.
 *
 * If no role ids are configured (ROLE_*_IDS unset), stays permissive and warns
 * once, so a deploy does not lock every admin out before the operator maps ids.
 */
function requireUserType(allowedRoles) {
  const allowed = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
  return function (req, _res, next) {
    if (!roles.configured) {
      if (!warnedOnce) {
        logger.warn(
          'RBAC role ids not configured (ROLE_*_IDS unset) — role checks are permissive. ' +
            'Set them from dbo.UserType; see docs/PRODUCTION-GO-LIVE-CHECKLIST.md',
        );
        warnedOnce = true;
      }
      return next();
    }
    const uid = req.user && req.user.userTypeId;
    if (roles.hasAnyRole(uid, allowed)) return next();
    return next(ApiError.forbidden('Your role is not permitted to perform this action'));
  };
}

module.exports = { requireUserType, GROUPS: roles.GROUPS };
