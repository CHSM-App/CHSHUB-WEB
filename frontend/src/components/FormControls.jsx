import { useRef, useState } from 'react';
import { api } from '@/api/client';

/** Labelled input with inline validation message. Replaces asp:TextBox + validator. */
export function TextField({ label, error, required, hint, type = 'text', className = '', ...rest }) {
  const id = `f-${rest.name}`;
  // Password fields get a show/hide toggle, as the legacy pages did with their
  // `visibility` icon. State lives here so every password box gets it for free.
  const [revealed, setRevealed] = useState(false);
  const isPassword = type === 'password';
  const inputType = isPassword && revealed ? 'text' : type;

  return (
    <div className={className}>
      <label htmlFor={id} className="field-label">
        {label}
        {required ? <span className="ml-0.5 text-red-500">*</span> : null}
      </label>
      <div className={isPassword ? 'relative' : undefined}>
        <input
          id={id}
          type={inputType}
          className={`field-input ${isPassword ? 'pr-10' : ''} ${
            error ? 'border-red-400 focus:border-red-500 focus:ring-red-500' : ''
          }`}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? `${id}-err` : undefined}
          {...rest}
        />
        {isPassword ? (
          <button
            type="button"
            className="absolute inset-y-0 right-0 flex items-center px-3 text-slate-400 hover:text-slate-600"
            // Announces the action, not the state, so screen readers say what
            // pressing it will do.
            aria-label={revealed ? 'Hide password' : 'Show password'}
            aria-pressed={revealed}
            onClick={() => setRevealed((v) => !v)}
            tabIndex={-1}
          >
            <EyeIcon off={revealed} />
          </button>
        ) : null}
      </div>
      {hint && !error ? <p className="mt-1 text-xs text-slate-500">{hint}</p> : null}
      {error ? (
        <p id={`${id}-err`} className="field-error" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

/** Inline eye / eye-with-slash, so nothing is fetched from an icon CDN. */
function EyeIcon({ off }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width="18"
      height="18"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7Z" />
      <circle cx="12" cy="12" r="3" />
      {off ? <path d="m3 3 18 18" /> : null}
    </svg>
  );
}

/** Replaces asp:DropDownList. Options are [{value,label}] or raw rows + keys. */
export function SelectField({
  label,
  error,
  required,
  hint,
  options = [],
  valueKey = 'value',
  labelKey = 'label',
  placeholder = 'Select…',
  className = '',
  ...rest
}) {
  const id = `f-${rest.name}`;
  return (
    <div className={className}>
      <label htmlFor={id} className="field-label">
        {label}
        {required ? <span className="ml-0.5 text-red-500">*</span> : null}
      </label>
      <select
        id={id}
        className={`field-input ${error ? 'border-red-400' : ''}`}
        aria-invalid={Boolean(error)}
        {...rest}
      >
        <option value="">{placeholder}</option>
        {options.map((o) => (
          <option key={o[valueKey]} value={o[valueKey]}>
            {o[labelKey]}
          </option>
        ))}
      </select>
      {hint && !error ? <p className="mt-1 text-xs text-slate-500">{hint}</p> : null}
      {error ? (
        <p className="field-error" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function TextAreaField({ label, error, required, hint, rows = 4, className = '', ...rest }) {
  const id = `f-${rest.name}`;
  return (
    <div className={className}>
      <label htmlFor={id} className="field-label">
        {label}
        {required ? <span className="ml-0.5 text-red-500">*</span> : null}
      </label>
      <textarea
        id={id}
        rows={rows}
        className={`field-input ${error ? 'border-red-400' : ''}`}
        aria-invalid={Boolean(error)}
        {...rest}
      />
      {hint && !error ? <p className="mt-1 text-xs text-slate-500">{hint}</p> : null}
      {error ? (
        <p className="field-error" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function CheckboxField({ label, className = '', ...rest }) {
  return (
    <label className={`flex items-center gap-2 ${className}`}>
      <input type="checkbox" className="h-4 w-4 rounded border-slate-300" {...rest} />
      <span className="text-sm text-slate-700">{label}</span>
    </label>
  );
}

/** Segmented control — replaces the legacy "mode" button rows (cheque/online/cash). */
export function ModeSwitch({ label, options, value, onChange, className = '' }) {
  return (
    <div className={className}>
      {label ? <span className="field-label">{label}</span> : null}
      <div className="inline-flex flex-wrap gap-1 rounded-md border border-slate-300 bg-slate-50 p-1">
        {options.map((o) => (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            className={`rounded px-3 py-1.5 text-sm transition-colors ${
              String(value) === String(o.value)
                ? 'bg-white font-medium text-blue-700 shadow-sm'
                : 'text-slate-600 hover:bg-white/60'
            }`}
            aria-pressed={String(value) === String(o.value)}
          >
            {o.label}
          </button>
        ))}
      </div>
    </div>
  );
}

/**
 * File upload — replaces asp:FileUpload.
 * Uploads immediately to /uploads/:category and hands back the stored path,
 * which the caller then passes to the relevant save endpoint.
 */
export function FileUploadField({
  label,
  category,
  onUploaded,
  multiple = false,
  hint,
  currentPath,
  className = '',
}) {
  const inputRef = useRef(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const [uploaded, setUploaded] = useState([]);

  const onPick = async (event) => {
    const files = Array.from(event.target.files ?? []);
    if (!files.length) return;

    setBusy(true);
    setError(null);
    try {
      const body = new FormData();
      files.forEach((f) => body.append('files', f));
      const data = await api.post(`/uploads/${category}`, body, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setUploaded(data.items ?? []);
      onUploaded?.(multiple ? data.items : data.items?.[0]);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
      if (inputRef.current) inputRef.current.value = '';
    }
  };

  return (
    <div className={className}>
      {label ? <span className="field-label">{label}</span> : null}
      <div className="flex flex-wrap items-center gap-2">
        <input
          ref={inputRef}
          type="file"
          multiple={multiple}
          onChange={onPick}
          disabled={busy}
          className="block w-full text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-blue-50 file:px-3 file:py-2 file:text-sm file:font-medium file:text-blue-700 hover:file:bg-blue-100"
        />
        {busy ? <span className="text-xs text-slate-500">Uploading…</span> : null}
      </div>

      {hint && !error ? <p className="mt-1 text-xs text-slate-500">{hint}</p> : null}
      {error ? (
        <p className="field-error" role="alert">
          {error}
        </p>
      ) : null}

      {uploaded.length ? (
        <ul className="mt-2 space-y-1">
          {uploaded.map((f) => (
            <li key={f.path} className="text-xs text-green-700">
              Uploaded {f.originalName}
            </li>
          ))}
        </ul>
      ) : currentPath ? (
        <p className="mt-2 text-xs text-slate-500">Current file: {String(currentPath).split('/').pop()}</p>
      ) : null}
    </div>
  );
}

/** Tab strip — replaces the legacy category link-button rows. */
export function Tabs({ tabs, active, onChange, className = '' }) {
  return (
    <div className={`border-b border-slate-200 ${className}`}>
      <nav className="-mb-px flex flex-wrap gap-4" aria-label="Sections">
        {tabs.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => onChange(t.id)}
            className={`whitespace-nowrap border-b-2 px-1 pb-2 text-sm transition-colors ${
              active === t.id
                ? 'border-blue-600 font-medium text-blue-700'
                : 'border-transparent text-slate-500 hover:border-slate-300 hover:text-slate-700'
            }`}
            aria-current={active === t.id ? 'page' : undefined}
          >
            {t.label}
            {t.count !== undefined ? (
              <span className="ml-1.5 rounded-full bg-slate-100 px-1.5 py-0.5 text-xs text-slate-600">
                {t.count}
              </span>
            ) : null}
          </button>
        ))}
      </nav>
    </div>
  );
}

/** Page header with title, subtitle and an actions slot. */
export function PageHeader({ title, subtitle, children }) {
  return (
    <header className="mb-4 flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 className="text-xl font-bold tracking-tight" style={{ color: 'var(--ink)' }}>
          {title}
        </h1>
        {subtitle ? <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p> : null}
      </div>
      {children ? <div className="flex flex-wrap items-center gap-2 print:hidden">{children}</div> : null}
    </header>
  );
}

/**
 * Stat tile used on dashboards and summary strips.
 *
 * The tone drives a coloured top rule as well as the figure: a strip of three
 * plain white boxes gave the eye nothing to read, and the accent lets a summary
 * row be scanned at a glance without turning the tiles into full colour blocks.
 */
export function StatCard({ label, value, hint, tone = 'default' }) {
  const tones = {
    default: { text: 'text-slate-800', rule: 'linear-gradient(90deg, #6f8ff5, #4e73df)' },
    positive: { text: 'text-green-700', rule: 'linear-gradient(90deg, #34e0a1, #1cc88a)' },
    negative: { text: 'text-red-700', rule: 'linear-gradient(90deg, #ff6b6b, #e74a3b)' },
    warning: { text: 'text-amber-700', rule: 'linear-gradient(90deg, #f8d476, #f6c23e)' },
  };
  const t = tones[tone] ?? tones.default;
  // The accent is inset inside the card's border rather than laid over it: the
  // card keeps its own 1px edge and radius, and `overflow-hidden` clips the
  // strip's square corners to the rounded top.
  return (
    <div className="card relative overflow-hidden">
      <span className="absolute inset-x-0 top-0 h-1" style={{ background: t.rule }} aria-hidden="true" />
      <div className="p-4 pt-[calc(1rem+2px)]">
        <p className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</p>
        <p className={`mt-1 text-2xl font-semibold ${t.text}`}>{value}</p>
        {hint ? <p className="mt-1 text-xs text-slate-500">{hint}</p> : null}
      </div>
    </div>
  );
}
