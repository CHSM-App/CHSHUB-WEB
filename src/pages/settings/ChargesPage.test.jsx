import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import ChargesPage from './ChargesPage.jsx';

const BASE = '/api/web';

const ROWS = [
  { charge_id: 1, NatureOfCharge: 'Sinking Fund', amount: 500, charges_type: true, status: true, Date: '01 Jan 2026' },
  { charge_id: 2, NatureOfCharge: 'Festival', amount: 250, charges_type: false, status: false, Date: '02 Jan 2026' },
];

beforeEach(() => {
  writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1', user: { society_id: 'C10001' } });
});

describe('ChargesPage', () => {
  it('lists charges and totals only the active ones', async () => {
    server.use(http.get(`${BASE}/settings/charges`, () => ok({ items: ROWS, count: ROWS.length })));
    render(<ChargesPage />);

    expect(await screen.findByText('Sinking Fund')).toBeInTheDocument();
    // 500 active + 250 inactive -> total must be 500.00
    expect(screen.getByText(/active total 500\.00/i)).toBeInTheDocument();

    // Scope to the table: "Regular"/"Add-on" also appear in the filter <select>.
    const table = within(screen.getByRole('table'));
    expect(table.getByText('Regular')).toBeInTheDocument();
    expect(table.getByText('Add-on')).toBeInTheDocument();
    expect(table.getByText('Active')).toBeInTheDocument();
    expect(table.getByText('Inactive')).toBeInTheDocument();
  });

  it('offers Deactivate only for active charges', async () => {
    server.use(http.get(`${BASE}/settings/charges`, () => ok({ items: ROWS, count: ROWS.length })));
    render(<ChargesPage />);

    await screen.findByText('Sinking Fund');
    // One active row -> exactly one Deactivate button.
    expect(screen.getAllByRole('button', { name: /deactivate/i })).toHaveLength(1);
    // The inactive one offers the opposite action instead.
    expect(screen.getAllByRole('button', { name: /include in next bill/i })).toHaveLength(1);
  });

  it('puts a spent add-on back into the next run', async () => {
    const user = userEvent.setup();
    const sent = [];
    server.use(
      http.get(`${BASE}/settings/charges`, () => ok({ items: ROWS, count: ROWS.length })),
      http.put(`${BASE}/settings/charges/2`, async ({ request }) => {
        sent.push(await request.json());
        return ok({ charge: { ...ROWS[1], status: true } });
      }),
    );
    render(<ChargesPage />);

    await screen.findByText('Festival');
    await user.click(screen.getByRole('button', { name: /include in next bill/i }));

    // sp_new_maintenance switches an add-on head off once it has been billed,
    // so recurring levies need a way back in. Reactivating must carry the
    // head's own name, amount and type across — sending the form defaults
    // would silently turn an add-on into a regular monthly charge.
    await waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0]).toMatchObject({
      name: 'Festival',
      amount: 250,
      chargesType: '0',
      active: true,
    });
  });

  it('passes the type filter to the API', async () => {
    const seen = [];
    server.use(
      http.get(`${BASE}/settings/charges`, ({ request }) => {
        seen.push(new URL(request.url).searchParams.get('chargesType'));
        return ok({ items: ROWS, count: ROWS.length });
      }),
    );

    const user = userEvent.setup();
    render(<ChargesPage />);
    await screen.findByText('Sinking Fund');

    await user.selectOptions(screen.getByLabelText(/filter by charge type/i), '0');
    await waitFor(() => expect(seen).toContain('0'));
  });

  it('creates a charge with the chosen type', async () => {
    let posted = null;
    server.use(
      http.post(`${BASE}/settings/charges`, async ({ request }) => {
        posted = await request.json();
        return ok({ charge: { charge_id: 3 } });
      }),
      http.get(`${BASE}/settings/charges`, () => ok({ items: ROWS, count: ROWS.length })),
    );

    const user = userEvent.setup();
    render(<ChargesPage />);
    await screen.findByText('Sinking Fund');
    await user.click(screen.getByRole('button', { name: /add charge/i }));

    const dialog = await screen.findByRole('dialog');
    await user.type(within(dialog).getByLabelText(/nature of charge/i), 'Water Tank Cleaning');
    await user.type(within(dialog).getByLabelText(/^amount/i), '1200');
    await user.selectOptions(within(dialog).getByLabelText(/charge type/i), '0');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    await waitFor(() => expect(posted).not.toBeNull());
    expect(posted).toMatchObject({
      name: 'Water Tank Cleaning',
      amount: '1200',
      chargesType: '0',
      active: true,
    });
  });

  describe('sorting', () => {
    /* Amounts chosen so a text sort would disagree with a numeric one: as
       strings "1000" < "250" < "90", which is the order to guard against. */
    const SORT_ROWS = [
      { charge_id: 1, NatureOfCharge: 'Sinking Fund', amount: 250, charges_type: true, status: true, Date: '02 Jan 2026' },
      { charge_id: 2, NatureOfCharge: 'Festival', amount: 1000, charges_type: false, status: false, Date: '03 Jan 2026' },
      { charge_id: 3, NatureOfCharge: 'Water', amount: 90, charges_type: true, status: true, Date: '01 Jan 2026' },
    ];

    const chargeNames = () =>
      screen
        .getAllByRole('row')
        .slice(1)
        .map((tr) => within(tr).getAllByRole('cell')[0].textContent);

    const renderSorted = async () => {
      server.use(
        http.get(`${BASE}/settings/charges`, () => ok({ items: SORT_ROWS, count: SORT_ROWS.length })),
      );
      const user = userEvent.setup();
      render(<ChargesPage />);
      await screen.findByText('Sinking Fund');
      return user;
    };

    it('keeps the server order until a heading is clicked', async () => {
      await renderSorted();
      expect(chargeNames()).toEqual(['Sinking Fund', 'Festival', 'Water']);
    });

    it('sorts by name, and reverses on a second click', async () => {
      const user = await renderSorted();

      await user.click(screen.getByRole('button', { name: 'Sort by Nature of charge' }));
      expect(chargeNames()).toEqual(['Festival', 'Sinking Fund', 'Water']);

      await user.click(screen.getByRole('button', { name: 'Sort by Nature of charge' }));
      expect(chargeNames()).toEqual(['Water', 'Sinking Fund', 'Festival']);
    });

    it('sorts amount as a number rather than as text', async () => {
      const user = await renderSorted();

      await user.click(screen.getByRole('button', { name: 'Sort by Amount' }));
      // 90 < 250 < 1000. A string sort would have put 1000 first.
      expect(chargeNames()).toEqual(['Water', 'Sinking Fund', 'Festival']);
    });

    it('sorts status by the word the pill shows, not the raw bit', async () => {
      const user = await renderSorted();

      await user.click(screen.getByRole('button', { name: 'Sort by Status' }));
      // Active before Inactive — Festival is the only inactive head.
      expect(chargeNames()).toEqual(['Sinking Fund', 'Water', 'Festival']);
    });

    it('sorts Created even though the server sends it pre-formatted', async () => {
      const user = await renderSorted();

      // '01 Jan 2026' … '03 Jan 2026' are display strings, not timestamps.
      await user.click(screen.getByRole('button', { name: 'Sort by Created' }));
      expect(chargeNames()).toEqual(['Water', 'Sinking Fund', 'Festival']);
    });

    it('marks the sorted column for assistive tech', async () => {
      const user = await renderSorted();

      const header = screen.getByRole('columnheader', { name: /Nature of charge/ });
      expect(header).toHaveAttribute('aria-sort', 'none');
      await user.click(screen.getByRole('button', { name: 'Sort by Nature of charge' }));
      expect(header).toHaveAttribute('aria-sort', 'ascending');
    });

    it('survives the type filter reloading the list', async () => {
      const user = await renderSorted();

      await user.click(screen.getByRole('button', { name: 'Sort by Amount' }));
      expect(chargeNames()).toEqual(['Water', 'Sinking Fund', 'Festival']);

      // Refetching must not silently drop the chosen order.
      await user.selectOptions(screen.getByLabelText(/filter by charge type/i), '1');
      await waitFor(() => expect(chargeNames()).toEqual(['Water', 'Sinking Fund', 'Festival']));
    });
  });
});
