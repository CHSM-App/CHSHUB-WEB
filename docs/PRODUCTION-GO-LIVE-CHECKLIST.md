# CHS HUB — Production Go-Live Gate

Assessed against `main`. Legend: **PASS** = done and verified in the repo ·
**CONFIG** = code done, needs an operator action (env/dashboard/keystore) ·
**BLOCKED** = human/ops action not doable from source · **UNVERIFIED** = needs a
live run not performed here.

## Verdict: 🔴 NOT PRODUCTION READY

The code-side security, financial-integrity, auth, authorization, tests, CI and
deployment gating are in place. Go-live is blocked on **operator/ops actions
that cannot be done from source** and a set of **live verifications**. Every
blocker is listed with exactly what remains.

---

## Gate checklist

| # | Item | Status | Evidence / what remains |
|---|---|---|---|
| 1 | Secrets rotated | 🔴 BLOCKED | Old values still valid until rotated with each provider. `docs/SECRET-REMEDIATION.md` §1. |
| 2 | Git history cleaned | 🔴 BLOCKED | `git filter-repo` + force-push not done (destructive, human). `docs/SECRET-REMEDIATION.md` §3–4. |
| 3 | Production env configured | 🟡 CONFIG | `backend/.env.example` complete; move to Plesk env, set `RAZORPAY_WEBHOOK_SECRET`, `OTP_PEPPER`, `ROLE_*_IDS`. |
| 4 | OTP working | 🟡 UNVERIFIED | Backend `sp_login_otp` + `/login/otp/request`/`Createlogin` done; both apps wired (no fakes). Needs one live SMS round-trip. |
| 5 | Payment verified | 🟢 PASS (code) / 🟡 UNVERIFIED (live) | `payments.test.js` 12/12; live Razorpay test-mode round-trip pending. |
| 6 | Webhook working | 🟡 CONFIG | `/payments/webhook` done; register URL + secret in Razorpay dashboard (`docs/PAYMENTS-REMEDIATION.md` §3). |
| 7 | IDOR tests passing | 🟢 PASS | `backend/test/ownership.test.js` + `sp_owner_scope` on prioritized routes. |
| 8 | Roles enforced | 🟢 PASS (code) / 🟡 CONFIG | `requireUserType` + `rbac.test.js`; set `ROLE_*_IDS` from `dbo.UserType` to activate (permissive until then, by design). |
| 9 | Release signing configured | 🟡 CONFIG | `signingConfigs.release` + `key.properties` wiring done; create keystores + CI secrets (`docs/RELEASE-SIGNING.md`). |
| 10 | Firebase configured | 🔴 BLOCKED | Resident/security need per-app `google-services.json` for the new appIds from the Firebase console. |
| 11 | Dependencies audited | 🟢 PASS (backend) / 🟡 (frontend) | Backend 37→14, 0 critical/high. Frontend: `xlsx`→`exceljs` migration pending (`docs/BACKEND-HARDENING.md`). |
| 12 | Backend tests green | 🟢 PASS | `auth, ownership, hardening, payments, rbac` — all pass (run twice, no flakiness). |
| 13 | Frontend tests green | 🟡 UNVERIFIED | Vitest wired in CI; the 5 pre-existing failing tests (audit P1-10) not fixed here. |
| 14 | Flutter tests green | 🟡 UNVERIFIED | Logic tests run in CI; goldens excluded (regenerate deliberately); analyzer has pre-existing warnings (Phase 6). |
| 15 | CI green | 🟡 UNVERIFIED | `ci.yml` (per-surface) created; first run pending. |
| 16 | Deployment gated | 🟢 PASS | `split-branches.yml` deploy jobs `need` validate-backend/frontend/flutter. |
| 17 | Cron configured externally | 🟢 PASS (code) / 🟡 CONFIG | Boot side-effects removed; `/api/web/cron/*` endpoints + schedule in `docs/BACKEND-HARDENING.md`; add Plesk tasks. |
| 18 | Health monitoring active | 🟢 PASS (code) / 🟡 CONFIG | `GET /api/web/health` (app+DB, 503 on DB down); point an uptime monitor at it. |
| 19 | Error tracking active | 🟢 PASS (baseline) / 🟡 CONFIG | pino + process handlers; set `SENTRY_DSN` + `npm i @sentry/node` for external capture. |
| 20 | Backups verified | 🔴 BLOCKED | DB + keystore + Firebase key backup/restore drill — ops. |
| 21 | Payment reconciliation completed | 🟢 PASS (tooling) / 🟡 UNVERIFIED | `payment_reconciliation_vw` + queries; run against live data before/after go-live. |
| 22 | Production smoke tests completed | 🔴 BLOCKED | Manual, on real devices — checklist below. |

**Cannot be marked PRODUCTION READY until #1, #2, #10, #20, #22 are done and #4,#5,#13,#14,#15,#21 are verified green.**

---

## Phase 8 — Security smoke matrix

| # | Assertion | Covered by | Status |
|---|---|---|---|
| 1 | User A cannot read User B's flat | `ownership.test.js` + `sp_owner_scope` | 🟢 automated |
| 2 | User A cannot modify User B's records | `ownership.test.js` (403 on write) | 🟢 automated |
| 3 | User A cannot change User B's FCM token | `requireOwnership` on `/notify/OwnerApp/Insert/NewToken` | 🟢 automated (unit) |
| 4 | Resident cannot access admin APIs | mobile `scope:'mobile'` rejected by web `authenticate` (`scope:'web'`) | 🟢 automated (`auth.test.js`) |
| 5 | Member cannot do Secretary-only actions | `rbac.test.js` + `requireUserType` mounts | 🟢 automated (needs `ROLE_*_IDS` live) |
| 6 | Client cannot manipulate payment amount | `payments.test.js` #1/#3 | 🟢 automated |
| 7 | Invalid payment signature fails | `payments.test.js` #4; `timingSafeEqual` | 🟢 automated |
| 8 | Duplicate payment → no duplicate receipt | `payments.test.js` #6; UNIQUE `transaction_ref` | 🟢 automated |
| 9 | Expired JWT fails | `auth.test.js` | 🟢 automated |
| 10 | Old JWT (leaked secret) fails | after secret rotation (#1) | 🔴 depends on rotation |
| 11 | OTP cannot be bypassed | server verifies in `sp_login_otp`; client fakes removed | 🟢 code (live verify) |
| 12 | OTP cannot be replayed | `sp_login_otp` consumes on success (single-use) | 🟢 code (live verify) |
| 13 | Rate limits work | `hardening.test.js` (429 at cap) | 🟢 automated |
| 14 | Secrets absent from source & history | source: 🟢 (no tracked secrets); history: 🔴 until purge (#2) | mixed |

---

## Phase 7 — Production smoke test checklist (manual, real devices)

Run against the production API (`https://chshub.co.in/`) after config is in place.

**Resident app** — [ ] login  [ ] OTP received + verified  [ ] dashboard  [ ] dues correct  [ ] receipt history  [ ] payment (Razorpay test→live)  [ ] visitor add/approve  [ ] notification received  [ ] logout.

**Security app** — [ ] login  [ ] OTP  [ ] QR scan  [ ] visitor entry  [ ] visitor exit  [ ] staff attendance  [ ] security alert  [ ] notification.

**Secretary app** — [ ] login  [ ] dashboard  [ ] bills  [ ] receipts  [ ] accounts  [ ] vendor bills  [ ] community  [ ] reports.

**Admin web** — [ ] login  [ ] tenant selection (society/village)  [ ] role restrictions (Member blocked from billing/masters; Treasurer allowed billing, blocked from config)  [ ] master data  [ ] billing  [ ] receipts  [ ] accounts  [ ] reports  [ ] village functionality.

---

## Phase 6 — P2 cleanup status

| Item | Status |
|---|---|
| Timing-safe Razorpay comparison | 🟢 done (`payments.js` `timingSafeEqual`; old `test.js` route now 410) |
| Duplicate/dead receipt code | 🟢 old `/insert/AddReceipt` disabled (403); insecure `test.js` routes 410 |
| Cron boot side-effects | 🟢 removed (Phase 4 of backend hardening) |
| `MANAGE_EXTERNAL_STORAGE` | 🟡 deferred — audit the manifest permission; scope down if not required |
| PBKDF2 → bcrypt rehash-on-login | 🟡 deferred — needs a backward-compatible verify-then-rehash path + migration |
| localStorage → httpOnly cookie tokens | 🟡 deferred — cross-cutting auth change; needs CSRF handling |
| Hardcoded Windows upload path | 🟡 deferred — move to env/config with a read fallback |
| Absolute URLs stored in DB | 🟡 deferred — **do not change format without a migration + backward-compatible read** (per task) |
| Resident analyzer issues | 🟡 deferred — pre-existing deprecations/warnings; tracked, surfaced by CI |

Deferred items are P2 by definition and were left intentionally rather than
changed under-tested; each names its safe approach.

---

## Referenced runbooks
- `docs/SECRET-REMEDIATION.md` — secrets rotation + history purge
- `docs/PAYMENTS-REMEDIATION.md` — payment flow, webhook, reconciliation
- `docs/RELEASE-SIGNING.md` — keystores, Firebase, CI signing, versioning
- `docs/BACKEND-HARDENING.md` — headers, rate limits, cron, logging, health
