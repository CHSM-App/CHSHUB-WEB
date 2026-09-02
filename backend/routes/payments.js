// Online payments (Razorpay) — server-authoritative amount + payment/receipt binding.
//
// Replaces the insecure routes/test.js create-order/verify-payment, where the
// client set the amount, the signature was compared with `!==`, and nothing
// bound the payment to a bill. See SQL/ADD_payment_order.sql for the model and
// docs/PAYMENTS-REMEDIATION.md for deployment.
//
// Mounted under `protect` at /payments (see app.js), except the webhook, which
// is public but authenticated by its Razorpay signature over the raw body.
const express = require('express');
const crypto = require('crypto');
const sql = require('mssql');
const Razorpay = require('razorpay');
const db = require('./db');
const protect = require('./middleware/protect');
const { requireOwnership } = require('./middleware/ownership');

const router = express.Router();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

/** Constant-time hex/string compare — never leak timing on the signature. */
function safeEqual(a, b) {
  const ba = Buffer.from(String(a || ''), 'utf8');
  const bb = Buffer.from(String(b || ''), 'utf8');
  if (ba.length !== bb.length) return false;
  return crypto.timingSafeEqual(ba, bb);
}

/** SQL Server unique-violation (UQ_transaction_ref / UQ_payment_order_rzp_order). */
function isDuplicate(err) {
  const n = err && (err.number || (err.originalError && err.originalError.info && err.originalError.info.number));
  return n === 2627 || n === 2601;
}

/**
 * Create the receipt from the ORDER's server-side amount and bind the Razorpay
 * payment id into receipt.transaction_ref (UNIQUE), then flip the order to
 * 'paid' — both inside one transaction. If anything throws, nothing is
 * committed: the payment is NOT reported settled and the call is retryable.
 * The UNIQUE transaction_ref means a replay of the same payment id cannot
 * create a second receipt.
 */
async function settleFromOrder(order, paymentId, payment) {
  const tx = new sql.Transaction(db);
  await tx.begin();
  try {
    const insert = await new sql.Request(tx)
      .input('Action', 'INSERT')
      .input('SocietyID', order.society_id)
      .input('FlatID', order.flat_id)
      .input('PayMode', payment && payment.method ? String(payment.method).slice(0, 20) : 'online')
      .input('TransactionRef', paymentId)               // UNIQUE — the anti-replay anchor
      .input('bills', order.bill_details)
      .input('PaidAmount', Number(order.amount_paise) / 100)  // trusted server amount, never client
      .input('Remarks', ('Razorpay ' + order.razorpay_order_id).slice(0, 255))
      .input('Status', 1)
      .input('CreatedBy', String(order.pre_mob).slice(0, 50))
      .execute('sp_MaintenanceReceipt');

    const receiptId = insert.recordset && insert.recordset[0] && insert.recordset[0].receipt_id;
    if (!receiptId) throw new Error('Receipt id not returned');

    await new sql.Request(tx)
      .input('operation', 'mark_paid')
      .input('razorpay_order_id', order.razorpay_order_id)
      .input('razorpay_payment_id', paymentId)
      .input('receipt_id', receiptId)
      .execute('sp_payment_order');

    await tx.commit();
    return receiptId;
  } catch (err) {
    try { await tx.rollback(); } catch (_) { /* already rolled back */ }
    throw err;
  }
}

/**
 * Step 2 — create an order. The client names the bills; the SERVER prices them.
 * Rejects: not the caller's flat (requireOwnership), missing/oversized bill
 * list, an invalid/already-settled bill, zero due, and any client-supplied
 * amount that disagrees with the server figure.
 */
router.post('/create-order', protect, requireOwnership('flat', r => r.body.flat_id), async (req, res) => {
  try {
    const flatId = parseInt(req.body.flat_id, 10);
    const billDetails = req.body.bill_details != null ? String(req.body.bill_details).trim() : '';
    if (!billDetails) return res.status(400).json({ error: 'bill_details (the bills to pay) is required' });
    if (billDetails.length > 20) {
      return res.status(400).json({ error: 'Too many bills for one payment (max 20 chars). Split the payment.' });
    }
    const requestedCount = billDetails.split(',').map(s => s.trim()).filter(Boolean).length;

    const quote = await db.request()
      .input('operation', 'quote')
      .input('flat_id', flatId)
      .input('bill_details', billDetails)
      .execute('sp_payment_order');

    const row = quote.recordset && quote.recordset[0];
    const amount = row ? Number(row.amount) : 0;
    const billCount = row ? Number(row.bill_count) : 0;
    const societyId = row ? row.society_id : null;

    // Every named bill must exist and still be due, or the price is wrong.
    if (billCount !== requestedCount) {
      return res.status(400).json({ error: 'One or more bills are invalid or already settled' });
    }
    if (!(amount > 0)) return res.status(400).json({ error: 'No outstanding dues to pay' });

    // A client amount is only ever cross-checked, never trusted.
    if (req.body.amount != null &&
        Math.round(Number(req.body.amount) * 100) !== Math.round(amount * 100)) {
      return res.status(400).json({ error: 'Amount mismatch: pay the outstanding amount', outstanding: amount });
    }

    const amountPaise = Math.round(amount * 100);
    const order = await razorpay.orders.create({
      amount: amountPaise,
      currency: 'INR',
      payment_capture: 1,
      notes: { flat_id: String(flatId), pre_mob: String(req.user.mobile) },
    });

    await db.request()
      .input('operation', 'create')
      .input('razorpay_order_id', order.id)
      .input('flat_id', flatId)
      .input('pre_mob', String(req.user.mobile).trim())
      .input('society_id', societyId)
      .input('amount_paise', amountPaise)
      .input('bill_details', billDetails)
      .execute('sp_payment_order');

    return res.json({ orderId: order.id, amount: amountPaise, currency: 'INR', keyId: process.env.RAZORPAY_KEY_ID });
  } catch (err) {
    console.error('create-order failed:', err.message);
    return res.status(500).json({ error: 'Could not create payment order' });
  }
});

/**
 * Step 3/4 — verify a client callback and settle. The callback is only a hint;
 * this endpoint re-derives everything from the server's order row and Razorpay.
 */
router.post('/verify', protect, async (req, res) => {
  const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body || {};
  if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
    return res.status(400).json({ error: 'razorpayOrderId, razorpayPaymentId and razorpaySignature are required' });
  }

  try {
    const got = await db.request()
      .input('operation', 'get')
      .input('razorpay_order_id', razorpayOrderId)
      .execute('sp_payment_order');
    const order = got.recordset && got.recordset[0];
    if (!order) return res.status(404).json({ error: 'Unknown order' });

    // Bind to the authenticated resident — not another flat's order.
    if (String(order.pre_mob).trim() !== String(req.user.mobile).trim()) {
      return res.status(403).json({ error: 'This order does not belong to you' });
    }

    // Signature over order_id|payment_id, constant-time.
    const expected = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(razorpayOrderId + '|' + razorpayPaymentId)
      .digest('hex');
    if (!safeEqual(expected, razorpaySignature)) {
      return res.status(400).json({ error: 'Invalid payment signature' });
    }

    // Already settled → idempotent success, no second receipt.
    if (order.status === 'paid') {
      return res.json({ success: true, receiptId: order.receipt_id, idempotent: true });
    }

    // Authoritative amount check against Razorpay itself.
    const payment = await razorpay.payments.fetch(razorpayPaymentId);
    if (!payment || Number(payment.amount) !== Number(order.amount_paise)) {
      return res.status(400).json({ error: 'Payment amount does not match the order' });
    }
    if (payment.status !== 'captured' && payment.status !== 'authorized') {
      return res.status(400).json({ error: 'Payment is not captured' });
    }

    const receiptId = await settleFromOrder(order, razorpayPaymentId, payment);
    return res.json({ success: true, receiptId });
  } catch (err) {
    if (isDuplicate(err)) {
      // A concurrent verify/webhook already settled this payment.
      return res.json({ success: true, idempotent: true });
    }
    console.error('verify failed:', err.message);
    return res.status(500).json({ error: 'Payment verification failed', retryable: true });
  }
});

/**
 * Step 5 — Razorpay webhook. Authoritative + idempotent. Uses the RAW body for
 * the signature (app.js stashes it on req.rawBody). Client callbacks are hints;
 * this is the source of truth if the client never returns.
 */
router.post('/webhook', async (req, res) => {
  try {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) { console.error('RAZORPAY_WEBHOOK_SECRET not set'); return res.status(500).end(); }

    const signature = req.get('x-razorpay-signature');
    const raw = req.rawBody || Buffer.from(JSON.stringify(req.body || {}));
    const expected = crypto.createHmac('sha256', secret).update(raw).digest('hex');
    if (!signature || !safeEqual(expected, signature)) {
      return res.status(400).json({ error: 'invalid signature' });
    }

    const event = req.body && req.body.event;
    const entity = req.body && req.body.payload && req.body.payload.payment && req.body.payload.payment.entity;
    if (event === 'payment.captured' && entity && entity.order_id) {
      const got = await db.request()
        .input('operation', 'get')
        .input('razorpay_order_id', entity.order_id)
        .execute('sp_payment_order');
      const order = got.recordset && got.recordset[0];
      if (order && order.status === 'created' && Number(entity.amount) === Number(order.amount_paise)) {
        try {
          await settleFromOrder(order, entity.id, entity);
        } catch (err) {
          if (!isDuplicate(err)) throw err; // duplicate == already settled, fine
        }
      }
    }

    // 200 once the signature is valid so Razorpay stops retrying.
    return res.json({ received: true });
  } catch (err) {
    console.error('webhook error:', err.message);
    return res.status(500).json({ error: 'webhook processing failed' });
  }
});

module.exports = router;
// Exported for unit tests (no live DB / Razorpay).
module.exports._internals = { safeEqual, isDuplicate };
