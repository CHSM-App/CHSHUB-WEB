 var createError = require('http-errors');
var express = require('express');
const cron = require('node-cron');

require('dotenv').config({ path: __dirname + '/.env' });
var path = require('path');
const cors = require('cors');
var cookieParser = require('cookie-parser');
const pinoHttp = require('pino-http');
const { randomUUID } = require('crypto');
const logger = require('./lib/logger');
const { initErrorTracking } = require('./lib/error-tracking');
const { securityHeaders, globalLimiter, authLimiter, otpLimiter, paymentLimiter } = require('./lib/security');
const jobs = require('./lib/jobs');
const http = require('http');

// Process-level error tracking (uncaught exceptions / unhandled rejections).
initErrorTracking();
var  insertRouter=require('./routes/insert')
var  loginRouter=require('./routes/login')
var  testRouter=require('./routes/test')
var  paymentsRouter=require('./routes/payments')
var  uploadRouter=require('./routes/uploadfile')
var indexRouter = require('./routes/deleteapi');
var usersRouter = require('./routes/users');
var notifyRouter = require('./routes/notify');
var dataRouter = require('./routes/gatekeeper');
var insertGate = require('./routes/gate_insert');
var communityRouter = require('./routes/community');
var insertCommunity = require('./routes/insert_community');
var fileAccess = require('./routes/fileAccess');
const protect = require('./routes/middleware/protect');
var webApi = require('./web');            // website (admin) API — see web/index.js
var db=require('./routes/db');
var app = express();




// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');
/*
 * The React build (vite build.outDir -> public/) is served ahead of cors on
 * purpose. Vite marks its module scripts and stylesheet `crossorigin`, so the
 * browser sends an Origin header even for same-origin asset requests; the cors
 * check below rejects any origin missing from CORS_ORIGINS, which turned every
 * /assets/* request into a 500 and left a blank page. Same-origin static files
 * need no CORS check, so they are answered before it runs.
 */
// Behind the Plesk/IIS reverse proxy there is exactly one hop; trust it so
// req.ip / X-Forwarded-* are correct (and express-rate-limit keys on the real
// client IP, not a spoofable header). Set before helmet/static/limiters.
app.set('trust proxy', 1);

// Security headers on every response, including static assets.
app.use(securityHeaders);

app.use(express.static(path.join(__dirname, 'public')));

/*
 * Was app.use(cors()), which allows every origin. Browsers may now only call
 * this API from the origins named in CORS_ORIGINS. The mobile apps are not
 * browsers and do not enforce CORS, so they are unaffected either way.
 */
const allowedOrigins = (process.env.CORS_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

app.use(cors({
  origin(origin, callback) {
    // No Origin header: same-origin, curl, or a native app. Not a browser
    // cross-origin request, so there is nothing for CORS to protect against.
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error("Origin not allowed by CORS"));
  },
  credentials: true,
}));


// Structured request logging with a request id (echoed as X-Request-Id).
// Redaction of secrets is configured in lib/logger.js. The authenticated
// identity is logged masked — never the full mobile/token.
app.use(pinoHttp({
  logger,
  genReqId: (req, res) => {
    const id = req.headers['x-request-id'] || randomUUID();
    res.setHeader('X-Request-Id', id);
    return id;
  },
  customLogLevel: (_req, res, err) =>
    (res.statusCode >= 500 || err ? 'error' : res.statusCode >= 400 ? 'warn' : 'info'),
  customProps: (req) => {
    const mob = req.user && req.user.mobile;
    return {
      authId: (req.user && (req.user.sub || req.user.userId)) || (mob ? '***' + String(mob).slice(-4) : undefined),
      tenant: req.societyId || req.villageId || undefined,
    };
  },
}));

// Abuse ceiling — after express.static so the SPA's asset requests are not counted.
app.use(globalLimiter);

// Keep the raw body so /payments/webhook can verify the Razorpay signature
// over the exact bytes Razorpay signed (a re-serialised body would not match).
app.use(express.json({ verify: (req, _res, buf) => { req.rawBody = buf; } }));
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
/*
 * Every mobile router now requires a valid token.
 *
 * deleteapi, users, uploadfile and fileAccess were mounted bare: roughly 85
 * endpoints — including fifteen DELETEs sitting at the root — served anyone
 * who could reach the host. `protect` is the floor, not the whole fix: it
 * establishes who is calling, but most of these handlers still act on any id
 * they are handed, so per-record ownership checks are still needed.
 *
 * /login stays public by necessity — it is where a token comes from — and
 * applies `auth` to the routes inside it that need it.
 */
// deleteapi is mounted at the root, so middleware placed here would run for
// every request on the server — including /login, which has to stay reachable.
// Its routes carry `protect` individually instead; see routes/deleteapi.js.
app.use('/', indexRouter);
app.use('/insert', protect, insertRouter);
app.use('/test', protect, testRouter);
// Online payments. protect is applied per-route inside (create-order, verify),
// leaving /payments/webhook public but authenticated by its Razorpay signature.
// The webhook is deliberately NOT rate-limited (Razorpay retries), only the
// resident-facing order/verify routes are.
app.use('/payments/create-order', paymentLimiter);
app.use('/payments/verify', paymentLimiter);
app.use('/payments', paymentsRouter);

// OTP endpoints get the strict per-mobile+IP limiter; the rest of /login gets
// the auth limiter.
app.use('/login/otp/request', otpLimiter);
app.use('/login/Createlogin', otpLimiter);
app.use('/login', authLimiter, loginRouter);
app.use('/users', protect, usersRouter);
app.use('/upload', protect, uploadRouter);
app.use('/data', protect, dataRouter);
app.use('/community', protect, communityRouter);
app.use('/insert/gate', protect, insertGate);
app.use('/insert/community', protect, insertCommunity);
app.use('/notify', protect, notifyRouter);
app.use('/file', protect, fileAccess);

// Website (admin) API. Self-contained: brings its own auth, validation and
// error handling, so it cannot affect the mobile routes mounted above.
app.use('/api/web/auth', authLimiter);   // brute-force protection on web login
app.use('/api/web', webApi);
app.get('/privacy-policy', (req, res) => {
  res.sendFile(path.join(__dirname, 'routes', 'privacy-policy.html'));
});
app.get('/delete-account', (req, res) => {
  res.sendFile(path.join(__dirname, 'routes', 'delete-account.html'));
});
// SPA fallback. The React build is emitted into public/ (vite build.outDir),
// so express.static above already answers "/" and the hashed assets. Anything
// the routers did not claim and that prefers HTML — a deep link like
// /dashboard reloaded in the browser — gets index.html and the client router
// resolves it. Clients that prefer JSON (the mobile app) fall through to the
// 404 below and still get a JSON error.
app.get('*', (req, res, next) => {
  if (req.accepts(['json', 'html']) !== 'html') return next();
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

/*
 * 404. The comment here has always said "catch 404 and forward to error
 * handler" with no code under it, so an unknown path fell through to
 * Express's HTML default page instead of this API's JSON.
 *
 * Registered after every route but before the error handler at the bottom.
 */
app.use((req, res, next) => {
  next(createError(404, "Not found"));
});


// The four scheduled jobs moved to lib/jobs.js so they no longer run as a
// side effect of module load, and so the /api/web/cron HTTP endpoints and the
// node-cron schedule below can share one guarded, idempotent implementation.

app.use((err, req, res, next) => {
  // 404s are routine and would otherwise fill the log with noise.
  if (!err.status || err.status >= 500) {
    (req.log || logger).error({ err, category: 'request', route: req.originalUrl, method: req.method }, 'unhandled error');
  }

  // If response already sent (like 401), do nothing
  if (res.headersSent) {
    return next(err);
  }

  // Client errors carry a safe message; anything else stays opaque so that
  // stack traces and SQL text do not reach the caller.
  const status = err.status || 500;
  const msg = status < 500 ? err.message : "Internal Server Error";
  return res.status(status).json({ msg });
});


/*
 * Scheduled work.
 *
 * NOTE: none of these run at boot any more. They used to be invoked at module
 * load, so every process start (and Plesk recycles idle processes often) fired
 * bill generation — audit finding P1-9. Scheduling is now deterministic only.
 *
 * node-cron fires these when the process happens to be up. Because Plesk
 * recycles idle apps, the AUTHORITATIVE schedule is Plesk scheduled tasks
 * hitting the token-protected /api/web/cron/* endpoints, which start the app to
 * serve the request. Both paths call the same guarded, idempotent jobs (a
 * period already billed is skipped; an in-process lock stops overlap), so
 * running both is safe. See docs/BACKEND-HARDENING.md for the exact schedule.
 */
if (process.env.ENABLE_INPROCESS_CRON !== 'false') {
  cron.schedule('0 10 * * *', () => { jobs.generateSocietyBills(); });        // society bills, 10:00
  cron.schedule('0 2 * * *',  () => { jobs.generateVillageBills(); });        // village bills, 02:00
  cron.schedule('0 10 * * *', () => { jobs.sendMaintenanceNotifications(); }); // reminders, 10:00
  cron.schedule('0 0 * * *',  () => { jobs.cleanupRefreshTokens(); });         // token cleanup, 00:00
}

const PORT = process.env.PORT || 8000;
app.listen(PORT, function () {
  logger.info({ port: PORT }, 'backend listening');
});

module.exports = app;
 