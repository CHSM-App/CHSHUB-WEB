// Payment-integrity tests (routes/payments.js). No live DB, no live Razorpay,
// no test framework: ./db, mssql and razorpay are stubbed via require.cache,
// then the REAL router is mounted and driven over HTTP with a genuine JWT and
// real HMAC signatures.
//
//   node backend/test/payments.test.js
const assert = require('assert');
const http = require('http');
const crypto = require('crypto');
const express = require('express');

process.env.JWT_SECRET_KEY = 'test-jwt-secret';
process.env.RAZORPAY_KEY_ID = 'rzp_test_key';
process.env.RAZORPAY_KEY_SECRET = 'rzp_test_secret';
process.env.RAZORPAY_WEBHOOK_SECRET = 'whsec_test';

const jwt = require('../node_modules/jsonwebtoken');

// ---- programmable stub state -------------------------------------------------
const state = {
  owned: 1,                                   // sp_owner_scope result
  quote: { amount: 5000, society_id: 'S1', bill_count: 1 },
  orders: {},                                 // order_id -> row
  txnSeen: new Set(),                         // receipt.transaction_ref (UNIQUE)
  nextReceiptId: 100,
  receiptThrows: null,                        // force a non-duplicate DB failure
};
let orderSeq = 0;
const dupErr = () => Object.assign(new Error('Violation of UNIQUE KEY'), { number: 2627 });

// Shared executor for db.request() and new sql.Request(tx).
async function execProc(proc, p) {
  if (proc === 'sp_owner_scope') return { recordset: [{ owned: state.owned }] };

  if (proc === 'sp_payment_order') {
    if (p.operation === 'quote') return { recordset: [state.quote] };
    if (p.operation === 'create') {
      state.orders[p.razorpay_order_id] = {
        razorpay_order_id: p.razorpay_order_id, flat_id: p.flat_id, pre_mob: p.pre_mob,
        society_id: p.society_id, amount_paise: p.amount_paise, bill_details: p.bill_details,
        status: 'created', razorpay_payment_id: null, receipt_id: null,
      };
      return { recordset: [{ razorpay_order_id: p.razorpay_order_id, amount_paise: p.amount_paise, status: 'created' }] };
    }
    if (p.operation === 'get') {
      const o = state.orders[p.razorpay_order_id];
      return { recordset: o ? [o] : [] };
    }
    if (p.operation === 'mark_paid') {
      const o = state.orders[p.razorpay_order_id];
      if (o && o.status === 'created') {
        o.status = 'paid'; o.razorpay_payment_id = p.razorpay_payment_id; o.receipt_id = p.receipt_id;
        return { recordset: [{ updated: 1 }] };
      }
      return { recordset: [{ updated: 0 }] };
    }
  }

  if (proc === 'sp_MaintenanceReceipt' && p.Action === 'INSERT') {
    if (state.receiptThrows) throw state.receiptThrows;
    if (state.txnSeen.has(p.TransactionRef)) throw dupErr();   // UNIQUE transaction_ref
    state.txnSeen.add(p.TransactionRef);
    return { recordset: [{ receipt_id: state.nextReceiptId++ }] };
  }
  throw new Error('unexpected proc ' + proc + '/' + (p.operation || p.Action));
}

function RequestStub() { this.p = {}; }
RequestStub.prototype.input = function (k, v) { this.p[k] = v; return this; };
RequestStub.prototype.execute = function (proc) { return execProc(proc, this.p); };

// ---- inject stubs before requiring the router --------------------------------
const dbStub = { request: () => new RequestStub(), connect: () => {}, on: () => {} };
require.cache[require.resolve('../routes/db')] = { id: '1', filename: '1', loaded: true, exports: dbStub };

const mssqlStub = {
  Transaction: function () {},
  Request: function () { return new RequestStub(); },
};
mssqlStub.Transaction.prototype.begin = async function () {};
mssqlStub.Transaction.prototype.commit = async function () {};
mssqlStub.Transaction.prototype.rollback = async function () {};
require.cache[require.resolve('../node_modules/mssql')] = { id: '2', filename: '2', loaded: true, exports: mssqlStub };

const rzpState = { fetch: { amount: 500000, status: 'captured', method: 'upi' } };
function RazorpayStub() {}
RazorpayStub.prototype.orders = { create: async (o) => ({ id: 'order_' + (++orderSeq), amount: o.amount }) };
RazorpayStub.prototype.payments = { fetch: async () => rzpState.fetch };
// razorpay is `new Razorpay(...)`, so the module export must be the constructor.
const RZ = function (cfg) { return new RazorpayStub(cfg); };
RZ.prototype = RazorpayStub.prototype;
require.cache[require.resolve('../node_modules/razorpay')] = { id: '3', filename: '3', loaded: true, exports: RazorpayStub };

const paymentsRouter = require('../routes/payments');
const insertRouter = require('../routes/insert');
const protect = require('../routes/middleware/protect');

// ---- server ------------------------------------------------------------------
const app = express();
app.use(express.json({ verify: (req, _res, buf) => { req.rawBody = buf; } }));
app.use('/payments', paymentsRouter);
app.use('/insert', protect, insertRouter);
const server = http.createServer(app);

const TOKEN = jwt.sign({ mobile: '9000000001', scope: 'mobile' }, process.env.JWT_SECRET_KEY);
const sign = (o, pmt) => crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET).update(o + '|' + pmt).digest('hex');

function call(method, path, body, { auth = true, raw } = {}) {
  return new Promise((resolve, reject) => {
    const data = raw != null ? raw : (body != null ? JSON.stringify(body) : '');
    const req = http.request({
      method, port: server.address().port, path,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
        ...(auth ? { Authorization: 'Bearer ' + TOKEN } : {}),
        ...(body && body.__sig ? { 'x-razorpay-signature': body.__sig } : {}),
        ...((raw && raw.__hdr) ? {} : {}),
      },
    }, (res) => {
      let out = '';
      res.on('data', (c) => (out += c));
      res.on('end', () => resolve({ status: res.statusCode, body: out ? JSON.parse(out) : {} }));
    });
    req.on('error', reject);
    req.end(data);
  });
}
function callWebhook(payloadObj) {
  const raw = JSON.stringify(payloadObj);
  const sig = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET).update(raw).digest('hex');
  return new Promise((resolve, reject) => {
    const req = http.request({
      method: 'POST', port: server.address().port, path: '/payments/webhook',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(raw), 'x-razorpay-signature': sig },
    }, (res) => { let o=''; res.on('data',c=>o+=c); res.on('end',()=>resolve({status:res.statusCode, body:o?JSON.parse(o):{}})); });
    req.on('error', reject); req.end(raw);
  });
}

function reset() {
  state.owned = 1;
  state.quote = { amount: 5000, society_id: 'S1', bill_count: 1 };
  state.orders = {}; state.txnSeen = new Set(); state.nextReceiptId = 100; state.receiptThrows = null;
  rzpState.fetch = { amount: 500000, status: 'captured', method: 'upi' };
}
async function makeOrder() {
  const r = await call('POST', '/payments/create-order', { flat_id: 10, bill_details: 'B1' });
  assert.strictEqual(r.status, 200, 'order create should succeed');
  return r.body.orderId;
}

(async () => {
  await new Promise((r) => server.listen(0, r));
  try {
    // 1. Cannot create a Rs.1 order for a Rs.5000 bill.
    reset();
    let r = await call('POST', '/payments/create-order', { flat_id: 10, bill_details: 'B1', amount: 1 });
    assert.strictEqual(r.status, 400, '#1 client amount mismatch must be rejected');

    // 2. Cannot pay another resident's bill (not the caller's flat).
    reset(); state.owned = 0;
    r = await call('POST', '/payments/create-order', { flat_id: 999, bill_details: 'B1' });
    assert.strictEqual(r.status, 403, '#2 foreign flat must be 403');

    // 3. Client cannot manipulate the amount — the order uses the server figure.
    reset();
    r = await call('POST', '/payments/create-order', { flat_id: 10, bill_details: 'B1' });
    assert.strictEqual(r.status, 200);
    assert.strictEqual(r.body.amount, 500000, '#3 order amount must be server-computed paise');

    // 4. Invalid signature fails.
    reset();
    let orderId = await makeOrder();
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_A', razorpaySignature: 'deadbeef' });
    assert.strictEqual(r.status, 400, '#4 bad signature must be 400');
    assert.strictEqual(state.orders[orderId].status, 'created', '#4 must not settle');

    // 5. Correct signature but wrong captured amount fails.
    reset(); orderId = await makeOrder();
    rzpState.fetch = { amount: 100, status: 'captured', method: 'upi' };  // != 500000
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_B', razorpaySignature: sign(orderId, 'pay_B') });
    assert.strictEqual(r.status, 400, '#5 amount mismatch must be 400');

    // 6. Same payment cannot generate two receipts.
    reset(); orderId = await makeOrder();
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_C', razorpaySignature: sign(orderId, 'pay_C') });
    assert.strictEqual(r.status, 200); assert.ok(r.body.receiptId, 'first verify creates receipt');
    const afterFirst = state.nextReceiptId;
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_C', razorpaySignature: sign(orderId, 'pay_C') });
    assert.strictEqual(r.status, 200); assert.strictEqual(r.body.idempotent, true, '#6 replay is idempotent');
    assert.strictEqual(state.nextReceiptId, afterFirst, '#6 no second receipt');

    // 7. Receipt is linked to the Razorpay payment id.
    reset(); orderId = await makeOrder();
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_D', razorpaySignature: sign(orderId, 'pay_D') });
    assert.strictEqual(r.status, 200);
    assert.strictEqual(state.orders[orderId].razorpay_payment_id, 'pay_D', '#7 payment id bound to order');
    assert.ok(state.txnSeen.has('pay_D'), '#7 receipt.transaction_ref = payment id');

    // 8. Direct AddReceipt cannot bypass the online controls.
    reset();
    r = await call('POST', '/insert/AddReceipt', { flat_id: 10, paid_amount: 1, bill_details: 'B1', society_id: 'S1' });
    assert.strictEqual(r.status, 403, '#8 AddReceipt must be blocked');

    // 9. Webhook is idempotent (and authoritative when the client never returns).
    reset(); orderId = await makeOrder();
    const evt = { event: 'payment.captured', payload: { payment: { entity: { id: 'pay_E', order_id: orderId, amount: 500000, status: 'captured' } } } };
    let w = await callWebhook(evt);
    assert.strictEqual(w.status, 200); assert.strictEqual(state.orders[orderId].status, 'paid', '#9 webhook settles');
    const afterWebhook = state.nextReceiptId;
    w = await callWebhook(evt);
    assert.strictEqual(w.status, 200); assert.strictEqual(state.nextReceiptId, afterWebhook, '#9 webhook idempotent');

    // 10. Failed DB transaction does not falsely settle.
    reset(); orderId = await makeOrder();
    state.receiptThrows = new Error('deadlock');   // non-duplicate DB failure
    r = await call('POST', '/payments/verify', { razorpayOrderId: orderId, razorpayPaymentId: 'pay_F', razorpaySignature: sign(orderId, 'pay_F') });
    assert.strictEqual(r.status, 500, '#10 failure must not report success');
    assert.strictEqual(r.body.retryable, true, '#10 must be retryable');
    assert.strictEqual(state.orders[orderId].status, 'created', '#10 order not marked paid');

    // 11. Partial/selective payment integrity — a named bill that is not due (or
    //     was already settled) makes matched-count != requested-count -> reject.
    reset(); state.quote = { amount: 5000, society_id: 'S1', bill_count: 1 };
    r = await call('POST', '/payments/create-order', { flat_id: 10, bill_details: 'B1,B2' }); // 2 requested, 1 due
    assert.strictEqual(r.status, 400, '#11 invalid/settled bill in the set must be rejected');

    // 12. Fully-paid bill cannot be paid again (no outstanding dues).
    reset(); state.quote = { amount: 0, society_id: 'S1', bill_count: 1 };
    r = await call('POST', '/payments/create-order', { flat_id: 10, bill_details: 'B1' });
    assert.strictEqual(r.status, 400, '#12 zero outstanding must be rejected');

    // Signature verification is constant-time.
    assert.strictEqual(paymentsRouter._internals.safeEqual('abc', 'abc'), true);
    assert.strictEqual(paymentsRouter._internals.safeEqual('abc', 'abd'), false);
    assert.strictEqual(paymentsRouter._internals.safeEqual('abc', 'abcd'), false);

    console.log('payments.test.js: all 12 cases + signature checks passed');
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    server.close();
  }
})();
