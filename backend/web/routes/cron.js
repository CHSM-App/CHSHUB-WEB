// Website API — scheduled work, callable from outside the Node process.
//
// app.js runs bill generation on node-cron, which only fires while the process
// is up. On Plesk an idle Node app is recycled, so an overnight run can be
// missed entirely — nobody is using the site at 02:00, which is exactly when
// the app is most likely to be stopped.
//
// These routes give a Plesk scheduled task (or any external scheduler) a way
// to trigger the same work over HTTP. Plesk starts the app to serve the
// request, so the run happens whether or not the process was already up.
//
// Both paths call the same stored procedure the cron job does, and a period
// already billed is skipped, so running both is harmless.
const express = require('express');

const { ok, asyncHandler, ApiError } = require('../lib/http');
const jobs = require('../../lib/jobs'); // guarded, idempotent, logged job implementations

const router = express.Router();

/*
 * A shared secret, not a user session: a scheduler has no user to sign in as.
 * Set CRON_TOKEN in the environment and pass it as ?token=... or in an
 * X-Cron-Token header.
 *
 * Without CRON_TOKEN set, every request is refused. Defaulting to open would
 * mean anyone who guessed the path could raise a village's bills, and a
 * missing environment variable is far too quiet a way to end up there.
 */
function requireCronToken(req, _res, next) {
  const expected = process.env.CRON_TOKEN;

  if (!expected) {
    return next(ApiError.forbidden('Scheduled tasks are not enabled: CRON_TOKEN is not set.'));
  }

  const supplied = req.get('x-cron-token') || req.query.token;

  /*
   * Compared as strings of equal length only. A mismatch in length tells an
   * attacker something on its own, so the length check comes first and the
   * comparison is over the whole string either way.
   */
  if (typeof supplied !== 'string' || supplied.length !== expected.length || supplied !== expected) {
    return next(ApiError.forbidden('Invalid cron token.'));
  }

  return next();
}

router.use(requireCronToken);

/**
 * GET|POST /api/web/cron/village-bills
 *
 * Raises today's village bills. sp_village_bill_run's Auto branch decides which
 * villages are due — auto_bill_generation on, bill_gen_day matching today — and
 * holds yearly charges back until the month named by property_tax_month.
 *
 * GET as well as POST because Plesk's scheduled tasks fetch a URL, and a task
 * that has to POST needs curl arguments people get wrong.
 */
// Each endpoint drives the same guarded job app.js's node-cron uses. Jobs are
// idempotent (a period already billed is skipped) and locked (no overlap), so a
// scheduler firing while a run is in progress is safe. GET and POST both work
// because Plesk scheduled tasks fetch a URL.
function cronRoute(path, job) {
  const handler = asyncHandler(async (_req, res) => {
    const result = await job();
    return ok(res, { ...result, at: new Date().toISOString() });
  });
  router.get(path, handler);
  router.post(path, handler);
}

cronRoute('/village-bills', jobs.generateVillageBills);   // village tax/house bills
cronRoute('/society-bills', jobs.generateSocietyBills);   // society maintenance bills (gen_bill)
cronRoute('/notifications', jobs.sendMaintenanceNotifications); // maintenance-due FCM reminders
cronRoute('/token-cleanup', jobs.cleanupRefreshTokens);   // expire old refresh tokens

module.exports = router;
