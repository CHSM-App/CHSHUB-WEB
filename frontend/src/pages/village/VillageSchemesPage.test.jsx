import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import VillageSchemesPage from './VillageSchemesPage.jsx';

const BASE = '/api/web';

const SCHEMES = [
  {
    scheme_id: 1,
    name: 'Gharkul Yojana',
    description: 'Housing assistance',
    eligibility: 'BPL households',
    benefit_amount: 120000,
    benefit_details: null,
    gr_number: 'GR/2026/114',
    gr_date: '2026-02-01',
    apply_from: null,
    apply_until: '2026-12-31',
    status: 'Open',
  },
  {
    scheme_id: 2,
    name: 'Seed Subsidy',
    description: null,
    eligibility: 'Farmers with under 2 hectares',
    // A scheme that gives something other than money.
    benefit_amount: null,
    benefit_details: 'Free seed for one season',
    gr_number: null,
    gr_date: null,
    apply_from: null,
    apply_until: '2026-01-31',
    status: 'Closed',
  },
];

function handlers({ items = SCHEMES, onCreate, onRemove } = {}) {
  return [
    http.get(`${BASE}/village/schemes`, () => ok({ items, count: items.length })),
    http.post(`${BASE}/village/schemes`, async ({ request }) => {
      onCreate?.(await request.json());
      return ok({ created: true, scheme_id: 3 }, 201);
    }),
    http.delete(`${BASE}/village/schemes/:id`, ({ params }) => {
      onRemove?.(params.id);
      return ok({ removed: true });
    }),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V10004' } });
});

describe('VillageSchemesPage', () => {
  it('lists schemes with who can apply and by when', async () => {
    server.use(...handlers());
    render(<VillageSchemesPage />);

    expect(await screen.findByText('Gharkul Yojana')).toBeInTheDocument();
    // The questions a resident actually asks — none of which a notice could
    // have held.
    expect(screen.getByText('BPL households')).toBeInTheDocument();
    expect(screen.getByText('GR/2026/114')).toBeInTheDocument();
  });

  /*
   * A scheme may pay money, give something in kind, or both. The column shows
   * whichever it has rather than assuming a figure.
   */
  it('shows a cash benefit and an in-kind one', async () => {
    server.use(...handlers());
    render(<VillageSchemesPage />);

    await screen.findByText('Gharkul Yojana');

    /*
     * Digit grouping comes from the runtime's locale — "1,20,000.00" under
     * en-IN, "120,000.00" elsewhere — so the row's text is matched on the
     * digits rather than a fixed rendering.
     */
    const cash = screen.getByRole('row', { name: /gharkul/i });
    expect(cash.textContent).toMatch(/₹1[,\d]*000\.00/);

    expect(screen.getByText('Free seed for one season')).toBeInTheDocument();
  });

  it('says whether applications are still open', async () => {
    server.use(...handlers());
    render(<VillageSchemesPage />);

    await screen.findByText('Gharkul Yojana');
    const open = screen.getByRole('row', { name: /gharkul/i });
    const closed = screen.getByRole('row', { name: /seed subsidy/i });

    expect(within(open).getByText('Open')).toBeInTheDocument();
    expect(within(closed).getByText('Closed')).toBeInTheDocument();
  });

  it('adds a scheme', async () => {
    const user = userEvent.setup();
    const onCreate = vi.fn();
    server.use(...handlers({ onCreate }));
    render(<VillageSchemesPage />);

    await screen.findByText('Gharkul Yojana');
    await user.click(screen.getByRole('button', { name: 'Add' }));

    await user.type(await screen.findByLabelText(/scheme name/i), 'Widow Pension');
    await user.type(screen.getByLabelText(/who can apply/i), 'Widowed women over 40');
    await user.type(screen.getByLabelText(/amount/i), '1500');
    await user.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() => expect(onCreate).toHaveBeenCalled());
    expect(onCreate.mock.calls[0][0]).toMatchObject({
      name: 'Widow Pension',
      eligibility: 'Widowed women over 40',
      benefitAmount: '1500',
    });
  });

  it('will not save a scheme with no name', async () => {
    const user = userEvent.setup();
    const onCreate = vi.fn();
    server.use(...handlers({ onCreate }));
    render(<VillageSchemesPage />);

    await screen.findByText('Gharkul Yojana');
    await user.click(screen.getByRole('button', { name: 'Add' }));
    await user.click(await screen.findByRole('button', { name: 'Save' }));

    expect(await screen.findByText('Scheme name is required')).toBeInTheDocument();
    expect(onCreate).not.toHaveBeenCalled();
  });

  /*
   * Removing keeps the record: residents ask about schemes that have closed,
   * so the confirmation says so rather than implying the row is destroyed.
   */
  it('removes a scheme, saying the record is kept', async () => {
    const user = userEvent.setup();
    const onRemove = vi.fn();
    server.use(...handlers({ onRemove }));
    render(<VillageSchemesPage />);

    await screen.findByText('Gharkul Yojana');
    const row = screen.getByRole('row', { name: /gharkul/i });
    await user.click(within(row).getByRole('button', { name: /remove/i }));

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText(/the record is kept/i)).toBeInTheDocument();
    await user.click(within(dialog).getByRole('button', { name: /^remove$/i }));

    await waitFor(() => expect(onRemove).toHaveBeenCalledWith('1'));
  });
});
