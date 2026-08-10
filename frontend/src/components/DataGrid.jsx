import { useMemo, useState } from 'react';
import { EmptyState, Spinner } from './ui.jsx';
import ExportToolbar from './ExportToolbar.jsx';

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
  searchable = false,
  searchPlaceholder = 'Search…',
  exportName,
  exportTitle,
  // Report screens pass these through to the PDF export, so it carries the
  // same run criteria the printed page shows.
  filters,
  emphasiseRow,
  footer,
  responsiveCards = true,
  dense = false,
}) {
  const [sort, setSort] = useState({ key: null, dir: 'asc' });
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');

  // Matches against what each column renders, so a search hits the text the
  // user can actually see rather than the raw record.
  const filtered = useMemo(() => {
    const term = search.trim().toLowerCase();
    if (!term) return rows;
    return rows.filter((r) =>
      columns.some((c) => {
        const v = c.render ? c.render(r[c.key], r) : r[c.key];
        return typeof v === 'object' && v !== null
          ? String(r[c.key] ?? '').toLowerCase().includes(term)
          : String(v ?? '').toLowerCase().includes(term);
      }),
    );
  }, [rows, columns, search]);

  const sorted = useMemo(() => {
    if (!sort.key) return filtered;
    const col = columns.find((c) => c.key === sort.key);
    const get = (r) => (col?.sortValue ? col.sortValue(r) : r[sort.key]);
    return [...filtered].sort((a, b) => {
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
  }, [filtered, sort, columns]);

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

  if (loading) return <Spinner />;
  if (!rows.length) return <EmptyState title={emptyTitle} hint={emptyHint} />;

  const cellPad = dense ? 'px-3 py-1.5' : 'px-4 py-2';

  return (
    <div>
      {searchable ? (
        <div className="px-4 pt-3 print:hidden">
          <input
            type="search"
            className="field-input w-full sm:max-w-xs"
            placeholder={searchPlaceholder}
            value={search}
            aria-label={searchPlaceholder}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(0);
            }}
          />
        </div>
      ) : null}

      {exportName ? (
        <ExportToolbar
          columns={columns}
          rows={sorted}
          exportName={exportName}
          exportTitle={exportTitle}
          filters={filters}
          emphasiseRow={emphasiseRow}
        />
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
            {/* Without this a filtered-to-nothing search shows bare headers and
                reads as "there is no data" rather than "nothing matched". */}
            {!sorted.length ? (
              <tr>
                <td
                  className="table-cell px-4 py-6 text-center text-sm text-slate-500"
                  colSpan={columns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}
                >
                  No records match “{search}”.
                </td>
              </tr>
            ) : null}
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
                    <div className="flex items-center justify-end gap-2">{actions(row)}</div>
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
                <div className="flex flex-wrap justify-end gap-2 gap-y-1 pt-2">{actions(row)}</div>
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
