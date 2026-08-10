import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render as rtlRender, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { http } from 'msw';
import { server, ok, fail } from '@/test/server';
import { writeSession } from '@/api/client';
import { InventoryMasterPage } from './MasterPages.jsx';

// The page links to the vendor bills screen, so it needs a router context.
const render = (ui) => rtlRender(<MemoryRouter>{ui}</MemoryRouter>);

const BASE = '/api/web';

const ITEM = {
  item_id: 7,
  item_name: 'Water pump',
  quantity: 2,
  unit: 'nos',
  vendor_id: 4,
  vendor_name: 'Acme Pumps',
  // Items reach this grid through an approved vendor bill.
  vendor_bill_id: 25,
  purchase_date: '2026-01-10',
  purchase_cost: 15000,
  total_amount: 30000,
  warranty: 6,
  warranty_last_date: '2026-07-10',
  // "Good" in InventoryMaster.aspx's list.
  condition_status: 2,
};

const listHandler = (items = [ITEM]) =>
  http.get(`${BASE}/masters/inventory`, () => ok({ items, count: items.length }));

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

/**
 * The table rendering of the row's dropdown.
 *
 * DataGrid renders both a table and a stacked-card list and hides one by
 * breakpoint, so every row has two of these in the DOM. The assertions below
 * take the table's; the card's is the same component with the same value.
 */
async function findConditionSelect() {
  const all = await screen.findAllByRole('combobox', { name: /condition for water pump/i });
  return all[0];
}

describe('InventoryMasterPage condition', () => {
  it('shows the stored condition using the legacy code list', async () => {
    server.use(listHandler());
    render(<InventoryMasterPage />);

    const select = await findConditionSelect();
    // 2 is "Good" — the list this page previously used had 2 as "Damaged",
    // which named a different condition than the one stored.
    expect(select).toHaveValue('2');
    expect(select.selectedOptions[0]).toHaveTextContent('Good');
  });

  it('saves the new condition from the grid without opening the form', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      listHandler(),
      http.put(`${BASE}/masters/inventory/7/condition`, async ({ request }) => {
        saved(await request.json());
        return ok({ item_id: 7, condition_status: 3 });
      }),
    );
    render(<InventoryMasterPage />);

    const select = await findConditionSelect();
    await user.selectOptions(select, '3');

    await waitFor(() => expect(saved).toHaveBeenCalledWith({ conditionStatus: 3 }));
    expect(select).toHaveValue('3');
  });

  it('opens the edit form on the condition just set in the grid', async () => {
    const user = userEvent.setup();
    server.use(
      listHandler(),
      http.put(`${BASE}/masters/inventory/7/condition`, () => ok({ item_id: 7, condition_status: 1 })),
    );
    render(<InventoryMasterPage />);

    const select = await findConditionSelect();
    await user.selectOptions(select, '1'); // New
    await waitFor(() => expect(select).toHaveValue('1'));

    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    // The row still carries the condition it was loaded with, so reading it
    // straight showed "Good" here while the grid showed "New" — and saving
    // the form would have written that stale value back.
    const inForm = await screen.findByLabelText(/^condition$/i);
    expect(inForm).toHaveValue('1');
  });

  it('drops the grid override once the reloaded row carries a new value', async () => {
    const user = userEvent.setup();
    let stored = 2;
    server.use(
      http.get(`${BASE}/masters/inventory`, () =>
        ok({ items: [{ ...ITEM, condition_status: stored }], count: 1 }),
      ),
      http.put(`${BASE}/masters/inventory/7/condition`, () => ok({ item_id: 7 })),
      http.post(`${BASE}/masters/inventory`, async ({ request }) => {
        stored = Number((await request.json()).conditionStatus);
        return ok({ saved: true });
      }),
    );
    render(<InventoryMasterPage />);

    const select = await findConditionSelect();
    await user.selectOptions(select, '1'); // grid says New
    await waitFor(() => expect(select).toHaveValue('1'));

    // Saving the form reloads the grid. The override must not keep masking
    // what came back, or the grid would show New for ever.
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);
    await user.selectOptions(await screen.findByLabelText(/^condition$/i), '4');
    await user.click(screen.getByRole('button', { name: /^save$/i }));

    await waitFor(async () => expect(await findConditionSelect()).toHaveValue('4'));
  });

  it('fills the edit form from the row, vendor included', async () => {
    const user = userEvent.setup();
    server.use(listHandler());
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    expect(await screen.findByLabelText(/item name/i)).toHaveValue('Water pump');
    // The vendor is on the row but was never put on the form, so the edit
    // modal showed nothing for it.
    expect(screen.getByLabelText(/vendor name/i)).toHaveValue('Acme Pumps');
    expect(screen.getByLabelText(/purchase date/i)).toHaveValue('2026-01-10');
    expect(screen.getByLabelText(/quantity/i)).toHaveValue(2);
    expect(screen.getByLabelText(/^unit$/i)).toHaveValue('nos');
    expect(screen.getByLabelText(/warranty \(months\)/i)).toHaveValue(6);
  });

  it('keeps the item attached to its vendor and bill when saved', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      listHandler(),
      http.post(`${BASE}/masters/inventory`, async ({ request }) => {
        saved(await request.json());
        return ok({ saved: true });
      }),
    );
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);
    await user.click(await screen.findByRole('button', { name: /^save$/i }));

    // vendorId and vendorBillId were absent from the form, so a plain edit
    // sent 0 for both — detaching the item from its bill, which the grid
    // joins on, and dropping it from the list for good.
    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({ vendorId: 4, vendorBillId: 25 });
  });

  it('recomputes the warranty last date as the form changes', async () => {
    const user = userEvent.setup();
    server.use(listHandler());
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    // 2026-01-10 + 6 months.
    const derived = await screen.findByLabelText(/warranty last date/i);
    expect(derived).toHaveValue('2026-07-10');

    const months = screen.getByLabelText(/warranty \(months\)/i);
    await user.clear(months);
    await user.type(months, '24');
    expect(derived).toHaveValue('2028-01-10');
  });

  it('clamps a month-end warranty date the way DATEADD does', async () => {
    const user = userEvent.setup();
    // 31 Jan + 1 month is 28 Feb in SQL Server; Date.setMonth would roll over
    // into March and disagree with the grid's DATEADD column.
    server.use(listHandler([{ ...ITEM, purchase_date: '2026-01-31', warranty: 1 }]));
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    expect(await screen.findByLabelText(/warranty last date/i)).toHaveValue('2026-02-28');
  });

  it('offers each condition once in the edit form', async () => {
    const user = userEvent.setup();
    server.use(listHandler());
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    const select = await screen.findByLabelText(/^condition$/i);
    // Code 0 is the legacy list's "Select", which is what SelectField's own
    // placeholder already means — listing both showed "Select" twice.
    const labels = [...select.options].map((o) => o.textContent);
    expect(labels.filter((l) => /select/i.test(l))).toHaveLength(1);
    expect(labels).toEqual(['Select…', 'New', 'Good', 'Needs repair', 'Disposed']);
  });

  it('shows an unset condition as the placeholder, not a blank box', async () => {
    const user = userEvent.setup();
    // Rows written before this screen existed have condition_status 0 or null.
    server.use(listHandler([{ ...ITEM, condition_status: 0 }]));
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.click(screen.getAllByRole('button', { name: 'Edit' })[0]);

    const select = await screen.findByLabelText(/^condition$/i);
    expect(select).toHaveValue('');
    expect(select.selectedOptions[0]).toHaveTextContent('Select…');
  });

  it('filters the loaded rows as you type, without refetching', async () => {
    const user = userEvent.setup();
    const listed = vi.fn();
    server.use(
      http.get(`${BASE}/masters/inventory`, ({ request }) => {
        listed(new URL(request.url).searchParams.get('search'));
        return ok({
          items: [ITEM, { ...ITEM, item_id: 8, item_name: 'Ceiling fan', vendor_name: 'Breeze Co' }],
          count: 2,
        });
      }),
    );
    render(<InventoryMasterPage />);

    await screen.findAllByText('Ceiling fan');
    await user.type(screen.getByLabelText(/search inventory/i), 'pump');

    await waitFor(() => expect(screen.queryByText('Ceiling fan')).not.toBeInTheDocument());
    expect(screen.getAllByText('Water pump').length).toBeGreaterThan(0);
    // The endpoint has no search operation, so the term must never become a
    // query parameter — the legacy page filtered the rendered table too.
    expect(listed).toHaveBeenCalledTimes(1);
    expect(listed).toHaveBeenCalledWith(null);
  });

  it('matches the vendor as well as the item name', async () => {
    const user = userEvent.setup();
    server.use(
      listHandler([
        ITEM,
        { ...ITEM, item_id: 8, item_name: 'Ceiling fan', vendor_name: 'Breeze Co' },
      ]),
    );
    render(<InventoryMasterPage />);

    await screen.findAllByText('Water pump');
    await user.type(screen.getByLabelText(/search inventory/i), 'breeze');

    await waitFor(() => expect(screen.queryByText('Water pump')).not.toBeInTheDocument());
    expect(screen.getAllByText('Ceiling fan').length).toBeGreaterThan(0);
  });

  it('puts the previous condition back when the save fails', async () => {
    const user = userEvent.setup();
    server.use(
      listHandler(),
      http.put(`${BASE}/masters/inventory/7/condition`, () => fail(500, 'Database unavailable')),
    );
    render(<InventoryMasterPage />);

    const select = await findConditionSelect();
    await user.selectOptions(select, '4');

    // Leaving the box showing a value the database does not hold would be
    // worse than saying nothing was saved.
    await waitFor(() => expect(select).toHaveValue('2'));
    expect(screen.getAllByRole('alert')[0]).toHaveTextContent('Not saved');
  });
});
