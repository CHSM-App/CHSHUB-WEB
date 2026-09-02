# Flutter production release — signing, Firebase & versioning

Fixes audit P0-5 (all three apps release-signed with the **debug** keystore) and
sets production application IDs.

## Production identities (done in code)

| App | Folder | applicationId / namespace | versionName+Code |
|---|---|---|---|
| Resident | `CHSHUB_APP` | `co.in.chshub.resident` | 1.0.0+1 |
| Security | `security_app` | `co.in.chshub.security` | 1.0.0+1 |
| Secretary | `Secretary_app` | `co.in.chshub.secretary` | 1.0.0+1 |

Each app now: reads signing from `android/key.properties` with a debug fallback,
enables R8 (`minifyEnabled` + `shrinkResources`) with a `proguard-rules.pro`, and
its `MainActivity.kt` lives under the new package. No `com.example.*` remains in
app config.

## 1. Create one upload keystore per app (human, once)

Never commit the `.jks` or the filled-in `key.properties` — both are git-ignored.

```bash
# Run once per app, in that app's folder. Use a STRONG, unique password each.
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then copy `android/key.properties.example` to `android/key.properties` and fill in:

```
storeFile=upload-keystore.jks
storePassword=<the store password>
keyPassword=<the key password>
keyAlias=upload
```

Back up each keystore somewhere safe (a lost upload key means you must ask Google
to reset it). Build locally:

```bash
flutter build appbundle --release   # AAB for Play
flutter build apk --release         # APK for sideload/testing
```

Confirm it is NOT the debug key:

```bash
# 'CN=CHS Hub…' (your dname), never 'CN=Android Debug'
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

## 2. Firebase per-app config (human — REQUIRED for resident & security)

Resident and Security use FCM. The applicationId changed, so their existing
`google-services.json` no longer matches. The `package_name` in each file was
updated to the new id as a **build stopgap**, but it still carries the OLD
Firebase app's keys — push token registration will not work correctly until you:

1. Firebase console → your project → Add app (Android) for **`co.in.chshub.resident`**,
   and again for **`co.in.chshub.security`**.
2. Add each app's release signing SHA-1/SHA-256 (from the keystore:
   `keytool -list -v -keystore android/app/upload-keystore.jks -alias upload`).
3. Download the fresh `google-services.json` for each and replace
   `CHSHUB_APP/android/app/google-services.json` and
   `security_app/android/app/google-services.json`.

Secretary has no Firebase and needs none. `google-services.json` is client config
(safe to commit); the Firebase **service-account** key is the secret — it stays on
the backend only, never in an app (see `docs/SECRET-REMEDIATION.md`).

## 3. CI signing (GitHub Actions)

`.github/workflows/manual-build.yml` injects signing from secrets and never prints
them. Add these repository secrets (Settings → Secrets and variables → Actions),
per app prefix `RESIDENT_` / `SECURITY_` / `SECRETARY_`:

| Secret | Value |
|---|---|
| `<PREFIX>_KEYSTORE_BASE64` | `base64 -w0 android/app/upload-keystore.jks` |
| `<PREFIX>_STORE_PASSWORD` | store password |
| `<PREFIX>_KEY_PASSWORD` | key password |
| `<PREFIX>_KEY_ALIAS` | `upload` |

Run the **Manual app builds** workflow and tick the AAB box for each app. With the
secrets present it produces Play-ready signed AABs; without them it falls back to
the debug key (a dev artifact, flagged in the log). The per-push `resident-app.yml`
is left on the debug fallback intentionally — it builds dev artifacts, not releases.

## 4. Versioning strategy

`versionName` (user-visible, e.g. `1.0.0`) and `versionCode` (integer Play upgrade
counter) both come from `pubspec.yaml`'s `version: 1.0.0+1` (name `1.0.0`, code `1`).
For each release bump the part you need — e.g. `1.0.1+2`, then `1.1.0+3`. The
`versionCode` (after `+`) must strictly increase for every Play upload.

## 5. Rollback

All changes are config; revert the commit to restore the previous state. Note that
reverts reinstate the debug-signing hole, so prefer fixing forward. Keystores and
`key.properties` are untracked, so a revert never touches them.
