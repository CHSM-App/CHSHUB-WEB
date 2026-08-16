import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { compareValues, compareRows } from './useSortedRows.js';
import useSortedRows from './useSortedRows.js';
import { SortableHead, SortControl } from './SortableHead.jsx';

/** A stand-in for the hand-written tables the hook was extracted for. */
function Table({ rows, columns }) {
  const { sorted, sort, toggleSort } = useSortedRows(rows, columns);
  return (
    <>
      <SortControl columns={columns} sort={sort} onSort={toggleSort} />
      <table>
        <thead>
          <tr>
            {columns.map((c) => (
              <SortableHead key={c.key} column={c} sort={sort} onSort={toggleSort} />
            ))}
          </tr>
        </thead>
        <tbody>
          {sorted.map((r, i) => (
            <tr key={r.id ?? i}>
              {columns.map((c) => (
                <td key={c.key}>{String(r[c.key] ?? '—')}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

const firstColumn = () =>
  screen.getAllByRole('row').slice(1).map((tr) => within(tr).getAllByRole('cell')[0].textContent);

describe('compareValues', () => {
  it('orders numbers numerically rather than as text', () => {
    expect(compareValues(9, 100)).toBeLessThan(0);
  });

  it('orders numeric-looking text the way a reader does', () => {
    // The bug this guards: plain string comparison puts "A-101" before "A-9".
    expect(compareValues('A-9', 'A-101')).toBeLessThan(0);
  });

  it('treats an empty string as missing, not as the smallest text', () => {
    expect(compareValues('', 'Alpha')).toBeGreaterThan(0);
  });
});

describe('compareRows', () => {
  it('sinks blanks to the bottom in BOTH directions', () => {
    // Negating the comparator for descending would carry the blanks up with
    // everything else and fill the top of the screen with empty cells.
    for (const dir of ['asc', 'desc']) {
      expect(compareRows(null, 5, dir)).toBeGreaterThan(0);
      expect(compareRows(5, null, dir)).toBeLessThan(0);
    }
  });

  it('still reverses the real values', () => {
    expect(compareRows(1, 2, 'asc')).toBeLessThan(0);
    expect(compareRows(1, 2, 'desc')).toBeGreaterThan(0);
  });
});

describe('sortable tables', () => {
  const COLUMNS = [
    { key: 'name', label: 'Name' },
    { key: 'qty', label: 'Qty', sortValue: (r) => (r.qty == null ? null : Number(r.qty)) },
    { key: 'note', label: 'Note', sortable: false },
  ];
  const ROWS = [
    { id: 1, name: 'Beta', qty: 100, note: 'b' },
    { id: 2, name: 'Alpha', qty: 9, note: 'a' },
    { id: 3, name: 'Gamma', qty: null, note: 'c' },
  ];

  it('leaves the server order alone until a heading is clicked', () => {
    render(<Table rows={ROWS} columns={COLUMNS} />);
    expect(firstColumn()).toEqual(['Beta', 'Alpha', 'Gamma']);
  });

  it('sorts ascending on the first click and reverses on the second', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    await user.click(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(firstColumn()).toEqual(['Alpha', 'Beta', 'Gamma']);

    await user.click(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(firstColumn()).toEqual(['Gamma', 'Beta', 'Alpha']);
  });

  it('sorts a formatted column by its sortValue, not its rendered text', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    await user.click(screen.getByRole('button', { name: 'Sort by Qty' }));
    // 9 before 100, and the empty quantity last.
    expect(firstColumn()).toEqual(['Alpha', 'Beta', 'Gamma']);

    await user.click(screen.getByRole('button', { name: 'Sort by Qty' }));
    // Reversed — but the blank stays at the bottom rather than leading.
    expect(firstColumn()).toEqual(['Beta', 'Alpha', 'Gamma']);
  });

  it('marks the sorted column for assistive tech', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    const header = screen.getByRole('columnheader', { name: /Name/ });
    expect(header).toHaveAttribute('aria-sort', 'none');

    await user.click(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(header).toHaveAttribute('aria-sort', 'ascending');

    await user.click(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(header).toHaveAttribute('aria-sort', 'descending');
  });

  it('gives an opted-out column no control at all', () => {
    render(<Table rows={ROWS} columns={COLUMNS} />);
    expect(screen.queryByRole('button', { name: 'Sort by Note' })).not.toBeInTheDocument();
    // …and it is absent from the phone control too.
    const select = screen.getByRole('combobox', { name: 'Sort by' });
    expect(within(select).queryByRole('option', { name: 'Note' })).not.toBeInTheDocument();
  });

  it('shows a tooltip naming the column on hover, and hides it again on leave', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    expect(screen.queryByText('Sort by Name')).not.toBeInTheDocument();

    await user.hover(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(screen.getByText('Sort by Name')).toBeInTheDocument();

    await user.unhover(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(screen.queryByText('Sort by Name')).not.toBeInTheDocument();
  });

  it('dismisses the tooltip on click so it never sits over the rows', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    await user.hover(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(screen.getByText('Sort by Name')).toBeInTheDocument();

    // The native `title` this replaces stayed up while you clicked the same
    // heading again and again to flip direction.
    await user.click(screen.getByRole('button', { name: 'Sort by Name' }));
    expect(screen.queryByText('Sort by Name')).not.toBeInTheDocument();
    // …and the click still sorted.
    expect(firstColumn()).toEqual(['Alpha', 'Beta', 'Gamma']);
  });

  it('uses no native title, so the browser paints no second tooltip', () => {
    render(<Table rows={ROWS} columns={COLUMNS} />);
    expect(screen.getByRole('button', { name: 'Sort by Name' })).not.toHaveAttribute('title');
  });

  it('gives a non-sortable column no tooltip', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    await user.hover(screen.getByRole('columnheader', { name: 'Note' }));
    expect(screen.queryByText('Sort by Note')).not.toBeInTheDocument();
  });

  it('sorts from the phone control, which is the only affordance once headings are hidden', async () => {
    const user = userEvent.setup();
    render(<Table rows={ROWS} columns={COLUMNS} />);

    await user.selectOptions(screen.getByRole('combobox', { name: 'Sort by' }), 'name');
    expect(firstColumn()).toEqual(['Alpha', 'Beta', 'Gamma']);

    await user.click(screen.getByRole('button', { name: /reverse/i }));
    expect(firstColumn()).toEqual(['Gamma', 'Beta', 'Alpha']);
  });
});
