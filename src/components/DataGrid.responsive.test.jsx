import { describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import DataGrid from './DataGrid.jsx';

/*
 * The grid's phone layout.
 *
 * jsdom applies no media queries, so both views are in the tree at once and
 * the `sm:` classes are what decide which one a browser shows. These assert on
 * that wiring — that the two views exist, carry opposite visibility classes,
 * and that the card view can absorb a value with no break opportunity in it.
 */
const COLUMNS = [
  { key: 'flat', label: 'Flat' },
  { key: 'owner', label: 'Owner' },
  { key: 'ref', label: 'Reference' },
];

const ROWS = [
  { id: 1, flat: 'A-101', owner: 'R. Sharma', ref: 'UPI/2026/0000000000000482155' },
  { id: 2, flat: 'A-102', owner: 'S. Iyer', ref: 'NEFT/2026/0000000000000913744' },
];

const grid = (props) => render(<DataGrid columns={COLUMNS} rows={ROWS} {...props} />);

describe('DataGrid responsive views', () => {
  it('renders the table for wide screens and cards for narrow ones', () => {
    const { container } = grid();

    // The table is hidden below `sm`; the card list is hidden from `sm` up.
    const table = container.querySelector('table').closest('div');
    expect(table.className).toContain('hidden');
    expect(table.className).toContain('sm:block');

    const cards = container.querySelector('ul');
    expect(cards.className).toContain('sm:hidden');
  });

  it('gives the table its own horizontal scroller', () => {
    const { container } = grid();

    // A grid can carry more columns than a phone is wide. The table scrolls
    // inside its own box rather than dragging the page sideways.
    expect(container.querySelector('table').closest('div').className).toContain('overflow-x-auto');
  });

  /*
   * The regression this guards: a reference number has no break opportunity,
   * so without a wrap rule it set the card's width, and the whole list
   * scrolled sideways on a phone.
   */
  it('lets an unbreakable value wrap inside a card', () => {
    const { container } = grid();
    const card = within(container.querySelector('ul')).getByText(ROWS[0].ref);

    expect(card.className).toContain('break-anywhere');
    expect(card.className).toContain('min-w-0');
  });

  it('keeps a card label on one line so the value takes the slack', () => {
    const { container } = grid();
    const label = within(container.querySelector('ul')).getAllByText('Reference')[0];

    expect(label.className).toContain('shrink-0');
  });

  it('renders every column in both views', () => {
    const { container } = grid();
    const cards = within(container.querySelector('ul'));

    for (const c of COLUMNS) {
      expect(cards.getAllByText(c.label).length).toBe(ROWS.length);
    }
    // The grid prepends its own row-number column ahead of the caller's.
    expect(screen.getAllByRole('columnheader').map((h) => h.textContent)).toEqual([
      'No.',
      'Flat',
      'Owner',
      'Reference',
    ]);
  });

  /*
   * With 25 rows to a page the pager appears on any real list. Its range text
   * and the two buttons did not fit a 320px screen on one line.
   */
  it('wraps the pager rather than overflowing a narrow screen', () => {
    const rows = Array.from({ length: 30 }, (_, i) => ({
      id: i,
      flat: `A-${i}`,
      owner: `Owner ${i}`,
      ref: `R${i}`,
    }));
    const { container } = render(<DataGrid columns={COLUMNS} rows={rows} pageSize={10} />);

    const pager = screen.getByRole('navigation', { name: 'Pagination' }).parentElement;
    expect(pager.className).toContain('flex-wrap');
    expect(container.textContent).toContain('1–10 of 30');
  });
});
