// Website API — password verification.
//
// Passwords in UserLogin.password are PBKDF2 hashes produced by the legacy
// WebForms app (Society2024/login1.aspx.cs, Rfc2898DeriveBytes):
//
//   salt      = 16 random bytes
//   hash      = PBKDF2-HMAC-SHA1(password, salt, 10000 iterations, 20 bytes)
//   stored    = Base64(salt || hash)          -> 36 bytes -> 48 Base64 chars
//
// .NET's Rfc2898DeriveBytes defaults to HMAC-SHA1, so SHA-1 is required here for
// compatibility. That is a property of the existing data, not a choice: changing
// it would invalidate every stored password. Rehash-on-login (below) is the
// migration path to something stronger.
const crypto = require('crypto');

const SALT_BYTES = 16;
const HASH_BYTES = 20;
const ITERATIONS = 10000;
const DIGEST = 'sha1';

/** Hash a new password in the legacy-compatible format. */
function hashPassword(plain, iterations = ITERATIONS) {
  const salt = crypto.randomBytes(SALT_BYTES);
  const hash = crypto.pbkdf2Sync(String(plain), salt, iterations, HASH_BYTES, DIGEST);
  return Buffer.concat([salt, hash]).toString('base64');
}

/**
 * Verify a password against a stored PBKDF2 value.
 * Returns false — never throws — on malformed input.
 */
function verifyPassword(plain, stored) {
  if (typeof stored !== 'string' || !stored) return false;

  let raw;
  try {
    raw = Buffer.from(stored, 'base64');
  } catch {
    return false;
  }
  if (raw.length !== SALT_BYTES + HASH_BYTES) return false;

  const salt = raw.subarray(0, SALT_BYTES);
  const expected = raw.subarray(SALT_BYTES);
  const actual = crypto.pbkdf2Sync(String(plain), salt, ITERATIONS, HASH_BYTES, DIGEST);

  return crypto.timingSafeEqual(expected, actual);
}

/** True when `stored` looks like the legacy PBKDF2 format. */
function isPbkdf2(stored) {
  if (typeof stored !== 'string' || stored.length !== 48) return false;
  try {
    return Buffer.from(stored, 'base64').length === SALT_BYTES + HASH_BYTES;
  } catch {
    return false;
  }
}

module.exports = { hashPassword, verifyPassword, isPbkdf2, ITERATIONS };
