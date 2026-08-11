import { useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice, Field } from '@/components/ui.jsx';
import { TextField } from '@/components/FormControls.jsx';
import { AuthLink, AuthSplitLayout, AuthSubmit } from '@/components/AuthLayout.jsx';

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

  return (
    <AuthSplitLayout
      title="Welcome to login"
      subtitle="Sign in to your society management account."
      footer={
        <>
          Don&rsquo;t have an account? <AuthLink to="/register">Sign Up</AuthLink>
        </>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field label="Username" required>
          <input
            className="field-input"
            name="username"
            autoComplete="username"
            placeholder="Username"
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
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={busy}
        />

        <div className="flex justify-end">
          <AuthLink to="/forgot-password">Forgot Password</AuthLink>
        </div>

        <ErrorNotice error={error} />

        <AuthSubmit busy={busy} busyLabel="Signing in…" disabled={!username || !password}>
          Sign In
        </AuthSubmit>
      </form>
    </AuthSplitLayout>
  );
}
