import { useMemo, useState } from 'react';
import { EmptyState, Spinner } from './ui.jsx';

/**
 * Production data grid — replaces asp:GridView.
 *
 * Covers what the WebForms grids provided: sorting, paging, per-row command
 * buttons, selection checkboxes, footer totals, and the three export actions
 * those pages carried — "Export to Excel", "Download PDF" and Print.
 * Responsive: scrolls horizontally on narrow screens and collapses to stacked
 * cards below the `sm` breakpoint when `responsiveCards` is set.
 */
export default function DataGrid({
  columns,
  rows,
  idKey = 'id',
  loading,
  emptyTitle = 'No records found',
  emptyHint,
  actions,
  selectable = false,
  selectedIds = [],
  onSelectionChange,
  pageSize = 25,
  sortable = true,
  exportName,
  exportTitle,
  footer,
  responsiveCards = true,
  dense = false,
}) {
  const [sort, setSort] = useState({ key: null, dir: 'asc' });
  const [page, setPage] = useState(0);
  const [pdfBusy, setPdfBusy] = useState(false);

  const sorted = useMemo(() => {
    if (!sort.key) return rows;
    const col = columns.find((c) => c.key === sort.key);
    const get = (r) => (col?.sortValue ? col.sortValue(r) : r[sort.key]);
    return [...rows].sort((a, b) => {
      const av = get(a);
      const bv = get(b);
      if (av == null) return 1;
      if (bv == null) return -1;
      const cmp =
        typeof av === 'number' && typeof bv === 'number'
          ? av - bv
          : String(av).localeCompare(String(bv), undefined, { numeric: true });
      return sort.dir === 'asc' ? cmp : -cmp;
    });
  }, [rows, sort, columns]);

  const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize));
  const safePage = Math.min(page, pageCount - 1);
  const visible = pageSize ? sorted.slice(safePage * pageSize, (safePage + 1) * pageSize) : sorted;

  const toggleSort = (key) => {
    if (!sortable) return;
    setSort((prev) =>
      prev.key === key ? { key, dir: prev.dir === 'asc' ? 'desc' : 'asc' } : { key, dir: 'asc' },
    );
  };

  const allOnPageSelected =
    selectable && visible.length > 0 && visible.every((r) => selectedIds.includes(r[idKey]));

  const toggleAll = () => {
    if (!onSelectionChange) return;
    const ids = visible.map((r) => r[idKey]);
    onSelectionChange(
      allOnPageSelected
        ? selectedIds.filter((id) => !ids.includes(id))
        : [...new Set([...selectedIds, ...ids])],
    );
  };

  const toggleOne = (id) => {
    if (!onSelectionChange) return;
    onSelectionChange(
      selectedIds.includes(id) ? selectedIds.filter((x) => x !== id) : [...selectedIds, id],
    );
  };

  /** CSV export — the legacy pages' "Export to Excel" button. */
  const exportCsv = () => {
    const head = columns.map((c) => `"${c.label}"`).join(',');
    const body = sorted
      .map((r) =>
        columns
          .map((c) => {
            const v = c.exportValue ? c.exportValue(r) : r[c.key];
            return `"${String(v ?? '').replace(/"/g, '""')}"`;
          })
          .join(','),
      )
      .join('\n');
    const blob = new Blob([`${head}\n${body}`], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `${exportName || 'export'}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  /** PDF export — the legacy pages' "Download PDF" button. */
  const exportPdf = async () => {
    setPdfBusy(true);
    try {
      const { tableToPdf } = await import('@/lib/pdf');
      await tableToPdf({
        columns,
        rows: sorted,
        title: exportTitle ?? exportName,
        filename: exportName || 'export',
      });
    } catch (err) {
      // A failed export should report itself, not disappear into the console.
      window.alert(`Could not create the PDF: ${err.message}`);
    } finally {
      setPdfBusy(false);
    }
  };

  if (loading) return <Spinner />;
  if (!rows.length) return <EmptyState title={emptyTitle} hint={emptyHint} />;

  const cellPad = dense ? 'px-3 py-1.5' : 'px-4 py-2';

  return (
    <div>
      {exportName ? (
        <div className="flex justify-end gap-2 border-b border-slate-200 px-4 py-2 print:hidden">
          <button type="button" className="btn-secondary text-xs" onClick={exportCsv}>
            Export to Excel
          </button>
          <button
            type="button"
            className="btn-secondary text-xs"
            onClick={exportPdf}
            disabled={pdfBusy}
          >
            {pdfBusy ? 'Preparing…' : 'Download PDF'}
          </button>
          <button type="button" className="btn-secondary text-xs" onClick={() => window.print()}>
            Print
          </button>
        </div>
      ) : null}

      {/* Table view */}
      <div className={`overflow-x-auto ${responsiveCards ? 'hidden sm:block' : ''}`}>
        <table className="min-w-full">
          <thead>
            <tr>
              {selectable ? (
                <th className="table-head w-10">
                  <input
                    type="checkbox"
                    className="h-4 w-4 rounded border-slate-300"
                    checked={allOnPageSelected}
                    onChange={toggleAll}
                    aria-label="Select all rows on this page"
                  />
                </th>
              ) : null}
              {columns.map((c) => (
                <th
                  key={c.key}
                  className={`table-head ${c.align === 'right' ? 'text-right' : ''} ${
                    sortable && c.sortable !== false ? 'cursor-pointer select-none' : ''
                  }`}
                  onClick={() => c.sortable !== false && toggleSort(c.key)}
                >
                  {c.label}
                  {sort.key === c.key ? (
                    <span aria-hidden="true"> {sort.dir === 'asc' ? '▲' : '▼'}</span>
                  ) : null}
                </th>
              ))}
              {/*
                w-px + nowrap makes the actions column shrink-to-fit: the table
                gives it exactly the width its buttons need and lets the data
                columns absorb the rest, instead of squeezing the buttons onto
                a second line.
              */}
              {actions ? (
                <th className="table-head w-px whitespace-nowrap text-right print:hidden">Actions</th>
              ) : null}
            </tr>
          </thead>
          <tbody>
            {visible.map((row, i) => (
              <tr key={row[idKey] ?? i} className="hover:bg-slate-50">
                {selectable ? (
                  <td className={`table-cell ${cellPad}`}>
                    <input
                      type="checkbox"
                      className="h-4 w-4 rounded border-slate-300"
                      checked={selectedIds.includes(row[idKey])}
                      onChange={() => toggleOne(row[idKey])}
                      aria-label={`Select row ${i + 1}`}
                    />
                  </td>
                ) : null}
                {columns.map((c, ci) => (
                  <td
                    key={c.key}
                    className={`table-cell ${cellPad} ${c.align === 'right' ? 'text-right' : ''} ${
                      ci === 0 ? 'font-medium text-slate-800' : ''
                    }`}
                  >
                    {c.render ? c.render(row[c.key], row) : (row[c.key] ?? "—")}
                  </td>
                ))}
                {/*
                  Actions wrap instead of being forced onto one line: rows with
                  four buttons (View Docs / Details / Edit / Delete) pushed the
                  leftmost ones out of view under nowrap.
                */}
                {actions ? (
                  <td className={`table-cell ${cellPad} w-px whitespace-nowrap print:hidden`}>
                    <div className="flex items-center justify-end">{actions(row)}</div>
                  </td>
                ) : null}
              </tr>
            ))}
          </tbody>
          {footer ? <tfoot>{footer(sorted)}</tfoot> : null}
        </table>
      </div>

      {/* Card view for narrow screens */}
      {responsiveCards ? (
        <ul className="divide-y divide-slate-100 sm:hidden">
          {visible.map((row, i) => (
            <li key={row[idKey] ?? i} className="space-y-1 p-4">
              {columns.map((c) => (
                <div key={c.key} className="flex justify-between gap-3 text-sm">
                  <span className="text-slate-500">{c.label}</span>
                  <span className="text-right text-slate-800">
                    {c.render ? c.render(row[c.key], row) : (row[c.key] ?? "—")}
                  </span>
                </div>
              ))}
              {actions ? (
                <div className="flex flex-wrap justify-end gap-y-1 pt-2">{actions(row)}</div>
              ) : null}
            </li>
          ))}
        </ul>
      ) : null}

      {pageCount > 1 ? (
        <div className="flex items-center justify-between border-t border-slate-200 px-4 py-2 text-sm print:hidden">
          <span className="text-slate-500">
            {safePage * pageSize + 1}–{Math.min((safePage + 1) * pageSize, sorted.length)} of{' '}
            {sorted.length}
          </span>
          <div className="flex gap-2">
            <button
              type="button"
              className="btn-secondary px-3 py-1 text-xs"
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={safePage === 0}
            >
              Previous
            </button>
            <button
              type="button"
              className="btn-secondary px-3 py-1 text-xs"
              onClick={() => setPage((p) => Math.min(pageCount - 1, p + 1))}
              disabled={safePage >= pageCount - 1}
            >
              Next
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
