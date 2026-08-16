import { useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/auth/AuthContext.jsx';
import { ErrorNotice } from '@/components/ui.jsx';
import {
  AUTH_ICONS,
  AuthLink,
  AuthSubmit,
  Glyph,
  RevealToggle,
  ShowcaseField,
} from '@/components/AuthLayout.jsx';
import AuthShowcaseLayout from '@/components/AuthShowcaseLayout.jsx';

/**
 * The sign-in screen.
 *
 * There is one sign-in here and it is the committee's: members use the mobile
 * app, so this page has no second, member-facing mode to switch into.
 */
export default function LoginPage() {
  const { login, isAuthenticated, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [revealed, setRevealed] = useState(false);
  const [remember, setRemember] = useState(true);
  const [error, setError] = useState(null);
  const [fieldErrors, setFieldErrors] = useState({});
  const [busy, setBusy] = useState(false);

  if (!loading && isAuthenticated) {
    return <Navigate to={location.state?.from?.pathname || '/dashboard'} replace />;
  }

  /*
   * Both boxes are required, and that is the whole of it. A username is
   * whatever the account was created with — an email, a name, a contact
   * number — so the form holds no opinion about its shape; only the server
   * knows which ones exist.
   */
  const validate = () => {
    const next = {};
    const id = username.trim();

    if (!id) {
      next.username = 'Enter your username.';
    }

    if (!password) next.password = 'Enter your password.';

    return next;
  };

  const onSubmit = async (event) => {
    event.preventDefault();
    setError(null);

    const problems = validate();
    setFieldErrors(problems);
    if (Object.keys(problems).length) return;

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

  /* Clearing a box's complaint as soon as it is edited: leaving it until the
     next submit means the message still names a value that is no longer there. */
  const clearError = (field) =>
    setFieldErrors((prev) => (prev[field] ? { ...prev, [field]: undefined } : prev));

  /*
   * The footer says "Register your society", not the reference's "Contact
   * Administrator": /register is where a committee that has no account yet
   * creates one, and that is a real destination. Telling an admin who has no
   * account to contact an administrator would send them in a circle.
   */
  return (
    <AuthShowcaseLayout
      heading="Smart Management"
      tagline={
        <>
          Stronger <span className="auth-showcase-heading__accent">Community</span>
        </>
      }
      title={
        <>
          Welcome <span className="auth-showcase-title__accent">Back!</span>
        </>
      }
      subtitle="Sign in to your committee account to continue"
      footer={
        <>
          New society? <AuthLink to="/register">Register your society</AuthLink>
        </>
      }
    >
      {/* The gaps are a class rather than Tailwind's fixed space-y: the card
          sits inside a viewport-pinned frame, and on a short laptop a fixed
          rhythm is what pushes the buttons past the fold. */}
      <form onSubmit={onSubmit} className="login-form" noValidate>
        <ShowcaseField
          label="Username"
          icon={AUTH_ICONS.user}
          name="username"
          autoComplete="username"
          placeholder="Enter username"
          value={username}
          onChange={(e) => {
            setUsername(e.target.value);
            clearError('username');
          }}
          error={fieldErrors.username}
          disabled={busy}
          required
        />

        <ShowcaseField
          label="Password"
          icon={AUTH_ICONS.lock}
          name="password"
          type={revealed ? 'text' : 'password'}
          autoComplete="current-password"
          placeholder="Enter your password"
          value={password}
          onChange={(e) => {
            setPassword(e.target.value);
            clearError('password');
          }}
          error={fieldErrors.password}
          disabled={busy}
          required
          action={<RevealToggle revealed={revealed} onToggle={() => setRevealed((v) => !v)} />}
        />

        <div className="flex items-center justify-between gap-3">
          <label className="flex items-center gap-2 text-[13px] text-slate-600">
            <input
              type="checkbox"
              className="login-checkbox"
              checked={remember}
              onChange={(e) => setRemember(e.target.checked)}
              disabled={busy}
            />
            Remember Me
          </label>
          <AuthLink to="/forgot-password">Forgot Password?</AuthLink>
        </div>

        <ErrorNotice error={error} />

        {/* Not disabled until both boxes are filled: a dead button says nothing
            about WHY it is dead. Submitting an empty form runs validate() and
            names the missing box instead. */}
        <AuthSubmit className="login-submit" busy={busy} busyLabel="Signing in…">
          {/* Sign-in arrow, as in the reference — the label leads and the
              glyph follows it rather than the button opening with an icon. */}
          <Glyph size={17}>
            <path d="M15 3h3a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-3M10 17l5-5-5-5M15 12H3" />
          </Glyph>
          Login
        </AuthSubmit>
      </form>

      {/*
        No "Login as Admin" second action.

        This site IS the committee's console — members use the mobile app, and
        there is no member-facing web sign-in for a second button to lead to. A
        button that only ever reloads the screen you are already on is worse
        than no button: it reads as a door, and there is nothing behind it.
      */}
    </AuthShowcaseLayout>
  );
}
