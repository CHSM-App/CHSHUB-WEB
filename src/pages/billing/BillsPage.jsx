import { useEffect, useMemo, useState } from 'react';
import { bills } from '@/api/billing';
import { EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';

const money = (v) => Number(v ?? 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/** Bill runs, and the per-flat detail behind each one. */
export default function BillsPage() {
  const [runs, setRuns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [yearFilter, setYearFilter] = useState('');

  const [detail, setDetail] = useState(null); // { run, items, chargeColumns }
  const [detailLoading, setDetailLoading] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    bills
      .list()
      .then((data) => {
        if (!cancelled) setRuns(data.items ?? []);
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

  const years = useMemo(
    () => [...new Set(runs.map((r) => r.year).filter(Boolean))].sort((a, b) => b - a),
    [runs],
  );

  const visible = useMemo(
    () => (yearFilter ? runs.filter((r) => String(r.year) === yearFilter) : runs),
    [runs, yearFilter],
  );

  const openDetail = async (run) => {
    setDetailLoading(true);
    setDetail({ run, items: [], chargeColumns: [] });
    try {
      const data = await bills.get(run.bill_id);
      setDetail({ run, items: data.items ?? [], chargeColumns: data.chargeColumns ?? [] });
    } catch (err) {
      setError(err);
      setDetail(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const detailTotal = detail?.items.reduce((sum, r) => sum + Number(r.total_amount || 0), 0) ?? 0;

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Maintenance bills</h1>
          <p className="text-sm text-slate-500">{visible.length} bill run(s)</p>
        </div>
        <select
          className="field-input w-40"
          value={yearFilter}
          onChange={(e) => setYearFilter(e.target.value)}
          aria-label="Filter by year"
        >
          <option value="">All years</option>
          {years.map((y) => (
            <option key={y} value={String(y)}>
              {y}
            </option>
          ))}
        </select>
      </header>

      <ErrorNotice error={error} />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : visible.length === 0 ? (
          <EmptyState title="No bill runs found" hint="Bills appear here once generated." />
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr>
                  <th className="table-head">Bill no.</th>
                  <th className="table-head">Period</th>
                  <th className="table-head">Generated</th>
                  <th className="table-head">Due</th>
                  <th className="table-head">Status</th>
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((run) => (
                  <tr key={run.bill_id} className="hover:bg-slate-50">
                    <td className="table-cell font-medium text-slate-800">#{run.bill_id}</td>
                    <td className="table-cell">
                      {run.month_name} {run.year}
                    </td>
                    <td className="table-cell">
                      {run.gen_date ? new Date(run.gen_date).toLocaleDateString() : '—'}
                    </td>
                    <td className="table-cell">
                      {run.due_date ? new Date(run.due_date).toLocaleDateString() : '—'}
                    </td>
                    <td className="table-cell">{run.Status || '—'}</td>
                    <td className="table-cell text-right">
                      <button type="button" className="btn-secondary" onClick={() => openDetail(run)}>
                        View flats
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal
        open={Boolean(detail)}
        title={
          detail ? `Bill #${detail.run.bill_id} — ${detail.run.month_name} ${detail.run.year}` : ''
        }
        onClose={() => setDetail(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setDetail(null)}>
            Close
          </button>
        }
      >
        {detailLoading ? (
          <Spinner />
        ) : !detail?.items.length ? (
          <EmptyState title="No flats in this bill run" />
        ) : (
          <>
            <p className="mb-3 text-sm text-slate-600">
              {detail.items.length} flat(s) · total {money(detailTotal)}
            </p>
            <div className="max-h-[26rem] overflow-auto">
              <table className="min-w-full">
                <thead className="sticky top-0">
                  <tr>
                    <th className="table-head">Unit</th>
                    <th className="table-head">Owner</th>
                    {/* Charge heads are pivoted per society, so the columns are
                        discovered from the response rather than hardcoded. */}
                    {detail.chargeColumns.map((c) => (
                      <th key={c.nameKey} className="table-head">
                        {detail.items[0]?.[c.nameKey] || 'Charge'}
                      </th>
                    ))}
                    <th className="table-head">Interest</th>
                    <th className="table-head">Total</th>
                    <th className="table-head">Due</th>
                  </tr>
                </thead>
                <tbody>
                  {detail.items.map((row) => (
                    <tr key={`${row.flat_id}-${row.bill_no}`}>
                      <td className="table-cell font-medium text-slate-800">{row.Unit}</td>
                      <td className="table-cell">{row.owner_name}</td>
                      {detail.chargeColumns.map((c) => (
                        <td key={c.amountKey} className="table-cell">
                          {row[c.amountKey] == null ? '—' : money(row[c.amountKey])}
                        </td>
                      ))}
                      <td className="table-cell">{money(row.tax_interest_amt)}</td>
                      <td className="table-cell">{money(row.total_amount)}</td>
                      <td className="table-cell">{money(row.due)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </Modal>
    </section>
  );
}
