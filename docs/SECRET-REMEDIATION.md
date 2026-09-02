# Secret containment & history purge — operator runbook

Status of code-side containment (done in the repo):

- `.gitignore` blocks `.env`, `.env.*` (except `.env.example`), and every
  `serviceAccountKey.json` from re-entering the repo.
- No secret file is tracked any more. The last tracked one,
  `Society_dotNet/Society2024/App_Data/serviceAccountKey.json`, was `git rm --cached`d
  (it stays on disk for the legacy app but is no longer in the index).
- On-disk leftovers deleted: `backend/routes/serviceAccountKey.json` (never loaded)
  and `backend/.env.backup-before-localdev`.
- `backend/serviceAccountKey.json` is **kept** — it is the live Firebase key loaded via
  `FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json`. It is untracked and gitignored.
  Prefer moving it into the `FIREBASE_SERVICE_ACCOUNT` env var on the server (raw or base64)
  so the file need not exist there at all.
- `backend/.env.example` lists every variable name with empty/placeholder values only.

What only a human with repo-admin + provider access can do — **do these in order**.

## 1. Rotate every exposed secret (the values in history are public)

The old values must be assumed known. Rotating the code without rotating the values
fixes nothing.

| Secret | Where to rotate | Note |
|---|---|---|
| `DB_PASSWORD` | SQL Server: `ALTER LOGIN chsadmin WITH PASSWORD = '<new>'` | also change host/user if feasible |
| `JWT_SECRET_KEY` | generate new (below) | signs out every session — expected |
| `REFRESH_KEY` | generate new (below) | |
| `RAZORPAY_KEY_SECRET` (+`KEY_ID`) | Razorpay dashboard → API keys → regenerate | revoke old key pair |
| `MSGBOT_API_KEY` | MessageBot account | |
| Firebase service account | Firebase console → Service accounts → generate new key; revoke old | on-disk key was already rotated once |

Generate a strong JWT/refresh secret:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"
```

## 2. Move secrets to the server environment (stop the file existing in prod)

Put every variable from `backend/.env.example` into the **Plesk → Node.js → Environment
variables** panel (or the host's env-var mechanism). Then delete `backend/.env` from the
server. `dotenv.config()` is a no-op when the vars are already in `process.env`, so the app
keeps working with no code change. For Firebase, set `FIREBASE_SERVICE_ACCOUNT` to the JSON
(base64 is safest for the multi-line private key) and drop `FIREBASE_SERVICE_ACCOUNT_PATH`.

## 3. Purge the secrets from git history

Affected paths (added across 8 commits):

```
backend/.env.bak.20260812
backend/serviceAccountKey.json
backend/routes/serviceAccountKey.json
Society2024/App_Data/serviceAccountKey.json
society2024DotNet/Society2024/App_Data/serviceAccountKey.json
Society_dotNet/Society2024/App_Data/serviceAccountKey.json
```

Install `git filter-repo` (`pip install git-filter-repo`), then from a **fresh mirror clone**:

```bash
git clone --mirror https://github.com/CHSM-App/CHSHUB-WEB.git chshub-purge.git
cd chshub-purge.git
git filter-repo \
  --path backend/.env.bak.20260812 \
  --path-glob '**/serviceAccountKey.json' \
  --invert-paths
```

This rewrites every commit hash. Verify the paths are gone:

```bash
git log --all --diff-filter=A --name-only --pretty=format: \
  -- backend/.env.bak.20260812 '**/serviceAccountKey.json' | sort -u   # must be empty
```

## 4. Force-push the rewritten history (destructive — do deliberately)

Not automated on purpose. Every collaborator must re-clone afterward; old clones and open
PRs will still contain the secrets.

```bash
git push --force --all
git push --force --tags
```

Then:

- Re-run the split-branch CI (or force-push each generated branch) — those branches carry
  the same history.
- Ask GitHub Support to expire cached views / stale refs of the old objects.
- Anyone with an existing clone: `git fetch && git reset --hard origin/main` or re-clone.

## 5. After rotation

- Assume the old keys were used: review recent Razorpay transactions and SMS sends for
  anything unfamiliar.
- Confirm the app boots with the new env vars and Firebase credential before closing this out.
