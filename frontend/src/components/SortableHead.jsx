import { useState } from 'react';

/**
 * Sorting affordances for the hand-written `<table>`s across the app.
 *
 * These screens predate DataGrid and render their own markup, so they can't
 * inherit its sortable headers. Rather than convert forty working tables, the
 * two pieces they need are supplied here and used in place of a plain `<th>`.
 */

/**
 * What the tip says: the column this heading sorts by.
 *
 * The wording follows the native tooltip it replaces — the column's own name,
 * so "Sort by Building" and "Sort by Floors" read as they always did.
 */
function tipLabel(column) {
  return `Sort by ${column.label}`;
}

/**
 * A column heading that sorts on click.
 *
 * Real `<button>` inside the cell rather than a click handler on the `<th>`:
 * a heading that reorders the table is a control, and it has to be reachable
 * and operable from the keyboard like any other. `aria-sort` on the cell is
 * what tells a screen reader which column is ordering the table and which way.
 */
export function SortableHead({ column, sort, onSort, className = '' }) {
  const active = sort?.key === column.key;
  const sortable = column.sortable !== false;
  const align = column.align === 'right' ? ' text-right' : '';
  const extra = `${column.printHidden ? ' print:hidden' : ''}${className ? ` ${className}` : ''}`;

  /*
   * The tip is state rather than a `:hover` rule because it has to be
   * dismissable: the native `title` it replaces stayed up while you clicked the
   * same heading repeatedly to flip direction, sitting over the rows you were
   * trying to read. Clicking hides it until the pointer leaves and comes back.
   */
  const [tipOpen, setTipOpen] = useState(false);

  if (!sortable) {
    return <th className={`table-head${align}${extra}`}>{column.label}</th>;
  }

  const tip = tipLabel(column);

  return (
    <th
      className={`table-head${align}${extra}`}
      aria-sort={active ? (sort.dir === 'asc' ? 'ascending' : 'descending') : 'none'}
    >
      {/* `relative` anchors the tip; `inline-flex` keeps the cell sized to the
          heading rather than stretching to the tip's width. */}
      <div className={`relative inline-flex w-full ${column.align === 'right' ? 'justify-end' : ''}`}>
        <button
          type="button"
          onClick={() => {
            setTipOpen(false);
            onSort(column.key);
          }}
          onMouseEnter={() => setTipOpen(true)}
          onMouseLeave={() => setTipOpen(false)}
          // Keyboard users get the same hint when the heading takes focus.
          onFocus={() => setTipOpen(true)}
          onBlur={() => setTipOpen(false)}
          /* Inherits the heading's own weight and colour — this should read as
             the column title, not as a button parked in the header band. */
          className={`group inline-flex w-full items-center gap-1 bg-transparent p-0 text-left text-inherit ${
            column.align === 'right' ? 'justify-end' : ''
          }`}
          style={{ font: 'inherit', letterSpacing: 'inherit' }}
          /*
           * Named for a screen reader here rather than with `title`, which the
           * browser would paint as a second, native tooltip beside this one.
           */
          aria-label={`Sort by ${column.label}`}
        >
          <span>{column.label}</span>
          {/*
            The arrow keeps its width whether or not this column is the sorted
            one, so switching columns doesn't shift every heading sideways.

            Only the active column puts a glyph in the markup; the hover hint on
            the others is drawn with `before:` content instead. A real character
            there would join the heading's text — "Flat▲" — for anything reading
            the cell, from an export to a test.
          */}
          <span
            aria-hidden="true"
            className={`shrink-0 text-[0.7em] print:hidden ${
              active
                ? 'opacity-100'
                : "opacity-0 before:content-['▲'] group-hover:opacity-40 group-focus:opacity-40"
            }`}
          >
            {active ? (sort.dir === 'desc' ? '▼' : '▲') : null}
          </span>
        </button>

        {tipOpen ? (
          /*
           * `aria-hidden` because the button's own label already says this to a
           * screen reader; announcing both would read the column name twice.
           * Pointer events are off so the tip can never sit between the cursor
           * and the heading it describes.
           */
          <span
            aria-hidden="true"
            className="pointer-events-none absolute left-1/2 top-full z-20 mt-1 -translate-x-1/2 whitespace-nowrap rounded bg-slate-800 px-2 py-1 text-xs font-medium normal-case tracking-normal text-white shadow-lg print:hidden"
          >
            {tip}
          </span>
        ) : null}
      </div>
    </th>
  );
}

/**
 * The same sort, for a phone.
 *
 * Below `sm` these tables collapse to cards and `stacked-table` hides `thead`
 * outright — so the clickable headings above simply aren't on screen, and
 * without this the whole feature would be desktop-only. A select plus a
 * direction toggle drives the identical state.
 */
export function SortControl({ columns, sort, onSort, className = '' }) {
  const sortable = columns.filter((c) => c.sortable !== false);
  if (!sortable.length) return null;

  const current = sort?.key ?? '';

  return (
    <div className={`flex items-center gap-2 sm:hidden print:hidden ${className}`}>
      <label className="shrink-0 text-xs font-semibold uppercase tracking-wide text-slate-500">
        Sort
      </label>
      <select
        className="field-input min-w-0 flex-1 py-1 text-sm"
        value={current}
        onChange={(e) => {
          const key = e.target.value;
          /* Choosing the column already sorted would toggle its direction —
             not what picking from a list means. Only a real change is sent. */
          if (key && key !== current) onSort(key);
        }}
        aria-label="Sort by"
      >
        <option value="">Default order</option>
        {sortable.map((c) => (
          <option key={c.key} value={c.key}>
            {c.label}
          </option>
        ))}
      </select>
      {current ? (
        <button
          type="button"
          className="btn-secondary shrink-0 px-2 py-1 text-xs"
          onClick={() => onSort(current)}
          aria-label={`Sorted ${sort.dir === 'asc' ? 'ascending' : 'descending'} — reverse`}
        >
          {sort.dir === 'asc' ? '▲ A–Z' : '▼ Z–A'}
        </button>
      ) : null}
    </div>
  );
}

export default SortableHead;
