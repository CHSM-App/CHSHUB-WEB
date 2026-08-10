import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';

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

/**
 * An outcome worth reporting that is not a failure — "no bills generated, this
 * month is already billed". ErrorNotice would paint that red and read as a
 * breakage; saying nothing at all leaves the user watching a dialog close with
 * no idea whether anything happened.
 */
export function InfoNotice({ message, tone = 'info', onDismiss }) {
  if (!message) return null;
  const palette =
    tone === 'success'
      ? 'border-green-200 bg-green-50 text-green-800'
      : 'border-blue-200 bg-blue-50 text-blue-800';
  return (
    <div className={`flex items-start gap-3 rounded-md border p-4 text-sm ${palette}`} role="status">
      <p className="flex-1 font-medium">{message}</p>
      {onDismiss ? (
        <button
          type="button"
          className="shrink-0 text-lg leading-none opacity-60 hover:opacity-100"
          onClick={onDismiss}
          aria-label="Dismiss"
        >
          ×
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
export function Modal({ open, title, onClose, children, footer, maxWidth = 'max-w-2xl' }) {
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
    // Printing while a dialog is open should give the dialog, not the page
    // behind it — see the print rules in index.css.
    document.body.classList.add('modal-open');

    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.body.classList.remove('modal-open');
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
   *
   * The print: variants below matter for the same reason in reverse. The
   * dialog is scrolled, so on paper only the visible slice came out — a bill
   * run of twenty flats printed two. Every layer that caps the height or
   * clips the overflow is released for print, and the backdrop dropped, so
   * the whole of a long dialog lays out down the page.
   */
  const panel = (
    <div className="modal-root fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-900/40 p-4 sm:items-center print:static print:block print:overflow-visible print:bg-transparent print:p-0">
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className={`card flex max-h-[calc(100vh-2rem)] w-full ${maxWidth} flex-col outline-none print:block print:max-h-none print:max-w-none print:border-0 print:shadow-none`}
      >
        <header className="flex shrink-0 items-center justify-between border-b border-slate-200 px-5 py-3 print:hidden">
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
        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-4 print:overflow-visible print:p-0">
          {children}
        </div>
        {/* The buttons are for the screen; they would only take up paper. */}
        {footer ? (
          <footer className="flex shrink-0 justify-end gap-2 border-t border-slate-200 px-5 py-3 print:hidden">
            {footer}
          </footer>
        ) : null}
      </div>
    </div>
  );

  // Rendered on <body> rather than in place. Printing needs the app shell
  // hidden and the dialog kept; nested inside <main> those are the same
  // element, and hiding it printed a blank page.
  return createPortal(panel, document.body);
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
