import { useDeferredValue, useEffect, useMemo, useState } from 'react';
import { bills } from '@/api/billing';
import { EmptyState, ErrorNotice, Spinner } from '@/components/ui.jsx';
import Pager, { usePaging } from '@/components/Pager.jsx';

const money = (v) => Number(v ?? 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

/** Flats with dues past their due date. Replaces Society2024/Defaulter.aspx. */
export default function DefaultersPage() {
  const [items, setItems] = useState([]);
  const [totalDue, setTotalDue] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [search, setSearch] = useState('');
  const deferred = useDeferredValue(search);

  useEffect(() => {
    let cancelled = false;
    bills
      .defaulters()
      .then((data) => {
        if (cancelled) return;
        setItems(data.items ?? []);
        setTotalDue(data.totalDue ?? 0);
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

  // Filtering client-side: the SP returns the whole list and there is no
  // search branch for defaulters.
  const visible = useMemo(() => {
    const q = deferred.trim().toLowerCase();
    if (!q) return items;
    return items.filter((r) =>
      [r.owner_name, r.Unit, r.flat_no, r.pre_mob, r.email]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q)),
    );
  }, [items, deferred]);

  const visibleTotal = visible.reduce((sum, r) => sum + Number(r.due || 0), 0);

  // The count and the outstanding total above stay over the whole filtered
  // list — paging changes what is on screen, not what is owed.
  const paging = usePaging(visible.length, 25);
  const pageRows = visible.slice(paging.first, paging.first + paging.size);

  return (
    <section>
      <header className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-semibold text-slate-800">Defaulters</h1>
          <p className="text-sm text-slate-500">
            {visible.length} of {items.length} · outstanding {money(visibleTotal)}
            {visible.length !== items.length ? ` (all: ${money(totalDue)})` : ''}
          </p>
        </div>
        <input
          className="field-input w-64"
          placeholder="Search name, unit or mobile…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          aria-label="Search defaulters"
        />
      </header>

      <ErrorNotice error={error} />

      <div className="card mt-3 overflow-hidden">
        {loading ? (
          <Spinner />
        ) : visible.length === 0 ? (
          <EmptyState
            title={items.length ? 'No matching defaulters' : 'No defaulters'}
            hint={items.length ? 'Try a different search term.' : 'All dues are settled.'}
          />
        ) : (
          <>
          <div className="overflow-x-auto">
            <table className="min-w-full stacked-table">
              <thead>
                <tr>
                  {/* Row number, as every other list carries. */}
                  <th className="table-head w-px whitespace-nowrap">No.</th>
                  <th className="table-head">Resident</th>
                  <th className="table-head">Unit</th>
                  <th className="table-head">Mobile</th>
                  <th className="table-head">Email</th>
                  <th className="table-head">Amount due</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.map((row, i) => (
                  <tr key={row.flat_id} className="hover:bg-slate-50">
                    {/* Counts from the row's place in the whole list, so page 2
                        carries on rather than restarting at 1. */}
                    <td className="table-cell w-px whitespace-nowrap text-slate-500" data-label="No.">
                      {paging.first + i + 1}
                    </td>
                    <td className="table-cell font-medium text-slate-800" data-label="Resident">{row.owner_name}</td>
                    <td className="table-cell" data-label="Unit">{row.Unit}</td>
                    <td className="table-cell" data-label="Mobile">{row.pre_mob || '—'}</td>
                    <td className="table-cell" data-label="Email">{row.email || '—'}</td>
                    <td className="table-cell font-medium text-red-700" data-label="Amount due">{money(row.due)}</td>
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
            total={visible.length}
            onPage={paging.setPage}
          />
          </>
        )}
      </div>
    </section>
  );
}
