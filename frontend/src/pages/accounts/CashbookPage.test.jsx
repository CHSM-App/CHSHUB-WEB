import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import CashbookPage from './CashbookPage.jsx';

const BASE = '/api/web';

/** What sp_cashbook returns: seq 1 opening, 2 transactions, 3 closing. */
const REPORT = {
  items: [
    { seq: 1, Date: null, Particular: 'Opening Balance', Debit: 0, Credit: 1000 },
    { seq: 2, Date: '2025-11-03T12:54:00', Particular: 'BY UPI: TXN-1', Debit: null, Credit: 2000 },
    { seq: 2, Date: '2025-11-10T10:00:00', Particular: 'TO Munna Tripathi', Debit: 500, Credit: null },
    { seq: 3, Date: null, Particular: 'Closing Balance', Debit: null, Credit: 2500 },
  ],
};

const handlers = (data = REPORT) => [
  http.get(`${BASE}/accounts/cashbook`, () => ok(data)),
];

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('CashbookPage', () => {
  it('shows the opening balance, transactions and closing balance', async () => {
    server.use(...handlers());
    render(<CashbookPage />);

    expect(await screen.findByText('Opening Balance')).toBeInTheDocument();
    expect(screen.getByText('BY UPI: TXN-1')).toBeInTheDocument();
    expect(screen.getByText('TO Munna Tripathi')).toBeInTheDocument();
    expect(screen.getByText('Closing Balance')).toBeInTheDocument();
  });

  it('totals the transactions without counting the balance rows', async () => {
    server.use(...handlers());
    render(<CashbookPage />);

    await screen.findByText('Opening Balance');

    // Debit 500, credit 2,000 — the opening 1,000 and closing 2,500 are
    // running balances, so adding them in would count the period twice.
    const footer = document.querySelector('tfoot');
    expect(within(footer).getByText('500.00')).toBeInTheDocument();
    expect(within(footer).getByText('2,000.00')).toBeInTheDocument();
  });

  it('offers the export actions the legacy page carried', async () => {
    server.use(...handlers());
    render(<CashbookPage />);

    await screen.findByText('Opening Balance');
    // cashbook.aspx had a PDF export of its own; Excel and Print come with
    // the shared toolbar.
    expect(screen.getByRole('button', { name: /download pdf/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /export to excel/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /^print$/i })).toBeInTheDocument();
  });

  it('says so when the range holds nothing', async () => {
    server.use(...handlers({ items: [] }));
    render(<CashbookPage />);

    expect(await screen.findByText(/no cashbook entries/i)).toBeInTheDocument();
  });
});
