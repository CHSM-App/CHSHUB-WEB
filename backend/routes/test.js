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

/*
 * The payment routes that used to live here were insecure: /create-order took
 * the amount from the client, and /verify-payment string-compared the signature
 * and bound the payment to no bill. They have MOVED to routes/payments.js, which
 * prices the order server-side, verifies in constant time, and binds the payment
 * to a receipt transactionally. These stubs stay so an old client build gets a
 * clear error instead of a silent security hole.
 */
router.post('/create-order', (_req, res) =>
  res.status(410).json({ error: 'Moved to POST /payments/create-order' }));

router.post('/verify-payment', (_req, res) =>
  res.status(410).json({ error: 'Moved to POST /payments/verify' }));

module.exports = router; 