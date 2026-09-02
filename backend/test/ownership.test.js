// Enforcement test for the IDOR fix (routes/middleware/ownership.js).
//
// No live DB and no test framework: sp_owner_scope is stubbed so we test the
// middleware contract in isolation — own record passes, another's is 403, the
// identity handed to SQL is the token's mobile (never the request's).
//
//   node backend/test/ownership.test.js
const assert = require('assert');
const path = require('path');

// Stub the db module ownership.js pulls in (../db from the middleware dir,
// which resolves to routes/db.js — the same file this test names via ../routes/db).
const dbPath = require.resolve('../routes/db');
let lastInputs;
const stub = {
  request() {
    lastInputs = {};
    const r = {
      input(name, value) { lastInputs[name] = value; return r; },
      // sp_owner_scope returns one row: { owned: 1|0 }
      execute() { return Promise.resolve({ recordset: [{ owned: stub._owned }] }); },
    };
    return r;
  },
  _owned: 0,
};
require.cache[dbPath] = { id: dbPath, filename: dbPath, loaded: true, exports: stub };

const { requireOwnership } = require('../routes/middleware/ownership');

function fakeRes() {
  return {
    statusCode: null, body: null,
    status(c) { this.statusCode = c; return this; },
    json(b) { this.body = b; return this; },
  };
}
// Run a middleware to completion; resolves with { nexted, res }.
function run(mw, req) {
  const res = fakeRes();
  return new Promise((resolve) => {
    let nexted = false;
    const next = () => { nexted = true; resolve({ nexted, res }); };
    const maybe = mw(req, res, next);
    // handlers that answer without next() resolve on the next tick
    Promise.resolve(maybe).then(() => { if (!nexted) resolve({ nexted, res }); });
  });
}

(async () => {
  const OWNER_MOBILE = '9000000001';

  // PASS — caller reads their own flat.
  stub._owned = 1;
  let { nexted, res } = await run(
    requireOwnership('flat', r => r.params.flat_id),
    { user: { mobile: OWNER_MOBILE }, params: { flat_id: '101' } },
  );
  assert.strictEqual(nexted, true, 'own record should call next()');
  assert.strictEqual(res.statusCode, null, 'own record should not set an error status');
  assert.strictEqual(lastInputs.pre_mob, OWNER_MOBILE, 'identity must come from the token');
  assert.strictEqual(lastInputs.kind, 'flat');
  assert.strictEqual(lastInputs.id, 101, 'id must be the parsed integer');

  // FAIL (read) — caller requests another resident's flat: sp says not owned.
  stub._owned = 0;
  ({ nexted, res } = await run(
    requireOwnership('flat', r => r.params.flat_id),
    { user: { mobile: OWNER_MOBILE }, params: { flat_id: '777' } },
  ));
  assert.strictEqual(nexted, false, 'another flat must not reach the handler');
  assert.strictEqual(res.statusCode, 403, 'another flat must be 403');

  // FAIL (modify) — repointing another resident's push token (notify NewToken).
  stub._owned = 0;
  ({ nexted, res } = await run(
    requireOwnership(r => (r.query.type === 'Owner' ? 'owner' : 'ownerext'), r => r.query.owner_id),
    { user: { mobile: OWNER_MOBILE }, query: { type: 'Owner', owner_id: '55' } },
  ));
  assert.strictEqual(nexted, false, "another owner's token write must be blocked");
  assert.strictEqual(res.statusCode, 403);
  assert.strictEqual(lastInputs.kind, 'owner', 'type=Owner resolves to the owner kind');

  // FAIL (delete) — deleting another resident's document.
  stub._owned = 0;
  ({ nexted, res } = await run(
    requireOwnership('document', r => r.params.id),
    { user: { mobile: OWNER_MOBILE }, params: { id: '999' } },
  ));
  assert.strictEqual(nexted, false, "another resident's document delete must be blocked");
  assert.strictEqual(res.statusCode, 403);

  // No token → 401 (fail closed), and SQL is never consulted.
  stub._owned = 1;
  ({ nexted, res } = await run(
    requireOwnership('flat', r => r.params.flat_id),
    { params: { flat_id: '101' } },
  ));
  assert.strictEqual(res.statusCode, 401, 'missing identity must be 401');
  assert.strictEqual(nexted, false);

  // Non-numeric id → 400 before any DB call.
  ({ nexted, res } = await run(
    requireOwnership('flat', r => r.params.flat_id),
    { user: { mobile: OWNER_MOBILE }, params: { flat_id: 'abc' } },
  ));
  assert.strictEqual(res.statusCode, 400, 'bad id must be 400');
  assert.strictEqual(nexted, false);

  console.log('ownership.test.js: all assertions passed');
})().catch((err) => { console.error(err); process.exit(1); });
