import { useCallback, useEffect, useState } from 'react';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';

export const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
export const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

const firstOfYear = () => `${new Date().getFullYear()}-01-01`;
const today = () => new Date().toISOString().slice(0, 10);

/**
 * Shared shell for the date-range reports (paid amounts, AGM, P&L, PDC
 * clearing). Handles the from/to form, loading and printing; the caller
 * supplies how to render the result.
 */
export default function DateRangeReport({ title, subtitle, load, render, printable = true }) {
  const [from, setFrom] = useState(firstOfYear);
  const [to, setTo] = useState(today);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const run = useCallback(
    async (f, t) => {
      setLoading(true);
      setError(null);
      try {
        setData(await load(f, t));
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    },
    [load],
  );

  useEffect(() => {
    run(from, to);
    // Initial load only; subsequent loads come from the form.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <section>
      <header className="mb-4 print:mb-2">
        <h1 className="text-lg font-semibold text-slate-800">{title}</h1>
        {subtitle ? <p className="text-sm text-slate-500">{subtitle}</p> : null}
      </header>

      <form
        onSubmit={(e) => {
          e.preventDefault();
          run(from, to);
        }}
        className="card mb-4 flex flex-wrap items-end gap-3 p-4 print:hidden"
      >
        <div className="w-44">
          <Field label="From">
            <input className="field-input" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
          </Field>
        </div>
        <div className="w-44">
          <Field label="To">
            <input className="field-input" type="date" value={to} onChange={(e) => setTo(e.target.value)} />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Show'}
        </button>
        {printable ? (
          <button type="button" className="btn-secondary" onClick={() => window.print()}>
            Print
          </button>
        ) : null}
      </form>

      <ErrorNotice error={error} />

      {loading ? <Spinner /> : data ? render(data, { from, to }) : <EmptyState title="No data" />}
    </section>
  );
}
