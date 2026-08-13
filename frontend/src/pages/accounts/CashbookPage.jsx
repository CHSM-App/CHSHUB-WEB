import { useCallback, useEffect, useMemo, useState } from 'react';
import { accounts } from '@/api/modules';
import { EmptyState, ErrorNotice, Field, Spinner } from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';

const money = (v) =>
  v == null || v === '' ? '' : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

const firstOfYear = () => `${new Date().getFullYear()}-01-01`;
const today = () => new Date().toISOString().slice(0, 10);

const dayOf = (v) => (v ? new Date(v).toLocaleDateString() : '');

// ExportToolbar reads raw row values, so dates and amounts are formatted here
// rather than being taken from the rendered cells.
const EXPORT_COLUMNS = [
  { key: 'Date', label: 'Date', exportValue: (r) => dayOf(r.Date) },
  { key: 'Particular', label: 'Particular' },
  { key: 'Debit', label: 'Debit', exportValue: (r) => money(r.Debit) },
  { key: 'Credit', label: 'Credit', exportValue: (r) => money(r.Credit) },
];

/**
 * Cashbook for a date range. sp_cashbook returns opening balance (seq 1),
 * transactions (seq 2) and closing balance (seq 3) in one result set.
 */
export default function CashbookPage() {
  const [from, setFrom] = useState(firstOfYear);
  const [to, setTo] = useState(today);
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(async (f, t) => {
    setLoading(true);
    setError(null);
    try {
      setData(await accounts.cashbook(f, t));
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(from, to);
    // Initial load only; later loads come from the form.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onSubmit = (e) => {
    e.preventDefault();
    load(from, to);
  };

  const rows = data?.items ?? [];

  // Totals over the transactions only — seq 1 and 3 are the opening and
  // closing balances, and adding those in would count the period twice.
  const totals = useMemo(
    () =>
      rows
        .filter((r) => Number(r.seq) === 2)
        .reduce(
          (acc, r) => ({
            debit: acc.debit + Number(r.Debit || 0),
            credit: acc.credit + Number(r.Credit || 0),
          }),
          { debit: 0, credit: 0 },
        ),
    [rows],
  );

  return (
    <section>
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">Cashbook</h1>
        <p className="text-sm text-slate-500">Receipts and payments over a date range.</p>
      </header>

      <form onSubmit={onSubmit} className="card mb-4 flex flex-wrap items-end gap-3 p-4">
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

      <ErrorNotice error={error} />

      <div className="card overflow-hidden">
        {loading ? (
          <Spinner />
        ) : rows.length === 0 ? (
          <EmptyState title="No cashbook entries" hint="Try a wider date range." />
        ) : (
          <>
            {/* cashbook.aspx carried a PDF export; Excel and Print come with
                the shared toolbar. */}
            <ExportToolbar
              columns={EXPORT_COLUMNS}
              rows={rows}
              exportName="cashbook"
              exportTitle="Cashbook"
            />
            <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  <th className="table-head">Date</th>
                  <th className="table-head">Particular</th>
                  <th className="table-head text-right">Debit</th>
                  <th className="table-head text-right">Credit</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => {
                  // seq 1 and 3 are the opening and closing balances.
                  const isBalance = Number(row.seq) !== 2;
                  return (
                    <tr key={i} className={isBalance ? 'bg-slate-50 font-medium' : 'hover:bg-slate-50'}>
                      <td className="table-cell" data-label="Date">{dayOf(row.Date)}</td>
                      <td className="table-cell" data-label="Particular">{row.Particular}</td>
                      <td className="table-cell text-right" data-label="Debit">{money(row.Debit)}</td>
                      <td className="table-cell text-right" data-label="Credit">{money(row.Credit)}</td>
                    </tr>
                  );
                })}
              </tbody>
              {/* The legacy page ended its grid with a totals row; without it
                  the debit and credit sides cannot be compared at a glance. */}
              <tfoot>
                <tr className="border-t-2 border-slate-300 bg-blue-50 font-semibold">
                  <td className="table-cell" colSpan={2}>
                    Total
                  </td>
                  <td className="table-cell text-right">{money(totals.debit)}</td>
                  <td className="table-cell text-right">{money(totals.credit)}</td>
                </tr>
              </tfoot>
            </table>
            </div>
          </>
        )}
      </div>
    </section>
  );
}
