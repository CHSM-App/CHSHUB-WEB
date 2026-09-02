// Structured logging for the backend (pino).
//
// Redaction is the important part: secrets must never reach the log stream.
// paths cover the Authorization/cookie headers and any field named like a
// credential, at the top level or one nested level deep (pino redact syntax).
const pino = require('pino');

const logger = pino({
  level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'req.headers["x-cron-token"]',
      'req.headers["x-razorpay-signature"]',
      'password', '*.password',
      'otp', '*.otp', 'otp_hash', '*.otp_hash',
      'token', '*.token',
      'accessToken', '*.accessToken', 'refreshToken', '*.refreshToken',
      'razorpaySignature', '*.razorpaySignature',
      'JWT_SECRET_KEY', 'RAZORPAY_KEY_SECRET', 'DB_PASSWORD',
    ],
    censor: '[redacted]',
  },
});

module.exports = logger;
