import { describe, expect, it, beforeEach } from 'vitest';
import { http } from 'msw';
import { server, ok, fail } from '@/test/server';
import { api, writeSession, readSession, clearSession } from './client';

const BASE = '/api/web';

describe('api client', () => {
  beforeEach(() => clearSession());

  it('attaches the access token to requests', async () => {
    writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1' });
    let seen = null;
    server.use(
      http.get(`${BASE}/masters/buildings`, ({ request }) => {
        seen = request.headers.get('Authorization');
        return ok({ items: [], count: 0 });
      }),
    );

    await api.get('/masters/buildings');
    expect(seen).toBe('Bearer access-1');
  });

  it('unwraps the { ok, data } envelope', async () => {
    writeSession({ accessToken: 'access-1' });
    server.use(http.get(`${BASE}/x`, () => ok({ items: [{ id: 1 }], count: 1 })));

    await expect(api.get('/x')).resolves.toEqual({ items: [{ id: 1 }], count: 1 });
  });

  it('refreshes once on 401 and replays the original request', async () => {
    writeSession({ accessToken: 'stale', refreshToken: 'refresh-1' });

    let attempts = 0;
    server.use(
      http.get(`${BASE}/masters/flats`, ({ request }) => {
        attempts += 1;
        return request.headers.get('Authorization') === 'Bearer access-2'
          ? ok({ items: [{ flat_id: 7 }], count: 1 })
          : fail(401, 'Token is invalid or has expired', 'UNAUTHORIZED');
      }),
      http.post(`${BASE}/auth/refresh`, () =>
        ok({ accessToken: 'access-2', refreshToken: 'refresh-2', expiresAt: null, user: { user_id: 1 } }),
      ),
    );

    await expect(api.get('/masters/flats')).resolves.toEqual({ items: [{ flat_id: 7 }], count: 1 });
    expect(attempts).toBe(2);
    // The rotated tokens must be persisted, not just used for the replay.
    expect(readSession().accessToken).toBe('access-2');
    expect(readSession().refreshToken).toBe('refresh-2');
  });

  it('clears the session when refreshing fails', async () => {
    writeSession({ accessToken: 'stale', refreshToken: 'dead' });
    server.use(
      http.get(`${BASE}/masters/flats`, () => fail(401, 'expired', 'UNAUTHORIZED')),
      http.post(`${BASE}/auth/refresh`, () => fail(401, 'Refresh token is invalid', 'UNAUTHORIZED')),
    );

    await expect(api.get('/masters/flats')).rejects.toThrow();
    expect(readSession()).toBeNull();
  });

  it('refreshes only once for concurrent 401s', async () => {
    writeSession({ accessToken: 'stale', refreshToken: 'refresh-1' });

    let refreshes = 0;
    server.use(
      http.get(`${BASE}/a`, ({ request }) =>
        request.headers.get('Authorization') === 'Bearer access-2' ? ok({ v: 'a' }) : fail(401, 'x'),
      ),
      http.get(`${BASE}/b`, ({ request }) =>
        request.headers.get('Authorization') === 'Bearer access-2' ? ok({ v: 'b' }) : fail(401, 'x'),
      ),
      http.post(`${BASE}/auth/refresh`, () => {
        refreshes += 1;
        return ok({ accessToken: 'access-2', refreshToken: 'refresh-2', expiresAt: null, user: {} });
      }),
    );

    const [a, b] = await Promise.all([api.get('/a'), api.get('/b')]);
    expect([a.v, b.v]).toEqual(['a', 'b']);
    // Two refreshes would revoke each other's token on the real backend.
    expect(refreshes).toBe(1);
  });

  it('surfaces the API error message', async () => {
    writeSession({ accessToken: 'access-1' });
    server.use(http.get(`${BASE}/x`, () => fail(409, 'Delete the wings in this building first', 'CONFLICT')));

    await expect(api.get('/x')).rejects.toMatchObject({
      message: 'Delete the wings in this building first',
      code: 'CONFLICT',
      status: 409,
    });
  });
});
