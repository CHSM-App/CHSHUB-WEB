import { Component } from 'react';
import { Link, useRouteError } from 'react-router-dom';

/**
 * Replaces errorPage.aspx (404) and errorPage500.aspx (500).
 *
 * The legacy pages were static markup with only a Page_Load. These do the same
 * job but also surface the error to the user and offer a way back, and the
 * boundary below catches render-time failures the WebForms pages could not.
 */
function ErrorShell({ code, title, message, detail, children }) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4">
      <div className="card w-full max-w-lg p-8 text-center">
        <p className="text-5xl font-bold text-slate-300">{code}</p>
        <h1 className="mt-3 text-lg font-semibold text-slate-800">{title}</h1>
        <p className="mt-2 text-sm text-slate-600">{message}</p>

        {detail ? (
          <pre className="mt-4 max-h-40 overflow-auto rounded bg-slate-50 p-3 text-left text-xs text-slate-600">
            {detail}
          </pre>
        ) : null}

        <div className="mt-6 flex justify-center gap-3">
          {children ?? (
            <Link to="/dashboard" className="btn-primary">
              Back to dashboard
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}

/** 404 — replaces errorPage.aspx. */
export function NotFoundPage() {
  return (
    <ErrorShell
      code="404"
      title="Page not found"
      message="The page you were looking for does not exist, or has moved."
    />
  );
}

/** 500 — replaces errorPage500.aspx. Used by the router's errorElement. */
export function ServerErrorPage() {
  const error = useRouteError?.();
  return (
    <ErrorShell
      code="500"
      title="Something went wrong"
      message="An unexpected error occurred. The problem has been logged."
      detail={import.meta.env.DEV ? error?.message : undefined}
    >
      <button type="button" className="btn-primary" onClick={() => window.location.reload()}>
        Reload page
      </button>
      <Link to="/dashboard" className="btn-secondary">
        Back to dashboard
      </Link>
    </ErrorShell>
  );
}

/**
 * Catches render errors anywhere below it, so one broken screen cannot blank
 * the whole application. WebForms had no equivalent — an unhandled exception
 * redirected to errorPage500.aspx and lost the user's context.
 */
export class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    // Left as console output: there is no client log sink configured.
    console.error('Unhandled UI error:', error, info?.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <ErrorShell
        code="500"
        title="Something went wrong"
        message="This screen failed to load. You can retry, or go back to the dashboard."
        detail={import.meta.env.DEV ? this.state.error.message : undefined}
      >
        <button
          type="button"
          className="btn-primary"
          onClick={() => this.setState({ error: null })}
        >
          Try again
        </button>
        <Link to="/dashboard" className="btn-secondary" onClick={() => this.setState({ error: null })}>
          Back to dashboard
        </Link>
      </ErrorShell>
    );
  }
}
