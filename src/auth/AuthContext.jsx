import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { api, readSession, writeSession, clearSession, setAuthLostHandler } from '@/api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(() => readSession());
  // `loading` covers the initial token revalidation so protected routes don't
  // bounce to /login before we know whether the stored session is still good.
  const [loading, setLoading] = useState(() => Boolean(readSession()));

  // The axios layer clears storage when a refresh fails; mirror that into React
  // state so the UI redirects instead of rendering with a dead session.
  useEffect(() => {
    setAuthLostHandler(() => setSession(null));
    return () => setAuthLostHandler(null);
  }, []);

  // Revalidate a restored session once on mount. A stored access token may have
  // expired while the tab was closed; /auth/me either succeeds, or triggers the
  // refresh interceptor, or fails and logs us out.
  useEffect(() => {
    let cancelled = false;
    if (!readSession()) {
      setLoading(false);
      return undefined;
    }

    (async () => {
      try {
        const { user } = await api.get('/auth/me');
        if (cancelled) return;
        setSession((prev) => {
          const next = { ...(prev ?? readSession()), user };
          writeSession(next);
          return next;
        });
      } catch {
        if (!cancelled) {
          clearSession();
          setSession(null);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  const login = useCallback(async (username, password) => {
    const data = await api.post('/auth/login', {
      username,
      password,
      deviceInfo: navigator.userAgent?.slice(0, 500),
    });
    const next = {
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      expiresAt: data.expiresAt,
      user: data.user,
    };
    writeSession(next);
    setSession(next);
    return next.user;
  }, []);

  const logout = useCallback(async () => {
    const current = readSession();
    try {
      if (current?.refreshToken) {
        await api.post('/auth/logout', { refreshToken: current.refreshToken });
      }
    } catch {
      // Logging out locally matters more than the server round-trip succeeding.
    } finally {
      clearSession();
      setSession(null);
    }
  }, []);

  const value = useMemo(
    () => ({
      user: session?.user ?? null,
      societyId: session?.user?.society_id ?? null,
      villageId: session?.user?.village_id ?? null,
      isAuthenticated: Boolean(session?.accessToken),
      loading,
      login,
      logout,
    }),
    [session, loading, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
