import { cloneElement, isValidElement, useEffect, useId, useRef } from 'react';
import { createPortal } from 'react-dom';

export function Spinner({ label = 'Loading…' }) {
  return (
    <div className="flex items-center justify-center gap-3 py-10 text-sm text-slate-500" role="status">
      <span className="h-4 w-4 animate-spin rounded-full border-2 border-slate-300 border-t-[#c94040]" />
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
  /*
   * The info tone stays blue rather than following the brand red. Red is now
   * the accent AND (deeper) the danger colour, so a red-tinted notice reads as
   * a failure — which is the opposite of what this component is for. Blue here
   * is carrying meaning, not brand.
   */
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

/**
 * How much of the form is still unanswered, shown above it.
 *
 * On a two-column form the offending field can sit well below the fold, so
 * pressing Save looked like it did nothing at all. A count is the difference
 * between "something is wrong somewhere" and "three fields, and here is the
 * first" — the submit handler scrolls to that first one.
 */
export function FormErrorSummary({ count }) {
  if (!count) return null;
  return (
    <div
      className="sm:col-span-2 flex items-start gap-2.5 rounded-md border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm text-red-800"
      role="alert"
    >
      <svg viewBox="0 0 16 16" className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true">
        <circle cx="8" cy="8" r="6.6" fill="none" stroke="currentColor" strokeWidth="1.5" />
        <path d="M8 4.8v3.6m0 2.3h.01" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      </svg>
      <p className="font-medium">
        {count === 1
          ? 'One required field still needs filling in.'
          : `${count} required fields still need filling in.`}
      </p>
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

/**
 * One labelled control, with its hint and its complaint.
 *
 * The asterisk alone was doing all the work of marking a field mandatory, and
 * a rejected field looked exactly like an accepted one apart from a line of
 * small text underneath. `data-invalid` on the wrapper lets the control itself
 * turn red (see .field-input in index.css) so the eye lands on the problem
 * rather than hunting for the message.
 */
export function Field({ label, error, required, children, hint, htmlFor, name }) {
  const generatedId = useId();
  const errorId = `${generatedId}-error`;
  const hintId = `${generatedId}-hint`;

  /*
   * WCAG 3.3.1 wants the error identified in text and tied to the control that
   * caused it — a red border and a line of prose sitting nearby satisfies a
   * sighted user and nobody else. Field renders the message but not the input,
   * so the wiring is handed down to whatever it was given: a function child
   * receives the ids, and a plain element is cloned with them.
   *
   * describedBy points at the error when there is one and the hint otherwise;
   * both at once would read the format advice before the complaint.
   */
  const describedBy = error ? errorId : hint ? hintId : undefined;
  const ariaProps = {
    'aria-invalid': error ? true : undefined,
    'aria-describedby': describedBy,
  };
  const control =
    typeof children === 'function'
      ? children(ariaProps)
      : isValidElement(children)
        ? cloneElement(children, ariaProps)
        : children;

  /*
   * `name` is the field key this box answers for. focusFirstInvalid looks for
   * [data-field="key"] to scroll to, and the screens that wrap a bare <input>
   * in a Field have no other anchor — the input carries no name or id of its
   * own, so a failed submit marked the box and then jumped nowhere.
   */
  return (
    <label
      className="block rounded-md"
      data-invalid={error ? '' : undefined}
      data-field={name}
      htmlFor={htmlFor}
    >
      <span className="field-label">
        {label}
        {/* aria-hidden: the asterisk is a visual shorthand. Screen readers get
            "required" from the control's own required attribute, and would
            otherwise read the label as "Name star". */}
        {required ? (
          <span className="ml-0.5 text-red-500" aria-hidden="true">
            *
          </span>
        ) : null}
        {required ? <span className="sr-only"> (required)</span> : null}
      </span>
      {control}
      {hint && !error ? (
        <span id={hintId} className="mt-1 block text-xs text-slate-500">
          {hint}
        </span>
      ) : null}
      {/* role="alert" so the complaint is announced when it appears, rather
          than sitting silently below a field the user has already left. */}
      {/* The warning mark comes from .field-error itself, so every control's
          complaint looks the same — see the rule in index.css. */}
      {error ? (
        <span id={errorId} className="field-error" role="alert">
          {error}
        </span>
      ) : null}
    </label>
  );
}

/**
 * Modal dialog. Closes on Escape and restores focus to whatever opened it, so
 * keyboard and screen-reader users are not stranded behind the overlay.
 */
export function Modal({
  open,
  title,
  description,
  onClose,
  children,
  footer,
  maxWidth = 'max-w-2xl',
  closeOnBackdrop = true,
}) {
  const panelRef = useRef(null);
  const openerRef = useRef(null);
  // Ids for aria-labelledby/aria-describedby. Generated per instance so two
  // dialogs mounted at once do not point at each other's heading.
  const headingId = useId();
  const descriptionId = useId();

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

    /*
     * Tab must not walk out of an open dialog. Without this the third Tab from
     * the last field lands on the sidebar behind the overlay — the user is
     * typing into a page they cannot see, with the dialog still covering it.
     * Everything focusable inside the panel is collected on each keypress
     * rather than once, since `showIf` fields appear and disappear as the form
     * is filled in.
     */
    const focusablesIn = (root) =>
      Array.from(
        root.querySelectorAll(
          'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
        ),
        // A disabled Save or a field inside a collapsed section is in the DOM
        // but not reachable; offsetParent is null for anything display:none.
        /*
         * Drop what is in the DOM but not reachable — a field inside a section
         * the form has collapsed. `hidden` is checked rather than offsetParent
         * because jsdom lays nothing out and reports every element as hidden,
         * which would leave the trap with nothing to cycle between under test.
         */
      ).filter((el) => !el.hidden && el.getAttribute('aria-hidden') !== 'true');

    const onKeyDown = (e) => {
      if (e.key === 'Escape') {
        onCloseRef.current?.();
        return;
      }
      if (e.key !== 'Tab') return;

      const panel = panelRef.current;
      if (!panel) return;
      const focusables = focusablesIn(panel);
      if (!focusables.length) {
        // Nothing to land on — keep focus on the panel itself.
        e.preventDefault();
        panel.focus();
        return;
      }
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement;

      // Wrap at both ends, and pull focus back in if it somehow escaped.
      if (e.shiftKey && (active === first || active === panel || !panel.contains(active))) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && (active === last || !panel.contains(active))) {
        e.preventDefault();
        first.focus();
      }
    };

    document.addEventListener('keydown', onKeyDown);

    /*
     * Freeze the page behind the overlay. Scrolling the dialog to its end and
     * carrying on scrolling used to hand the wheel to the list underneath, so
     * the page crept away behind a dialog the user had not finished with. The
     * scrollbar is replaced by padding of the same width, otherwise removing it
     * widens the page and everything jumps sideways as the dialog opens.
     */
    const { body } = document;
    const previousOverflow = body.style.overflow;
    const previousPadding = body.style.paddingRight;
    const scrollbar = window.innerWidth - document.documentElement.clientWidth;
    body.style.overflow = 'hidden';
    if (scrollbar > 0) body.style.paddingRight = `${scrollbar}px`;

    // Printing while a dialog is open should give the dialog, not the page
    // behind it — see the print rules in index.css.
    body.classList.add('modal-open');

    // Start on the first real control rather than the panel, so a keyboard user
    // is already in the form. The panel stays the fallback for an empty dialog.
    const inPanel = focusablesIn(panelRef.current ?? document.body);
    /*
     * A field or an action, never the ✕ — landing on Close first offers the
     * user the exit before the thing they opened the dialog to do.
     *
     * data-modal-autofocus, not the autoFocus prop: React consumes autoFocus
     * and focuses the node itself rather than leaving an attribute behind, so
     * there is nothing here to match on — and its focus call would race this
     * one anyway. The attribute lets a caller nominate the control that should
     * start focused (ConfirmDialog puts the decision itself under the cursor).
     */
    const initial =
      inPanel.find((el) => el.dataset.modalAutofocus !== undefined) ??
      inPanel.find((el) => el.dataset.modalClose === undefined);
    (initial ?? panelRef.current)?.focus();

    return () => {
      document.removeEventListener('keydown', onKeyDown);
      body.classList.remove('modal-open');
      body.style.overflow = previousOverflow;
      body.style.paddingRight = previousPadding;
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
    <div
      className="modal-root modal-backdrop fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-slate-900/50 p-4 backdrop-blur-[2px] sm:items-center print:static print:block print:overflow-visible print:bg-transparent print:p-0"
      /*
       * Clicking the dark surround closes, the way every dialog of this kind
       * behaves. Guarded on the target being the backdrop itself: a click that
       * starts inside the panel and drifts out — selecting text in a field and
       * releasing past the edge — used to close the form and lose the entry.
       */
      onMouseDown={(e) => {
        if (closeOnBackdrop && e.target === e.currentTarget) onClose?.();
      }}
    >
      <div
        ref={panelRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        aria-labelledby={headingId}
        aria-describedby={description ? descriptionId : undefined}
        // Stops a mousedown inside the panel reaching the backdrop handler.
        onMouseDown={(e) => e.stopPropagation()}
        className={`card modal-panel flex max-h-[calc(100vh-2rem)] w-full ${maxWidth} flex-col outline-none print:block print:max-h-none print:max-w-none print:border-0 print:shadow-none`}
      >
        <header className="flex shrink-0 items-start justify-between gap-4 border-b border-slate-200 px-5 py-3.5 print:hidden">
          <div className="min-w-0">
            <h2 id={headingId} className="text-base font-semibold text-slate-800">
              {title}
            </h2>
            {/* Room for the one line of context a dense form needs, without
                each screen inventing its own header markup. */}
            {description ? (
              <p id={descriptionId} className="mt-0.5 text-sm text-slate-500">
                {description}
              </p>
            ) : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            // Marks this as the exit, so the initial-focus pass above can skip
            // it without matching on the label text.
            data-modal-close=""
            className="-mr-1 shrink-0 rounded-md p-1.5 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#c94040]"
          >
            <svg viewBox="0 0 16 16" className="h-4 w-4" aria-hidden="true">
              <path d="m4 4 8 8M12 4l-8 8" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
          </button>
        </header>
        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-4 print:overflow-visible print:p-0">
          {children}
        </div>
        {/* The buttons are for the screen; they would only take up paper. */}
        {footer ? (
          <footer className="flex shrink-0 flex-wrap justify-end gap-2 border-t border-slate-200 bg-slate-50/70 px-5 py-3 print:hidden">
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

/**
 * The stop-and-think dialog before something irreversible.
 *
 * `tone` picks the icon and the confirm button: 'danger' for a delete, 'warning'
 * for a run that cannot be undone but destroys nothing, 'info' for a plain
 * are-you-sure. The icon is what makes the weight of the action readable before
 * the sentence is — a red triangle and a blue circle are not the same prompt.
 */
export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Delete',
  onConfirm,
  onCancel,
  busy,
  tone = 'danger',
}) {
  const palette = CONFIRM_TONES[tone] ?? CONFIRM_TONES.danger;

  return (
    <Modal
      open={open}
      title={title}
      onClose={onCancel}
      maxWidth="max-w-md"
      // A misplaced click outside must not confirm or cancel something
      // irreversible — this one closes on the button or Escape only.
      closeOnBackdrop={false}
      footer={
        <>
          <button type="button" className="btn-secondary" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button
            type="button"
            className={palette.button}
            onClick={onConfirm}
            disabled={busy}
            // The dialog is up because this is the decision to make, so it
            // takes focus — Enter confirms without reaching for the mouse.
            // Read by Modal's initial-focus pass; see the note there on why
            // this is not the autoFocus prop.
            data-modal-autofocus=""
          >
            {busy ? (
              <span className="flex items-center gap-2">
                <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white/40 border-t-white" />
                Working…
              </span>
            ) : (
              confirmLabel
            )}
          </button>
        </>
      }
    >
      <div className="flex gap-4">
        <span
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
          style={{ backgroundColor: palette.tint, color: palette.accent }}
          aria-hidden="true"
        >
          <svg viewBox="0 0 20 20" className="h-5 w-5">
            {palette.icon}
          </svg>
        </span>
        <div className="min-w-0 pt-0.5">
          <p className="text-sm text-slate-600">{message}</p>
        </div>
      </div>
    </Modal>
  );
}

const CONFIRM_TONES = {
  danger: {
    accent: '#dc3545',
    tint: '#fdeaec',
    button: 'btn-danger',
    icon: (
      <path
        d="M10 3.5 2.5 16.5h15L10 3.5Zm0 5v3.2m0 2.3h.01"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    ),
  },
  warning: {
    accent: '#b8860b',
    tint: '#fdf4e0',
    button: 'btn-primary',
    icon: (
      <>
        <circle cx="10" cy="10" r="7.2" fill="none" stroke="currentColor" strokeWidth="1.6" />
        <path d="M10 6.2v4.4m0 2.6h.01" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      </>
    ),
  },
  info: {
    accent: '#a82a2a',
    tint: '#e6efff',
    button: 'btn-primary',
    icon: (
      <>
        <circle cx="10" cy="10" r="7.2" fill="none" stroke="currentColor" strokeWidth="1.6" />
        <path d="M10 9.2v4.2m0-6.6h.01" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
      </>
    ),
  },
};
