// Role matrix for the website/admin API (user_type_id authorization).
//
// The real user_type_id -> role mapping lives in the DB's UserType table, not
// in source, so it is NOT hardcoded here — that would risk locking out admins
// or mislabelling a role. Instead each role's ids come from the environment.
// The operator reads them once from their DB and sets them:
//
//   SELECT UserTypeId, UserTypeName FROM dbo.UserType;   -- then, e.g.:
//   ROLE_CHAIRMAN_IDS=1
//   ROLE_SECRETARY_IDS=2
//   ROLE_TREASURER_IDS=3
//   ROLE_MEMBER_IDS=4,5
//
// Until at least one ROLE_*_IDS is set, `configured` is false and the
// authorize middleware stays permissive (logs a warning) so existing admins
// are not locked out mid-deploy. See docs/PRODUCTION-GO-LIVE-CHECKLIST.md.

function idsFromEnv(name) {
  return new Set(
    (process.env[name] || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
      .map(Number)
      .filter((n) => Number.isInteger(n)),
  );
}

const ROLE_IDS = {
  chairman: idsFromEnv('ROLE_CHAIRMAN_IDS'),
  secretary: idsFromEnv('ROLE_SECRETARY_IDS'),
  treasurer: idsFromEnv('ROLE_TREASURER_IDS'),
  member: idsFromEnv('ROLE_MEMBER_IDS'),
};

const configured = Object.values(ROLE_IDS).some((s) => s.size > 0);

/** True if userTypeId belongs to any of the named roles. */
function hasAnyRole(userTypeId, roleNames) {
  if (userTypeId == null) return false;
  const id = Number(userTypeId);
  return roleNames.some((r) => ROLE_IDS[r] && ROLE_IDS[r].has(id));
}

/*
 * Named groups used at the route mounts. Roles are evaluated independently of
 * tenant type (society vs village) — a treasurer is a treasurer in either.
 *   SOCIETY_ADMIN — Chairman/Secretary: full administration.
 *   FINANCE       — + Treasurer: billing, receipts, accounts, vendor bills, reports.
 *   MEMBER        — read-only / community.
 */
const GROUPS = {
  SOCIETY_ADMIN: ['chairman', 'secretary'],
  FINANCE: ['chairman', 'secretary', 'treasurer'],
  MEMBER: ['chairman', 'secretary', 'treasurer', 'member'],
};

module.exports = { ROLE_IDS, configured, hasAnyRole, GROUPS };
