# Backend production hardening

Covers audit P1s: security headers/rate limiting (#6), npm advisories (#8),
boot-time bill generation (#9), structured logging & error tracking (#13).
Architecture unchanged — Express 4 / mssql / stored procedures.

## Security middleware & headers (Steps 1–2)

`lib/security.js`, wired in `app.js`:

- **helmet** on every response — `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: no-referrer`, frameguard, HSTS (effective over HTTPS).
- **CSP is intentionally OFF.** helmet's default CSP blocks the React admin
  build served from `public/` (inline styles / module scripts), blanking the
  app. Add a tuned CSP only after testing against the real frontend.
- **express-rate-limit**, tiered (per client IP; `trust proxy` set to `1` for the
  single Plesk/IIS reverse-proxy hop so the real client IP is used):

  | Scope | Window | Max | Notes |
  |---|---|---|---|
  | Global | 15 min | 1000 | after `express.static`, so SPA assets aren't counted |
  | `/login/*`, `/api/web/auth` | 15 min | 50 | brute-force |
  | `/login/otp/request`, `/login/Createlogin` | 10 min | 5 | keyed by IP **and** mobile |
  | `/payments/create-order`, `/payments/verify` | 10 min | 20 | webhook deliberately unlimited |

## Scheduled jobs (Step 4)

**Removed:** the four jobs no longer run at module load — that fired bill
generation on every process start (P1-9). `lib/jobs.js` holds them now, guarded
by an in-process lock (no self-overlap) and idempotent in SQL (a billed period
is skipped).

Two ways they run, both calling the same guarded functions:
- node-cron while the process is up (disable with `ENABLE_INPROCESS_CRON=false`);
- **authoritative:** Plesk scheduled tasks hitting the token-protected endpoints
  (Plesk starts the app to serve the request, so recycled idle apps don't miss a run).

Endpoints (require `X-Cron-Token` header or `?token=` matching `CRON_TOKEN`):

| Job | Endpoint | Schedule |
|---|---|---|
| Society maintenance bills (`gen_bill`) | `GET/POST /api/web/cron/society-bills` | daily 10:00 |
| Village tax/house bills (`sp_village_bill_run` Auto) | `/api/web/cron/village-bills` | daily 02:00 |
| Maintenance-due FCM reminders | `/api/web/cron/notifications` | daily 10:00 |
| Refresh-token cleanup | `/api/web/cron/token-cleanup` | daily 00:00 |

Plesk task example: `curl -fsS -H "X-Cron-Token: $CRON_TOKEN" https://chshub.co.in/api/web/cron/society-bills`

## Structured logging (Step 5)

`lib/logger.js` (pino) + `pino-http` in `app.js`. Every request gets an id
(echoed as `X-Request-Id`), and logs carry method, route, status, duration, a
**masked** auth id (web user id, or `***`+last4 of mobile), and tenant id.
Secrets are redacted (Authorization/cookie/cron/razorpay headers; any
password/otp/token/secret field). `morgan` removed.

## Error tracking (Step 6)

`lib/error-tracking.js` installs `unhandledRejection` / `uncaughtException`
handlers that log (redacted) with a category. If `SENTRY_DSN` is set **and**
`@sentry/node` is installed, exceptions also ship to Sentry; otherwise it is a
no-op, so development stays quiet. Enable: `npm i @sentry/node` + set `SENTRY_DSN`.

## Health (Step 7)

`GET /api/web/health` (unauthenticated) checks app liveness + a `SELECT 1` DB
probe. `200 {status:'up',db:'up'}` healthy; `503` when the DB is unreachable, for
an uptime monitor. No connection string or secret is exposed.

## New environment variables

| Var | Purpose |
|---|---|
| `LOG_LEVEL` | pino level (default info in prod, debug otherwise) |
| `ENABLE_INPROCESS_CRON` | `false` to rely solely on Plesk-driven cron |
| `SENTRY_DSN` | optional error tracking (needs `@sentry/node`) |
| `CRON_TOKEN` | already used; now guards all four cron endpoints |

## Dependencies (Step 3)

- **Backend:** `npm audit fix` (non-breaking) applied — patches the Express-4
  transitive highs (path-to-regexp ReDoS, body-parser/qs DoS). Remaining
  advisories need **major** bumps held back as breaking and documented below.
- **Frontend:** the 2 highs are `xlsx` (SheetJS) — no fixed version on the npm
  registry. Migration to `exceljs` is the remedy (see deferred).

### Known residual risks (require deliberate, tested upgrades)

- `pug@2.0.0-beta11` (→ pug-filters advisory): pug is only the error-view engine;
  the API returns JSON. Upgrade to `pug@3` or drop the view engine entirely.
- `firebase-admin` transitive `tar-fs`: bump `firebase-admin` to the latest 13.x
  and re-audit; test FCM send after.
- **`xlsx` → `exceljs` (frontend, DEFERRED):** `frontend/src/pages/settings/ExcelImport.jsx`
  reads a workbook and calls `XLSX.utils.sheet_to_json(sheet, {header:1})` to get a
  raw grid; `ExcelImport.test.jsx` builds fixtures with `xlsx`. exceljs replacement:
  `const wb = new ExcelJS.Workbook(); await wb.xlsx.load(arrayBuffer); ws.eachRow(...)`
  to rebuild the same grid. Not done here because it changes parsing behaviour and
  needs the Excel-import flow re-tested end-to-end against real legacy sheets.
