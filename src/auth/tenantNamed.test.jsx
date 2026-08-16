import { describe, expect, it } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider, useAuth } from '@/auth/AuthContext.jsx';
import { writeSession, clearSession } from '@/api/client';

/*
 * `tenantNamed` is what stops a society that has already been set up from being
 * shown the setup wizard again.
 *
 * Getting it wrong is not cosmetic in either direction. False negative: an
 * account that finished setup signs in and lands back on an empty four-step
 * wizard, and submitting it re-runs the first-time setup over a live society.
 * False positive: an account that genuinely needs setup is bounced to a
 * dashboard for a tenant that does not exist yet.
 */
function Probe() {
  const { tenantNamed } = useAuth();
  return <span data-testid="named">{String(tenantNamed)}</span>;
}

function renderWith(user) {
  clearSession();
  writeSession({
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresAt: new Date(Date.now() + 3600e3).toISOString(),
    user,
  });
  return render(
    <MemoryRouter>
      <AuthProvider>
        <Probe />
      </AuthProvider>
    </MemoryRouter>,
  );
}

const named = () => screen.getByTestId('named').textContent;

describe('tenantNamed', () => {
  it('is true once the society has a name', async () => {
    renderWith({ user_id: 1, society_id: 'C10001', society_name: 'Radha CHS' });
    await waitFor(() => expect(named()).toBe('true'));
  });

  it('is true once the village has a name', async () => {
    renderWith({ user_id: 1, village_id: 'V10001', village_name: 'Wayri' });
    await waitFor(() => expect(named()).toBe('true'));
  });

  /*
   * The state that sends an account to the wizard: the tenant row exists — the
   * registration created it — but it has not been filled in yet.
   */
  it('is false for a tenant that exists but has never been named', async () => {
    renderWith({ user_id: 1, society_id: 'C10001', society_name: null });
    await waitFor(() => expect(named()).toBe('false'));
  });

  it('is false when the name is only whitespace', async () => {
    renderWith({ user_id: 1, society_id: 'C10001', society_name: '   ' });
    await waitFor(() => expect(named()).toBe('false'));
  });

  it('is false when there is no session at all', async () => {
    clearSession();
    render(
      <MemoryRouter>
        <AuthProvider>
          <Probe />
        </AuthProvider>
      </MemoryRouter>,
    );
    await waitFor(() => expect(named()).toBe('false'));
  });
});
