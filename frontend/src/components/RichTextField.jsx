import { useEffect, useRef, useState } from 'react';
import { api } from '@/api/client';

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
  { sep: true },
  // The last pair on the legacy TinyMCE toolbar: `... | link image`. Both take
  // a URL, so they prompt rather than acting on the selection alone.
  {
    cmd: 'createLink',
    label: 'Insert link',
    prompt: 'Link URL',
    icon: 'M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1',
  },
  {
    cmd: 'insertImage',
    label: 'Insert image',
    // Picks a file off the machine rather than asking for a URL: the images
    // people paste into terms and notices are their own, not ones already
    // hosted somewhere. Uploaded first, then inserted by its served URL.
    upload: true,
    icon: 'M3 5h18v14H3zM3 15l5-5 4 4 3-3 6 6',
  },
];

/**
 * A URL safe to place in an href or src.
 *
 * The value is stored as markup and rendered back into the page, so a
 * `javascript:` URL typed into the prompt would execute on click. Only http,
 * https and mailto survive; a bare `example.com` is assumed to be https.
 */
function safeUrl(input) {
  const raw = String(input ?? '').trim();
  if (!raw) return null;
  // Protocol-relative and scheme-bearing URLs are checked as written; anything
  // else is treated as a bare host and given a scheme before parsing.
  const candidate = /^[a-z][a-z0-9+.-]*:/i.test(raw) || raw.startsWith('//') ? raw : `https://${raw}`;
  try {
    const url = new URL(candidate, window.location.origin);
    return ['http:', 'https:', 'mailto:'].includes(url.protocol) ? url.href : null;
  } catch {
    return null;
  }
}

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
  // Where a picked image is stored. The uploads route only accepts a fixed set
  // of category folders, and 'society-documents' is the one these pages write.
  imageCategory = 'society-documents',
}) {
  const ref = useRef(null);
  const fileRef = useRef(null);
  const savedRange = useRef(null);
  const [focused, setFocused] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState(null);

  // Only write into the DOM when the incoming value differs from what is
  // already there. Assigning innerHTML on every render would move the caret
  // to the start on each keystroke.
  useEffect(() => {
    const el = ref.current;
    if (el && el.innerHTML !== (value ?? '')) el.innerHTML = value ?? '';
  }, [value]);

  const exec = (cmd, arg = null) => {
    ref.current?.focus();
    // execCommand is deprecated but is still the only cross-browser way to
    // format a contentEditable selection. jsdom does not implement it, so the
    // call is guarded rather than left to throw under test.
    document.execCommand?.(cmd, false, arg);
    onChange(clean(ref.current?.innerHTML ?? ''));
  };

  /** The caret position, before anything steals focus from the editor. */
  const rememberSelection = () => {
    const selection = window.getSelection?.();
    savedRange.current =
      selection && selection.rangeCount ? selection.getRangeAt(0).cloneRange() : null;
  };

  /** Puts the caret back where it was, so the command has somewhere to apply. */
  const restoreSelection = () => {
    if (!savedRange.current) return;
    const selection = window.getSelection?.();
    selection?.removeAllRanges();
    selection?.addRange(savedRange.current);
  };

  /**
   * Run a command that needs a URL.
   *
   * window.prompt closes the editor's selection, and createLink applied with
   * none does nothing — so the range is captured before the prompt opens and
   * restored before the command runs.
   */
  const execWithUrl = (command) => {
    rememberSelection();
    const url = safeUrl(window.prompt(command.prompt));
    if (!url) return;
    restoreSelection();
    exec(command.cmd, url);
  };

  /**
   * Upload the picked image, then insert it at the remembered caret.
   *
   * The file dialog takes focus for as long as it is open, so the selection is
   * saved on the button press rather than here.
   */
  const onPickImage = async (event) => {
    const file = event.target.files?.[0];
    // Let the same file be picked twice in a row.
    event.target.value = '';
    if (!file) return;

    setUploading(true);
    setUploadError(null);
    try {
      const body = new FormData();
      body.append('files', file);
      const data = await api.post(`/uploads/${imageCategory}`, body, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const url = data.items?.[0]?.url;
      if (!url) throw new Error('Upload did not return a file');
      restoreSelection();
      exec('insertImage', url);
    } catch (err) {
      setUploadError(err.message ?? 'Could not upload the image');
    } finally {
      setUploading(false);
    }
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
          over ? 'border-red-400' : focused ? 'border-[#e31b23]' : 'border-slate-300'
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
                disabled={c.upload && uploading}
                onClick={() => {
                  if (c.upload) {
                    // Saved now: the file dialog holds focus once it opens.
                    rememberSelection();
                    fileRef.current?.click();
                  } else if (c.prompt) {
                    execWithUrl(c);
                  } else {
                    exec(c.cmd);
                  }
                }}
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
          {uploading ? <span className="ml-1 text-xs text-slate-500">Uploading…</span> : null}
        </div>

        {/* Driven by the toolbar's image button, never focused directly. */}
        <input
          ref={fileRef}
          type="file"
          accept="image/png,image/jpeg,image/gif,image/webp"
          className="hidden"
          onChange={onPickImage}
        />

        <div
          ref={ref}
          contentEditable
          suppressContentEditableWarning
          role="textbox"
          aria-multiline="true"
          aria-label={label}
          className="min-h-[9rem] px-3 py-2 text-sm text-slate-800 focus:outline-none [&_a]:text-[#b91c1c] [&_a]:underline [&_img]:max-w-full [&_ol]:list-decimal [&_ol]:pl-6 [&_ul]:list-disc [&_ul]:pl-6"
          onInput={(e) => onChange(clean(e.currentTarget.innerHTML))}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
      </div>

      {uploadError ? (
        <p className="field-error" role="alert">
          {uploadError}
        </p>
      ) : null}

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
