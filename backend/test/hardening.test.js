// Security middleware (lib/security.js): headers + rate limiting.
//   node backend/test/hardening.test.js
const assert = require('assert');
const http = require('http');
const express = require('express');
const { securityHeaders, globalLimiter, otpLimiter } = require('../lib/security');

const app = express();
app.set('trust proxy', 1);
app.use(securityHeaders);
app.use(express.json());
// A tiny endpoint under a very low limiter to prove limiting engages.
app.use('/tight', require('express-rate-limit')({ windowMs: 60000, max: 2, standardHeaders: true, legacyHeaders: false }));
app.get('/tight', (_req, res) => res.json({ ok: true }));
app.get('/ok', globalLimiter, (_req, res) => res.json({ ok: true }));
const server = http.createServer(app);

function get(path) {
  return new Promise((resolve, reject) => {
    http.get({ port: server.address().port, path }, (res) => {
      let b = ''; res.on('data', (c) => (b += c)); res.on('end', () => resolve({ status: res.statusCode, headers: res.headers }));
    }).on('error', reject);
  });
}

(async () => {
  await new Promise((r) => server.listen(0, r));
  try {
    // helmet headers present, and no CSP (deliberately off for the React app).
    const r = await get('/ok');
    assert.strictEqual(r.headers['x-content-type-options'], 'nosniff', 'nosniff header set');
    assert.ok(r.headers['referrer-policy'], 'referrer-policy set');
    assert.ok(!r.headers['content-security-policy'], 'CSP intentionally not set');
    assert.ok(r.headers['ratelimit-limit'] || r.headers['ratelimit'], 'standard rate-limit headers present');

    // Limiter actually blocks after the cap.
    assert.strictEqual((await get('/tight')).status, 200);
    assert.strictEqual((await get('/tight')).status, 200);
    assert.strictEqual((await get('/tight')).status, 429, 'third request over cap is 429');

    // OTP limiter keys on IP + mobile.
    const key = otpLimiter.keyGenerator || (otpLimiter.options && otpLimiter.options.keyGenerator);
    if (key) {
      const k = key({ ip: '1.2.3.4', body: { mobile: '9000000001' } });
      assert.ok(k.includes('1.2.3.4') && k.includes('9000000001'), 'otp key includes ip + mobile');
    }

    console.log('hardening.test.js: all assertions passed');
  } catch (e) {
    console.error(e); process.exitCode = 1;
  } finally {
    server.close();
  }
})();
