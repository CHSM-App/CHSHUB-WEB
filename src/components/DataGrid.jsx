import { useEffect, useMemo, useState } from 'react';
import { EmptyState, Spinner } from './ui.jsx';
import ExportToolbar from './ExportToolbar.jsx';
import { SortableHead, SortControl } from './SortableHead.jsx';
import { compareRows, sortValueOf } from './useSortedRows.js';
import Pager, { pageItems, usePrinting } from './Pager.jsx';

// Re-exported: both were defined here before the hand-written tables needed
// them too, and tests and callers import them from the grid.
export { pageItems };

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
  /*
   * Put the tick column last rather than first, and head it "Select". Most
   * grids select-then-act, so the box leads; v_tax_payment.aspx's pending grid
   * reads its amounts first and offers the tick at the end, for the reminder
   * below it.
   */
  selectionAtEnd = false,
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
  /*
   * The leading row-number column the legacy grids carried as "Sr.No", headed
   * "No." here. On by default, so every list numbers its rows the same way —
   * screens used to differ, some hand-rolling the column and most having none.
   *
   * Numbering continues across pages — page 2 of a 25-row grid starts at 26,
   * not 1 — so the number identifies a row in the whole list rather than in the
   * visible slice. It counts the sorted-and-filtered rows, so it stays 1..n
   * with no gaps after a search, and follows the order actually on screen.
   *
   * Screens that already render their own serial column pass `false`.
   */
  serialColumn = true,
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
    return [...filtered].sort((a, b) =>
      compareRows(sortValueOf(col, a, sort.key), sortValueOf(col, b, sort.key), sort.dir),
    );
  }, [filtered, sort, columns]);

  /*
   * Paging is a screen affordance. Printing a paged grid would put 25 of 200
   * records on paper and silently drop the rest, so the whole set is rendered
   * while the print dialog is open.
   */
  const printing = usePrinting();

  const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize));
  const safePage = Math.min(page, pageCount - 1);
  const visible =
    pageSize && !printing ? sorted.slice(safePage * pageSize, (safePage + 1) * pageSize) : sorted;

  /*
   * The caller's columns are what search, sort and export work from — the
   * serial number is derived from position, so it is prepended for rendering
   * only. Searching it would be meaningless and sorting by it would sort by the
   * current order, hence `sortable: false`.
   *
   * The offset is the row's index in `sorted`, so the count runs unbroken
   * across pages. `visible` is a slice of `sorted`, so a row's position within
   * the page plus the page's start gives its number without an indexOf scan.
   */
  const firstOnPage = pageSize && !printing ? safePage * pageSize : 0;
  const renderColumns = serialColumn
    ? [
        {
          key: '__sr',
          label: 'No.',
          sortable: false,
          render: (_v, _row, i) => firstOnPage + i + 1,
        },
        ...columns,
      ]
    : columns;

  const toggleSort = (key) => {
    if (!sortable) return;
    // The header cell already refuses to call this for an opted-out column,
    // but the card view's sort control reaches it by key alone.
    if (columns.find((c) => c.key === key)?.sortable === false) return;
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
              {selectable && !selectionAtEnd ? (
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
              {/*
                Through the shared header rather than a click handler on the
                `<th>`, so these grids get the same keyboard-reachable control
                and the same tooltip as the hand-written tables elsewhere.
                `sortable={false}` on the grid disables the lot, which the
                column-level flag expresses here.
              */}
              {renderColumns.map((c) => (
                <SortableHead
                  key={c.key}
                  column={sortable ? c : { ...c, sortable: false }}
                  sort={sort}
                  onSort={toggleSort}
                />
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
              {selectable && selectionAtEnd ? (
                <th className="table-head w-20 whitespace-nowrap print:hidden">
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      className="h-4 w-4 rounded border-slate-300"
                      checked={allOnPageSelected}
                      onChange={toggleAll}
                      aria-label="Select all rows on this page"
                    />
                    Select
                  </label>
                </th>
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
                  colSpan={renderColumns.length + (selectable ? 1 : 0) + (actions ? 1 : 0)}
                >
                  No records match “{search}”.
                </td>
              </tr>
            ) : null}
            {visible.map((row, i) => (
              <tr key={row[idKey] ?? i} className="hover:bg-slate-50">
                {selectable && !selectionAtEnd ? (
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
                {renderColumns.map((c, ci) => (
                  <td
                    key={c.key}
                    className={`table-cell ${cellPad} ${c.align === 'right' ? 'text-right' : ''} ${
                      // The serial number is a row label, not the row's subject:
                      // when it leads, the emphasis belongs to the column after.
                      ci === (serialColumn ? 1 : 0) ? 'font-medium text-slate-800' : ''
                    } ${c.key === '__sr' ? 'w-px whitespace-nowrap text-slate-500' : ''}`}
                  >
                    {c.render ? c.render(row[c.key], row, i) : (row[c.key] ?? "—")}
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
                {selectable && selectionAtEnd ? (
                  <td className={`table-cell ${cellPad} print:hidden`}>
                    <input
                      type="checkbox"
                      className="h-4 w-4 rounded border-slate-300"
                      checked={selectedIds.includes(row[idKey])}
                      onChange={() => toggleOne(row[idKey])}
                      aria-label={`Select row ${i + 1}`}
                    />
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
        <>
        {/* The column headings carry the sort on a wide screen, and the card
            view has no headings — so without this the grids were sortable on
            a desktop only. */}
        {sortable ? (
          <SortControl columns={columns} sort={sort} onSort={toggleSort} className="px-4 pb-2 pt-3" />
        ) : null}
        <ul className="divide-y divide-slate-100 sm:hidden">
          {visible.map((row, i) => (
            <li key={row[idKey] ?? i} className="space-y-1 p-4">
              {/* As a heading rather than another label/value row: on a card
                  the number says which record this is, and a "Sr.No — 4" line
                  in among the data reads as one more field. */}
              {serialColumn ? (
                <div className="text-xs font-medium text-slate-400">#{firstOnPage + i + 1}</div>
              ) : null}
              {columns.map((c) => (
                <div key={c.key} className="flex justify-between gap-3 text-sm">
                  {/* The label holds its width and the value takes the rest:
                      without the floor on the label, a long value squeezed
                      "Registration No" down to one word per line. */}
                  <span className="shrink-0 text-slate-500">{c.label}</span>
                  {/* An email or a UPI reference has no break opportunity in
                      it, so without this the card set its own width and the
                      whole list scrolled sideways. */}
                  <span className="break-anywhere min-w-0 text-right text-slate-800">
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
        </>
      ) : null}

      {/* Not while printing: the whole set is on the paper, so a "1–25 of 200"
          footer would contradict it. */}
      {!printing ? (
        <Pager
          page={safePage}
          pageCount={pageCount}
          first={firstOnPage}
          last={Math.min((safePage + 1) * pageSize, sorted.length)}
          total={sorted.length}
          onPage={setPage}
        />
      ) : null}
    </div>
  );
}
