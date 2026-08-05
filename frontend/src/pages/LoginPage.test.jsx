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
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    expect(await screen.findByRole('heading', { name: /dashboard/i })).toBeInTheDocument();
    await waitFor(() => expect(readSession()?.accessToken).toBe('access-1'));
  });

  it('shows the server error and stays on the page for bad credentials', async () => {
    const user = userEvent.setup();
    renderLogin();

    await user.type(screen.getByLabelText(/username/i), 'admin');
    await user.type(screen.getByLabelText(/^password/i), 'wrong');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    expect(await screen.findByRole('alert')).toHaveTextContent(/invalid username or password/i);
    expect(screen.queryByRole('heading', { name: /dashboard/i })).not.toBeInTheDocument();
    expect(readSession()).toBeNull();
  });

  it('keeps submit disabled until both fields are filled', async () => {
    const user = userEvent.setup();
    renderLogin();

    const submit = screen.getByRole('button', { name: /sign in/i });
    expect(submit).toBeDisabled();

    await user.type(screen.getByLabelText(/username/i), 'admin');
    expect(submit).toBeDisabled();

    await user.type(screen.getByLabelText(/^password/i), 'correct');
    expect(submit).toBeEnabled();
  });
});
