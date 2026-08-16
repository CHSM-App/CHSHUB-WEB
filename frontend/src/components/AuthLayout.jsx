import { useId } from 'react';
import { Link } from 'react-router-dom';

/*
 * Shared parts for the signed-out and onboarding screens — the fields, the
 * marks and the submit. The shell they sit in is AuthShowcaseLayout; this file
 * is only the furniture that goes inside it.
 *
 * Colours read the --login-* tokens scoped to .auth-showcase-page in index.css,
 * so a change there carries to every one of these screens at once.
 */

/** A stroke-only glyph, sized to the 20px slot the panel and footer use. */
export function Glyph({ children, size = 20, className = '' }) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {children}
    </svg>
  );
}

/*
 * The glyphs the signed-out fields lead with. Kept here beside ShowcaseField
 * rather than in each page, so sign in, create account and reset password draw
 * the same mark for the same kind of box instead of each picking its own.
 */
export const AUTH_ICONS = {
  user: <path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM4 20a8 8 0 0 1 16 0" />,
  lock: (
    <path d="M6 10V8a6 6 0 1 1 12 0v2M5 10h14a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1Z" />
  ),
  mail: <path d="M3 6h18v12H3zM3 7l9 6 9-6" />,
  phone: <path d="M7 3h4l2 5-2.5 1.5a12 12 0 0 0 4 4L16 11l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 5a2 2 0 0 1 2-2Z" />,
  home: <path d="M4 20V9.5L12 4l8 5.5V20H4Zm6 0v-6h4v6" />,
  id: <path d="M4 5h16v14H4zM8 10h.01M8 14h4M14 10h2M14 14h2" />,
};

/**
 * A filled input carrying a leading glyph and, optionally, a trailing action.
 *
 * The label is VISIBLE above the box, not sr-only. A placeholder disappears the
 * moment you type into the field, so a placeholder-only form loses every one of
 * its labels exactly when someone goes back to check what they entered — and on
 * autofill it never showed them at all.
 *
 * `error` is the message the last submit left against this box. It is wired
 * through aria-describedby / aria-invalid rather than only coloured, because a
 * red ring says nothing about which rule was broken.
 */
export function ShowcaseField({ label, icon, action, error, hint, ...rest }) {
  const generatedId = useId();
  const id = `auth-${rest.name || generatedId}`;
  const messageId = error || hint ? `${id}-msg` : undefined;
  return (
    <div className="login-row">
      <label htmlFor={id} className="login-label">
        {label}
      </label>
      <div className={`login-field${error ? ' login-field--invalid' : ''}`}>
        <span className="login-field__icon" aria-hidden="true">
          <Glyph size={19}>{icon}</Glyph>
        </span>
        <input
          id={id}
          className="login-field__input"
          aria-invalid={error ? true : undefined}
          aria-describedby={messageId}
          {...rest}
        />
        {action ? <div className="login-field__action">{action}</div> : null}
      </div>
      {error ? (
        <p id={messageId} className="login-field__error" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p id={messageId} className="login-field__hint">
          {hint}
        </p>
      ) : null}
    </div>
  );
}

/**
 * The reveal toggle the password boxes carry, as its own component so every
 * password field on every signed-out screen gets the same control rather than
 * one screen having a reveal and the next not.
 *
 * An eye rather than a SHOW / HIDE word: the boxes now carry a visible label
 * above them, and a second piece of text inside the box competed with it.
 */
export function RevealToggle({ revealed, onToggle }) {
  return (
    <button
      type="button"
      className="login-field__reveal"
      // Announces the action, not the state, so screen readers say what
      // pressing it will do.
      aria-label={revealed ? 'Hide password' : 'Show password'}
      aria-pressed={revealed}
      onClick={onToggle}
    >
      <Glyph size={17}>
        {revealed ? (
          // Struck through when the password is showing: the icon says what
          // pressing it does, which is hide.
          <>
            <path d="M10.6 6.2A9.6 9.6 0 0 1 12 6c5 0 9 6 9 6a16 16 0 0 1-2.9 3.4M6.6 6.8A16.2 16.2 0 0 0 3 12s4 6 9 6a9.4 9.4 0 0 0 4.2-1M9.9 9.9a3 3 0 0 0 4.2 4.2" />
            <path d="m3 3 18 18" />
          </>
        ) : (
          <>
            <path d="M3 12s4-6 9-6 9 6 9 6-4 6-9 6-9-6-9-6Z" />
            <circle cx="12" cy="12" r="2.6" />
          </>
        )}
      </Glyph>
    </button>
  );
}

/**
 * The full CHS HUB lockup — the mark beside the name — used at the top of the
 * showcase panel where the mark alone would not say what the product is.
 */
export function BrandWordmark() {
  return (
    <div className="auth-wordmark">
      <BuildingMark size={60} />
      <div>
        <p className="auth-wordmark__name">SOCIETY</p>
        <p className="auth-wordmark__sub">Management</p>
      </div>
    </div>
  );
}

/**
 * The building glyph the signed-out screens lead with — three towers of
 * different heights over a swept baseline, drawn in the brand red.
 *
 * Filled shapes rather than Glyph's strokes: this is a logo at 46–52px, and a
 * 1.75px stroke at that size reads as a wireframe rather than as a mark.
 */
export function BuildingMark({ size = 48 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 48 48"
      fill="none"
      aria-hidden="true"
      style={{ display: 'block', flex: 'none' }}
    >
      {/* Left tower, shortest. */}
      <rect x="4" y="16" width="11" height="24" rx="1" fill="#e31b23" />
      {/* Centre tower, tallest — the one the eye reads as the building. */}
      <rect x="16.5" y="6" width="14" height="34" rx="1" fill="#b91c1c" />
      {/* Right tower, mid-height and lighter, so the group has depth. */}
      <rect x="32" y="12" width="12" height="28" rx="1" fill="#ef4444" />
      {/* Window grid, knocked out of the towers in white. */}
      <g fill="#fff" opacity="0.9">
        {[19, 24].map((x) =>
          [10, 16, 22, 28, 34].map((y) => (
            <rect key={`${x}-${y}`} x={x} y={y} width="3.5" height="3.5" rx="0.6" />
          )),
        )}
        {[7, 11.5].map((x) =>
          [20, 26, 32].map((y) => (
            <rect key={`l${x}-${y}`} x={x} y={y} width="3" height="3" rx="0.6" />
          )),
        )}
        {[35, 39.5].map((x) =>
          [16, 22, 28, 34].map((y) => (
            <rect key={`r${x}-${y}`} x={x} y={y} width="3" height="3" rx="0.6" />
          )),
        )}
      </g>
      {/* The swept baseline the reference's mark sits on. */}
      <path d="M2 43c10-3.4 34-3.4 44 0v3H2v-3Z" fill="#b91c1c" />
    </svg>
  );
}

/**
 * The single primary action on a signed-out page. --grad-accent is the
 * dashboard's own accent wash, so this button is filled with the same red the
 * tiles are; only the height and radius are raised off .btn's compact
 * table-toolbar geometry, because this is the one action on the page.
 */
export function AuthSubmit({ busy, busyLabel, disabled = false, className = '', children }) {
  return (
    <button
      type="submit"
      className={`auth-submit btn-primary w-full ${className}`}
      style={{
        background: 'var(--grad-accent)',
        borderColor: 'var(--accent-strong)',
        borderRadius: '8px',
        padding: '11px 16px',
        fontSize: '0.9375rem',
        fontWeight: 600,
        boxShadow: '0 4px 12px -2px rgba(201, 64, 64,0.4)',
      }}
      disabled={busy || disabled}
    >
      {busy ? (
        <>
          {/* Spinner rather than only a label swap: on a slow link the text
              alone leaves the button looking merely disabled. */}
          <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2.5" opacity="0.3" />
            <path
              d="M21 12a9 9 0 0 0-9-9"
              stroke="currentColor"
              strokeWidth="2.5"
              strokeLinecap="round"
            />
          </svg>
          {busyLabel}
        </>
      ) : (
        children
      )}
    </button>
  );
}

/** Link styled as the accent, used in the layout's footer slot. */
export function AuthLink({ to, children }) {
  return (
    <Link to={to} className="font-semibold hover:underline" style={{ color: 'var(--accent-strong)' }}>
      {children}
    </Link>
  );
}
