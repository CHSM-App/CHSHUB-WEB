import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const BASE = '/api/web';

/** Mirror the backend's success envelope. */
export const ok = (data) => HttpResponse.json({ ok: true, data });

/** Mirror the backend's failure envelope. */
export const fail = (status, message, code = 'ERROR') =>
  HttpResponse.json({ ok: false, error: { message, code } }, { status });

export const defaultHandlers = [
  http.post(`${BASE}/auth/login`, async ({ request }) => {
    const { username, password } = await request.json();
    if (username === 'admin' && password === 'correct') {
      return ok({
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAt: new Date(Date.now() + 3600e3).toISOString(),
        user: { user_id: 1, name: 'Admin User', username: 'admin', society_id: 'C10001' },
      });
    }
    return fail(401, 'Invalid username or password', 'UNAUTHORIZED');
  }),

  http.get(`${BASE}/auth/me`, ({ request }) => {
    const auth = request.headers.get('Authorization');
    if (auth === 'Bearer access-1' || auth === 'Bearer access-2') {
      return ok({ user: { user_id: 1, name: 'Admin User', username: 'admin', society_id: 'C10001' } });
    }
    return fail(401, 'Token is invalid or has expired', 'UNAUTHORIZED');
  }),

  http.post(`${BASE}/auth/logout`, () => ok({ loggedOut: true })),
];

export const server = setupServer(...defaultHandlers);
