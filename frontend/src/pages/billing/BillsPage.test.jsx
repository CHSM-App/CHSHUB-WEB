import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import BillsPage from './BillsPage.jsx';
import GenerateBillsPage from './GenerateBillsPage.jsx';

const BASE = '/api/web';

const RUNS = [
  { bill_id: 39, gen_date: '2026-07-01T00:00:00.000Z', due_date: '2026-07-15', month: 7, month_name: 'July', year: 2026, Status: 'Bill Generated' },
  { bill_id: 38, gen_date: '2025-06-01T00:00:00.000Z', due_date: '2025-06-15', month: 6, month_name: 'June', year: 2025, Status: 'Bill Generated' },
];

// The charge columns are pivoted per society, so the page must discover them
// from chargeColumns rather than assuming a fixed set.
const DETAIL = {
  run: RUNS[0],
  items: [
    {
      flat_id: 3,
      bill_no: 494,
      Unit: 'W-1 301',
      owner_name: 'Asha Kulkarni',
      col2_name: 'Parking Charges',
      col2_amount: 200,
      col3_name: 'Sinking Fund',
      col3_amount: 1832,
      tax_interest_amt: 15.5,
      total_amount: 2047.5,
      due: 2047.5,
    },
  ],
  chargeColumns: [
    { nameKey: 'col2_name', amountKey: 'col2_amount' },
    { nameKey: 'col3_name', amountKey: 'col3_amount' },
  ],
};

beforeEach(() => {
  writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1', user: { society_id: 'C10001' } });
});

describe('BillsPage', () => {
  it('lists bill runs', async () => {
    server.use(http.get(`${BASE}/billing/bills`, () => ok({ items: RUNS, count: RUNS.length })));
    render(<BillsPage />);

    expect(await screen.findByText('#39')).toBeInTheDocument();
    expect(screen.getByText('July 2026')).toBeInTheDocument();
    expect(screen.getByText(/2 bill run/i)).toBeInTheDocument();
  });

  it('filters by year', async () => {
    server.use(http.get(`${BASE}/billing/bills`, () => ok({ items: RUNS, count: RUNS.length })));
    const user = userEvent.setup();
    render(<BillsPage />);
    await screen.findByText('#39');

    await user.selectOptions(screen.getByLabelText(/filter by year/i), '2025');
    expect(screen.queryByText('#39')).not.toBeInTheDocument();
    expect(screen.getByText('#38')).toBeInTheDocument();
  });

  it('renders dynamic charge columns in the detail view', async () => {
    server.use(
      http.get(`${BASE}/billing/bills`, () => ok({ items: RUNS, count: RUNS.length })),
      http.get(`${BASE}/billing/bills/39`, () => ok(DETAIL)),
    );

    const user = userEvent.setup();
    render(<BillsPage />);
    await screen.findByText('#39');
    await user.click(screen.getAllByRole('button', { name: /view flats/i })[0]);

    const dialog = await screen.findByRole('dialog');
    // Column headers come from the data, not from hardcoded markup.
    expect(within(dialog).getByText('Parking Charges')).toBeInTheDocument();
    expect(within(dialog).getByText('Sinking Fund')).toBeInTheDocument();
    expect(within(dialog).getByText('Asha Kulkarni')).toBeInTheDocument();
    // 2,047.50 is both the total and the due, so assert on the count.
    expect(within(dialog).getAllByText('2,047.50')).toHaveLength(2);
    expect(within(dialog).getByText('1,832.00')).toBeInTheDocument();
  });
});

describe('GenerateBillsPage', () => {
  const PREVIEW = {
    flatCount: 25,
    settings: { ratePerSqFt: 5 },
    regular: {
      charges: [{ charge_id: 1, name: 'Sinking Fund', amount: 45800, perFlat: 1832 }],
      totalAmount: 45800,
      perFlatTotal: 1832,
    },
    addOn: { charges: [], totalAmount: 0, perFlatTotal: 0 },
    existingRuns: 11,
    alreadyGeneratedThisMonth: false,
    warnings: [],
  };

  it('shows the preview without writing anything', async () => {
    let posts = 0;
    server.use(
      http.get(`${BASE}/billing/generate/preview`, () => ok(PREVIEW)),
      http.post(`${BASE}/billing/generate/regular`, () => {
        posts += 1;
        return ok({});
      }),
    );

    render(<GenerateBillsPage />);
    expect(await screen.findByText('25')).toBeInTheDocument();
    // 45,800.00 appears in the summary card and again in the charge table.
    expect(screen.getAllByText('45,800.00')).toHaveLength(2);
    expect(screen.getByText('Sinking Fund')).toBeInTheDocument();
    // The preview must be purely read-only.
    expect(posts).toBe(0);
  });

  it('keeps the generate button disabled while writes are off', async () => {
    server.use(http.get(`${BASE}/billing/generate/preview`, () => ok(PREVIEW)));
    render(<GenerateBillsPage />);

    await screen.findByText('25');
    expect(screen.getByRole('button', { name: /generate bills/i })).toBeDisabled();
    expect(screen.getByText(/disabled/i)).toBeInTheDocument();
  });

  it('surfaces preview warnings', async () => {
    server.use(
      http.get(`${BASE}/billing/generate/preview`, () =>
        ok({ ...PREVIEW, warnings: ['A bill run already exists for the current month.'] }),
      ),
    );

    render(<GenerateBillsPage />);
    expect(await screen.findByText(/already exists for the current month/i)).toBeInTheDocument();
  });
});
