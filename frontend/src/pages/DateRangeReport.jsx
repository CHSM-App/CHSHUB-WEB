import { useCallback, useEffect, useState } from 'react';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';

export const money = (v) =>
  v == null || v === '' ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
export const day = (v) => (v ? new Date(v).toLocaleDateString() : '—');

const firstOfYear = () => `${new Date().getFullYear()}-01-01`;
const today = () => new Date().toISOString().slice(0, 10);

/**
 * Shared shell for the date-range reports (paid amounts, AGM, P&L, PDC
 * clearing). Handles the from/to form, loading and exporting; the caller
 * supplies how to render the result.
 *
 * `exportColumns` opts a report into the standard toolbar — Export to Excel,
 * Download PDF and Print, all three built by tableToPdf, with the period the
 * report was run for printed in the criteria box. A report that renders its own
 * ExportToolbar (cheque clearing) leaves it unset and keeps that one; nothing
 * here calls window.print(), which used to print the screen instead and so gave
 * a different sheet from the Download button beside it.
 */
export default function DateRangeReport({
  title,
  subtitle,
  load,
  render,
  exportColumns,
  // Rows to export, picked out of the loaded payload. Defaults to `items`,
  // which is the shape every one of these reports returns.
  exportRows = (d) => d?.items ?? [],
  exportName,
}) {
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
      </form>

      {/* Below the form, so the criteria box carries the period actually
          loaded rather than whatever the date boxes have been changed to. */}
      {exportColumns && data ? (
        <div className="card mb-4 overflow-hidden">
          <ExportToolbar
            columns={exportColumns}
            rows={exportRows(data)}
            exportName={exportName || 'report'}
            exportTitle={title}
            filters={[{ label: 'Period', value: `${day(from)} to ${day(to)}` }]}
          />
        </div>
      ) : null}

      <ErrorNotice error={error} />

      {/* `reload` lets a report that also writes — PDC clearing marks cheques
          — refresh itself without re-running the date form by hand. */}
      {loading ? (
        <Spinner />
      ) : data ? (
        render(data, { from, to, reload: () => run(from, to) })
      ) : (
        <EmptyState title="No data" />
      )}
    </section>
  );
}
