// Production error tracking.
//
// Baseline is structured logging of every fatal category via pino. If SENTRY_DSN
// is set AND @sentry/node is installed, exceptions are also shipped to Sentry;
// otherwise it stays a no-op, so development is quiet and nothing new is required
// to run. Install with `npm i @sentry/node` and set SENTRY_DSN to enable.
const logger = require('./logger');

function initErrorTracking() {
  const dsn = process.env.SENTRY_DSN;
  let sentry = null;

  if (dsn) {
    try {
      sentry = require('@sentry/node');
      sentry.init({
        dsn,
        environment: process.env.NODE_ENV || 'development',
        tracesSampleRate: 0,
      });
      logger.info('error tracking: Sentry initialised');
    } catch (_e) {
      logger.warn('SENTRY_DSN is set but @sentry/node is not installed — run `npm i @sentry/node`');
      sentry = null;
    }
  }

  const capture = (err, ctx) => {
    if (!sentry) return;
    try { sentry.captureException(err, { extra: ctx }); } catch (_) { /* never let tracking crash us */ }
  };

  // Last-resort process-level handlers. Log (redacted) + report; do not exit on
  // rejection, but treat an uncaught exception as fatal state.
  process.on('unhandledRejection', (reason) => {
    logger.error({ err: reason, category: 'unhandledRejection' }, 'unhandled promise rejection');
    capture(reason, { kind: 'unhandledRejection' });
  });
  process.on('uncaughtException', (err) => {
    logger.fatal({ err, category: 'uncaughtException' }, 'uncaught exception');
    capture(err, { kind: 'uncaughtException' });
  });

  return { capture };
}

module.exports = { initErrorTracking };
