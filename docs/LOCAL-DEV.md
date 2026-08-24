# Running the website locally

Backend (Express) and frontend (React + Vite). Both are prepared — dependencies
installed, config written — so this is just the two commands.

## Run it

Two terminals:

```sh
# 1. API on http://localhost:8000
cd backend
npm run dev          # node --watch app.js; `npm start` for no reload

# 2. Website on http://localhost:5173
cd frontend
npm run dev
```

Open <http://localhost:5173>. Vite proxies `/api` to the backend, so the browser
sees one origin and CORS never enters into it.

Check the API alone with <http://localhost:8000/api/web/health>.

## What was set up

**`backend/package.json`** — `start` now runs `app.js`. It ran `bin/www`, which
created a *second* HTTP server and called `listen` on the same port that
`app.js` had already bound, so `npm start` died with `EADDRINUSE` every time.
`bin/www` is deleted; deployment uses `app.js` through iisnode anyway. `npm run
dev` is new and restarts on file changes.

**`backend/.env`** — three changes, backed up first as `.env.backup-before-localdev`:

- `DB_TRUST_SERVER_CERT=true`. Certificate verification is now the default (it
  used to be unconditionally off), but `winsome.grabweb.in` presents a
  self-signed certificate, so nothing can connect with verification on. This is
  a real P1 item, not just a local quirk: install a proper certificate on the
  SQL Server and set this back to `false`.
- `CORS_ORIGINS` gained `http://localhost:5173` and `http://127.0.0.1:5173`.
- `FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json`, resolved against
  `backend/`. The file is on disk and gitignored.

**`frontend/.env.local`** — API base and proxy target, plus the three financial
write flags left off (see the warning below). Gitignored.

**Firebase is no longer required to boot.** `routes/notify.js` called
`initializeApp` at require time, so a machine without credentials could not
start the API at all — even to serve routes that send no push. Initialisation
is now lazy: without credentials the API runs and only push sending fails.

## Verified

Started both, then stopped them again:

| Check | Result |
| --- | --- |
| Database connect (`DB_*` from `.env`) | connects to `society` |
| `GET /api/web/health` | `200 {"ok":true,...}` |
| `GET /privacy-policy` | `200` — public page still public |
| `GET /users/SearchSociety` | `401` — was open before today |
| `GET /file/db.js` | `401` — used to return source with the DB password |
| `POST /api/web/auth/login` with `{}` | `400`, not `500` |

## Two things to know before you click around

**`DB_SERVER` points at the production database.** Nothing about running
locally makes the data local — every save, delete and bill generated from
`localhost:5173` writes to the live `society` database. Point `DB_*` at a copy
before testing anything destructive.

**The three financial flows are switched off** in `frontend/.env.local`:
bill generation, receipt entry and village payments. Their buttons render
disabled. Turn one on only when you mean to exercise it — and given the point
above, preferably against a test database first.

## Not needed for the website

`SQL/ADD_login_otp.sql` is for the **mobile** login (the new OTP flow) and is
not yet applied to this database. The website authenticates with a username and
password through `/api/web/auth/login`, which is unaffected, so you do not need
the migration to work on the site.
