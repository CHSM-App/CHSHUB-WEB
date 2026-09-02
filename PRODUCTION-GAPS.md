# Production readiness — full audit

Assessed **2026-09-01** against `main` @ `a2c6ef62`, working tree clean.
Scope: `backend/`, `frontend/`, `CHSHUB_APP/`, `security_app/`, `Secretary_app/`.
`Society_dotNet/` excluded, except where its files sit in shared git history.

**Verdict: not production ready.**

This supersedes the status claims in [docs/PRODUCTION-READINESS.md](docs/PRODUCTION-READINESS.md).
That document's code fixes are real and verified — CORS, uploads, SQL injection, `/file`,
`web.config`, `bin/www` are genuinely closed. What it recorded as "still to do by hand" was never
done, and five further blockers it did not cover are below.

Everything here was verified by running the code, not by reading it. Commands and outputs are named
per finding.

---

## Summary

| # | Blocker | Area | Severity |
|---|---|---|---|
| 1 | Every credential unrotated and still readable in git history | backend | **P0** |
| 2 | Both mobile apps cannot log in; OTP is faked client-side | apps | **P0** |
| 3 | Payment amount is client-supplied and never bound to the receipt | backend | **P0** |
| 4 | Any valid token reads and writes any resident's data (IDOR) | backend | **P0** |
| 5 | All three apps release-sign with the debug keystore | apps | **P0** |
| 6 | No rate limiting, no security headers | backend | P1 |
| 7 | `user_type_id` is issued but never enforced — no roles | backend + web | P1 |
| 8 | 37 npm advisories on the backend, 4 critical | backend | P1 |
| 9 | Bill generation fires on every process start | backend | P1 |
| 10 | 5 failing frontend tests; 3 financial flows flag-disabled and unvalidated | frontend | P1 |
| 11 | Resident-app CI is red; three components have no CI; deploys are ungated | CI | P1 |
| 12 | Zero backend tests across 14,700 lines | backend | P1 |
| 13 | No structured logging, error tracking, or alerting | all | P1 |

P2 items follow the P1 section.

---

# P0 — must be fixed before this is reachable from the internet

## 1. Every credential is unrotated and still readable in git history

`docs/PRODUCTION-READINESS.md` moved the secrets out of source into `backend/.env` and told the
operator to rotate them. **The rotation never happened.** The values in the live `.env` are
byte-identical to values that are still in the repository's history today.

Verified by extracting each key from the historical `backend/.env.bak.20260812` and from the
original hardcoded `backend/routes/db.js`, and comparing against the current `backend/.env`:

| Secret | Status |
|---|---|
| `DB_PASSWORD` | **identical** to the value hardcoded in the first commit of `routes/db.js` |
| `JWT_SECRET_KEY` | **identical** to the leaked value |
| `REFRESH_KEY` | **identical** to the leaked value |
| `RAZORPAY_KEY_SECRET` | **identical** to the leaked value |
| `MSGBOT_API_KEY` | **identical** to the leaked value |
| Firebase service account | rotated — the on-disk key differs from the one in history |

The history still contains, across 8 commits: `backend/.env.bak.20260812`,
`backend/serviceAccountKey.json`, `backend/routes/serviceAccountKey.json`,
`Society2024/App_Data/serviceAccountKey.json`, and
`society2024DotNet/Society2024/App_Data/serviceAccountKey.json`. The database host
(`winsome.grabweb.in`) and user (`chsadmin`) are in there too.

Left on disk, untracked but present: `backend/serviceAccountKey.json`,
`backend/routes/serviceAccountKey.json`, `backend/.env.backup-before-localdev`.

**Why this outranks everything else:** `JWT_SECRET_KEY` signs both APIs.
[`backend/web/lib/tokens.js:16`](backend/web/lib/tokens.js#L16) signs website access tokens with the
same key `routes/middleware/auth.js` verifies mobile tokens with. Anyone who reads the history can
mint a token with `scope: 'web'` and any `society_id` they choose, and the tenant guards in
[`authenticate.js`](backend/web/middleware/authenticate.js) will honour it — those guards trust the
token precisely because the token was assumed unforgeable. Every other access control in this system
is downstream of that key.

### Fix

1. Rotate all five: new SQL password, new `JWT_SECRET_KEY` (signs everyone out — expected), new
   `REFRESH_KEY`, new Razorpay key pair from the dashboard, new MessageBot key.
2. Purge the history with `git filter-repo --path backend/.env.bak.20260812 --path-glob
   '**/serviceAccountKey.json' --invert-paths`, then force-push `main` and every generated branch.
   Ask GitHub Support to expire cached views of the old objects.
3. Delete the three leftover files from disk.
4. Move `backend/.env` to the Plesk environment-variable panel so the file stops existing.
5. Revoke any Razorpay payments or SMS sends that look unfamiliar — assume the keys were used.

---

## 2. Both mobile apps cannot log in, and their OTP is theatre

The backend now demands a verifiable OTP:
[`login.js:139`](backend/routes/login.js#L139) rejects `POST /login/Createlogin` with
`400 Verification code required` unless `otp` is in the body.

Neither app sends one. The request body is `TokenResponse`
([`CHSHUB_APP/lib/domain/models/token_response.dart`](CHSHUB_APP/lib/domain/models/token_response.dart)),
whose fields are `accessToken`, `refreshToken`, `mobile`, `deviceDetails` — **there is no `otp`
field**. Neither app calls `POST /login/otp/request` anywhere; a grep for it across both `lib/`
trees returns nothing.

**Resident and security app login is broken against the deployed backend right now.**

What the apps do instead:

- **Resident** — [`otp_verification.dart:96`](CHSHUB_APP/lib/SocietyApp/screens/otp_verification.dart#L96):
  ```dart
  if (otp != "123456") {
    _showErrorSnackBar("Enter Valid OTP");
  ```
  A hardcoded code, compared on the device.
- **Security** — [`otp_screen.dart:554-562`](security_app/lib/screens/otp_screen.dart#L554-L562):
  ```dart
  // Simulate OTP verification
  await Future.delayed(const Duration(seconds: 2));
  ...
  // For demo, accept any 6-digit OTP
  if (otp.length == 6) {
  ```
  No code is ever requested or checked. "Resend OTP" is a `Future.delayed` and a snackbar.

So the choice today is: the apps stay broken, or the backend check is weakened and any phone number
plus `123456` — or any six digits — logs in as that resident or guard.

### Fix

1. Add `otp` to `TokenResponse` (or a dedicated `LoginRequest`) in both apps and regenerate the
   `json_serializable` / retrofit output.
2. Add `@POST("login/otp/request")` to both `api_service.dart` files; call it from the login screen
   before navigating to the OTP screen.
3. Delete the `123456` comparison and the "accept any 6-digit OTP" branch. Verification happens on
   the server; the screen only forwards the code and renders the error the server returns.
4. Wire "Resend" to `/login/otp/request` and surface the `429` when
   `OTP_MAX_PER_HOUR` is hit.
5. Confirm [`SQL/ADD_login_otp.sql`](SQL/ADD_login_otp.sql) has been applied to the production
   database. If it has not, `sp_login_otp` does not exist and every login 500s.
6. Ship both app updates **before** anyone is told to install them.

---

## 3. Payment amount is client-supplied, and verification is never written down

[`backend/routes/test.js:17-33`](backend/routes/test.js#L17-L33):

```js
router.post('/create-order', async (req, res) => {
  const { amount, currency, receipt } = req.body;
  const options = { amount: amount, ... };
  const order = await razorpay.orders.create(options);
```

The amount is taken from the request body and never checked against what the flat actually owes.

[`/test/verify-payment`](backend/routes/test.js#L36) does verify the HMAC signature correctly — but
it only returns JSON. **It writes nothing to the database.** The receipt is recorded by a separate,
unrelated call to `POST /insert/AddReceipt`, which takes `paid_amount` from its own request body and
has no reference to a Razorpay payment id.

The two are never joined. A resident can:

- create an order for ₹1 against a ₹5,000 bill, pay it, and get a valid signature; or
- skip Razorpay entirely and `POST /insert/AddReceipt` with any `paid_amount` they like.

Both settle the bill. There is no reconciliation anywhere that would catch it.

Also: the payment routes live in a file called `test.js`, and it calls
`dotenv.config({ path: __dirname + '/.env' })` — that resolves to `backend/routes/.env`, which does
not exist. It works only because `app.js` already loaded the real `.env` first.

### Fix

1. `create-order` must compute the amount server-side from the outstanding bill
   (`sp_new_maintenance` `TotalDue`) for the caller's own flat. Never read `amount` from the body.
2. `verify-payment` must, inside one transaction: re-fetch the payment from Razorpay, check
   `payment.amount` equals the order amount, then write the receipt itself — storing
   `razorpay_payment_id` on the receipt row with a unique constraint so a signature cannot be
   replayed.
3. Close `/insert/AddReceipt` to app clients, or require it to carry a verified payment id.
4. Add the Razorpay **webhook** as the authoritative source; the client callback is a hint, not proof.
5. Move these routes out of `test.js` into `routes/payments.js` and fix the `dotenv` path.
6. Reconcile existing receipts against the Razorpay dashboard before going live.

---

## 4. Any valid token reads and writes any resident's data

`protect` establishes *who* is calling. Nothing checks *what they may touch*. The handlers act on
whatever id is in the URL. [docs/PRODUCTION-READINESS.md](docs/PRODUCTION-READINESS.md) flagged this
as "still open" under P0-4; it is still open, and it is not a lesser issue than the ones marked
fixed.

Representative cases:

- [`users.js:248`](backend/routes/users.js#L248) — `GET /users/Home/TotalDue/:flat_id` passes
  `flat_id` straight to the SP. Any resident reads any flat's dues, in any society.
- [`notify.js:191-201`](backend/routes/notify.js#L191-L201) — `POST /notify/OwnerApp/Insert/NewToken`
  sets `owner_master.token` for the `owner_id` in the query string. **Any authenticated caller can
  point another resident's push notifications at their own device** — visitor approvals, panic
  alerts, gate passes.
- The same shape repeats across `/users/FamilyMembers/:flat_id`, `/users/VehicleList/...`,
  `/users/OwnerDocumentsList/:flat_id`, and the fifteen DELETEs in `deleteapi.js`.

With finding 1 unfixed, "any valid token" includes tokens an attacker forges themselves.

### Fix

The lazy fix is the correct one: put the ownership check where all callers already route through —
the stored procedures. Each SP that takes a `flat_id` / `owner_id` should also take the caller's
`pre_mob` (already in the JWT as `mobile`) and return an empty set when the record is not theirs.
That is one `WHERE` clause per SP, versus a guard in ~85 handlers.

Order of work: money and identity first (`TotalDue`, `DueHistory`, `AddReceipt`, all token-setting
routes, all DELETEs), then the read-only lists.

---

## 5. All three apps release-sign with the debug keystore

| App | `applicationId` | Release signing |
|---|---|---|
| `CHSHUB_APP` | `com.example.society_app` | `signingConfigs.getByName("debug")` |
| `security_app` | `com.example.security_app` | `signingConfigs.getByName("debug")` |
| `Secretary_app` | `co.in.chshub.secretary_app` | `signingConfigs.getByName("debug")` |

Both problems are hard stops:

- **Google Play rejects any package under `com.example.*`.** Two of the three apps cannot be
  uploaded at all, and the id cannot be changed after the first release — so this must be fixed now,
  not later.
- **Debug-signed builds cannot be published**, and the debug keystore is shared across every Flutter
  install on the machine, so the signing identity is not yours.

`manual-build.yml` and `resident-app.yml` both run `flutter build appbundle --release`, so the
artifacts they produce today are unshippable.

### Fix

1. Rename to `co.in.chshub.resident` and `co.in.chshub.security` (matching Secretary's convention),
   update `namespace`, the Kotlin package path, and regenerate `google-services.json` from Firebase
   for the new ids.
2. Generate one upload keystore per app, store it as a base64 GitHub secret, and add a real
   `signingConfigs.release` reading from `key.properties`. Never commit the keystore.
3. Set `minifyEnabled`/`shrinkResources` on release, with a ProGuard keep rule for the Retrofit and
   `json_serializable` models.
4. Bump `security_app` and `Secretary_app` off `0.1.0`, and set `Secretary_app`'s
   `android:label` to a real name — it currently ships as `secretary_app`.

---

# P1 — must be fixed before real traffic

## 6. No rate limiting, no security headers

`express-rate-limit` and `helmet` are absent from
[`backend/package.json`](backend/package.json). The only limiter anywhere is the per-number OTP cap
in `login.js`, which does not cover `/api/web/auth/login`, `/test/create-order`, or the ~221 mobile
endpoints.

**Fix:** `helmet()` before the routers; `express-rate-limit` globally at a loose ceiling and tightly
on `/login/*`, `/api/web/auth/*`, and the payment routes. `app.set('trust proxy', true)` is already
set, so `req.ip` is correct behind IIS.

## 7. `user_type_id` is issued but never enforced — the admin surface has no roles

The claim is minted into every website token
([`tokens.js:36`](backend/web/lib/tokens.js#L36)) and read back in
[`authenticate.js:29`](backend/web/middleware/authenticate.js#L29). It is then used in exactly one
place — [`community/index.js:942`](backend/web/routes/community/index.js#L942) — to label a notice
author. It gates nothing.

Every signed-in website or Secretary-app user therefore has the complete admin surface: delete
flats, edit maintenance charges, generate bills, record receipts, approve vendor bills. For a
product whose whole premise is different user roles, a committee member and the chairman are
currently the same account.

`RequireTenant` in [`App.jsx`](frontend/src/App.jsx) separates *society from village*. It does not
separate *people within a society*.

**Fix:** add a `requireUserType([...])` middleware next to `requireSociety`, apply it to the
destructive and financial routers, and hide the corresponding sidebar groups in `AppLayout.jsx`.
Decide the matrix first — at minimum Chairman/Secretary (full), Treasurer (billing + accounts),
Member (read + community).

## 8. 37 npm advisories on the backend, 4 critical

`npm audit` in `backend/` (never run before, per the previous doc):

```
37 vulnerabilities (8 low, 15 moderate, 10 high, 4 critical)
```

Critical: `websocket-driver` (resource-limit bypass, message corruption) — `npm audit fix` resolves
it. The `firebase-admin` → `@google-cloud/firestore` → `google-gax` chain carries vulnerable `uuid`
and `retry-request` and needs a major bump.

Frontend is much better — 2 high: `nanoid` (fixable) and `xlsx` (prototype pollution + ReDoS, **no
fix available**). `xlsx` is dynamically imported and only reachable from the Excel Import modal
([`ExcelImport.jsx:184`](frontend/src/pages/settings/ExcelImport.jsx#L184)), so exposure is limited
to files an admin chooses to open — but that is still parsing untrusted input.

The stale dependencies the previous doc listed are unchanged: `express ~4.16.1` (2018),
`pug 2.0.0-beta11`, `multer 1.4.5-lts.1`, and `body-parser 2.x` paired with Express 4 — an
unsupported combination.

**Fix:** `npm audit fix` in both; upgrade `firebase-admin` and `multer` to current majors; drop
`pug` and `body-parser` (Express 4.16+ has `express.json`/`express.urlencoded` built in, and both
are already used in `app.js` — `body-parser` is only still imported by `login.js` and `test.js`).
Replace `xlsx` with `exceljs`.

## 9. Bill generation fires on every process start

[`app.js`](backend/app.js) calls `sendMaintenancePaymentNotifications()`, `cleanupRefreshTokens()`,
`GenerateBill()` and `GenerateVillageBill()` at module scope, before the cron registrations. Under
iisnode, an idle app is recycled and a request restarts it — so bill generation runs at
unpredictable times, and the FCM reminder sweep can push a "payment pending" notification to every
resident on a restart.

The procedures are idempotent for *billing*, which is why no duplicate bills have appeared. The
notification sweep is not idempotent in any way a resident would recognise.

**Fix:** delete the four boot-time calls. `/api/web/cron` already exists with a shared-secret guard;
drive all four from a Plesk scheduled task, which is also the only thing that works when the Node
process is asleep at 02:00.

## 10. Five failing frontend tests, a flaky suite, and three unvalidated money paths

`npx vitest run`, three consecutive runs:

| Run | Result | Wall clock |
|---|---|---|
| 1 | 7 failed / 389, **2** files | 327 s |
| 2 | 5 failed / 389, 1 file | — |
| 3 | 5 failed / 389, 1 file | 79 s |

Five failures are deterministic, all in
[`VillagePaymentsPage.test.jsx`](frontend/src/pages/village/VillagePaymentsPage.test.jsx): the pay
button is disabled because `VITE_ENABLE_VILLAGE_PAYMENTS` is unset in the test env
([`VillagePages.jsx:838`](frontend/src/pages/village/VillagePages.jsx#L838)), so
`findByRole('dialog')` times out.

The two extra failures in run 1 appeared only on the slow cold run and vanished on the warm ones —
a timing-sensitive suite that will fail intermittently in CI.

Separately, all three financial write flows are still flag-disabled and, per
[`frontend/.env.example`](frontend/.env.example), have never been run against a test database:

- `VITE_ENABLE_BILL_GENERATION=false`
- `VITE_ENABLE_RECEIPT_ENTRY=false`
- `VITE_ENABLE_VILLAGE_PAYMENTS=false`

A society management system that cannot raise a bill or record a receipt is not functionally ready,
regardless of its security posture.

**Fix:** set the three flags in the vitest env so the tests exercise the real path; raise
`testTimeout` or replace the `findBy*` races with explicit waits; then run each of the three flows
end-to-end against a restored copy of production and turn the flags on.

## 11. CI is red where it exists, absent where it does not, and gates nothing

- **Resident app** — [`resident-app.yml`](.github/workflows/resident-app.yml) runs `flutter analyze`
  then `flutter test`. `flutter analyze` exits **1** (539 issues, including `override_on_non_overriding_member`
  warnings, which are fatal by default), so the workflow has been failing at that step and **no
  build artifact has been produced**. Its only test is the untouched `Counter increments smoke test`
  from the Flutter template, and it fails.
- **security_app** — 166 analyzer issues, 0 test files, no CI workflow at all.
- **Secretary_app** — clean (1 info), 20 test files, but no per-push CI. It also has eight committed
  golden **failure** artifacts in `test/failures/` (`receipt-desktop_*`, `receipt-phone_*`), which
  means the golden tests were failing when they were last run and the diffs were committed.
- **frontend / backend** — no workflow runs their tests. Ever.
- **Deploys are ungated.** [`split-branches.yml`](.github/workflows/split-branches.yml) fires on
  every push to `main` and force-pushes each component branch, and `sync-backend` builds the
  frontend and publishes the whole backend (including `node_modules`, with the 4 critical
  advisories) to the `backend` branch. There is no test step in front of any of it.

**Fix:** clear the resident-app warnings (or `--no-fatal-warnings` as an explicit, temporary
decision); delete the template counter test; add `flutter analyze`/`test` workflows for the other
two apps; add a `frontend` workflow running `npm ci && npm run build && npx vitest run`; and make
`split-branches` depend on those jobs so a red suite cannot deploy.

## 12. Zero backend tests

14,700 lines across `routes/` and `web/`, no test file of any kind. The billing SPs, the OTP flow,
the tenant guards, and the payment verification all ship unverified.

**Fix:** not a full suite. Start with the paths where a bug costs money or leaks data — `web/lib/tokens.js`,
`web/lib/password.js`, `middleware/authenticate.js` (tenant mismatch → 403), the OTP verify branch,
and payment verification. Supertest against a stubbed `db` module; no new framework beyond `node:test`.

## 13. No structured logging, error tracking, or alerting

`morgan('dev')` plus scattered `console.log`/`console.error`. No request ids, no aggregation, no
error tracker, no uptime check on `/api/web/health` (which exists and is unused). When the payment
flow or a cron bill run fails in production, nobody finds out.

**Fix:** `pino` with a request id, an error tracker (Sentry's free tier), and an uptime monitor
pointed at `/api/web/health`. One alert on the cron jobs failing is worth more than the rest.

---

# P2 — should fix

- **`MANAGE_EXTERNAL_STORAGE`** is requested in
  [`CHSHUB_APP/android/app/src/main/AndroidManifest.xml`](CHSHUB_APP/android/app/src/main/AndroidManifest.xml).
  Google Play requires a written justification and rejects it for apps that only need document and
  photo access. Drop it — `READ_MEDIA_*` plus the storage access framework covers the real use.
- **Password hashing is PBKDF2-HMAC-SHA1, 10k iterations**
  ([`web/lib/password.js`](backend/web/lib/password.js)) — weak by current standards, constrained by
  the legacy .NET data. `bcryptjs` is already a backend dependency; finish the rehash-on-login
  migration that is already documented there.
- **Website tokens live in `localStorage`** ([`client.js:12-24`](frontend/src/api/client.js#L12-L24)),
  readable by any XSS. Keep the 15-minute TTL and add a CSP header; httpOnly cookies are the real fix.
- **Hardcoded Windows path default** — `uploadfile.js:24` defaults to
  `C:/Inetpub/vhosts/vengurlatech.com/chsmanagement/publish/Documents`. It is env-overridable now
  (`PUBLIC_UPLOAD_BASE`, `FILE_HOST`), but the default should fail loudly rather than point at one
  specific server.
- **Absolute URLs written into database rows** — `uploadfile.js` stores
  `https://chshub.co.in/upload/...` into `doc_path`, `image_path`, `profile_image`. Changing domain
  or CDN requires a data migration. Store the relative path; build the URL at read time.
- **Duplicate route definitions** — `/OwnerDocuments` is declared twice in `uploadfile.js`
  ([:19](backend/routes/uploadfile.js#L19), [:73](backend/routes/uploadfile.js#L73)); the second is
  unreachable. Several `/AddVisitor/*` and `/AddReceipt` paths are likewise doubled (one commented
  block, one live) across `insert.js`.
- **Commented-out dead code** — `insert.js:967-1014` is a superseded `AddReceipt`. Delete it; git has it.
- **Timing-unsafe signature compare** — `test.js:45` uses `!==` on the Razorpay HMAC. Use
  `crypto.timingSafeEqual`. Low practical risk, one-line fix.
- **Committed test failure artifacts** — delete `Secretary_app/test/failures/` and add it to
  `.gitignore`; regenerate the goldens.
- **539 analyzer issues in the resident app** — mostly naming and `withOpacity` deprecations, but
  four `override_on_non_overriding_member` warnings and an unused-variable warning in
  `visitor_viewModel.dart:391` point at real dead code.
- **Bundle size is fine, contrary to the old doc.** `npm run build` produces a 548 kB app chunk +
  228 kB react + 74 kB vendor on first paint (~216 kB gzipped total). `chart-vendor` (848 kB),
  `pdf-vendor` (751 kB) and `xlsx-vendor` (424 kB) are all genuinely lazy — `lazy(() => import(...))`
  in `DashboardPage.jsx:9`, `lib/pdf.js:14`, `ExcelImport.jsx:184`. No action needed.

---

## Suggested order

1. **Contain, today.** Rotate all five credentials (finding 1). Nothing else matters until the JWT
   signing key is private — every guard in the system assumes it.
2. **Purge history** and delete the on-disk leftovers.
3. **Fix the money path** (finding 3) — server-side amounts, verification writes the receipt,
   webhook as source of truth. Reconcile what already exists.
4. **Close the IDOR** (finding 4), money and identity routes first.
5. **Ship working apps** (findings 2 and 5) — real OTP, real signing config, real application ids.
   These are a coordinated backend + app release; plan it as one.
6. **Harden** (6, 8, 9) — helmet, rate limiting, `npm audit fix`, move cron off boot.
7. **Prove the money paths work** (10) — green suite, then validate and enable the three flags.
8. **Make the pipeline mean something** (11, 12) — tests in CI, CI gating deploys.
9. **Add roles** (7) before onboarding a society with more than one committee login.
10. Then P2.

Steps 1–5 are the difference between "hardened but broken" and "shippable". The apps in their
current state cannot log in and cannot be published; the backend in its current state can be
authenticated as anyone by anyone who reads the git log.
