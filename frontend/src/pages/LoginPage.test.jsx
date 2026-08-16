import { describe, expect, it } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AuthProvider } from '@/auth/AuthContext.jsx';
import { readSession } from '@/api/client';
import LoginPage from './LoginPage.jsx';

function renderLogin() {
  return render(
    <MemoryRouter initialEntries={['/login']}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/dashboard" element={<h1>Dashboard</h1>} />
        </Routes>
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe('LoginPage', () => {
  it('signs in and redirects to the dashboard', async () => {
    const user = userEvent.setup();
    renderLogin();

    await user.type(screen.getByLabelText(/username/i), 'admin');
    await user.type(screen.getByLabelText(/^password/i), 'correct');
    await user.click(screen.getByRole('button', { name: /^login$/i }));

    expect(await screen.findByRole('heading', { name: /dashboard/i })).toBeInTheDocument();
    await waitFor(() => expect(readSession()?.accessToken).toBe('access-1'));
  });

  it('shows the server error and stays on the page for bad credentials', async () => {
    const user = userEvent.setup();
    renderLogin();

    await user.type(screen.getByLabelText(/username/i), 'admin');
    await user.type(screen.getByLabelText(/^password/i), 'wrong');
    await user.click(screen.getByRole('button', { name: /^login$/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/invalid username or password/i);
    expect(screen.queryByRole('heading', { name: /dashboard/i })).not.toBeInTheDocument();
    expect(readSession()).toBeNull();
  });

  /*
   * The submit used to be disabled until both boxes were filled. It is now
   * always enabled and an empty submit names the missing box instead — a dead
   * button says nothing about why it is dead.
   */
  it('names the empty fields instead of disabling submit', async () => {
    const user = userEvent.setup();
    renderLogin();

    const submit = screen.getByRole('button', { name: /^login$/i });
    expect(submit).toBeEnabled();

    await user.click(submit);

    expect(await screen.findByText(/enter your username/i)).toBeInTheDocument();
    expect(screen.getByText(/enter your password/i)).toBeInTheDocument();
    // Nothing was sent: a rejected submit must not reach the API.
    expect(readSession()).toBeNull();
  });

  /*
   * A username is whatever the account was created with, so the form holds no
   * opinion about its shape — a short all-digits one goes to the server like
   * any other and comes back rejected on its own merits, not on a format rule.
   */
  it('sends an all-digit username to the server instead of rejecting it', async () => {
    const user = userEvent.setup();
    renderLogin();

    await user.type(screen.getByLabelText(/username/i), '98765');
    await user.type(screen.getByLabelText(/^password/i), 'correct');
    await user.click(screen.getByRole('button', { name: /^login$/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/invalid username or password/i);
    expect(screen.queryByText(/must be 10 digits/i)).not.toBeInTheDocument();
  });

  it('clears a field complaint as soon as the box is edited', async () => {
    const user = userEvent.setup();
    renderLogin();

    await user.click(screen.getByRole('button', { name: /^login$/i }));
    expect(await screen.findByText(/enter your password/i)).toBeInTheDocument();

    await user.type(screen.getByLabelText(/^password/i), 'x');
    expect(screen.queryByText(/enter your password/i)).not.toBeInTheDocument();
  });
});
