import { useEffect, useRef } from 'react';

export function Spinner({ label = 'Loading…' }) {
  return (
    <div className="flex items-center justify-center gap-3 py-10 text-sm text-slate-500" role="status">
      <span className="h-4 w-4 animate-spin rounded-full border-2 border-slate-300 border-t-blue-600" />
      {label}
    </div>
  );
}

export function ErrorNotice({ error, onRetry }) {
  if (!error) return null;
  return (
    <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-800" role="alert">
      <p className="font-medium">{error.message}</p>
      {error.details ? (
        <pre className="mt-2 overflow-x-auto text-xs opacity-80">
          {JSON.stringify(error.details, null, 2)}
        </pre>
      ) : null}
      {onRetry ? (
        <button type="button" className="btn-secondary mt-3" onClick={onRetry}>
          Try again
        </button>
      ) : null}
    </div>
  );
}

export function EmptyState({ title, hint, action }) {
  return (
    <div className="px-4 py-12 text-center">
      <p className="text-sm font-medium text-slate-700">{title}</p>
      {hint ? <p className="mt-1 text-sm text-slate-500">{hint}</p> : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  );
}

export function Field({ label, error, required, children, hint }) {
  return (
    <label className="block">
      <span className="field-label">
        {label}
        {required ? <span className="ml-0.5 text-red-500">*</span> : null}
      </span>
      {children}
      {hint && !error ? <span className="mt-1 block text-xs text-slate-500">{hint}</span> : null}
      {error ? <span className="field-error">{error}</span> : null}
    </label>
  );
}

/**
 * Modal dialog. Closes on Escape and restores focus to whatever opened it, so
 * keyboard and screen-reader users are not stranded behind the overlay.
 */
export function Modal({ open, title, onClose, children, footer }) {
  const panelRef = useRef(null);
  const openerRef = useRef(null);

  // Callers pass an inline arrow for onClose, so its identity changes on every
  // render. Keep it in a ref and depend only on `open`, otherwise the effect
  // below re-runs on each keystroke and pulls focus off the field being typed
  // into — leaving only the first character.
  const onCloseRef = useRef(onClose);
  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    if (!open) return undefined;
    openerRef.current = document.activeElement;

    const onKeyDown = (e) => {
      if (e.key === 'Escape') onCloseRef.current?.();
    };
    document.addEventListener('keydown', onKeyDown);
    panelRef.current?.focus();

    return () => {
      document.removeEventListener('keydown', onKeyDown);
      openerRef.current?.focus?.();
    };
  }, [open]);

  if (!open) return null;

  /*
   * The panel is capped at the viewport height and scrolls its own body, so the
   * header and footer stay put however long the form is.
   *
   * Centring the panel while letting it grow past the viewport is what broke
   * this before: an over-tall dialog overflowed equally off the top and bottom,
   * cutting off its own title and putting Save out of reach.
   */
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-900/40 p-4 sm:items-center">
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="card flex max-h-[calc(100vh-2rem)] w-full max-w-2xl flex-col outline-none"
      >
        <header className="flex shrink-0 items-center justify-between border-b border-slate-200 px-5 py-3">
          <h2 className="text-base font-semibold text-slate-800">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
          >
            ✕
          </button>
        </header>
        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-4">{children}</div>
        {footer ? (
          <footer className="flex shrink-0 justify-end gap-2 border-t border-slate-200 px-5 py-3">
            {footer}
          </footer>
        ) : null}
      </div>
    </div>
  );
}

export function ConfirmDialog({ open, title, message, confirmLabel = 'Delete', onConfirm, onCancel, busy }) {
  return (
    <Modal
      open={open}
      title={title}
      onClose={onCancel}
      footer={
        <>
          <button type="button" className="btn-secondary" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button type="button" className="btn-danger" onClick={onConfirm} disabled={busy}>
            {busy ? 'Working…' : confirmLabel}
          </button>
        </>
      }
    >
      <p className="text-sm text-slate-600">{message}</p>
    </Modal>
  );
}
