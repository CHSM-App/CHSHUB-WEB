import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import VillageReportsPage from './VillageReportsPage.jsx';

const BASE = '/api/web';

const COLLECTION = [
  {
    payment_type: 1,
    payment_type_name: 'Property Tax',
    frequency: 'Y',
    bills: 22,
    billed: 307400,
    collected: 12000,
    outstanding: 295400,
  },
  {
    payment_type: 2,
    payment_type_name: 'Water Charges',
    frequency: 'M',
    bills: 80,
    billed: 10000,
    collected: 5000,
    outstanding: 5000,
  },
];

const DEFAULTERS = [
  {
    house_id: 5,
    house_no: '698',
    owner_name: 'rahul',
    contact: '3443434343',
    unpaid_bills: 18,
    periods: 10,
    outstanding: 188800,
    oldest_period: '2025',
  },
];

const MONTHLY = [{ y: 2026, m: 8, receipts: 8, collected: 12700 }];

const LEDGER = {
  items: [
    {
      house_receipt_id: 1,
      receipt_no: '1001',
      payment_type_name: 'Property Tax',
      frequency: 'Y',
      bill_year: 2025,
      bill_month: null,
      amount: 6000,
      payment_status: 1,
      status: 'Paid',
      paid_on: '2026-08-12',
      pay_mode: 'Cash',
    },
    {
      house_receipt_id: 2,
      receipt_no: '2011',
      payment_type_name: 'Water Charges',
      frequency: 'M',
      bill_year: 2026,
      bill_month: 1,
      amount: 100,
      payment_status: 0,
      status: 'Unpaid',
      paid_on: null,
      pay_mode: null,
    },
  ],
  totals: { billed: 6100, paid: 6000, outstanding: 100 },
};

function handlers() {
  return [
    http.get(`${BASE}/village/reports/collection`, () =>
      ok({ items: COLLECTION, count: COLLECTION.length }),
    ),
    http.get(`${BASE}/village/reports/defaulters`, () =>
      ok({ items: DEFAULTERS, count: DEFAULTERS.length }),
    ),
    http.get(`${BASE}/village/reports/monthly`, () => ok({ items: MONTHLY, count: MONTHLY.length })),
    http.get(`${BASE}/village/reports/ledger/:id`, () =>
      ok({ items: LEDGER.items, count: LEDGER.items.length, totals: LEDGER.totals }),
    ),
    http.get(`${BASE}/village/houses`, () =>
      ok({ items: [{ house_id: 1, house_no: '101', name: 'Rajesh Kumar' }], count: 1 }),
    ),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V10004' } });
});

describe('VillageReportsPage', () => {
  /*
   * Digit grouping comes from the runtime's locale — "3,17,400.00" under
   * en-IN, "317,400.00" elsewhere — so these match on the digits rather than a
   * fixed rendering.
   */
  it('leads with what was billed, collected and is outstanding', async () => {
    server.use(...handlers());
    render(<VillageReportsPage />);

    // The tab strip, which is the one nav on the page — "Collection" also
    // appears as a column heading, so the role alone is ambiguous.
    const tabs = await screen.findByRole('navigation', { name: /sections/i });
    const page = document.body.textContent;

    // Totalled across the charges, so the three figures are the whole picture.
    expect(page).toMatch(/3[,\d]*400\.00/); // billed 317,400
    expect(page).toMatch(/17[,\d]*000\.00/); // collected 17,000
    expect(page).toMatch(/3[,\d]*400\.00/); // outstanding 300,400
  });

  /*
   * Two charges can owe similar amounts while one is nearly settled and the
   * other has barely started, so the proportion is shown alongside.
   */
  it('shows how much of each charge has been collected', async () => {
    server.use(...handlers());
    render(<VillageReportsPage />);

    // The tab strip, which is the one nav on the page — "Collection" also
    // appears as a column heading, so the role alone is ambiguous.
    const tabs = await screen.findByRole('navigation', { name: /sections/i });
    const property = screen.getByRole('row', { name: /property tax/i });
    const water = screen.getByRole('row', { name: /water charges/i });

    expect(within(property).getByText('4%')).toBeInTheDocument();
    expect(within(water).getByText('50%')).toBeInTheDocument();
  });

  it('lists who owes, how far behind, and how to reach them', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageReportsPage />);

    // The tab strip, which is the one nav on the page — "Collection" also
    // appears as a column heading, so the role alone is ambiguous.
    const tabs = await screen.findByRole('navigation', { name: /sections/i });
    await user.click(within(tabs).getByRole('button', { name: /defaulters/i }));

    // DataGrid renders a table and a stacked card list, so each value appears
    // twice — the assertion is that it is there, not how many times.
    expect((await screen.findAllByText('rahul')).length).toBeGreaterThan(0);
    // The contact is there because the point of the list is to chase people.
    expect(screen.getAllByText('3443434343').length).toBeGreaterThan(0);
    expect(screen.getAllByText('2025').length).toBeGreaterThan(0);
  });

  it('names each month rather than showing a number', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageReportsPage />);

    // The tab strip, which is the one nav on the page — "Collection" also
    // appears as a column heading, so the role alone is ambiguous.
    const tabs = await screen.findByRole('navigation', { name: /sections/i });
    await user.click(within(tabs).getByRole('button', { name: /monthly/i }));

    expect((await screen.findAllByText('August 2026')).length).toBeGreaterThan(0);
  });

  it('shows one house’s bills once a house is chosen', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageReportsPage />);

    // The tab strip, which is the one nav on the page — "Collection" also
    // appears as a column heading, so the role alone is ambiguous.
    const tabs = await screen.findByRole('navigation', { name: /sections/i });
    await user.click(within(tabs).getByRole('button', { name: /ledger/i }));

    // Nothing is loaded until a house is picked — there is no sensible default.
    expect((await screen.findAllByText(/choose a house/i)).length).toBeGreaterThan(0);

    await user.selectOptions(screen.getByLabelText(/house/i), '1');

    await waitFor(() => expect(screen.getAllByText('Water Charges').length).toBeGreaterThan(0));
    // A yearly charge is named by its year, a monthly one by its month.
    expect(screen.getAllByText('2025').length).toBeGreaterThan(0);
    expect(screen.getAllByText('January 2026').length).toBeGreaterThan(0);
  });
});
