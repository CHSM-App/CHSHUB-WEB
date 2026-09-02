# CHS HUB — Project Overview

One product, one database, one backend. Five deployable surfaces, split by **user role**.
(`Society_dotNet/` is the legacy ASP.NET WebForms app being replaced — ignored in this doc.)

```
                     ┌──────────────────────────────┐
                     │  SQL Server  "society"       │
                     │  119 tables · 72 SPs · views │
                     └──────────────┬───────────────┘
                                    │  (stored procedures only, no ORM)
                     ┌──────────────┴───────────────┐
                     │   backend/   Express 4 (Node)│
                     ├──────────────┬───────────────┤
                     │ routes/      │ web/          │
                     │ MOBILE API   │ ADMIN API     │
                     │ ~221 eps     │ /api/web      │
                     └───┬───┬──────┴────┬──────┬───┘
                         │   │           │      │
              ┌──────────┘   │           │      └──────────┐
              │              │           │                 │
      ┌───────▼──────┐ ┌─────▼──────┐ ┌──▼─────────┐ ┌─────▼─────────┐
      │ CHSHUB_APP   │ │security_app│ │ frontend/  │ │ Secretary_app │
      │ Resident     │ │ Guard      │ │ Admin web  │ │ Secretary     │
      │ Flutter      │ │ Flutter    │ │ React SPA  │ │ Flutter       │
      └──────────────┘ └────────────┘ └────────────┘ └───────────────┘
```

All clients point at `https://chshub.co.in/`.

---

## 1. The five components

| Folder | Role served | Stack | API it uses | Split branch |
|---|---|---|---|---|
| `backend/` | — (shared) | Node/Express 4, `mssql`, JWT, Firebase FCM, Razorpay | — | `backend` |
| `frontend/` | **Society Admin / Village (Gram Panchayat) Admin** | React 19 + Vite + Tailwind + React Router 7 | `/api/web` | `Society_web` |
| `CHSHUB_APP/` | **Resident** (owner / tenant) | Flutter, Riverpod, Retrofit/Dio | `backend/routes/` (mobile) | `CHSHUB_resident_app` |
| `security_app/` | **Security guard / Gatekeeper** | Flutter, Riverpod, `mobile_scanner` (QR) | `backend/routes/` (mobile) | `security_app` |
| `Secretary_app/` | **Secretary / Committee** (admin on mobile) | Flutter, Riverpod, Retrofit/Dio, `fl_chart` | `/api/web` (same as web) | `secretary_app` |
| `Society_dotNet/` | legacy admin — **ignored** | ASP.NET WebForms, 104 `.aspx` | — | `society_dotNet` |

CI (`.github/workflows/split-branches.yml`) mirrors each folder to its own branch with the folder
as repo root, so each surface is independently deployable. The `backend` branch is special: the
React build is compiled into `backend/public/` first, then the whole backend is published.

---

## 2. Backend — two APIs in one process

`backend/app.js` mounts two entirely separate route trees. They share the DB pool and nothing else.

### 2a. Mobile API — `backend/routes/` (~221 endpoints, ~5100 LOC)

Serves the **resident** and **security** apps. Bare JSON/array responses (no envelope).

| File | LOC | Covers |
|---|---|---|
| `insert.js` | 1109 | Visitors, family members, vehicles, helpers, facilities, expenses, helpdesk |
| `users.js` | 830 | Profiles, directory, committee, neighbours, polls, marketplace |
| `gate_insert.js` | 620 | Gate entries, staff attendance, visitor status, security alerts |
| `uploadfile.js` | 508 | Photos, documents, receipts |
| `notify.js` | 423 | FCM push, SMS, panic/emergency alerts |
| `login.js` | 367 | OTP login, `Createlogin`, refresh/revoke tokens, gatekeeper check |
| `gatekeeper.js` | 328 | Guard-side visitor & staff lists |
| `community.js` / `insert_community.js` | 285 / 174 | Notices, events, meetings |
| `deleteapi.js` | 197 | 15 DELETE endpoints, mounted at `/` |
| `fileAccess.js`, `db.js`, `firebase.js`, `test.js` | — | Infra |

Auth: `routes/middleware/protect.js` → `auth.js` — plain `jwt.verify` on `JWT_SECRET_KEY`, sets
`req.user`. Every router is wrapped in `protect` except `/login` (must be public) and `deleteapi`
(mounted at `/`, so it applies `protect` per-route).

> Known gap, documented in `app.js`: `protect` proves *who* is calling but most handlers still act
> on whatever id they are handed — per-record ownership checks are still missing.

### 2b. Website/Admin API — `backend/web/` (mounted at `/api/web`)

Serves the **React admin** and the **Secretary app**. Self-contained: own auth, own validation,
own error handler, enveloped responses `{ ok: true, data }` / `{ ok: false, error }`.

```
web/
├── index.js                      router root
├── lib/     db, http, notify, password (PBKDF2, legacy-compatible),
│            publicUser, tokens, validate
├── middleware/authenticate.js    authenticate + requireSociety / requireVillage / requireTenant
└── routes/
    ├── auth.js                   login / refresh (rotating) / logout / me
    ├── onboarding.js             register, forgot password, society & village setup
    ├── cron.js                   shared-secret endpoints for external schedulers
    ├── masters/     buildings, wings, flats, owners, family, ownerExtras, misc
    ├── settings/    accountSettings, charges, societyCharges, terms
    ├── billing/     bills, receipts, generation, pdc
    ├── accounts/    index (cashbook/ledger/expenses), vendors, vendorBills
    ├── community/   notices, events, meetings, facilities, helpdesk, visitors
    ├── reports/     financials, audit, balance sheet
    └── village/     village-tenant equivalents
```

**Tenancy is the security model.** `society_id` / `village_id` come *only* from the JWT, never from
query or body; a mismatched client-supplied id is a 403. Mobile-issued tokens are rejected here
(they lack `scope: 'web'`, and the mobile login performs no password check).

Login note: the shared `validateuser` SP declares `@password` but never uses it in its WHERE clause,
so the web API verifies the password itself against the legacy PBKDF2 format (`lib/password.js`).
Unknown username and wrong password return the same message and run the same work, so the endpoint
cannot be used to enumerate accounts.

### 2c. Scheduled jobs (node-cron, inside the API process)

| Time | Job |
|---|---|
| 10:00 | `GenerateBill()` → `gen_bill` (society maintenance bills) |
| 10:00 | Maintenance-due FCM reminders → `sp_maintenance_charges` |
| 02:00 | `GenerateVillageBill()` → `sp_village_bill_run` (overnight so figures don't shift mid-day) |
| 00:00 | `cleanupRefreshTokens()` → `ManageRefreshToken` |

All are idempotent (a period already billed is skipped) and also run once at boot. Because Plesk
recycles idle processes, `GET /api/web/village/bill-run/auto` exists as an external-scheduler hook.

---

## 3. Role-by-role: what each surface does

### Resident — `CHSHUB_APP/` (168 Dart files)

Layered: `core/{network,storage}` → `data/{api,repositories}` → `domain/{models,repository,usecase}`
→ `presentation/{providers,viewModels}`, with screens in `SocietyApp/screens/`.

Home · OTP login · maintenance bills + receipts + Razorpay payment · gate pass · visitor management
and approve/deny dialogs · helpdesk / raise complaint · amenity & facility booking · society polls ·
notices · marketplace (add/edit/view product) · document upload · vehicle parking · members
directory · helper reviews · multi-language · notifications.

### Security guard — `security_app/` (95 Dart files)

Same layered structure, plus `l10n/` (localisation) and Firebase auth/messaging.

Login/OTP · QR scanner · add visitor · in/out log · visitor action dialogs · staff attendance ·
gatekeeper attendance · security alert dialog · notifications · profile, language, support, privacy
policy, T&C.

### Secretary — `Secretary_app/` (109 Dart files)

Effectively the **admin web app as a phone app** — the only Flutter app on `/api/web/`. Adds
`core/pdf/`, `core/theme/`, `widgets/`, and a `home_shell` + `hub_scaffold` navigation shell.

`dashboard/` · `billing/` (bills, bill detail, generate, defaulters + detail, receipts + entry +
detail, PDC) · `accounts/` (cashbook, expenses, ledger, vendor bills) · `community/` (notices,
visitors, helpdesk, facility bookings) · `settings/` · `auth/`.

### Admin web — `frontend/` (React 19)

`src/{api,auth,components,pages,lib,test}`. Session in `localStorage`; axios instance auto-attaches
the token and does a deduplicated single-flight refresh on 401.

Route guards: `RequireAuth` (session) and `RequireTenant` (society vs village — a village user
hitting `/masters/*` is bounced to `/dashboard`, mirroring the API's `requireSociety`).

Sidebar sections (deliberately mirroring the legacy ASPX menu):

- **Property Master** — society, buildings, wings, flats, rental, maintenance charges, amenities, parking places
- **People & Staff** — committee members, owners, visitors, staff
- **Service & Facility** — parking allotment, facility booking, assistant/technician/supplier, car pooling, events, notices
- **Society Management** — documents, shop maintenance, meetings, inventory
- **Vendor Management** — vendors, vendor bills & approvals
- **Finance & Billing** — loans & lien, PDC reminder, PDC clearing, ledger, cashbook
- **Credit & Debit** — maintenance bills, maintenance receipts, other credits, audit Q&A
- **Reports** — shop maintenance, ownerwise maintenance, annual income & expenditure, balance sheet
- **Others** — suggestions, billing settings, terms & conditions
- **Village (separate tenant)** — residents, charges, generate bills, tax payments, reports, history, announcements, government schemes, staff, settings

Tests are colocated `*.test.jsx` (Vitest + Testing Library + MSW).

---

## 4. Two tenant kinds, not just two roles

The admin surface serves two *different organisations* off the same schema:

| | Society (CHS) | Village (Gram Panchayat) |
|---|---|---|
| Token claim | `society_id` | `village_id` |
| API guard | `requireSociety` | `requireVillage` |
| UI guard | `RequireTenant kind="society"` | `RequireTenant kind="village"` |
| Setup page | `/setup/society` | `/setup/village` |
| Billing | `gen_bill`, monthly maintenance | `sp_village_bill_run`, house charges + yearly property tax |
| Notices | Notices | Announcements (same route; `NoticesRoute` switches) |

A few routes are tenant-neutral — dashboard, notices, change password, uploads — and use
`requireTenant`, which accepts either id.

---

## 5. Database conventions (they matter everywhere)

- **Stored procedures only** — no inline SQL, no ORM, no schema changes. Reused as-is from the legacy app.
- SPs dispatch on an `@operation` param: `Update` (insert *and* update — id `0` means insert),
  `Select`, `Delete`, `Grid_Show`, `Search`, `check_*`, `fill_*`.
- **Soft delete everywhere**: `active_status = 0` is live, `1` is deleted.
- `SQL/` holds migration/fix scripts applied on top (`ADD_*`, `FIX_*`, `CLEAR_*`) — largely village
  billing, receipts, and report corrections.
- Connection config from env (`DB_USER`, `DB_PASSWORD`, `DB_SERVER`, `DB_NAME`, …); the pool
  auto-reconnects on loss.

---

## 6. Existing docs

| File | What it is |
|---|---|
| `docs/MIGRATION-MAP.md` | Legacy `.aspx` page → React route → SP, per module, with API/WEB/GAP status |
| `docs/PAGE-AUDIT.md` | Page-by-page audit |
| `docs/PARITY-CHECKLIST.md` | Legacy vs new feature parity |
| `docs/FIELD-GAPS.md` | Fields not yet carried over |
| `docs/PRODUCTION-READINESS.md` | Go-live checklist |
| `docs/LOCAL-DEV.md` | Running it locally |
| `docs/BRANCHING.md` | The split-branch scheme |
| `docs/proposed-sql/`, `docs/sample-imports/` | Draft SPs, Excel import templates |

---

## 7. Where to change what

| Task | Touch |
|---|---|
| Resident-facing feature | `CHSHUB_APP/lib/` + `backend/routes/` |
| Guard-facing feature | `security_app/lib/` + `backend/routes/gatekeeper.js` / `gate_insert.js` |
| Admin feature (web **and** secretary app) | `backend/web/routes/` + `frontend/src/pages/` + `Secretary_app/lib/screens/` |
| New DB behaviour | New SP or `@operation` branch in `SQL/`, then call via `web/lib/db.js` |
| Auth / tenancy | `backend/web/middleware/authenticate.js` (web) or `backend/routes/middleware/` (mobile) |
