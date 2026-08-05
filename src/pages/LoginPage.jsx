import { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field } from '@/components/ui.jsx';
import { TextField } from '@/components/FormControls.jsx';

export default function LoginPage() {
  const { login, isAuthenticated, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [busy, setBusy] = useState(false);

  if (!loading && isAuthenticated) {
    return <Navigate to={location.state?.from?.pathname || '/dashboard'} replace />;
  }

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await login(username.trim(), password);
      navigate(location.state?.from?.pathname || '/dashboard', { replace: true });
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  // Background and gradient lifted from the legacy login1.aspx.
  return (
    <div
      className="flex min-h-screen items-center justify-center p-4"
      style={{ backgroundColor: '#f0f4f8' }}
    >
      <div className="card w-full max-w-sm p-6">
        <div className="mb-5 flex items-center gap-3">
          <div
            className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg text-center text-white"
            style={{ background: 'linear-gradient(to right, #466CD9, #5D8FEF)', lineHeight: 1.05 }}
          >
            <span className="text-xs font-bold">
              CHS
              <br />
              HUB
            </span>
          </div>
          <div>
            <h1 className="text-lg font-semibold" style={{ color: '#012970' }}>
              Sign in
            </h1>
            <p className="text-sm" style={{ color: '#6b7280' }}>
              Society Management
            </p>
          </div>
        </div>

        <form onSubmit={onSubmit} className="mt-6 space-y-4" noValidate>
          <Field label="Username" required>
            <input
              className="field-input"
              name="username"
              autoComplete="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              disabled={busy}
              required
            />
          </Field>

          {/* TextField carries the show/hide toggle, matching login1.aspx's
              `visibility` icon. */}
          <TextField
            label="Password"
            name="password"
            type="password"
            required
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={busy}
          />

          <ErrorNotice error={error} />

          <button
            type="submit"
            className="btn-primary w-full"
            style={{
              background: 'linear-gradient(to right, #466CD9, #5D8FEF)',
              borderColor: '#466CD9',
            }}
            disabled={busy || !username || !password}
          >
            {busy ? 'Signing in…' : 'Sign in'}
          </button>

          <div className="flex justify-between pt-2 text-sm">
            <Link to="/forgot-password" className="text-blue-600 hover:underline">
              Forgot password?
            </Link>
            <Link to="/register" className="text-blue-600 hover:underline">
              Create an account
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}
