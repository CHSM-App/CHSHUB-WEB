import { useEffect, useState } from 'react';
import { receipts } from '@/api/billing';
import { EmptyState, ErrorNotice, Modal, Spinner } from '@/components/ui.jsx';
import useSortedRows from '@/components/useSortedRows.js';
import { SortableHead, SortControl } from '@/components/SortableHead.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

const money = (v) => Number(v ?? 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/*
 * Date and amount sort on their underlying value, not the rendered text: the
 * cells show a localised date and a grouped number, and ordering those as
 * strings puts 9,000 above 10,000 and sorts dates by their leading digit.
 */
const COLUMNS = [
  { key: 'receipt_no', label: 'Receipt no.' },
  { key: 'receipt_date', label: 'Date', sortValue: (r) => (r.receipt_date ? new Date(r.receipt_date).getTime() : null) },
  { key: 'owner', label: 'Resident' },
  { key: 'transaction_ref', label: 'Reference' },
  { key: 'paid_amount', label: 'Amount', sortValue: (r) => Number(r.paid_amount ?? 0) },
  { key: 'bill_status', label: 'Status' },
];

/**
 * Receipts ledger. Read-only for now: recording a payment writes to `receipt`
 * and mutates `maintenance_cal` via sp_SettleMaintenancePayment, so it stays
 * disabled until exercised against a test database.
 */
export default function ReceiptsPage() {
  const [items, setItems] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [viewing, setViewing] = useState(null);
  const [viewLoading, setViewLoading] = useState(false);
  const { sorted, sort, toggleSort } = useSortedRows(items, COLUMNS);

  const paging = usePaging(sorted.length, 25);
  const visible = sorted.slice(paging.first, paging.first + paging.size);

  useEffect(() => {
    let cancelled = false;
    receipts
      .list()
      .then((data) => {
        if (cancelled) return;
        setItems(data.items ?? []);
        setTotal(data.totalCollected ?? 0);
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

  const openReceipt = async (row) => {
    setViewLoading(true);
    setViewing({ summary: row, detail: null });
    try {
      const data = await receipts.get(row.receipt_id);
      setViewing({ summary: row, detail: data.receipt });
    } catch (err) {
      setError(err);
      setViewing(null);
    } finally {
      setViewLoading(false);
    }
  };

  return (
    <section>
      <header className="mb-4">
        <h1 className="text-lg font-semibold text-slate-800">Receipts</h1>
        <p className="text-sm text-slate-500">
          {items.length} receipt(s) · {money(total)} collected
        </p>
      </header>

      <ErrorNotice error={error} />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : items.length === 0 ? (
          <EmptyState title="No receipts recorded" />
        ) : (
          <>
          <SortControl columns={COLUMNS} sort={sort} onSort={toggleSort} className="px-4 pb-2 pt-3" />
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {/* Row number, as every other list carries. */}
                  <th className="table-head w-px whitespace-nowrap">No.</th>
                  {COLUMNS.map((c) => (
                    <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
                  ))}
                  <th className="table-head sr-only">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map((row, i) => (
                  <tr key={row.receipt_id} className="hover:bg-slate-50">
                    {/* Counts from the row's place in the whole list, so page 2
                        carries on rather than restarting at 1. */}
                    <td className="table-cell w-px whitespace-nowrap text-slate-500" data-label="No.">
                      {paging.first + i + 1}
                    </td>
                    <td className="table-cell font-medium text-slate-800" data-label="Receipt no.">{row.receipt_no}</td>
                    <td className="table-cell" data-label="Date">
                      {row.receipt_date ? new Date(row.receipt_date).toLocaleDateString() : '—'}
                    </td>
                    <td className="table-cell" data-label="Resident">{row.owner}</td>
                    <td className="table-cell" data-label="Reference">{row.transaction_ref || '—'}</td>
                    <td className="table-cell" data-label="Amount">{money(row.paid_amount)}</td>
                    <td className="table-cell" data-label="Status">{row.bill_status}</td>
                    <td className="table-cell text-right" data-actions="">
                      <button type="button" className="btn-secondary" onClick={() => openReceipt(row)}>
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pager
            page={paging.page}
            pageCount={paging.pageCount}
            first={paging.first}
            last={paging.last}
            total={sorted.length}
            onPage={paging.setPage}
          />
          </>
        )}
      </div>

      <Modal
        open={Boolean(viewing)}
        title={`Receipt ${viewing?.summary?.receipt_no ?? ''}`}
        onClose={() => setViewing(null)}
        footer={
          <button type="button" className="btn-secondary" onClick={() => setViewing(null)}>
            Close
          </button>
        }
      >
        {viewLoading ? (
          <Spinner />
        ) : viewing?.detail ? (
          <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
            {[
              ['Receipt no.', viewing.detail.receipt_no],
              ['Date', viewing.detail.date ? new Date(viewing.detail.date).toLocaleDateString() : '—'],
              ['Resident', viewing.detail.name],
              ['Unit', viewing.detail.unit],
              ['Pay mode', viewing.detail.pay_mode],
              ['Reference', viewing.detail.transaction_ref || '—'],
              ['Bill', viewing.detail.bill_ref || viewing.detail.Billno || '—'],
              ['Amount paid', money(viewing.detail.paid_amount)],
              ['Status', viewing.detail.bill_status],
              ['Society', viewing.detail.society_name],
            ].map(([label, value]) => (
              <div key={label}>
                <dt className="text-xs uppercase tracking-wide text-slate-500">{label}</dt>
                <dd className="mt-0.5 text-slate-800">{value ?? '—'}</dd>
              </div>
            ))}
          </dl>
        ) : (
          <EmptyState title="Receipt details unavailable" />
        )}
      </Modal>
    </section>
  );
}
