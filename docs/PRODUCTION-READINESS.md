# Production readiness — backend and frontend

Assessed 2026-08-19 against `main` @ `f0e7b81`.

**Verdict: not production ready** — but the seven P0 ship-stoppers are fixed
as of 2026-08-19 (see below). What remains is P1/P2 plus three manual steps:
rotate the exposed credentials, purge git history, and run the OTP migration.

**Original assessment follows.**

**Verdict as first assessed: not production ready.** The blockers are concentrated almost
entirely in `backend/routes/` (the legacy mobile API). `backend/web/` (the
website API) and `frontend/` are in good shape and close to ready.

Anyone with the public API hostname could read and delete other societies' data
without an account. That was the state before the P0 work below.

## What is already solid

- **`backend/web/`** — parameterised stored-procedure calls throughout, tenant
  scoping taken from the token and never from client input
  ([authenticate.js:59-77](../backend/web/middleware/authenticate.js#L59-L77)),
  refresh-token rotation, a real error envelope, a `/health` probe.
- **`frontend/`** — builds clean, no `console.log`, error boundaries,
  env-driven config, 39 test files, MSW-mocked API tests, feature flags
  guarding the money-moving flows.

Neither of these is the problem. The rest of this document is.

---

## P0 — ship-stoppers · FIXED 2026-08-19

All seven are closed in the working tree. Verified by booting the app and
calling each previously-open endpoint anonymously — 13/13 now refuse. Three
deployment steps below are **not** code and still have to be done by hand.

### 1. Secrets in git — code fixed, rotation still outstanding

- `routes/db.js` reads `DB_USER`/`DB_PASSWORD`/`DB_SERVER`/`DB_NAME`/`DB_PORT`
  from the environment and throws at boot naming any that is missing.
- `trustServerCertificate` now defaults to **off** (`DB_TRUST_SERVER_CERT`), so
  the database connection verifies the server certificate.
- The Firebase key is loaded by the new [routes/firebase.js](../backend/routes/firebase.js)
  from `FIREBASE_SERVICE_ACCOUNT` (raw or base64) or `FIREBASE_SERVICE_ACCOUNT_PATH`.
  `app.js`, `routes/notify.js`, `routes/gate_insert.js` and `web/lib/notify.js`
  all go through it, and `initializeApp` happens exactly once.
- The MessageBot API token, hardcoded in `login.js`, is now `MSGBOT_API_KEY`.
- Both `serviceAccountKey.json` files and `.env.bak.20260812` are untracked and
  `.gitignore`d. Every variable is documented in [backend/.env.example](../backend/.env.example).

**Still to do by hand — the code change does not undo the exposure:**
1. **Rotate every credential.** SQL password, `JWT_SECRET_KEY` (signs everyone
   out), `REFRESH_KEY`, Razorpay key + secret, MessageBot key, and a fresh
   Firebase key from the console.
2. **Purge git history** (`git filter-repo`). The files are untracked from here
   on, but every earlier commit still contains them — including on the pushed
   `backend` branch.
3. The old `.env.bak.20260812` and key files are still **on disk**, only
   untracked. Delete them once the new values are in `backend/.env`.

### 2. Login without verification — FIXED

`POST /login/Createlogin` now requires an OTP it can verify:

- `POST /login/otp/request` generates a six-digit code from the CSPRNG, stores
  only a salted SHA-256 of it, and sends it by SMS. Answers identically for
  known and unknown numbers, so it cannot enumerate residents. Rate limited to
  `OTP_MAX_PER_HOUR` per number.
- `POST /login/Createlogin` verifies the code before minting anything. Codes
  expire (`OTP_TTL_MINUTES`, default 5), verify exactly once, void when a new
  one is requested, and lock after five wrong attempts.

Storage is [SQL/ADD_login_otp.sql](../SQL/ADD_login_otp.sql) — **run this
migration before deploying**, or every login fails.

**This is a breaking change for both apps.** They must call `/login/otp/request`
and pass `otp` to `Createlogin`. Today they generate the code in the app and
compare it there, which is exactly why the server could be bypassed.

### 3. `GET /login/:table` — REMOVED

Deleted. It also shadowed every single-segment GET on that router.

### 4. Unauthenticated endpoints — FIXED

`protect` now applies to `/users`, `/upload`, `/file` and every route in
`deleteapi.js`. The deleteapi routes take it individually rather than at the
mount, because that router sits at `/` and mount-level middleware there would
have run for every request on the server — including `/login`.

Both Flutter apps already attach `Authorization: Bearer` through a Dio
interceptor on every request, multipart uploads included, so these mounts do
not break them.

**Still open:** authentication is not authorisation. These handlers still act on
whatever id they are given, so resident A can still address resident B's
records. Per-record ownership belongs in the stored procedures.

### 5. SQL injection — FIXED, all 29 sites

Every one now binds parameters, across `deleteapi.js`, `insert_community.js`,
`notify.js`, `gatekeeper.js`, `users.js` and `uploadfile.js`. A sweep for
request input concatenated into SQL returns nothing.

Four statements were also malformed and had never worked — they are fixed in
passing, so these routes now function for the first time:
- `DELETE /DeletePanicAlert` — `where owner_id= AND contact=`, with a stray comma
- `POST /insert/community/staff` — `@contact_no'` with no `=`
- `DELETE /DeleteHelpdeskRequest` — missing comma, and it ignored `err` and
  reported failures to the app as successful deletes
- `GET /notify/Admin/Society/GetAllToken` — unbracketed `and`/`or` meant the
  society filter applied to only one branch, returning other societies' tokens

### 6. `/file` — FIXED

The `GET /file/*` handler that served this backend's own source directory
(`/file/db.js`, `/file/serviceAccountKey.json`) is deleted. `fileshow/:owner_id`
requires a token and matches the owner row against the caller's own mobile
number, answering 404 identically for "no such owner" and "not yours".

### 7. Uploads — FIXED

Behind `protect`, with a 10 MB per-file cap (`UPLOAD_MAX_BYTES`), 10 files per
request, and an allowlist on both MIME type and extension. Stored filenames are
now `timestamp-random.ext` — the old name was `Date.now() + originalname`, so a
client-supplied `../../routes/db.js` chose where the file landed.

The same traversal existed in eight file-*serving* handlers here: route params
arrive URL-decoded, so `/upload/ProfilePhoto/1/..%2f..%2fdb.js` returned source.
All of them now go through one helper that passes a `root` to `res.sendFile`,
which is what makes Express enforce containment.

---

## P1 — must fix before real traffic

- ~~CORS is open to every origin.~~ **FIXED** — origins now come from
  `CORS_ORIGINS`; requests with no Origin header (native apps, curl) still pass,
  since CORS only governs browsers.
- **No rate limiting anywhere.** Add `express-rate-limit`, tightest on auth and
  payments. Partially mitigated: OTP requests are capped per number per hour and
  a code locks after five wrong attempts, but that is specific to login, not a
  general limit.
- **No security headers.** Add `helmet`.
- **iisnode leaks stack traces in production.**
  [web.config](../backend/web.config) has `devErrorsEnabled="true"` and
  `debuggingEnabled="true"`. Both must be `false`.
- ~~TLS to SQL Server is unverified.~~ **FIXED in code** — verification is now
  the default (`DB_TRUST_SERVER_CERT`). The server still needs a real
  certificate; until it has one, that variable must be set to `true` and the
  connection stays interceptable.
- **Four cron jobs fire on every process start.**
  [app.js:210-213](../backend/app.js#L210-L213) runs bill generation and the
  notification sweep at boot; under iisnode worker recycling that is
  unpredictable. The procs are idempotent, which is why this has not caused
  visible damage, but bill generation should not be triggered by a restart.
  Move to the existing `/api/web/cron` endpoints driven by a Plesk task.
- **Duplicate cron schedule.** `0 10 * * *` is registered twice
  ([app.js:216](../backend/app.js#L216) and [app.js:243](../backend/app.js#L243)).
- ~~No 404 handler.~~ **FIXED** — unknown paths return JSON 404, and the error
  handler no longer flattens client errors into 500s or logs them as unhandled.
- **The frontend test suite is red.** 5 of 389 tests fail — the whole of
  `VillagePaymentsPage.test.jsx`. Cause: `PAYMENTS_ENABLED` is false in the test
  environment, so the pay button is `disabled`
  ([VillagePages.jsx:810](../frontend/src/pages/village/VillagePages.jsx#L810))
  and the dialog never opens. Set `VITE_ENABLE_VILLAGE_PAYMENTS=true` for tests.
  Until then the payment flow is unverified.
- **Three financial flows are switched off and never validated.** Bill
  generation, receipt entry and village payments are all flag-disabled per
  `frontend/.env.example`, which states none has been run against a test
  database. A society management system that cannot raise a bill or record a
  receipt is not functionally ready. Validate each against a test DB, then
  enable.

---

## P2 — should fix

- **Dependencies.** `express ~4.16.1` (2018), `pug 2.0.0-beta11` (a beta),
  `multer 1.4.5-lts.1` (2.x is current), and `body-parser 2.x` paired with
  Express 4 — that pairing is unsupported. Run `npm audit` on the backend; it
  has never been done.
- **`xlsx` has an unpatched high-severity advisory** (prototype pollution +
  ReDoS, no fix available). Consider `exceljs`, or confine it to
  trusted-input-only paths.
- **Password hashing is PBKDF2-HMAC-SHA1, 10k iterations**
  ([web/lib/password.js](../backend/web/lib/password.js)). Weak by current
  standards. The constraint is the legacy .NET data and rehash-on-login is
  already the documented path — finish that migration.
- **Access tokens live in `localStorage`**
  ([client.js:12-24](../frontend/src/api/client.js#L12-L24)), readable by any
  XSS. httpOnly cookies are stronger; at minimum keep the 15-minute TTL and add
  a CSP.
- **`bin/www` is dead code and would crash.** Deployment runs `app.js` directly
  via iisnode, but `app.js` calls `app.listen` at
  [line 230](../backend/app.js#L230) *and* `bin/www` listens again at
  [line 28](../backend/bin/www#L28). `npm start` — the only script in
  `package.json` — therefore binds the port twice and exits with `EADDRINUSE`.
  Delete `bin/www`, or remove the `app.listen` from `app.js`.
- **No backend tests at all.** 14,686 lines, zero tests.
- **No structured logging.** `morgan('dev')` plus `console.log`/`console.error`.
  No request ids, no log aggregation, no error tracking.
- **Hardcoded absolute Windows paths**, e.g.
  `C:/Inetpub/vhosts/vengurlatech.com/...` at
  [uploadfile.js:59](../backend/routes/uploadfile.js#L59).
- **Hardcoded environment URLs**, e.g. `https://app.chshub.co.in/upload/...`
  written into database rows across `uploadfile.js`. Moving domain would
  require a data migration.
- **Duplicate route definitions.** `/OwnerDocuments` is declared twice in
  `uploadfile.js` ([:19](../backend/routes/uploadfile.js#L19) and
  [:73](../backend/routes/uploadfile.js#L73)); the second is unreachable.
- **Frontend bundle is heavy** — ~2.9 MB raw, ~840 KB gzipped, with
  `chart-vendor` at 848 KB and `pdf-vendor` at 751 KB. Lazy-load both; they are
  not needed on first paint.

---

## Suggested order

1. **Contain** (day one): rotate every secret in P0-1; take `/file` and
   `/login/:table` offline immediately.
2. **Close the front door**: P0-2 (real login), P0-4 (`protect` on every mount).
3. **Fix the injections and uploads**: P0-5, P0-6, P0-7.
4. **Harden**: all of P1 — CORS, rate limiting, helmet, web.config, DB TLS, cron.
5. **Prove the money paths work**: green test suite, then validate and enable
   the three financial flags.
6. **Then** P2.

Steps 1-3 are the difference between "insecure" and "actively exploitable".
Nothing should be publicly advertised until they are done.
