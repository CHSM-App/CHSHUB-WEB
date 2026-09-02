// Mobile auth middleware (routes/middleware/auth.js): scope + validity.
//   node backend/test/auth.test.js
const assert = require('assert');
process.env.JWT_SECRET_KEY = 'test-jwt-secret';
const jwt = require('../node_modules/jsonwebtoken');
const auth = require('../routes/middleware/auth');

function res() {
  return { code: null, body: null, status(c){ this.code = c; return this; }, json(b){ this.body = b; return this; } };
}
function run(token) {
  const req = { header: (k) => (k === 'Authorization' && token ? 'Bearer ' + token : undefined) };
  const r = res();
  let nexted = false;
  auth(req, r, () => { nexted = true; });
  return { nexted, r, req };
}

// valid mobile token -> next(), req.user set
let t = jwt.sign({ mobile: '9000000001', scope: 'mobile' }, process.env.JWT_SECRET_KEY);
let { nexted, r, req } = run(t);
assert.strictEqual(nexted, true, 'valid mobile token passes');
assert.strictEqual(req.user.mobile, '9000000001');

// no header -> 401
({ nexted, r } = run(null));
assert.strictEqual(r.code, 401, 'missing token 401');
assert.strictEqual(nexted, false);

// garbage token -> 401
({ nexted, r } = run('not.a.jwt'));
assert.strictEqual(r.code, 401, 'invalid token 401');

// wrong scope (web token) -> 401 on the mobile API
t = jwt.sign({ sub: '5', scope: 'web' }, process.env.JWT_SECRET_KEY);
({ nexted, r } = run(t));
assert.strictEqual(r.code, 401, 'web-scope token rejected on mobile API');
assert.strictEqual(nexted, false);

// unscoped legacy token -> 401 (scope now required)
t = jwt.sign({ mobile: '9000000001' }, process.env.JWT_SECRET_KEY);
({ nexted, r } = run(t));
assert.strictEqual(r.code, 401, 'unscoped token rejected');

// expired token -> 401
t = jwt.sign({ mobile: '9000000001', scope: 'mobile' }, process.env.JWT_SECRET_KEY, { expiresIn: -10 });
({ nexted, r } = run(t));
assert.strictEqual(r.code, 401, 'expired token 401');

// wrong secret -> 401
t = jwt.sign({ mobile: '9000000001', scope: 'mobile' }, 'some-other-secret');
({ nexted, r } = run(t));
assert.strictEqual(r.code, 401, 'token signed with wrong secret 401');

console.log('auth.test.js: all assertions passed');
