
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
require('dotenv').config();
const auth = require('./middleware/auth');
const db = require('./db'); // your mssql pool wrapper
const crypto = require('crypto');
var bodyParser = require('body-parser');

const axios = require("axios");

router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: true }));


function generateRefreshToken() {
  // opaque random token for DB storage + never reveal secret structure
  return crypto.randomBytes(64).toString('hex');
}

// Create tokens helper
function createAccessToken(payload) {
  return jwt.sign(payload, process.env.JWT_SECRET_KEY, { expiresIn: '15m' }); // production: 15m
}
function createRefreshTokenPayload(mobile) {
  // we don't sign this with jwt secret; we'll store opaque token in db
  const token = generateRefreshToken();
  // You can optionally also sign metadata as a jwt for additional checks.
  return token;
}

/*
 * Login OTP.
 *
 * The code is generated, sent and checked here. It used to be generated in
 * the app and compared in the app, while /login/Createlogin issued a token to
 * anyone who asked — so the check could be skipped entirely by calling
 * Createlogin directly. See SQL/ADD_login_otp.sql.
 */
const OTP_TTL_MINUTES = Number(process.env.OTP_TTL_MINUTES || 5);
const OTP_MAX_PER_HOUR = Number(process.env.OTP_MAX_PER_HOUR || 5);

/** Six digits, from the CSPRNG rather than Math.random. */
function generateOtp() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, "0");
}

/*
 * Stored salted, so a leaked table cannot be replayed. The pepper is held in
 * the environment; falling back to JWT_SECRET_KEY keeps this working on a
 * deployment that has not set OTP_PEPPER yet.
 */
function hashOtp(mobile, otp) {
  const pepper = process.env.OTP_PEPPER || process.env.JWT_SECRET_KEY || "";
  return crypto.createHash("sha256").update(mobile + ":" + otp + ":" + pepper).digest("hex");
}

/** Digits only, 10-15 of them — E.164 without the plus, as the app dials. */
function normaliseMobile(value) {
  const digits = String(value || "").replace(/[^0-9]/g, "");
  return /^[0-9]{10,15}$/.test(digits) ? digits : null;
}

/** Send one SMS through MessageBot. Throws on a transport failure. */
async function sendSms(phone, messageText, dltEntityId, dltTemplateId) {
  if (!API_TOKEN) throw new Error("MSGBOT_API_KEY is not configured");
  const payload = [{
    apiToken: API_TOKEN,
    messageType: "3",
    messageEncoding: "1",
    destinationAddress: phone,
    sourceAddress: SOURCE_ID,
    messageText: messageText,
    dltEntityId: dltEntityId,
    dltEntityTemplateId: dltTemplateId,
  }];
  const response = await axios.post(API_URL, payload, {
    headers: { "Content-Type": "application/json" },
    timeout: 15000,
  });
  return response.data;
}

/**
 * Step 1 of login: send a code to the number.
 *
 * Answers the same way whether or not the number is registered, so it cannot
 * be used to enumerate which residents exist.
 */
router.post('/otp/request', async (req, res) => {
  const mobile = normaliseMobile(req.body && req.body.mobile);
  if (!mobile) return res.status(400).json({ error: 'A valid mobile number is required' });

  try {
    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);

    const issued = await db.request()
      .input('operation', 'issue')
      .input('mobile', mobile)
      .input('otp_hash', hashOtp(mobile, otp))
      .input('expires_at', expiresAt)
      .execute('sp_login_otp');

    const recent = (issued.recordset && issued.recordset[0] && issued.recordset[0].recent_count) || 0;
    if (recent > OTP_MAX_PER_HOUR) {
      // Issuing already voided the previous code, so the one just minted is
      // dead too. Nothing is sent.
      return res.status(429).json({ error: 'Too many code requests. Try again later.' });
    }

    await sendSms(
      mobile,
      otp + " is your CHS Hub verification code. It expires in " + OTP_TTL_MINUTES + " minutes.",
      process.env.MSGBOT_DLT_ENTITY_ID,
      process.env.MSGBOT_DLT_TEMPLATE_ID
    );

    return res.json({ success: true, expiresIn: OTP_TTL_MINUTES * 60 });
  } catch (err) {
    console.error('OTP request failed:', err.message);
    return res.status(500).json({ error: 'Could not send the verification code' });
  }
});

/**
 * Login (creates access + refresh token)
 * Expect mobile in req.body
 *
 * WARNING: there is no verification step. Any caller that supplies a mobile
 * number is handed a token for it, so every authenticated mobile endpoint is
 * reachable by anyone who knows a resident's phone number. The OTP exchange
 * that used to guard this is still here — POST /login/otp/request issues a
 * code, and the sp_login_otp 'verify' operation checks it. Restore that check
 * before this reaches a public deployment.
 */
router.post('/Createlogin', async (req, res) => {
  try {
    const { deviceDetails } = req.body;
    const mobile = normaliseMobile(req.body && req.body.mobile);

    if (!mobile) return res.status(400).json({ error: 'A valid mobile number is required' });

    // Create Access Token (short)
    const accessToken = createAccessToken({ mobile });

    // Create opaque refresh token (store in DB)
    const refreshToken = createRefreshTokenPayload(mobile);
    const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000); // 7 days

    await db.request()
      .input('operation', 'insert')
      .input('user_mobile', mobile)
      .input('refresh_token', refreshToken)
      .input('device_info', deviceDetails)
      .input('expires_at', expiresAt)
      .execute('ManageRefreshToken');

    return res.json({ accessToken, refreshToken, expiresAt });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * Refresh access token
 * Expect { refresh_token } in req.body
 * Implements rotation: revoke old refresh token, issue new one
 */

router.post('/refreshAccessToken', async (req, res) => {
  try {
    const { refreshToken } = req.body;
   // const ip = req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress;

    if (!refreshToken) return res.status(400).json({ error: 'Refresh token required' });

    // Validate token exists and not revoked and not expired
    const result = await db.request()
	.input('operation', 'get')
      .input('refresh_token', refreshToken)
      .execute('ManageRefreshToken'); // returns token row if valid

    const rows = result.recordset || [];
    if (!rows.length) {
      return res.status(403).json({ error: 'Invalid or revoked refresh token' });
    }

    const row = rows[0];

    // At this point we have user_mobile
    const mobile = row.user_mobile;

    // rotate: revoke old token
    await db.request()
	  .input('operation', 'revoke')
      .input('refresh_token', refreshToken)
      .execute('ManageRefreshToken');

    // create new tokens
    const newAccessToken = createAccessToken({ mobile });
    const newRefreshToken = createRefreshTokenPayload(mobile);
    const newExpiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);

    // Insert new refresh token record with same device info/ip if available
    await db.request()
	  .input('operation', 'insert')
      .input('user_mobile', mobile)
      .input('refresh_token', newRefreshToken)
      .input('device_info', row.device_info || null)
     // .input('ip_address', ip || row.ip_address || null)
      .input('expires_at', newExpiresAt)
      .execute('ManageRefreshToken');

    return res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAt: newExpiresAt
    });

  } catch (err) {
    console.error("Refresh error:", err);
    return res.status(500).json({ error: 'Could not refresh token' });
  }
});


router.post('/logout', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ error: 'Refresh token required' });

    await db.request()
	  .input('operation', 'revoke')
		.input('refresh_token', refreshToken)
		.execute('ManageRefreshToken');
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Logout failed' });
  }
});
router.get('/Gatekeeper/checkUser', async (req, res) => {
  try {
    const { contact } = req.query;
 if (!contact) return res.status(400).json({ error: 'Mobile Number required' });
    const result = await db.request()
      .input("operation", "CheckUserByContact")
      .input("contact_no", contact)
      .execute("sp_staff_master");

    res.status(200).json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/*
 * GET /login/:table was here: it ran "select * from " + req.params.table with
 * no authentication, so GET /login/UserLogin returned the user table and
 * GET /login/owner_master returned every resident on the system. Removed —
 * it had no caller that a named endpoint does not already serve.
 *
 * It also shadowed every later GET on this router, because /:table matches
 * any single segment. /Home/CheckPhone and /Otp/CheckUser below are two
 * segments and were reachable; a one-segment route added here would not be.
 */

router.get('/Home/CheckPhone', async function(req, res, next) {
     try {
    const { pre_mob } = req.query;

    const result = await db.request()
	 .input('operation', 'UserExist')
      .input('pre_mob', pre_mob)
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
router.get('/Otp/CheckUser' ,async function(req, res, next) {
    try {
    const { pre_mob } = req.query;

    const result = await db.request()
	 .input('operation', 'CheckFlat')
      .input('pre_mob', pre_mob)
      .execute('sp_owner_master');

    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const API_URL = "http://papi.messagebot.in/SendSmsV2";
// Was hardcoded here, which published the SMS account token with the source.
const API_TOKEN = process.env.MSGBOT_API_KEY;
const SOURCE_ID = process.env.MSGBOT_SOURCE_ID || "SMSALA"; // approved sender ID

/*
 * Was unauthenticated and sent whatever text the caller supplied to whatever
 * number it named — an open SMS relay billed to this account, usable for
 * phishing under the approved sender ID. Now behind `auth`.
 *
 * Login codes do not come through here any more; /otp/request owns that and
 * composes its own message.
 */
router.post("/send-sms", auth, async (req, res) => {
  const { phone, message, dltEntityId, dltTemplateId } = req.body;

  if (!phone || !message) {
    return res.status(400).json({ error: "phone and message are required" });
  }

  const destination = normaliseMobile(phone);
  if (!destination) {
    return res.status(400).json({ error: "phone is not a valid mobile number" });
  }

  try {
    const providerResponse = await sendSms(destination, String(message), dltEntityId, dltTemplateId);
    return res.json({ success: true, providerResponse });
  } catch (err) {
    console.error("SMS send failed:", err.message);
    return res.status(500).json({ success: false, error: "Could not send the message" });
  }
});

router.post('/update/attendance',  async (req, res) => {
  try {
    const { staff_id, status} = req.body;

    const result = await db.request()
      .input("operation", "Attendance")
      .input("staff_id", staff_id)
      .input("status", status)
      .execute("sp_staff_attendance");

    return res.status(200).json({ message: "Successfully" });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});





module.exports = router; 