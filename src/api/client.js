import axios from 'axios';

// Single axios instance for the website API. Two behaviours live here so no
// screen has to think about them:
//   1. attach the access token to every request
//   2. on a 401, refresh once and replay the original request
const BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/web';

const STORAGE_KEY = 'society.session';

export function readSession() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function writeSession(session) {
  if (session) localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
  else localStorage.removeItem(STORAGE_KEY);
}

export const clearSession = () => writeSession(null);

const client = axios.create({ baseURL: BASE_URL, timeout: 30000 });

client.interceptors.request.use((config) => {
  const session = readSession();
  if (session?.accessToken) {
    config.headers.Authorization = `Bearer ${session.accessToken}`;
  }
  return config;
});

// Refresh is deduplicated: if several requests 401 at once they all await the
// same refresh call rather than each rotating the token and invalidating the
// others (the backend revokes the presented refresh token on use).
let refreshInFlight = null;
let onAuthLost = () => {};

/** Register a callback invoked when the session can no longer be recovered. */
export function setAuthLostHandler(fn) {
  onAuthLost = typeof fn === 'function' ? fn : () => {};
}

async function refreshSession() {
  const session = readSession();
  if (!session?.refreshToken) throw new Error('No refresh token');

  // Bare axios: the instance's interceptors would attach the dead access token
  // and could recurse back into this handler.
  const { data } = await axios.post(`${BASE_URL}/auth/refresh`, {
    refreshToken: session.refreshToken,
  });

  const next = {
    accessToken: data.data.accessToken,
    refreshToken: data.data.refreshToken,
    expiresAt: data.data.expiresAt,
    user: data.data.user,
  };
  writeSession(next);
  return next;
}

client.interceptors.response.use(
  (response) => response,
  async (error) => {
    const { response, config } = error;

    // Only retry a genuine auth failure, and only once per request.
    if (response?.status !== 401 || config?._retried) {
      return Promise.reject(normaliseError(error));
    }

    // A 401 from /auth/login means "wrong credentials", not "expired session" —
    // refreshing would replace that message with a refresh failure. A 401 from
    // /auth/refresh is unrecoverable by definition.
    const url = config?.url || '';
    if (url.includes('/auth/login')) {
      return Promise.reject(normaliseError(error));
    }
    if (url.includes('/auth/refresh')) {
      clearSession();
      onAuthLost();
      return Promise.reject(normaliseError(error));
    }
    // Nothing to refresh with: fail cleanly rather than throwing "No refresh token".
    if (!readSession()?.refreshToken) {
      clearSession();
      onAuthLost();
      return Promise.reject(normaliseError(error));
    }

    try {
      refreshInFlight = refreshInFlight || refreshSession().finally(() => {
        refreshInFlight = null;
      });
      const session = await refreshInFlight;

      config._retried = true;
      config.headers = { ...config.headers, Authorization: `Bearer ${session.accessToken}` };
      return client(config);
    } catch (refreshError) {
      clearSession();
      onAuthLost();
      return Promise.reject(normaliseError(refreshError));
    }
  },
);

/**
 * Collapse axios/network/API failures into one shape so components can render
 * `err.message` without unpacking response bodies.
 */
export function normaliseError(error) {
  const apiError = error?.response?.data?.error;
  if (apiError) {
    const e = new Error(apiError.message || 'Request failed');
    e.code = apiError.code;
    e.details = apiError.details;
    e.status = error.response.status;
    return e;
  }
  if (error?.response) {
    const e = new Error(`Request failed (${error.response.status})`);
    e.status = error.response.status;
    return e;
  }
  if (error?.code === 'ECONNABORTED') return new Error('The request timed out');
  return new Error(error?.message || 'Network error — is the server running?');
}

/** Unwrap the { ok, data } envelope so callers receive `data` directly. */
async function unwrap(promise) {
  const response = await promise;
  return response.data?.data ?? response.data;
}

export const api = {
  get: (url, config) => unwrap(client.get(url, config)),
  post: (url, body, config) => unwrap(client.post(url, body, config)),
  put: (url, body, config) => unwrap(client.put(url, body, config)),
  delete: (url, config) => unwrap(client.delete(url, config)),
  raw: client,
};

export default client;
