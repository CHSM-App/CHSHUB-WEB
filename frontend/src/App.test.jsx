import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';

/*
 * The tenant guard, exercised on its own.
 *
 * App's real route tree cannot be mounted here: every page under it fetches on
 * mount, so a test of "which route wins" would turn into a test of two dozen
 * mock handlers. The guard's whole job is one comparison against the session,
 * so the tree below reproduces the nesting App uses — a RequireTenant layout
 * route wrapping tenant pages — and drives it from a stubbed context instead of
 * a real login. Keep it in step with App.jsx if that nesting changes.
 */
function RequireTenant({ kind, villageId }) {
  if ((kind === 'village') !== Boolean(villageId)) return <Navigate to="/dashboard" replace />;
  return <Outlet />;
}

function Where() {
  return <p>at {useLocation().pathname}</p>;
}

function renderAt(path, { villageId }) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/dashboard" element={<Where />} />
        <Route element={<RequireTenant kind="village" villageId={villageId} />}>
          <Route path="/village/settings" element={<Where />} />
        </Route>
        <Route element={<RequireTenant kind="society" villageId={villageId} />}>
          <Route path="/masters/buildings" element={<Where />} />
        </Route>
      </Routes>
    </MemoryRouter>,
  );
}

describe('tenant routing', () => {
  it('lets a village account reach a village page', () => {
    renderAt('/village/settings', { villageId: 'V1' });
    expect(screen.getByText('at /village/settings')).toBeInTheDocument();
  });

  it('lets a society account reach a society page', () => {
    renderAt('/masters/buildings', { villageId: null });
    expect(screen.getByText('at /masters/buildings')).toBeInTheDocument();
  });

  /*
   * The reported case: a village user logs out from /village/settings, a
   * society admin signs in, and RequireAuth's stored `from` sends them to the
   * village page. It rendered, then failed request by request — the API scopes
   * by the token's tenant, so every call 403d.
   */
  it('sends a society account away from a village page', () => {
    renderAt('/village/settings', { villageId: null });
    expect(screen.getByText('at /dashboard')).toBeInTheDocument();
  });

  it('sends a village account away from a society page', () => {
    renderAt('/masters/buildings', { villageId: 'V1' });
    expect(screen.getByText('at /dashboard')).toBeInTheDocument();
  });
});
