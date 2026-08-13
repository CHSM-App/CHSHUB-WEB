import { useEffect, useState } from 'react';
import { generation } from '@/api/billing';
import { ErrorNotice, Spinner } from '@/components/ui.jsx';

const money = (v) =>
  v == null ? '—' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/**
 * Bill generation.
 *
 * The preview is read-only and safe. Actually running a generation inserts real
 * charges into maintenance_cal and is NOT reversible by any stored procedure
 * here, so the trigger stays disabled until the operation has been exercised
 * against a test database and signed off.
 *
 * Set VITE_ENABLE_BILL_GENERATION=true to enable it once that has happened.
 */
const WRITES_ENABLED = import.meta.env.VITE_ENABLE_BILL_GENERATION === 'true';

export default function GenerateBillsPage() {
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = () => {
    setLoading(true);
    setError(null);
    generation
      .preview()
      .then(setPreview)
      .catch(setError)
      .finally(() => setLoading(false));
  };

  useEffect(load, []);

  if (loading) return <Spinner label="Calculating preview…" />;

  return (
    <section className="max-w-4xl">
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">Generate bills</h1>
        <p className="text-sm text-slate-500">
          Preview of what the next bill run would charge. Nothing is written until you run it.
        </p>
      </header>

      <ErrorNotice error={error} onRetry={load} />

      {preview ? (
        <>
          {preview.warnings?.length ? (
            <div className="mb-4 rounded-md border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
              <p className="font-medium">Before generating:</p>
              <ul className="mt-1 list-inside list-disc">
                {preview.warnings.map((w) => (
                  <li key={w}>{w}</li>
                ))}
              </ul>
            </div>
          ) : null}

          <div className="grid gap-4 sm:grid-cols-3">
            <div className="card p-4">
              <p className="text-xs uppercase tracking-wide text-slate-500">Flats to bill</p>
              <p className="mt-1 text-2xl font-semibold text-slate-800">{preview.flatCount}</p>
            </div>
            <div className="card p-4">
              <p className="text-xs uppercase tracking-wide text-slate-500">Regular total</p>
              <p className="mt-1 text-2xl font-semibold text-slate-800">
                {money(preview.regular?.totalAmount)}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {money(preview.regular?.perFlatTotal)} per flat
              </p>
            </div>
            <div className="card p-4">
              <p className="text-xs uppercase tracking-wide text-slate-500">Add-on total</p>
              <p className="mt-1 text-2xl font-semibold text-slate-800">
                {money(preview.addOn?.totalAmount)}
              </p>
              <p className="mt-1 text-xs text-slate-500">
                {money(preview.addOn?.perFlatTotal)} per flat
              </p>
            </div>
          </div>

          <div className="card mt-4 overflow-hidden">
            <h2 className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-800">
              Charge heads included
            </h2>
            {preview.regular?.charges?.length ? (
              <div className="overflow-x-auto">
              <table className="min-w-full stacked-table">
                <thead>
                  <tr>
                    <th className="table-head">Charge</th>
                    <th className="table-head">Total amount</th>
                    <th className="table-head">Per flat</th>
                  </tr>
                </thead>
                <tbody>
                  {preview.regular.charges.map((c) => (
                    <tr key={c.charge_id}>
                      <td className="table-cell font-medium text-slate-800" data-label="Charge">{c.name}</td>
                      <td className="table-cell" data-label="Total amount">{money(c.amount)}</td>
                      <td className="table-cell" data-label="Per flat">{money(c.perFlat)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              </div>
            ) : (
              <p className="px-4 py-6 text-sm text-slate-500">No active regular charges configured.</p>
            )}
          </div>

          <div className="card mt-4 p-5">
            <h2 className="text-sm font-semibold text-slate-800">Run generation</h2>
            {WRITES_ENABLED ? (
              <p className="mt-1 text-sm text-slate-600">
                This inserts {preview.flatCount} bill(s) totalling {money(preview.regular?.totalAmount)}.
                It cannot be undone from this application.
              </p>
            ) : (
              <p className="mt-1 text-sm text-slate-600">
                Generation is <span className="font-medium">disabled</span> in this build. It writes
                real charges to <code className="rounded bg-slate-100 px-1">maintenance_cal</code> and
                has no undo, so it is enabled only after being verified against a test database.
              </p>
            )}
            <button type="button" className="btn-primary mt-3" disabled={!WRITES_ENABLED}>
              Generate bills
            </button>
          </div>
        </>
      ) : null}
    </section>
  );
}
