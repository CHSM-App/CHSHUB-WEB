import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import HouseChargesPage from './HouseChargesPage.jsx';

const BASE = '/api/web';

const TYPES = [
  { payment_type: 1, payment_type_name: 'Property Tax', frequency: 'Y', basis: 'AREA' },
  { payment_type: 2, payment_type_name: 'Water Charges', frequency: 'M', basis: 'TAP' },
  { payment_type: 3, payment_type_name: 'Waste Charges', frequency: 'M', basis: 'FLAT' },
];

/** One row per house per charge type, as sp_house_charge Grid_Show returns. */
function grid(houses) {
  return houses.flatMap((h) =>
    TYPES.map((t) => ({
      house_id: h.house_id,
      house_no: h.house_no,
      area: h.area,
      no_of_tab: h.no_of_tab,
      ...t,
      house_charge_id: h.charges[t.payment_type] == null ? null : h.house_id * 10 + t.payment_type,
      amount: h.charges[t.payment_type] ?? null,
      applies: h.charges[t.payment_type] != null,
      effective_from: h.from?.[t.payment_type] ?? '2026-08-01',
      pending: Boolean(h.pending?.[t.payment_type]),
    })),
  );
}

// House 101 has taps and pays everything. House 0 has no tap connection, so it
// has no water row at all — the case dbo.house's three columns could not express.
const HOUSES = [
  { house_id: 1, house_no: '101', area: 1200, no_of_tab: 2, charges: { 1: 6000, 2: 100, 3: 100 } },
  { house_id: 11, house_no: '0', area: 100, no_of_tab: 0, charges: { 1: 200, 3: 500 } },
];

/** sp_village_charge_type Grid_Show — the charges the village levies. */
function chargeTypeRows() {
  return TYPES.map((t) => ({
    ...t,
    active_status: 0,
    is_builtin: t.payment_type <= 3,
    // Locked once billed, whichever charge it is.
    is_locked: true,
    houses_charged: 2,
    bills_raised: 9,
  }));
}

function handlers({ houses = HOUSES, types = chargeTypeRows(), onSave, onCreate, onRemove } = {}) {
  return [
    http.get(`${BASE}/village/house-charges`, () => {
      const items = grid(houses);
      return ok({ items, count: items.length });
    }),
    http.put(`${BASE}/village/house-charges`, async ({ request }) => {
      onSave?.(await request.json());
      return ok({ saved: true });
    }),
    http.get(`${BASE}/village/charge-types`, () => ok({ items: types, count: types.length })),
    http.post(`${BASE}/village/charge-types`, async ({ request }) => {
      onCreate?.(await request.json());
      return ok({ created: true, payment_type: 4 }, 201);
    }),
    http.delete(`${BASE}/village/charge-types/:id`, ({ params }) => {
      onRemove?.(params.id);
      return ok({ deactivated: true });
    }),
  ];
}

/*
 * The house grid's row for one house. Matched on the first cell rather than
 * the row's accessible name: that name is every cell's text run together, so
 * it changes whenever a cell gains a label such as "from Sep 2026".
 */
const rowFor = (houseNo) => {
  const grid = screen.getAllByRole('table').at(-1);
  const row = within(grid)
    .getAllByRole('row')
    .find((r) => r.querySelector('td')?.textContent === String(houseNo));
  if (!row) throw new Error(`No row for house ${houseNo}`);
  return row;
};

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V10004' } });
});

describe('HouseChargesPage', () => {
  it('shows each charge against each house', async () => {
    server.use(...handlers());
    render(<HouseChargesPage />);

    await screen.findByText('101');
    expect(screen.getByRole('columnheader', { name: /property tax/i })).toBeInTheDocument();
    expect(screen.getByRole('columnheader', { name: /water charges/i })).toBeInTheDocument();
    expect(screen.getByRole('columnheader', { name: /waste charges/i })).toBeInTheDocument();
  });

  /*
   * The point of house_charge: a house with no tap connection is not billed
   * for water. Under the old three-column shape it was.
   */
  it('marks a charge that does not apply as not billed', async () => {
    server.use(...handlers());
    render(<HouseChargesPage />);

    await screen.findByText('101');

    const noTaps = rowFor('0');
    expect(within(noTaps).getByLabelText(/water charges applies to house 0/i)).not.toBeChecked();
    expect(within(noTaps).getByText(/not billed/i)).toBeInTheDocument();

    // The house that does have taps is billed.
    const withTaps = rowFor('101');
    expect(within(withTaps).getByLabelText(/water charges applies to house 101/i)).toBeChecked();
  });

  it('switches a charge off for one house', async () => {
    const user = userEvent.setup();
    const onSave = vi.fn();
    server.use(...handlers({ onSave }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    await user.click(
      within(rowFor('101')).getByLabelText(/water charges applies to house 101/i),
    );

    await waitFor(() => expect(onSave).toHaveBeenCalled());
    expect(onSave.mock.calls[0][0]).toMatchObject({ houseId: 1, paymentType: 2, applies: false });
  });

  it('edits the amount a house is charged', async () => {
    const user = userEvent.setup();
    const onSave = vi.fn();
    server.use(...handlers({ onSave }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    // The amount is a button until clicked, so the grid stays readable.
    await user.click(within(rowFor('101')).getByRole('button', { name: '6,000.00' }));

    const input = await screen.findByLabelText(/property tax amount for house 101/i);
    await user.clear(input);
    await user.type(input, '6500');
    await user.tab();

    await waitFor(() => expect(onSave).toHaveBeenCalled());
    expect(onSave.mock.calls[0][0]).toMatchObject({
      houseId: 1,
      paymentType: 1,
      applies: true,
      amount: '6500',
    });
  });

  /*
   * Adding a charge was an INSERT run by hand before this: neither application
   * could create one, so a village levying a fourth charge had to wait for a
   * developer.
   */
  it('adds a charge the village levies itself', async () => {
    const user = userEvent.setup();
    const onCreate = vi.fn();
    server.use(...handlers({ onCreate }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    await user.click(screen.getByRole('button', { name: /add charge/i }));

    await user.type(await screen.findByLabelText(/^name/i), 'Street Light Tax');
    await user.selectOptions(screen.getByLabelText(/how often/i), 'M');
    await user.selectOptions(screen.getByLabelText(/how the amount/i), 'FLAT');
    await user.click(screen.getByRole('button', { name: /^save$/i }));

    await waitFor(() => expect(onCreate).toHaveBeenCalled());
    expect(onCreate.mock.calls[0][0]).toMatchObject({
      name: 'Street Light Tax',
      frequency: 'M',
      basis: 'FLAT',
    });
  });

  /*
   * The three built-ins carry 81 bills and are joined by name in views and
   * procedures. Renaming is fine; re-shaping them would reinterpret bills
   * already raised.
   */
  it('will not let a built-in charge be removed or re-shaped', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<HouseChargesPage />);

    await screen.findByText('101');

    // The charge list is the first table; the house grid below repeats these
    // names in its column headers, so scope the lookup to that table.
    const [chargeList] = screen.getAllByRole('table');
    const row = within(chargeList).getByRole('row', { name: /property tax/i });
    expect(within(row).queryByRole('button', { name: /remove/i })).not.toBeInTheDocument();

    await user.click(within(row).getByRole('button', { name: /edit/i }));
    expect(await screen.findByLabelText(/how often/i)).toBeDisabled();
    expect(screen.getByLabelText(/how the amount/i)).toBeDisabled();
    // The name is still editable.
    expect(screen.getByLabelText(/^name/i)).not.toBeDisabled();
  });

  /*
   * A bill stores its period in the shape the charge had when it was raised.
   * Re-shaping the charge afterwards orphans those bills — the run stops
   * recognising them and bills the period again, which is how one household
   * ended up owing 500 and 100 for a single charge.
   */
  it('locks a village-added charge once it has been billed', async () => {
    const user = userEvent.setup();
    const types = [
      ...chargeTypeRows(),
      {
        payment_type: 4,
        payment_type_name: 'Street Light Tax',
        frequency: 'M',
        basis: 'FLAT',
        active_status: 0,
        is_builtin: false,
        is_locked: true,
        houses_charged: 1,
        bills_raised: 1,
      },
    ];
    server.use(...handlers({ types }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    const [chargeList] = screen.getAllByRole('table');
    const row = within(chargeList).getByRole('row', { name: /street light tax/i });
    await user.click(within(row).getByRole('button', { name: /edit/i }));

    expect(await screen.findByLabelText(/how often/i)).toBeDisabled();
    expect(screen.getByLabelText(/how the amount/i)).toBeDisabled();
    expect(screen.getByText(/bills have already been raised/i)).toBeInTheDocument();
    // Renaming is still allowed: a name cannot misdescribe a period.
    expect(screen.getByLabelText(/^name/i)).not.toBeDisabled();
  });

  it('lets a charge with no bills yet be re-shaped', async () => {
    const user = userEvent.setup();
    const types = [
      ...chargeTypeRows(),
      {
        payment_type: 4,
        payment_type_name: 'Market Fee',
        frequency: 'M',
        basis: 'FLAT',
        active_status: 0,
        is_builtin: false,
        is_locked: false,
        houses_charged: 0,
        bills_raised: 0,
      },
    ];
    server.use(...handlers({ types }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    const [chargeList] = screen.getAllByRole('table');
    const row = within(chargeList).getByRole('row', { name: /market fee/i });
    await user.click(within(row).getByRole('button', { name: /edit/i }));

    expect(await screen.findByLabelText(/how often/i)).not.toBeDisabled();
    expect(screen.getByLabelText(/how the amount/i)).not.toBeDisabled();
  });

  it('removes a charge the village added', async () => {
    const user = userEvent.setup();
    const onRemove = vi.fn();
    const types = [
      ...chargeTypeRows(),
      {
        payment_type: 4,
        payment_type_name: 'Street Light Tax',
        frequency: 'M',
        basis: 'FLAT',
        active_status: 0,
        is_builtin: false,
        houses_charged: 0,
        bills_raised: 0,
      },
    ];
    server.use(...handlers({ types, onRemove }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    const [chargeList] = screen.getAllByRole('table');
    const row = within(chargeList).getByRole('row', { name: /street light tax/i });
    await user.click(within(row).getByRole('button', { name: /remove/i }));

    // The row's own button and the dialog's both read "Remove"; confirm on the
    // one inside the dialog.
    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: /^remove$/i }));

    await waitFor(() => expect(onRemove).toHaveBeenCalledWith('4'));
  });

  /*
   * The date is the whole of the rule made visible: an amount changed after
   * the period was billed does not apply until the next one. Without it on
   * screen, a figure typed today and a figure already in force look identical.
   */
  it('says when each amount starts applying', async () => {
    server.use(...handlers());
    render(<HouseChargesPage />);

    await screen.findByText('101');
    const row = rowFor('101');

    // In force already — a monthly charge is named by its month, spelled
    // however the runtime's locale data spells it.
    expect(row.textContent).toMatch(/since Aug\w* 2026/);
    // A yearly charge is named by its year alone, not a day in a month.
    expect(within(row).getByText(/since 2026$/)).toBeInTheDocument();
  });

  it('marks an amount that has not started yet', async () => {
    const houses = [
      {
        house_id: 1,
        house_no: '101',
        area: 1200,
        no_of_tab: 2,
        charges: { 1: 6000, 2: 175, 3: 100 },
        // Water was changed after August had already been billed, so it does
        // not take effect until September.
        from: { 2: '2026-09-01' },
        pending: { 2: true },
      },
    ];
    server.use(...handlers({ houses }));
    render(<HouseChargesPage />);

    await screen.findByText('101');
    /*
     * Asserted on the row's text, since "from " and the month are separate
     * text nodes in one span. The month's spelling comes from the runtime's
     * locale data — "Sep" or "Sept" — so match the shared prefix.
     */
    expect(rowFor('101').textContent).toMatch(/from Sep\w* 2026/);
  });

  it('narrows the list by house number', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<HouseChargesPage />);

    await screen.findByText('101');
    await user.type(screen.getByLabelText(/search house charges/i), '101');

    await waitFor(() => expect(screen.queryByRole('row', { name: /^0\b/ })).not.toBeInTheDocument());
    expect(screen.getByText('101')).toBeInTheDocument();
  });
});
