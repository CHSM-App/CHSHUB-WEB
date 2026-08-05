// Website API — database access.
//
// Reuses the single mssql ConnectionPool created in routes/db.js so the web and
// mobile APIs share one pool rather than opening a second set of connections.
const sql = require('mssql');
const pool = require('../../routes/db');

// routes/db.js connects the pool asynchronously and retries on failure, so for
// the first moment after boot — and after any reconnect — the pool exists but
// is not yet usable. Issuing a request then fails with ECONNCLOSED, which the
// error handler reports as a 500. Under iisnode worker recycling that window is
// hit by real traffic, so wait for the pool instead of failing.
//
// Only the website API waits; routes/ keeps its existing behaviour.
const CONNECT_TIMEOUT_MS = 15000;
const POLL_INTERVAL_MS = 50;

async function ready() {
  if (pool.connected) return;

  const deadline = Date.now() + CONNECT_TIMEOUT_MS;
  while (Date.now() < deadline) {
    if (pool.connected) return;
    // Not connecting and not connected means the retry timer in routes/db.js
    // has not fired yet; keep waiting rather than opening a competing pool.
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }

  const err = new Error('Database connection is not available');
  err.code = 'ECONNCLOSED';
  throw err;
}

/**
 * Execute a stored procedure with named parameters.
 *
 * Params are passed as a plain object. A value may be given either as a bare
 * JS value (mssql infers the type) or as { type, value } when the type has to
 * be pinned down — needed for NULLs and for NVARCHAR(MAX) text.
 *
 *   execProc('sp_building_master', {
 *     operation: 'Grid_Show',
 *     society_id: { type: sql.NVarChar(10), value: societyId },
 *   })
 *
 * Returns the raw mssql result so callers can reach recordsets/output/rowsAffected.
 */
async function execProc(procName, params = {}) {
  await ready();
  const request = pool.request();

  for (const [name, raw] of Object.entries(params)) {
    if (raw !== null && typeof raw === 'object' && 'type' in raw) {
      request.input(name, raw.type, raw.value);
    } else {
      request.input(name, raw);
    }
  }

  return request.execute(procName);
}

/** First recordset, or [] when the proc returned none. */
async function query(procName, params) {
  const result = await execProc(procName, params);
  return result.recordset || [];
}

/** First row of the first recordset, or null. */
async function queryOne(procName, params) {
  const rows = await query(procName, params);
  return rows.length ? rows[0] : null;
}

/**
 * Run a proc for its side effect. Returns the first row when the proc emits one
 * (many of these SPs `SELECT @new AS id` after inserting), otherwise null.
 */
async function exec(procName, params) {
  const result = await execProc(procName, params);
  const rows = result.recordset || [];
  return rows.length ? rows[0] : null;
}

/**
 * A connected pool, for the few places that need a raw request or a transaction
 * rather than a stored-procedure call. Prefer this over importing `pool`
 * directly, which may not be connected yet.
 */
async function getPool() {
  await ready();
  return pool;
}

module.exports = { sql, pool, getPool, execProc, query, queryOne, exec };
