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
});
