import { useEffect, useState } from 'react';
import { terms as termsApi } from '@/api/settings';
import { ErrorNotice, Spinner } from '@/components/ui.jsx';
import RichTextField from '@/components/RichTextField.jsx';

/**
 * The visible text inside the editor's HTML.
 *
 * The value is markup now, so an "empty" box still arrives as something like
 * `<p><br></p>`. Tags are stripped before the Save button decides whether
 * there is anything worth sending.
 */
const stripHtml = (html) =>
  String(html ?? '')
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .trim();

/**
 * Bill terms & conditions — the one setting Terms_and_Condition.aspx carried.
 *
 * A society keeps a single terms row, so this is a load-and-save form rather
 * than a grid: the API reuses the existing row's id on every save, the same
 * one-record rule the legacy page enforced by hiding its Add button.
 */
export default function TermsPage() {
  const [text, setText] = useState('');
  const [loading, setLoading] = useState(true);
  const [savingTerms, setSavingTerms] = useState(false);
  const [error, setError] = useState(null);
  const [savedNote, setSavedNote] = useState('');

  useEffect(() => {
    let cancelled = false;
    termsApi
      .get()
      .then((t) => {
        if (!cancelled) setText(t.current?.terms ?? '');
      })
      .catch((err) => {
        if (!cancelled) setError(err);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const saveTerms = async (event) => {
    event.preventDefault();
    setSavingTerms(true);
    setError(null);
    setSavedNote('');
    try {
      const data = await termsApi.save({ terms: text });
      setText(data.current?.terms ?? text);
      setSavedNote('Terms saved.');
    } catch (err) {
      setError(err);
    } finally {
      setSavingTerms(false);
    }
  };

  if (loading) return <Spinner />;

  return (
    <section className="max-w-3xl space-y-6">
      <div>
        <h1 className="text-lg font-semibold text-slate-800">Terms and Condition</h1>
        <p className="text-sm text-slate-500">Printed at the foot of every maintenance bill.</p>
      </div>

      <ErrorNotice error={error} />
      {savedNote ? <p className="text-sm text-green-700">{savedNote}</p> : null}

      {/* Terms_and_Condition.aspx edited this in a TinyMCE box, so the stored
          value is HTML. RichTextField is this app's replacement for that CDN
          editor — a plain textarea showed the raw markup. */}
      <form onSubmit={saveTerms} className="card p-5" noValidate>
        <RichTextField
          label="Terms &amp; conditions"
          hint="Shown at the foot of every maintenance bill"
          value={text}
          onChange={setText}
        />
        <button type="submit" className="btn-primary mt-4" disabled={savingTerms || !stripHtml(text)}>
          {savingTerms ? 'Saving…' : 'Save terms'}
        </button>
      </form>
    </section>
  );
}
