import { useEffect, useState } from 'react';
import { terms as termsApi, societyCharges } from '@/api/settings';
import { ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

/**
 * Bill terms & conditions, plus the society's own per-unit charge. Both are
 * single-row settings, so they share one page rather than two near-empty ones.
 */
export default function TermsPage() {
  const [text, setText] = useState('');
  const [charge, setCharge] = useState({ amount: '', totalUnits: '' });
  const [loading, setLoading] = useState(true);
  const [savingTerms, setSavingTerms] = useState(false);
  const [savingCharge, setSavingCharge] = useState(false);
  const [error, setError] = useState(null);
  const [savedNote, setSavedNote] = useState('');

  useEffect(() => {
    let cancelled = false;
    Promise.all([termsApi.get(), societyCharges.get()])
      .then(([t, c]) => {
        if (cancelled) return;
        setText(t.current?.terms ?? '');
        setCharge({
          amount: c.charge?.amount ?? '',
          totalUnits: c.charge?.total_unit ?? '',
        });
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

  const saveCharge = async (event) => {
    event.preventDefault();
    setSavingCharge(true);
    setError(null);
    setSavedNote('');
    try {
      const data = await societyCharges.save(charge);
      setCharge({
        amount: data.charge?.amount ?? charge.amount,
        totalUnits: data.charge?.total_unit ?? charge.totalUnits,
      });
      setSavedNote('Society charge saved.');
    } catch (err) {
      setError(err);
    } finally {
      setSavingCharge(false);
    }
  };

  const setChargeField = (key) => (e) => {
    const { value } = e.target;
    setCharge((prev) => ({ ...prev, [key]: value }));
  };

  if (loading) return <Spinner />;

  return (
    <section className="max-w-3xl space-y-6">
      <div>
        <h1 className="text-lg font-semibold text-slate-800">Terms &amp; society charge</h1>
        <p className="text-sm text-slate-500">Printed on bills, and the society&apos;s per-unit fee.</p>
      </div>

      <ErrorNotice error={error} />
      {savedNote ? <p className="text-sm text-green-700">{savedNote}</p> : null}

      <form onSubmit={saveTerms} className="card p-5" noValidate>
        <Field label="Terms &amp; conditions" hint="Shown at the foot of every maintenance bill">
          <textarea
            className="field-input min-h-[10rem] font-mono text-xs"
            value={text}
            onChange={(e) => setText(e.target.value)}
          />
        </Field>
        <button type="submit" className="btn-primary mt-4" disabled={savingTerms || !text.trim()}>
          {savingTerms ? 'Saving…' : 'Save terms'}
        </button>
      </form>

      <form onSubmit={saveCharge} className="card p-5" noValidate>
        <h2 className="mb-3 text-base font-semibold text-slate-800">Society charge</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Amount per unit" required>
            <input
              className="field-input"
              type="number"
              step="0.01"
              min="0"
              value={charge.amount}
              onChange={setChargeField('amount')}
              required
            />
          </Field>
          <Field label="Total units">
            <input
              className="field-input"
              type="number"
              min="0"
              value={charge.totalUnits}
              onChange={setChargeField('totalUnits')}
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary mt-4" disabled={savingCharge}>
          {savingCharge ? 'Saving…' : 'Save society charge'}
        </button>
      </form>
    </section>
  );
}
