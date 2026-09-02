// Production security middleware: helmet headers + tiered rate limiting.
const helmet = require('helmet');
const rlModule = require('express-rate-limit');
const rateLimit = rlModule.rateLimit || rlModule;
// Normalises IPs (groups IPv6 into /64s) so a per-IP key can't be bypassed by
// an IPv6 client rotating addresses within its prefix.
const ipKeyGenerator = rlModule.ipKeyGenerator || ((ip) => ip);

/*
 * helmet, minus a Content-Security-Policy.
 *
 * The React admin build is served from public/ and uses inline styles/module
 * scripts that helmet's default CSP would block, blanking the app. Enabling a
 * CSP safely needs it tuned and tested against the real frontend, so it is left
 * off here (documented in docs/BACKEND-HARDENING.md) while every other header
 * — X-Content-Type-Options, Referrer-Policy, frameguard, HSTS — stays on.
 */
const securityHeaders = helmet({
  contentSecurityPolicy: false,
  // Assets are same-origin; COEP off avoids breaking cross-origin images/fonts.
  crossOriginEmbedderPolicy: false,
  referrerPolicy: { policy: 'no-referrer' },
});

const base = { standardHeaders: true, legacyHeaders: false };
const tooMany = (msg) => ({ error: msg || 'Too many requests. Please try again later.' });

/*
 * Generous ceiling against abuse. Applied AFTER express.static so the SPA's
 * many asset requests are not counted — residents behind one building's NAT
 * share an IP, so this stays high enough not to lock them out.
 */
const globalLimiter = rateLimit({
  ...base, windowMs: 15 * 60 * 1000, max: 1000,
  message: tooMany(),
});

/** Login / password endpoints — brute-force protection. */
const authLimiter = rateLimit({
  ...base, windowMs: 15 * 60 * 1000, max: 50,
  message: tooMany('Too many attempts. Please wait and try again.'),
});

/*
 * OTP request + verify — strict, keyed by IP *and* mobile so one number cannot
 * be sprayed and one IP cannot fan out across numbers. Mirrors the server-side
 * OTP_MAX_PER_HOUR cap in SQL, at the edge.
 */
const otpLimiter = rateLimit({
  ...base, windowMs: 10 * 60 * 1000, max: 5,
  keyGenerator: (req) => `${ipKeyGenerator(req.ip)}:${(req.body && req.body.mobile) || ''}`,
  message: tooMany('Too many verification code requests. Please wait a few minutes.'),
});

/** Payment order-creation and verification. */
const paymentLimiter = rateLimit({
  ...base, windowMs: 10 * 60 * 1000, max: 20,
  message: tooMany('Too many payment attempts. Please wait and try again.'),
});

module.exports = { securityHeaders, globalLimiter, authLimiter, otpLimiter, paymentLimiter };
