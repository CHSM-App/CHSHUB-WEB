// Website API — HTTP helpers.
//
// The mobile API returns bare arrays and ad-hoc { error } objects. The website
// API uses a consistent envelope so the React client can handle every response
// the same way:
//
//   success -> { ok: true, data }
//   failure -> { ok: false, error: { message, code?, details? } }

/** An error carrying an HTTP status, thrown by route handlers and validators. */
class ApiError extends Error {
  constructor(status, message, { code, details } = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.code = code;
    this.details = details;
  }

  static badRequest(message, details) {
    return new ApiError(400, message, { code: 'BAD_REQUEST', details });
  }
  static unauthorized(message = 'Authentication required') {
    return new ApiError(401, message, { code: 'UNAUTHORIZED' });
  }
  static forbidden(message = 'Not permitted') {
    return new ApiError(403, message, { code: 'FORBIDDEN' });
  }
  static notFound(message = 'Not found') {
    return new ApiError(404, message, { code: 'NOT_FOUND' });
  }
  static conflict(message, details) {
    return new ApiError(409, message, { code: 'CONFLICT', details });
  }
}

function ok(res, data, status = 200) {
  return res.status(status).json({ ok: true, data });
}

/**
 * Wrap an async handler so a rejected promise reaches the error middleware
 * instead of hanging the request. Express 4 does not do this for us.
 */
function asyncHandler(fn) {
  return function wrapped(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/** Terminal error middleware for the website API. */
function errorHandler(err, req, res, _next) {
  if (err instanceof ApiError) {
    return res.status(err.status).json({
      ok: false,
      error: { message: err.message, code: err.code, details: err.details },
    });
  }

  // Anything else is unexpected: log it in full, but never leak SQL text,
  // connection strings or stack traces to the client.
  console.error(`[web-api] ${req.method} ${req.originalUrl}`, err);
  return res.status(500).json({
    ok: false,
    error: { message: 'Internal server error', code: 'INTERNAL' },
  });
}

function notFoundHandler(req, res) {
  return res.status(404).json({
    ok: false,
    error: { message: `No such endpoint: ${req.method} ${req.originalUrl}`, code: 'NOT_FOUND' },
  });
}

module.exports = { ApiError, ok, asyncHandler, errorHandler, notFoundHandler };
