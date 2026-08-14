import { useId, useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice } from '@/components/ui.jsx';
import { AuthLink, AuthSubmit, Glyph } from '@/components/AuthLayout.jsx';
import AuthShowcaseLayout from '@/components/AuthShowcaseLayout.jsx';

const USER_ICON = <path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM4 20a8 8 0 0 1 16 0" />;
const LOCK_ICON = (
  <path d="M6 10V8a6 6 0 1 1 12 0v2M5 10h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1Z" />
);

/*
 * A filled input carrying a leading glyph and, optionally, a trailing action.
 *
 * The design puts no visible label above these boxes, so the label is rendered
 * for assistive tech only and the placeholder carries it visually — without the
 * sr-only label the icon would be the only thing naming the field, and an icon
 * names nothing to a screen reader.
 */
function ShowcaseField({ label, icon, action, ...rest }) {
  const generatedId = useId();
  const id = `login-${rest.name || generatedId}`;
  return (
    <div>
      <label htmlFor={id} className="sr-only">
        {label}
      </label>
      <div className="login-field">
        <span className="login-field__icon" aria-hidden="true">
          <Glyph size={19}>{icon}</Glyph>
        </span>
        <input id={id} className="login-field__input" {...rest} />
        {action ? <div className="login-field__action">{action}</div> : null}
      </div>
    </div>
  );
}

export default function LoginPage() {
  const { login, isAuthenticated, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [revealed, setRevealed] = useState(false);
  const [remember, setRemember] = useState(true);
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
    <AuthShowcaseLayout
      heading="Welcome"
      tagline="to your society, online"
      title="Sign in"
      subtitle="Enter your credentials to reach your society dashboard."
      footer={
        <>
          Don&rsquo;t have an account? <AuthLink to="/register">Sign Up</AuthLink>
        </>
      }
    >
      <form onSubmit={onSubmit} className="space-y-3.5" noValidate>
        <ShowcaseField
          label="Username"
          icon={USER_ICON}
          name="username"
          autoComplete="username"
          placeholder="User Name"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          disabled={busy}
          required
        />

        <ShowcaseField
          label="Password"
          icon={LOCK_ICON}
          name="password"
          type={revealed ? 'text' : 'password'}
          autoComplete="current-password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={busy}
          required
          action={
            <button
              type="button"
              className="login-field__reveal"
              // Announces the action, not the state, so screen readers say what
              // pressing it will do.
              aria-label={revealed ? 'Hide password' : 'Show password'}
              aria-pressed={revealed}
              onClick={() => setRevealed((v) => !v)}
            >
              {revealed ? 'HIDE' : 'SHOW'}
            </button>
          }
        />

        <div className="flex items-center justify-between gap-3 pt-0.5">
          <label className="flex items-center gap-2 text-[13px] text-slate-600">
            <input
              type="checkbox"
              className="login-checkbox"
              checked={remember}
              onChange={(e) => setRemember(e.target.checked)}
              disabled={busy}
            />
            Remember me
          </label>
          <AuthLink to="/forgot-password">Forgot Password?</AuthLink>
        </div>

        <ErrorNotice error={error} />

        <div className="pt-1">
          <AuthSubmit
            className="login-submit"
            busy={busy}
            busyLabel="Signing in…"
            disabled={!username || !password}
          >
            Sign in
          </AuthSubmit>
        </div>
      </form>

      {/* The reference's "Or / Sign in with other" pair. There is no SSO behind
          this app, so "other" is the emailed one-time link rather than a
          third-party provider — the label is the reference's, and the
          destination is the only alternative sign-in that actually exists. */}
      <div className="login-divider" role="presentation">
        <span>Or</span>
      </div>

      <Link to="/forgot-password" className="login-alt-action">
        Sign in with other
      </Link>
    </AuthShowcaseLayout>
  );
}
