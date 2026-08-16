import { useMemo, useState } from 'react';

/**
 * Compares two cell values the way the grids across the app already do.
 *
 * Nulls sink to the bottom in both directions — a blank cell is missing data,
 * not the smallest value, so flipping the arrow shouldn't drag a block of
 * empties to the top. Strings go through `localeCompare` with `numeric`, which
 * is what puts "Flat 10" after "Flat 9" instead of between "Flat 1" and "Flat 2".
 */
export function compareValues(av, bv) {
  const aBlank = av == null || av === '';
  const bBlank = bv == null || bv === '';
  if (aBlank || bBlank) return aBlank && bBlank ? 0 : aBlank ? 1 : -1;
  return typeof av === 'number' && typeof bv === 'number'
    ? av - bv
    : String(av).localeCompare(String(bv), undefined, { numeric: true });
}

/**
 * Orders two rows, keeping blanks at the bottom whichever way the arrow points.
 *
 * Negating the comparator to get descending would flip the blanks up with
 * everything else, so an empty column would fill the top of the screen on the
 * second click. Missing data isn't the largest value any more than it is the
 * smallest — it sorts last either way, and only the real values reverse.
 */
export function compareRows(av, bv, dir) {
  const aBlank = av == null || av === '';
  const bBlank = bv == null || bv === '';
  if (aBlank || bBlank) return aBlank && bBlank ? 0 : aBlank ? 1 : -1;
  const cmp = compareValues(av, bv);
  return dir === 'asc' ? cmp : -cmp;
}

/**
 * Reads the value a column sorts on.
 *
 * A column may render something that isn't its raw field — a status pill, a
 * formatted date, a button. `sortValue` lets such a column say what it orders
 * by; without one the raw field is used, which is right for plain text cells.
 */
export function sortValueOf(col, row, key) {
  return col?.sortValue ? col.sortValue(row) : row[key];
}

/**
 * Click-to-sort state plus the ordered rows, for the tables that predate
 * DataGrid and render their own `<table>`.
 *
 * Returns the rows untouched until a header is actually clicked, so each list
 * keeps arriving in whatever order the server sent — several screens rely on
 * that default (newest first, or a sequence the user arranged).
 *
 * Columns opt out with `sortable: false`, for the serial-number and
 * button-only columns where an ordering would mean nothing.
 */
export default function useSortedRows(rows, columns) {
  const [sort, setSort] = useState({ key: null, dir: 'asc' });

  const toggleSort = (key) => {
    const col = columns?.find((c) => c.key === key);
    if (col?.sortable === false) return;
    setSort((prev) =>
      prev.key === key ? { key, dir: prev.dir === 'asc' ? 'desc' : 'asc' } : { key, dir: 'asc' },
    );
  };

  const sorted = useMemo(() => {
    if (!sort.key) return rows;
    const col = columns?.find((c) => c.key === sort.key);
    return [...rows].sort((a, b) =>
      compareRows(sortValueOf(col, a, sort.key), sortValueOf(col, b, sort.key), sort.dir),
    );
  }, [rows, columns, sort]);

  return { sorted, sort, toggleSort };
}
