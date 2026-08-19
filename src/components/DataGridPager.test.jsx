import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import DataGrid, { pageItems } from './DataGrid.jsx';

/*
 * The grid's pager.
 *
 * A member list runs to hundreds of rows, and reaching the end of it by
 * holding Next is not a list anyone reads. These cover the numbered pages:
 * that they appear, that they move the grid, and that a long list windows its
 * numbers instead of printing one button per page.
 */
const COLUMNS = [
  { key: 'flat', label: 'Flat' },
  { key: 'owner', label: 'Owner' },
];

const rowsOf = (n) =>
  Array.from({ length: n }, (_, i) => ({ id: i, flat: `A-${i + 1}`, owner: `Owner ${i + 1}` }));

describe('pageItems', () => {
  it('lists every page when they all fit', () => {
    expect(pageItems(0, 5)).toEqual([0, 1, 2, 3, 4]);
    expect(pageItems(0, 7)).toEqual([0, 1, 2, 3, 4, 5, 6]);
  });

  it('collapses only the far side near the start', () => {
    expect(pageItems(1, 20)).toEqual([0, 1, 2, 3, 4, '…', 19]);
  });

  it('collapses only the near side at the end', () => {
    expect(pageItems(19, 20)).toEqual([0, '…', 15, 16, 17, 18, 19]);
  });

  it('keeps a neighbour either side in the middle', () => {
    expect(pageItems(10, 20)).toEqual([0, '…', 9, 10, 11, '…', 19]);
  });

  /*
   * The window is fixed-width so the pager does not resize as the user walks
   * through the pages — buttons must not move under the pointer.
   */
  it('holds a steady width across a long list', () => {
    const widths = new Set();
    for (let p = 0; p < 40; p += 1) widths.add(pageItems(p, 40).length);
    expect([...widths]).toEqual([7]);
  });
});

describe('DataGrid pagination', () => {
  it('numbers the pages and marks the current one', () => {
    render(<DataGrid columns={COLUMNS} rows={rowsOf(30)} pageSize={10} />);

    expect(screen.getByRole('button', { name: 'Page 1' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByRole('button', { name: 'Page 3' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Page 4' })).toBeNull();
  });

  it('shows the chosen page when a number is clicked', async () => {
    const user = userEvent.setup();
    render(<DataGrid columns={COLUMNS} rows={rowsOf(30)} pageSize={10} />);

    // Page 1 holds A-1..A-10, so A-21 is proof the third page rendered. Both
    // views are in the jsdom tree at once, so it appears once per view.
    expect(screen.queryAllByText('A-21')).toHaveLength(0);
    await user.click(screen.getByRole('button', { name: 'Page 3' }));

    expect(screen.getAllByText('A-21').length).toBeGreaterThan(0);
    expect(screen.getByRole('button', { name: 'Page 3' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByText('21–30 of 30')).toBeTruthy();
  });

  it('windows the numbers rather than one button per page', () => {
    render(<DataGrid columns={COLUMNS} rows={rowsOf(500)} pageSize={10} />);

    // 50 pages, 7 slots. Without windowing this would be 50 buttons.
    const numbered = screen
      .getAllByRole('button')
      .filter((b) => /^Page \d+$/.test(b.getAttribute('aria-label') ?? ''));
    expect(numbered).toHaveLength(6);
    expect(screen.getByRole('button', { name: 'Page 50' })).toBeTruthy();
  });

  /*
   * The number identifies a row in the whole list, so it must not restart at 1
   * on every page — page 2 of a 10-row grid begins at 11.
   */
  it('continues the row numbering across pages', async () => {
    const user = userEvent.setup();
    const { container } = render(<DataGrid columns={COLUMNS} rows={rowsOf(30)} pageSize={10} />);

    const numbers = () =>
      [...container.querySelectorAll('tbody tr')].map((tr) => tr.firstChild.textContent);

    expect(numbers()[0]).toBe('1');
    expect(numbers().at(-1)).toBe('10');

    await user.click(screen.getByRole('button', { name: 'Page 2' }));
    expect(numbers()[0]).toBe('11');
    expect(numbers().at(-1)).toBe('20');
  });

  it('numbers 1..n with no gaps after a search narrows the list', async () => {
    const user = userEvent.setup();
    const { container } = render(
      <DataGrid columns={COLUMNS} rows={rowsOf(30)} pageSize={25} searchable />,
    );

    // "Owner 2" also matches Owner 20..29, giving a scattered subset of rows.
    await user.type(screen.getByRole('searchbox'), 'Owner 2');
    const numbers = [...container.querySelectorAll('tbody tr')].map(
      (tr) => tr.firstChild.textContent,
    );

    expect(numbers).toEqual(numbers.map((_, i) => String(i + 1)));
  });

  it('can be switched off by a screen that supplies its own', () => {
    render(<DataGrid columns={COLUMNS} rows={rowsOf(3)} serialColumn={false} />);

    expect(screen.getAllByRole('columnheader').map((h) => h.textContent)).toEqual([
      'Flat',
      'Owner',
    ]);
  });

  it('leaves the pager out when everything fits on one page', () => {
    render(<DataGrid columns={COLUMNS} rows={rowsOf(8)} pageSize={25} />);

    expect(screen.queryByRole('navigation', { name: 'Pagination' })).toBeNull();
  });

  /*
   * Searching to a shorter result set while on a later page used to leave the
   * grid past the end. `safePage` clamps it, and the numbers follow.
   */
  it('clamps to the last page when a search shortens the list', async () => {
    const user = userEvent.setup();
    const { rerender } = render(<DataGrid columns={COLUMNS} rows={rowsOf(30)} pageSize={10} />);

    await user.click(screen.getByRole('button', { name: 'Page 3' }));
    rerender(<DataGrid columns={COLUMNS} rows={rowsOf(12)} pageSize={10} />);

    expect(screen.getByRole('button', { name: 'Page 2' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByText('11–12 of 12')).toBeTruthy();
  });
});
