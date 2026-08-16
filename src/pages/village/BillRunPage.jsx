import { Fragment, useCallback, useEffect, useState } from 'react';
import { village } from '@/api/modules';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';
import ExportToolbar from '@/components/ExportToolbar.jsx';
import { useToast } from '@/components/Toast.jsx';

/*
 * Raising a period's bills.
 *
 * The screen shows what would be raised before anything is. A bill is what a
 * household is told it owes and cannot be quietly withdrawn, so the list comes
 * first and the button second — the preview and the generate run the same
 * query inside sp_village_bill_run, so the two cannot disagree.
 *
 * Re-running is safe. A charge already billed for the period is skipped, so a
 * second run raises only what is missing — a house added mid-month, or a
 * charge switched on after the first run.
 */

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const money = (v) =>
  v == null || v === ''
    ? '—'
    : Number(v).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/*
 * One row per household, not per charge. A bill is the single thing a house is
 * handed for the period; listing "101 water" and "101 waste" separately
 * describes how the charges are stored rather than what is being issued.
 */
const COLUMNS = [
  { key: 'house_no', label: 'House' },
  { key: 'owner_name', label: 'Owner' },
  { key: 'pre_mob', label: 'Contact' },
  {
    key: 'charges',
    label: 'Charges',
    format: (_v, row) => row.charge_list,
    exportValue: (row) => row.charge_list,
  },
  { key: 'total', label: 'Total', format: money },
];

export default function BillRunPage() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState(null);
  const [result, setResult] = useState(null);
  const toast = useToast();
  // The house whose charges are expanded, if any.
  const [openHouse, setOpenHouse] = useState(null);

  const load = useCallback(
    (y, m) => {
      setLoading(true);
      setError(null);
      return village
        .billRunPreview({ year: y, month: m })
        .then((data) => {
          const lines = data.lines ?? [];
          // The charges behind each bill, so a row can name them and the
          // printed copy can itemise them.
          const byHouse = new Map();
          for (const l of lines) {
            if (!byHouse.has(l.house_id)) byHouse.set(l.house_id, []);
            byHouse.get(l.house_id).push(l);
          }

          setPreview({
            items: (data.items ?? []).map((r) => {
              const own = byHouse.get(r.house_id) ?? [];
              return {
                ...r,
                lines: own,
                charge_list: own.map((l) => l.charge_name).join(', '),
              };
            }),
            lineCount: data.lineCount ?? lines.length,
            total: data.total ?? 0,
          });
        })
        .catch(setError)
        .finally(() => setLoading(false));
    },
    [],
  );

  useEffect(() => {
    load(year, month);
    // Re-runs whenever the period changes; `load` is stable.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [year, month]);

  const generate = async () => {
    setRunning(true);
    setError(null);
    try {
      const data = await village.runBills({ year, month });
      setResult(data);
      await load(year, month);
      // A bill run is the kind of operation worth stating plainly — it writes
      // a row per house and cannot be undone from the app.
      const raised = Number(data?.bills ?? 0);
      toast.success(
        raised
          ? `${raised} bill(s) raised for ${MONTHS[month - 1]} ${year}.`
          : `Nothing new to raise for ${MONTHS[month - 1]} ${year} — the period is already billed.`,
        { title: raised ? 'Bills generated' : 'Already billed' },
      );
    } catch (err) {
      setError(err);
      toast.error(err?.message ?? 'The bill run could not be completed. Please try again.');
    } finally {
      setRunning(false);
    }
  };

  const items = preview?.items ?? [];
  const periodLabel = `${MONTHS[month - 1]} ${year}`;

  return (
    <section>
      <header className="mb-4 print:w-full print:text-center">
        <h1 className="text-xl font-bold" style={{ color: '#1f2937' }}>
          Generate bills
        </h1>
        <p className="text-sm text-slate-500 print:hidden">
          What would be raised for a period, before it is.
        </p>
      </header>

      <ErrorNotice error={error} />

      <div className="card mb-4 p-4 print:hidden">
        <div className="flex flex-wrap items-end gap-3">
          <label className="block">
            <span className="field-label">Month</span>
            <select
              className="field-input w-44"
              value={month}
              onChange={(e) => {
                setResult(null);
                setMonth(Number(e.target.value));
              }}
            >
              {MONTHS.map((name, i) => (
                <option key={name} value={i + 1}>
                  {name}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="field-label">Year</span>
            <input
              className="field-input w-28"
              type="number"
              min="2000"
              max="2100"
              value={year}
              onChange={(e) => {
                setResult(null);
                setYear(Number(e.target.value));
              }}
            />
          </label>

          <button
            type="button"
            className="btn-primary"
            disabled={loading || running || items.length === 0}
            onClick={generate}
          >
            {running ? 'Raising…' : `Raise ${items.length} bill(s)`}

          </button>
        </div>

        {/*
          Yearly charges are raised once for the year whatever month is chosen,
          so the month box does not govern them. Saying so avoids the reading
          that picking August somehow bills property tax for August.
        */}
        <p className="mt-3 text-xs text-slate-500">
          Monthly charges are raised for {periodLabel}. Yearly charges are
          raised once for {year}, whichever month is chosen.
        </p>

        {result ? (
          <p
            className="mt-3 rounded-lg px-3 py-2 text-sm"
            style={{ background: '#ecfdf5', color: '#065f46' }}
          >
            {result.bills > 0
              ? `Raised ${result.bills} bill(s), ${money(result.total)} in total.`
              : 'Nothing left to raise for this period.'}
          </p>
        ) : null}
      </div>

      <div className="card overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState
            title={`Nothing to raise for ${periodLabel}`}
            hint="Every charge that applies has already been billed for this period."
          />
        ) : (
          <>
            <div className="flex items-center justify-between border-b border-slate-200 px-4 py-2">
              <span className="text-sm text-slate-600">
                {items.length} bill(s), {preview.lineCount} charge(s) — {money(preview.total)}
              </span>
            </div>
            <ExportToolbar
              columns={COLUMNS}
              rows={items}
              exportName={`bills-${year}-${String(month).padStart(2, '0')}`}
              exportTitle={`Bills to raise — ${periodLabel}`}
            />
            <div className="overflow-x-auto">
              <table className="min-w-full stacked-table">
                <thead>
                  <tr>
                    {COLUMNS.map((c) => (
                      <th key={c.key} className="table-head">
                        {c.label}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {items.map((row, i) => (
                    <Fragment key={row.house_id}>
                      <tr
                        className="cursor-pointer hover:bg-slate-50"
                        onClick={() => setOpenHouse(openHouse === row.house_id ? null : row.house_id)}
                      >
                        {COLUMNS.map((c, ci) => (
                          <td
                            key={c.key}
                            className={
                              ci === 0 ? 'table-cell font-medium text-slate-800' : 'table-cell'
                            }
                            /* Names the line in the phone card view, from the
                               same column that titles it on a wide screen. */
                            data-label={c.label}
                          >
                            {c.format ? c.format(row[c.key], row, i) : (row[c.key] ?? '—')}
                          </td>
                        ))}
                      </tr>

                      {/* The charges behind the total, for anyone checking a
                          figure before the bills go out. */}
                      {openHouse === row.house_id ? (
                        <tr>
                          <td colSpan={COLUMNS.length} className="bg-slate-50 px-4 py-2">
                            <ul className="text-sm text-slate-600">
                              {row.lines.map((l) => (
                                <li key={l.payment_type} className="flex justify-between py-0.5">
                                  <span>
                                    {l.charge_name}
                                    <span className="ml-2 text-xs text-slate-400">
                                      {l.frequency === 'Y' ? `${year} (yearly)` : periodLabel}
                                    </span>
                                  </span>
                                  <span>{money(l.amount)}</span>
                                </li>
                              ))}
                            </ul>
                          </td>
                        </tr>
                      ) : null}
                    </Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>

      <p className="mt-3 text-xs text-slate-500">
        A charge already billed for this period is not listed and will not be
        raised again, so running this a second time only picks up what is
        missing.
      </p>
    </section>
  );
}
