import { describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import GenericCrudPage from './GenericCrudPage.jsx';
import { ToastProvider } from '@/components/Toast.jsx';

/*
 * Paging and the row-number column on the hand-written tables.
 *
 * Most screens do not go through DataGrid — GenericCrudPage and ReadOnlyPages'
 * DataTable render their own <table>, and between them they back dozens of
 * pages. Both used to render every loaded row at once, so a few hundred flats
 * made one unreadable page, and neither numbered its rows. These cover the
 * shared behaviour on GenericCrudPage; DataTable uses the same `usePaging` and
 * markup.
 */
const COLUMNS = [
  { key: 'name', label: 'Name' },
  { key: 'flat', label: 'Flat' },
];

const rowsOf = (n) =>
  Array.from({ length: n }, (_, i) => ({ id: i + 1, name: `Member ${i + 1}`, flat: `A-${i + 1}` }));

/** A resource whose list() answers with `n` rows. */
const resourceOf = (n) => ({
  list: vi.fn().mockResolvedValue({ items: rowsOf(n) }),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
});

const renderPage = (n, props = {}) =>
  render(
    <ToastProvider>
      <GenericCrudPage
        title="Members"
        resource={resourceOf(n)}
        columns={COLUMNS}
        canCreate={false}
        canEdit={false}
        canDelete={false}
        {...props}
      />
    </ToastProvider>,
  );

/** The row numbers currently rendered, read off the first cell of each row. */
const numbers = (container) =>
  [...container.querySelectorAll('tbody tr')].map((tr) => tr.firstChild.textContent);

describe('GenericCrudPage paging', () => {
  it('shows one page of rows rather than the whole list', async () => {
    const { container } = renderPage(60, { pageSize: 25 });

    await waitFor(() => expect(container.querySelectorAll('tbody tr')).toHaveLength(25));
    expect(screen.getByText('1–25 of 60')).toBeTruthy();
  });

  it('numbers the rows and continues the count across pages', async () => {
    const user = userEvent.setup();
    const { container } = renderPage(60, { pageSize: 25 });

    await waitFor(() => expect(numbers(container)[0]).toBe('1'));
    expect(numbers(container).at(-1)).toBe('25');

    // Page 2 carries on from 26 — the number identifies a row in the whole
    // list, so restarting at 1 would make it meaningless.
    await user.click(screen.getByRole('button', { name: 'Page 2' }));
    expect(numbers(container)[0]).toBe('26');
    expect(screen.getByText('26–50 of 60')).toBeTruthy();

    // The last page is short, and the range text must not overrun the total.
    await user.click(screen.getByRole('button', { name: 'Page 3' }));
    expect(numbers(container)).toHaveLength(10);
    expect(screen.getByText('51–60 of 60')).toBeTruthy();
  });

  it('heads the number column "No."', async () => {
    renderPage(3);

    await waitFor(() => expect(screen.getAllByRole('columnheader').length).toBeGreaterThan(0));
    expect(screen.getAllByRole('columnheader').map((h) => h.textContent)).toEqual([
      'No.',
      'Name',
      'Flat',
    ]);
  });

  it('leaves the pager out when everything fits on one page', async () => {
    renderPage(8, { pageSize: 25 });

    await waitFor(() => expect(screen.getByText('Member 1')).toBeTruthy());
    expect(screen.queryByRole('navigation', { name: 'Pagination' })).toBeNull();
  });

  /*
   * The rows are a different set after a search, so holding position at page 3
   * of the old list would strand the view — often past the end of the new one.
   */
  it('returns to the first page when a search changes the list', async () => {
    const user = userEvent.setup();
    const { container } = renderPage(60, {
      pageSize: 25,
      // A client-side filter, so the list narrows without a refetch.
      filterRow: (r, term) => r.name.toLowerCase().includes(term),
    });

    await waitFor(() => expect(numbers(container)[0]).toBe('1'));
    await user.click(screen.getByRole('button', { name: 'Page 3' }));
    expect(numbers(container)[0]).toBe('51');

    await user.type(screen.getByRole('textbox', { name: 'Search Members' }), 'Member 1');
    await waitFor(() => expect(numbers(container)[0]).toBe('1'));
    expect(screen.queryByText(/^51–/)).toBeNull();
  });

  it('numbers a searched list 1..n with no gaps', async () => {
    const user = userEvent.setup();
    const { container } = renderPage(60, {
      pageSize: 25,
      filterRow: (r, term) => r.name.toLowerCase().includes(term),
    });

    await waitFor(() => expect(numbers(container)[0]).toBe('1'));
    // Matches Member 4 and Member 40..49 — a scattered subset of the rows.
    await user.type(screen.getByRole('textbox', { name: 'Search Members' }), 'Member 4');

    await waitFor(() => expect(numbers(container)).toHaveLength(11));
    expect(numbers(container)).toEqual(numbers(container).map((_, i) => String(i + 1)));
  });

  /*
   * Paging is a screen affordance: the export toolbar works from the full
   * sorted list, so a 60-row export must not shrink to the visible 25.
   */
  it('exports the whole list rather than the visible page', async () => {
    const { container } = renderPage(60, { pageSize: 25 });

    await waitFor(() => expect(container.querySelectorAll('tbody tr')).toHaveLength(25));
    const toolbar = screen.getByRole('button', { name: /excel/i });
    expect(toolbar).toBeTruthy();
    // The count in the header still describes the whole list.
    expect(within(container).getByText('60 record(s)')).toBeTruthy();
  });
});
