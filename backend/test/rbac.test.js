// Role-based access control (web/middleware/authorize.js + web/lib/roles.js).
//   node backend/test/rbac.test.js
// Configure a known id->role mapping BEFORE requiring the modules (roles.js
// reads env at load).
process.env.ROLE_CHAIRMAN_IDS = '1';
process.env.ROLE_SECRETARY_IDS = '2';
process.env.ROLE_TREASURER_IDS = '3';
process.env.ROLE_MEMBER_IDS = '4';

const assert = require('assert');
const { requireUserType, GROUPS } = require('../web/middleware/authorize');

function run(mw, userTypeId) {
  const req = { user: { userTypeId } };
  let err = null, nexted = false;
  mw(req, {}, (e) => { if (e) err = e; else nexted = true; });
  return { err, nexted };
}
const denied = (r) => !!(r.err && r.err.status === 403) && !r.nexted;
const allowed = (r) => r.nexted && !r.err;

// Member (4): denied society-admin AND finance.
assert.ok(denied(run(requireUserType(GROUPS.SOCIETY_ADMIN), 4)), 'member denied society-admin');
assert.ok(denied(run(requireUserType(GROUPS.FINANCE), 4)), 'member denied finance');

// Treasurer (3): finance yes, society-admin no.
assert.ok(allowed(run(requireUserType(GROUPS.FINANCE), 3)), 'treasurer allowed finance');
assert.ok(denied(run(requireUserType(GROUPS.SOCIETY_ADMIN), 3)), 'treasurer denied society-admin');

// Secretary (2) + Chairman (1): both areas.
assert.ok(allowed(run(requireUserType(GROUPS.SOCIETY_ADMIN), 2)), 'secretary society-admin');
assert.ok(allowed(run(requireUserType(GROUPS.FINANCE), 1)), 'chairman finance');
assert.ok(allowed(run(requireUserType(GROUPS.SOCIETY_ADMIN), 1)), 'chairman society-admin');

// Missing / unknown role -> denied when configured.
assert.ok(denied(run(requireUserType(GROUPS.FINANCE), null)), 'no role id denied');
assert.ok(denied(run(requireUserType(GROUPS.FINANCE), 99)), 'unknown role id denied');

console.log('rbac.test.js: all assertions passed');
