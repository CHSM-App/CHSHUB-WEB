 var express = require('express');
var router = express.Router();
var http=require('http');
var db = require("./db");
const Razorpay = require('razorpay');
const bodyParser = require('body-parser');
const crypto = require('crypto');
require('dotenv').config({ path: __dirname + '/.env' });
router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: true }));

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

router.post('/create-order', async (req, res) => {
    const { amount, currency , receipt  } = req.body;

  const options = {
    amount: amount, // amount in paise
    currency: currency,
    receipt: receipt,
    payment_capture: 1,
  };

  try {
    const order = await razorpay.orders.create(options);
    res.json(order);
  } catch (error) {
    console.error('Error creating Razorpay order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

router.post('/verify-payment', async (req, res) => {
  try {
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    const generated_signature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(razorpayOrderId + '|' + razorpayPaymentId)
      .digest('hex');

    if (generated_signature !== razorpaySignature) {
      return res.json({ status: 'failure' });
    }

    // ✅ Fetch payment details from Razorpay
    const payment = await razorpay.payments.fetch(razorpayPaymentId);

    const rrn = payment.acquirer_data?.rrn || payment.acquirer_data?.upi_transaction_id;

    res.json({
      success: true,
      payment_id: razorpayPaymentId,
      order_id: razorpayOrderId,
      rrn: rrn,
      method: payment.method,
      bank: payment.bank,
      created_at: payment.created_at,
    });
  } catch (err) {
    console.error("💥 Verification error:", err);
    res.status(500).json({ status: 'failure', error: err.message });
  }
});



module.exports = router; 