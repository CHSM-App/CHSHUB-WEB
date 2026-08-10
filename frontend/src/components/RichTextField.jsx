import { useEffect, useRef, useState } from 'react';

/**
 * Small formatting editor — replaces the TinyMCE box the legacy meeting and
 * notice modals loaded from a CDN.
 *
 * Built on contentEditable rather than pulling in an editor package: the
 * legacy toolbar people actually used was bold/italic, alignment and lists,
 * and that fits in a component this size. A CDN script is not an option here
 * anyway — the app is served without one.
 *
 * The value is HTML. `details` columns are narrow (meeting_master.details is
 * nvarchar(300)), so `maxLength` counts the markup that will be stored, not
 * the visible characters, and the counter warns before a save is rejected.
 */

const COMMANDS = [
  { cmd: 'undo', label: 'Undo', icon: 'M9 14 4 9l5-5M4 9h7a6 6 0 0 1 0 12H8' },
  { cmd: 'redo', label: 'Redo', icon: 'm15 14 5-5-5-5M20 9h-7a6 6 0 0 0 0 12h3' },
  { sep: true },
  { cmd: 'bold', label: 'Bold', text: 'B', bold: true },
  { cmd: 'italic', label: 'Italic', text: 'I', italic: true },
  { sep: true },
  { cmd: 'justifyLeft', label: 'Align left', icon: 'M4 6h16M4 10h10M4 14h16M4 18h10' },
  { cmd: 'justifyCenter', label: 'Align centre', icon: 'M4 6h16M7 10h10M4 14h16M7 18h10' },
  { cmd: 'justifyRight', label: 'Align right', icon: 'M4 6h16M10 10h10M4 14h16M10 18h10' },
  { sep: true },
  { cmd: 'insertUnorderedList', label: 'Bulleted list', icon: 'M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01' },
  { cmd: 'insertOrderedList', label: 'Numbered list', icon: 'M10 6h11M10 12h11M10 18h11M4 6h1v4M4 10h2M4 16h2v3H4z' },
];

/**
 * Ordinary spaces out of what contentEditable produces.
 *
 * Browsers insert `&nbsp;` for typed spaces so trailing ones survive. That is
 * six stored characters per space against a 300-character column, and the
 * entity shows through anywhere the text is read as plain. A run of them is
 * collapsed back to real spaces; a `&nbsp;` between two other characters was
 * never meaningful here.
 */
function clean(html) {
  return html
    .replace(/(&nbsp;| )/g, ' ')
    // contentEditable also leaves a bare <br> in an otherwise empty box.
    .replace(/^(<br\s*\/?>)+$/i, '');
}

export default function RichTextField({
  label,
  value,
  onChange,
  required,
  className = '',
  maxLength,
  hint,
}) {
  const ref = useRef(null);
  const [focused, setFocused] = useState(false);

  // Only write into the DOM when the incoming value differs from what is
  // already there. Assigning innerHTML on every render would move the caret
  // to the start on each keystroke.
  useEffect(() => {
    const el = ref.current;
    if (el && el.innerHTML !== (value ?? '')) el.innerHTML = value ?? '';
  }, [value]);

  const exec = (cmd) => {
    ref.current?.focus();
    // execCommand is deprecated but is still the only cross-browser way to
    // format a contentEditable selection. jsdom does not implement it, so the
    // call is guarded rather than left to throw under test.
    document.execCommand?.(cmd, false, null);
    onChange(clean(ref.current?.innerHTML ?? ''));
  };

  const length = String(value ?? '').length;
  const over = maxLength != null && length > maxLength;

  return (
    <div className={className}>
      {label ? (
        <span className="field-label">
          {label}
          {required ? <span className="ml-0.5 text-red-500">*</span> : null}
        </span>
      ) : null}

      <div
        className={`overflow-hidden rounded-lg border bg-white ${
          over ? 'border-red-400' : focused ? 'border-blue-500' : 'border-slate-300'
        }`}
      >
        <div className="flex flex-wrap items-center gap-0.5 border-b border-slate-200 bg-slate-50 px-2 py-1">
          {COMMANDS.map((c, i) =>
            c.sep ? (
              <span key={`sep-${i}`} className="mx-1 h-5 w-px bg-slate-300" aria-hidden="true" />
            ) : (
              <button
                key={c.cmd}
                type="button"
                title={c.label}
                aria-label={c.label}
                className="flex h-7 w-7 items-center justify-center rounded text-slate-600 hover:bg-slate-200 hover:text-slate-900"
                // The editor loses focus on mousedown otherwise, and
                // execCommand then has no selection to act on.
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => exec(c.cmd)}
              >
                {c.text ? (
                  <span
                    className={`text-sm ${c.bold ? 'font-bold' : ''} ${c.italic ? 'font-serif italic' : ''}`}
                  >
                    {c.text}
                  </span>
                ) : (
                  <svg
                    viewBox="0 0 24 24"
                    width="15"
                    height="15"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    aria-hidden="true"
                  >
                    <path d={c.icon} />
                  </svg>
                )}
              </button>
            ),
          )}
        </div>

        <div
          ref={ref}
          contentEditable
          suppressContentEditableWarning
          role="textbox"
          aria-multiline="true"
          aria-label={label}
          className="min-h-[9rem] px-3 py-2 text-sm text-slate-800 focus:outline-none [&_ol]:list-decimal [&_ol]:pl-6 [&_ul]:list-disc [&_ul]:pl-6"
          onInput={(e) => onChange(clean(e.currentTarget.innerHTML))}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
      </div>

      <div className="mt-1 flex justify-between gap-3">
        <p className="text-xs text-slate-500">{hint}</p>
        {maxLength != null ? (
          <p className={`shrink-0 text-xs ${over ? 'font-medium text-red-600' : 'text-slate-400'}`}>
            {length}/{maxLength}
          </p>
        ) : null}
      </div>
    </div>
  );
}
