// Firebase Admin — one initialisation, shared by everything that sends a push.
//
// The service-account key used to be `require`d from a JSON file committed to
// the repository (twice: backend/ and backend/routes/), which published the
// project's private key to anyone who could read a clone or reach the old
// GET /file/* handler. The key is now supplied by the environment.
//
// Two ways to supply it, in this order:
//   FIREBASE_SERVICE_ACCOUNT       the JSON itself, raw or base64-encoded
//   FIREBASE_SERVICE_ACCOUNT_PATH  a path to the JSON file, kept off the repo
//
// initializeApp throws if called twice, so callers must come through here
// rather than calling it themselves.
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const admin = require('firebase-admin');

function loadCredentials() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline) {
    // Accept base64 as well as raw JSON: a private key spans lines, which many
    // environment-variable editors will not carry intact.
    const text = inline.trim().startsWith('{')
      ? inline
      : Buffer.from(inline, 'base64').toString('utf8');
    return JSON.parse(text);
  }

  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (path) return require(path);

  throw new Error(
    'Firebase credentials are not configured — set FIREBASE_SERVICE_ACCOUNT or ' +
      'FIREBASE_SERVICE_ACCOUNT_PATH (see backend/.env.example)',
  );
}

/** The initialised admin app, created on first use. */
function app() {
  if (!admin.apps.length) {
    admin.initializeApp({ credential: admin.credential.cert(loadCredentials()) });
  }
  return admin;
}

/** admin.messaging(), with initialisation handled. */
function messaging() {
  return app().messaging();
}

module.exports = { app, messaging, admin };
