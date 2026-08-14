import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

/**
 * Transient confirmations — "Saved successfully", "Deleted", "Could not save".
 *
 * The screens had no answer at all to "did that save?": a successful submit
 * closed the modal and left the list to redraw, which looks identical to a
 * dialog dismissed by accident. Errors at least painted an ErrorNotice inside
 * the form; success said nothing.
 *
 * A toast rather than a dialog: saving is the expected outcome, so it should
 * not need dismissing. Failures stay on screen until dismissed, since those do
 * need reading.
 */

const ToastContext = createContext(null);

/**
 * Called as `toast.success('Saved')` from anywhere under the provider.
 *
 * Outside a provider this returns no-ops rather than throwing — a page rendered
 * on its own in a unit test should not fail for want of a toast host.
 */
export function useToast() {
  return useContext(ToastContext) ?? NOOP_TOAST;
}

const NOOP_TOAST = {
  show: () => {},
  success: () => {},
  error: () => {},
  info: () => {},
  dismiss: () => {},
};

const DEFAULT_DURATION = 3200;

let nextId = 0;

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  // id -> timeout handle, so a hover can pause and a dismiss can cancel.
  const timers = useRef(new Map());

  const dismiss = useCallback((id) => {
    const timer = timers.current.get(id);
    if (timer) {
      clearTimeout(timer);
      timers.current.delete(id);
    }
    // Mark it leaving first so the exit transition can run, then drop it.
    setToasts((prev) => prev.map((t) => (t.id === id ? { ...t, leaving: true } : t)));
    setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), 200);
  }, []);

  const arm = useCallback(
    (id, duration) => {
      if (!duration) return;
      const timer = setTimeout(() => dismiss(id), duration);
      timers.current.set(id, timer);
    },
    [dismiss],
  );

  const show = useCallback(
    (message, { tone = 'success', title, duration } = {}) => {
      const id = ++nextId;
      // Failures wait to be read; the rest clear themselves.
      const ttl = duration ?? (tone === 'error' ? 0 : DEFAULT_DURATION);
      setToasts((prev) => {
        // More than a handful stacked up is a runaway loop, not information.
        const next = [...prev, { id, message, tone, title, duration: ttl }];
        return next.slice(-4);
      });
      arm(id, ttl);
      return id;
    },
    [arm],
  );

  // Clear every pending timer if the provider itself unmounts.
  useEffect(() => {
    const pending = timers.current;
    return () => {
      pending.forEach((t) => clearTimeout(t));
      pending.clear();
    };
  }, []);

  const api = useMemo(
    () => ({
      show,
      dismiss,
      success: (message, opts) => show(message, { ...opts, tone: 'success' }),
      error: (message, opts) => show(message, { ...opts, tone: 'error' }),
      info: (message, opts) => show(message, { ...opts, tone: 'info' }),
    }),
    [show, dismiss],
  );

  return (
    <ToastContext.Provider value={api}>
      {children}
      <ToastViewport toasts={toasts} onDismiss={dismiss} onPause={(id) => {
        const timer = timers.current.get(id);
        if (timer) {
          clearTimeout(timer);
          timers.current.delete(id);
        }
      }} onResume={(id, duration) => arm(id, duration)} />
    </ToastContext.Provider>
  );
}

const TONES = {
  success: {
    accent: '#1cc88a',
    ring: 'rgba(28, 200, 138, 0.18)',
    icon: (
      <path d="m4 8.5 3 3L12.5 5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    ),
    defaultTitle: 'Success',
  },
  error: {
    accent: '#a4161a',
    ring: 'rgba(164, 22, 26, 0.18)',
    icon: (
      <path d="M8 4.5v4.25M8 11.4h.01" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    ),
    defaultTitle: 'Something went wrong',
  },
  /*
   * Slate, not the brand red. With a red accent an "info" toast tinted red was
   * indistinguishable from the error one beside it, and a neutral note must not
   * read as a failure.
   */
  info: {
    accent: '#475569',
    ring: 'rgba(71, 85, 105, 0.18)',
    icon: (
      <path d="M8 7.25v4.25M8 4.6h.01" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    ),
    defaultTitle: 'Note',
  },
};

/**
 * Fixed above everything, including the z-50 modal overlay — a save made from
 * inside a dialog has to be visible while that dialog is still closing.
 *
 * `pointer-events-none` on the stack with `auto` on each card keeps the empty
 * column from swallowing clicks on the page beneath it.
 */
function ToastViewport({ toasts, onDismiss, onPause, onResume }) {
  if (!toasts.length) return null;

  const stack = (
    <div
      className="pointer-events-none fixed inset-x-0 top-4 z-[100] flex flex-col items-center gap-2 px-4 print:hidden sm:inset-x-auto sm:right-6 sm:items-end"
      aria-live="polite"
      aria-atomic="false"
    >
      {toasts.map((t) => (
        <ToastCard
          key={t.id}
          toast={t}
          onDismiss={() => onDismiss(t.id)}
          onPause={() => onPause(t.id)}
          onResume={() => onResume(t.id, t.duration)}
        />
      ))}
    </div>
  );

  return createPortal(stack, document.body);
}

function ToastCard({ toast, onDismiss, onPause, onResume }) {
  const { tone, title, message, leaving, duration } = toast;
  const palette = TONES[tone] ?? TONES.info;

  // Mounted flat, then transitioned in on the next frame — a CSS transition
  // needs two different values to animate between.
  const [shown, setShown] = useState(false);
  useEffect(() => {
    const frame = requestAnimationFrame(() => setShown(true));
    return () => cancelAnimationFrame(frame);
  }, []);

  const visible = shown && !leaving;

  return (
    <div
      role={tone === 'error' ? 'alert' : 'status'}
      onMouseEnter={onPause}
      onMouseLeave={onResume}
      className={`toast-card pointer-events-auto w-full max-w-sm overflow-hidden rounded-2xl border border-slate-200 bg-white transition-all duration-200 ease-out ${
        visible ? 'translate-y-0 scale-100 opacity-100' : '-translate-y-2 scale-95 opacity-0'
      }`}
      /* Floats over the page rather than resting on it, so a true drop shadow
         rather than the moulded pair — same reasoning as the modal panel. */
      style={{ boxShadow: '0 18px 40px -10px rgba(17,24,39,0.3)' }}
    >
      <div className="flex items-start gap-3 p-3.5">
        <span
          className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-white"
          style={{ backgroundColor: palette.accent, boxShadow: `0 0 0 4px ${palette.ring}` }}
          aria-hidden="true"
        >
          <svg viewBox="0 0 16 16" className="h-4 w-4">
            {palette.icon}
          </svg>
        </span>
        <div className="min-w-0 flex-1">
          <p className="text-sm font-semibold text-slate-800">{title ?? palette.defaultTitle}</p>
          {message ? <p className="mt-0.5 break-words text-sm text-slate-600">{message}</p> : null}
        </div>
        <button
          type="button"
          onClick={onDismiss}
          aria-label="Dismiss"
          className="-mr-1 -mt-1 shrink-0 rounded p-1 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600"
        >
          <svg viewBox="0 0 16 16" className="h-3.5 w-3.5">
            <path d="m4 4 8 8M12 4l-8 8" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
          </svg>
        </button>
      </div>
      {/* Time left, as a bar that drains. Only for the ones that expire. */}
      {duration ? (
        <div className="h-0.5 w-full bg-slate-100">
          <div
            className="toast-progress h-full"
            style={{ backgroundColor: palette.accent, animationDuration: `${duration}ms` }}
          />
        </div>
      ) : null}
    </div>
  );
}
