import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { PdcPage, PdcClearingPage } from './PdcPage.jsx';

const BASE = '/api/web';

const CHEQUE = {
  pdc_rem_id: 4,
  owner_id: 27,
  wing_id: 69,
  chqno: '333',
  che_amount: 200,
  che_date: '2026-08-03',
  che_dep: 0,
  che_ret: 0,
  che_can: 0,
  name: 'Vihan Raut',
  Unit: 'Bird Wing 1 202',
};

const OWNERS = [
  { owner_id: 27, name: 'Vihan Raut', Unit: 'Bird Wing 1 202', wing_id: 69 },
  { owner_id: 31, name: 'Asha Patil', Unit: 'Rose Wing 2 101', wing_id: 70 },
];

/** What sp_pdc_reminder's owner_select branch returns for one resident. */
const OWNER_DETAILS = {
  31: {
    owner_name: 'Asha Patil',
    pre_mob: '9876500011',
    alter_mob: '9876500012',
    email: 'asha@example.com',
    w_name: 'Rose Wing 2',
    build_name: 'Tathastu',
    wing_id: 70,
    pre_addr1: '101, Tathastu, Beach Road',
    pre_add2: 'Near market',
  },
  27: {
    owner_name: 'Vihan Raut',
    pre_mob: '3435949549',
    alter_mob: '',
    email: 'vihan@example.com',
    w_name: 'Bird Wing 1',
    build_name: 'Tathastu',
    wing_id: 69,
    pre_addr1: '202, Tathastu, Sagreshwar Beach',
    pre_add2: 'Ok',
  },
};

function handlers({ items = [CHEQUE], extra = [] } = {}) {
  return [
    http.get(`${BASE}/billing/pdc`, () => ok({ items, count: items.length })),
    http.get(`${BASE}/masters/owners`, () => ok({ items: OWNERS, count: OWNERS.length })),
    http.get(`${BASE}/billing/pdc/owner/:ownerId/details`, ({ params }) =>
      ok({ owner: OWNER_DETAILS[params.ownerId] ?? null }),
    ),
    ...extra,
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('PdcPage', () => {
  it('picks the owner from a list rather than asking for an id', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<PdcPage />);

    await screen.findByText('333');
    await user.click(screen.getByRole('button', { name: /add cheque/i }));

    // The form used to be a bare "Owner ID" number box, which nothing on the
    // page told the user how to fill.
    const select = await screen.findByLabelText(/^owner/i);
    expect(within(select).getByRole('option', { name: /Vihan Raut/ })).toBeInTheDocument();
    expect(within(select).getByRole('option', { name: /Asha Patil/ })).toBeInTheDocument();
  });

  it('fills the contact block from the chosen owner, read-only', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<PdcPage />);

    await screen.findByText('333');
    await user.click(screen.getByRole('button', { name: /add cheque/i }));
    await user.selectOptions(await screen.findByLabelText(/^owner/i), '31');

    // The legacy form filled building-wing, mobile, address and email as soon
    // as an owner was picked, and disabled each one; this page asked for a
    // bare owner id and showed none of it.
    const dialog = screen.getByRole('dialog');
    for (const value of [
      'Tathastu — Rose Wing 2',
      '9876500011',
      '9876500012',
      'asha@example.com',
      '101, Tathastu, Beach Road',
    ]) {
      expect(await within(dialog).findByDisplayValue(value)).toHaveAttribute('readonly');
    }
  });

  it('lists the cheques already on file for the chosen owner', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/pdc/owner/31`, () =>
            ok({
              items: [
                {
                  pdc_rem_id: 2,
                  chqno: 1000000,
                  che_amount: 2000,
                  che_date: '2026-01-14',
                  che_dep: 1,
                  che_ret: 0,
                  che_can: 0,
                },
              ],
              count: 1,
            }),
          ),
        ],
      }),
    );
    render(<PdcPage />);

    await screen.findByText('333');
    await user.click(screen.getByRole('button', { name: /add cheque/i }));
    await user.selectOptions(await screen.findByLabelText(/^owner/i), '31');

    // GridView2 in the legacy modal — it showed what was already recorded for
    // the owner, so a duplicate was visible before adding one more. The API
    // for it existed here but nothing rendered it.
    const dialog = screen.getByRole('dialog');
    expect(await within(dialog).findByText('1000000')).toBeInTheDocument();
    expect(within(dialog).getByText('Deposited')).toBeInTheDocument();
  });

  it('sends the wing that came with the owner', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/billing/pdc`, async ({ request }) => {
            saved(await request.json());
            return ok({ pdc_rem_id: 9 });
          }),
        ],
      }),
    );
    render(<PdcPage />);

    await screen.findByText('333');
    await user.click(screen.getByRole('button', { name: /add cheque/i }));
    await user.selectOptions(await screen.findByLabelText(/^owner/i), '31');
    // Wait for the contact block, which is what carries wing_id.
    await screen.findByDisplayValue('asha@example.com');

    await user.type(screen.getByLabelText(/cheque number/i), '9001');
    await user.type(screen.getByLabelText(/^amount/i), '5000');
    await user.type(screen.getByLabelText(/cheque date/i), '2026-09-01');
    await user.click(screen.getByRole('button', { name: /^save$/i }));

    // wing_id is not asked for — it belongs to the owner, and a separate box
    // for it only invited a mismatch.
    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({ ownerId: 31, wingId: 70 });
  });

  it('keeps the wing and cheque status when an existing cheque is saved', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      ...handlers({
        items: [{ ...CHEQUE, che_dep: 1 }],
        extra: [
          http.put(`${BASE}/billing/pdc/4`, async ({ request }) => {
            saved(await request.json());
            return ok({ pdc_rem_id: 4 });
          }),
        ],
      }),
    );
    render(<PdcPage />);

    await screen.findByText('333');
    await user.click(screen.getByRole('button', { name: 'Edit' }));
    await screen.findByLabelText(/cheque number/i);
    await user.click(screen.getByRole('button', { name: /^save$/i }));

    // wing_id was never put on the form and the status flags were dropped, so
    // a plain edit sent 0 for all four — detaching the cheque from its wing
    // and marking a deposited cheque pending again.
    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({ wingId: 69, deposited: true });
  });

  it('filters the loaded cheques as you type', async () => {
    const user = userEvent.setup();
    const listed = vi.fn();
    server.use(
      http.get(`${BASE}/masters/owners`, () => ok({ items: OWNERS, count: OWNERS.length })),
      http.get(`${BASE}/billing/pdc`, ({ request }) => {
        listed(new URL(request.url).searchParams.get('search'));
        return ok({
          items: [CHEQUE, { ...CHEQUE, pdc_rem_id: 5, chqno: '999', name: 'Asha Patil' }],
          count: 2,
        });
      }),
    );
    render(<PdcPage />);

    await screen.findByText('999');
    await user.type(screen.getByLabelText(/search cheques/i), 'asha');

    // The legacy page filtered the rendered table on keyup rather than
    // querying, so the term must never become a request.
    await waitFor(() => expect(screen.queryByText('333')).not.toBeInTheDocument());
    expect(screen.getByText('999')).toBeInTheDocument();
    expect(listed).toHaveBeenCalledTimes(1);
    expect(listed).toHaveBeenCalledWith(null);
  });

  it('offers the export actions the legacy grid pages carried', async () => {
    server.use(...handlers());
    render(<PdcPage />);

    await screen.findByText('333');
    // This screen builds its own table rather than using DataGrid, so it had
    // none of these.
    expect(screen.getByRole('button', { name: /export to excel/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /download pdf/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /^print$/i })).toBeInTheDocument();
  });

  it('deletes a cheque', async () => {
    const user = userEvent.setup();
    const removed = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.delete(`${BASE}/billing/pdc/4`, () => {
            removed();
            return ok({ deleted: true, pdc_rem_id: 4 });
          }),
        ],
      }),
    );
    render(<PdcPage />);

    await screen.findByText('333');
    // There was no way to remove a cheque: sp_pdc_reminder's Delete branch
    // sets active_status = 0, which is the live value, so the row came back.
    await user.click(screen.getByRole('button', { name: 'Delete' }));

    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: /^delete$/i }));

    await waitFor(() => expect(removed).toHaveBeenCalled());
  });
});

describe('PdcClearingPage', () => {
  const DUE = {
    pdc_rem_id: 2,
    chqno: '1000000',
    owner_name: 'Jivan Kudalkar',
    che_amount: 2000,
    che_date: '2026-01-14',
    che_dep: 0,
    che_ret: 0,
    che_can: 0,
  };

  const clearingHandlers = ({ items = [DUE], extra = [] } = {}) => [
    http.get(`${BASE}/billing/pdc/clearing`, () => ok({ items, count: items.length })),
    ...extra,
  ];

  it('records a bounced cheque without confirming', async () => {
    const user = userEvent.setup();
    const cleared = vi.fn();
    server.use(
      ...clearingHandlers({
        extra: [
          http.post(`${BASE}/billing/pdc/2/clear`, async ({ request }) => {
            cleared(await request.json());
            return ok({ updated: true, pdc_rem_id: 2 });
          }),
        ],
      }),
    );
    render(<PdcClearingPage />);

    // Bouncing raises no receipt, so it applies straight away — only
    // depositing needs the warning.
    await user.click(await screen.findByRole('radio', { name: /bounced — cheque 1000000/i }));

    await waitFor(() => expect(cleared).toHaveBeenCalled());
    expect(cleared.mock.lastCall[0]).toMatchObject({
      deposited: false,
      returned: false,
      cancelled: true,
    });
  });

  it('warns before depositing, because that raises a receipt', async () => {
    const user = userEvent.setup();
    const cleared = vi.fn();
    server.use(
      ...clearingHandlers({
        extra: [
          http.post(`${BASE}/billing/pdc/2/clear`, async ({ request }) => {
            cleared(await request.json());
            return ok({ updated: true, pdc_rem_id: 2 });
          }),
        ],
      }),
    );
    render(<PdcClearingPage />);

    await user.click(await screen.findByRole('radio', { name: /deposited — cheque 1000000/i }));

    // sp_pdc_reminder's save_change_rem calls sp_receipt when che_dep is 1,
    // so a mis-click would create a real financial record.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText(/raises a receipt for 2,000/i)).toBeInTheDocument();
    expect(cleared).not.toHaveBeenCalled();

    await user.click(within(dialog).getByRole('button', { name: /mark deposited/i }));

    await waitFor(() => expect(cleared).toHaveBeenCalled());
    expect(cleared.mock.lastCall[0]).toMatchObject({ deposited: true, confirm: true });
  });

  it('shows the outcome already recorded, one at a time', async () => {
    server.use(...clearingHandlers({ items: [{ ...DUE, che_dep: 1 }] }));
    render(<PdcClearingPage />);

    // The legacy checkboxes cleared each other; radios in one group per
    // cheque say the same thing without letting all three be on at once.
    expect(await screen.findByRole('radio', { name: /deposited — cheque 1000000/i })).toBeChecked();
    expect(screen.getByRole('radio', { name: /bounced — cheque 1000000/i })).not.toBeChecked();
  });
});
