// Website API — input coercion and validation.
//
// The SPs are permissive: they accept NULLs and silently coerce, so bad input
// tends to produce a wrong result rather than an error. These helpers reject at
// the edge instead, and normalise types before they reach mssql.
const { ApiError } = require('./http');

const isBlank = (v) => v === undefined || v === null || String(v).trim() === '';

/** Required string, trimmed, with an optional max length. */
function str(value, field, { max, required = true } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return null;
  }
  const s = String(value).trim();
  if (max && s.length > max) {
    throw ApiError.badRequest(`${field} must be at most ${max} characters`);
  }
  return s;
}

/** Optional string — blank becomes null so the SP writes NULL, not ''. */
function optionalStr(value, field, opts = {}) {
  return str(value, field, { ...opts, required: false });
}

/** Integer, rejecting non-numeric input rather than letting it become NaN. */
function int(value, field, { min, max, required = true, default: dflt } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return dflt === undefined ? null : dflt;
  }
  const n = Number(value);
  if (!Number.isInteger(n)) {
    throw ApiError.badRequest(`${field} must be an integer`);
  }
  if (min !== undefined && n < min) throw ApiError.badRequest(`${field} must be at least ${min}`);
  if (max !== undefined && n > max) throw ApiError.badRequest(`${field} must be at most ${max}`);
  return n;
}

/** Decimal/number, for amounts and rates. */
function num(value, field, { min, max, required = true, default: dflt } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return dflt === undefined ? null : dflt;
  }
  const n = Number(value);
  if (!Number.isFinite(n)) throw ApiError.badRequest(`${field} must be a number`);
  if (min !== undefined && n < min) throw ApiError.badRequest(`${field} must be at least ${min}`);
  if (max !== undefined && n > max) throw ApiError.badRequest(`${field} must be at most ${max}`);
  return n;
}

/** Accepts common truthy spellings from query strings and JSON bodies. */
function bool(value, field, { required = false, default: dflt = false } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return dflt;
  }
  const s = String(value).trim().toLowerCase();
  if (['1', 'true', 'yes', 'y'].includes(s)) return true;
  if (['0', 'false', 'no', 'n'].includes(s)) return false;
  throw ApiError.badRequest(`${field} must be a boolean`);
}

/** ISO-ish date, returned as a JS Date for mssql to bind. */
function date(value, field, { required = true } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return null;
  }
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) throw ApiError.badRequest(`${field} must be a valid date`);
  return d;
}

/**
 * Clock time from an <input type="time">, which sends "HH:MM" (or "HH:MM:SS").
 * `new Date("14:30")` is Invalid Date, so those columns — all smalldatetime —
 * need the time anchored to a date before mssql can bind it. Anything that is
 * not a bare time falls through to `date()`.
 */
function time(value, field, { required = true } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return null;
  }
  const s = String(value).trim();
  const m = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(s);
  if (!m) return date(s, field, { required });

  const [h, min, sec] = [Number(m[1]), Number(m[2]), Number(m[3] ?? 0)];
  if (h > 23 || min > 59 || sec > 59) throw ApiError.badRequest(`${field} must be a valid time`);
  return new Date(1900, 0, 1, h, min, sec);
}

/** Value restricted to a fixed set — used for SP @operation dispatch. */
function oneOf(value, field, allowed, { required = true } = {}) {
  if (isBlank(value)) {
    if (required) throw ApiError.badRequest(`${field} is required`);
    return null;
  }
  const s = String(value).trim();
  if (!allowed.includes(s)) {
    throw ApiError.badRequest(`${field} must be one of: ${allowed.join(', ')}`);
  }
  return s;
}

module.exports = { str, optionalStr, int, num, bool, date, time, oneOf, isBlank };
