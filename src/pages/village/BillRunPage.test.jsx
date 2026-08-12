import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import BillRunPage from './BillRunPage.jsx';

const BASE = '/api/web';

/* The charges making up the bills — one row per house per charge. */
const LINES = [
  {
    house_id: 1,
    house_no: '101',
    owner_name: 'Rajesh Kumar',
    payment_type: 1,
    charge_name: 'Property Tax',
    frequency: 'Y',
    amount: 6000,
    bill_month: null,
  },
  {
    house_id: 1,
    house_no: '101',
    owner_name: 'Rajesh Kumar',
    payment_type: 2,
    charge_name: 'Water Charges',
    frequency: 'M',
    amount: 100,
    bill_month: 8,
  },
  {
    house_id: 2,
    house_no: '102',
    owner_name: 'Priya Sharma',
    payment_type: 2,
    charge_name: 'Water Charges',
    frequency: 'M',
    amount: 150,
    bill_month: 8,
  },
];

/** One bill per house, as sp_village_bill_run's first recordset returns. */
function billsFrom(lines) {
  const byHouse = new Map();
  for (const l of lines) {
    const b = byHouse.get(l.house_id) ?? {
      house_id: l.house_id,
      house_no: l.house_no,
      owner_name: l.owner_name,
      pre_mob: '9810000000',
      charge_count: 0,
      total: 0,
    };
    b.charge_count += 1;
    b.total += Number(l.amount);
    byHouse.set(l.house_id, b);
  }
  return [...byHouse.values()];
}

function handlers({ lines = LINES, onRun, afterRun } = {}) {
  let ran = false;
  return [
    http.get(`${BASE}/village/bill-run/preview`, () => {
      // After a run there is nothing left to raise, which is what makes a
      // second run safe.
      const rows = ran ? (afterRun ?? []) : lines;
      const bills = billsFrom(rows);
      return ok({
        items: bills,
        lines: rows,
        count: bills.length,
        lineCount: rows.length,
        total: rows.reduce((sum, r) => sum + Number(r.amount), 0),
      });
    }),
    http.post(`${BASE}/village/bill-run`, async ({ request }) => {
      ran = true;
      onRun?.(await request.json());
      return ok(
        {
          bills: billsFrom(lines).length,
          lines: lines.length,
          total: lines.reduce((s, r) => s + Number(r.amount), 0),
        },
        201,
      );
    }),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V10004' } });
});

describe('BillRunPage', () => {
  /*
   * A bill is one thing a household is handed. House 101 owes property tax and
   * water; listing those as two rows describes the stored charges rather than
   * the bill, which is what the screen showed before.
   */
  it('lists one bill per household, not one per charge', async () => {
    server.use(...handlers());
    render(<BillRunPage />);

    await screen.findByText('101');
    expect(screen.getAllByRole('row', { name: /101/ })).toHaveLength(1);
    // Its two charges are named on that single row, and totalled.
    expect(screen.getByText('Property Tax, Water Charges')).toBeInTheDocument();
    expect(screen.getByText('6,100.00')).toBeInTheDocument();
  });

  it('names the owner, so a bill can be handed to someone', async () => {
    server.use(...handlers());
    render(<BillRunPage />);

    expect(await screen.findByText('Rajesh Kumar')).toBeInTheDocument();
    expect(screen.getByText('Priya Sharma')).toBeInTheDocument();
  });

  it('opens a bill to show the charges behind its total', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillRunPage />);

    await screen.findByText('101');
    expect(screen.queryByText('6,000.00')).not.toBeInTheDocument();

    await user.click(screen.getByText('Rajesh Kumar'));

    // The individual amounts appear only once the bill is opened.
    expect(await screen.findByText('6,000.00')).toBeInTheDocument();
    expect(screen.getByText('100.00')).toBeInTheDocument();
  });

  it('counts bills by household and charges separately', async () => {
    server.use(...handlers());
    render(<BillRunPage />);

    await screen.findByText('101');
    // Two households, three charges between them.
    expect(screen.getByRole('button', { name: /raise 2 bill\(s\)/i })).toBeInTheDocument();
    expect(screen.getByText(/2 bill\(s\), 3 charge\(s\)/)).toBeInTheDocument();
  });

  it('raises the bills for the chosen period', async () => {
    const user = userEvent.setup();
    const onRun = vi.fn();
    server.use(...handlers({ onRun }));
    render(<BillRunPage />);

    await screen.findByText('101');
    await user.selectOptions(screen.getByLabelText(/month/i), '8');
    await user.click(screen.getByRole('button', { name: /raise 2 bill\(s\)/i }));

    await waitFor(() => expect(onRun).toHaveBeenCalled());
    expect(onRun.mock.calls[0][0]).toMatchObject({ month: 8 });
    expect(await screen.findByText(/raised 2 bill\(s\)/i)).toBeInTheDocument();
  });

  /*
   * The guard against billing a period twice. After a run the preview comes
   * back empty, and the page has to say so rather than offering the button
   * again.
   */
  it('has nothing left to raise once the period is billed', async () => {
    const user = userEvent.setup();
    server.use(...handlers({ afterRun: [] }));
    render(<BillRunPage />);

    await screen.findByText('101');
    await user.click(screen.getByRole('button', { name: /raise 2 bill\(s\)/i }));

    expect(await screen.findByText(/nothing to raise/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /raise 0 bill\(s\)/i })).toBeDisabled();
  });

  it('names a yearly charge by its year rather than the chosen month', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillRunPage />);

    await screen.findByText('101');
    await user.click(screen.getByText('Rajesh Kumar'));

    // Property tax is raised once for the year, so a month against it would
    // misdescribe it.
    expect(await screen.findByText(/2026 \(yearly\)/)).toBeInTheDocument();
  });

  it('shows an empty state when the period is already fully billed', async () => {
    server.use(...handlers({ lines: [] }));
    render(<BillRunPage />);

    expect(await screen.findByText(/nothing to raise/i)).toBeInTheDocument();
  });
});
