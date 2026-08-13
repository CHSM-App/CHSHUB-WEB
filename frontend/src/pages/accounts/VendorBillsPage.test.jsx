import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import VendorBillsPage from './VendorBillsPage.jsx';

const BASE = '/api/web';

const BILL = {
  bill_id: 12,
  bill_number: 'VB-0012',
  bill_date: '2026-02-01',
  vendor_name: 'Acme Pumps',
  vendor_id: 4,
  total_amount: 5000,
  paid_amount: 1000,
  remaining_amount: 4000,
  payment_status: 'Partially Paid',
  bill_status: 'Approved',
};

function handlers({ bills = [BILL], extra = [] } = {}) {
  return [
    http.get(`${BASE}/accounts/vendor-bills`, () => ok({ items: bills, count: bills.length })),
    http.get(`${BASE}/accounts/vendor-bills/form-data`, () =>
      ok({ vendors: [], staff: [], staffRoles: [], approvers: [], chargeHeads: [] }),
    ),
    ...extra,
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('VendorBillsPage — new bill', () => {
  it('asks for the service type before anything else', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));

    // The service type decides which sub-form the bill has, so on open it is
    // the only question — bill number, date and the tabs come after.
    expect(await screen.findByLabelText(/service type/i)).toBeInTheDocument();
    expect(screen.queryByLabelText(/bill number/i)).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /bill details/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /save bill/i })).not.toBeInTheDocument();
  });

  it('generates a bill number prefixed by the service type', async () => {
    const user = userEvent.setup();
    server.use(...handlers());

    // Each type gets its own prefix so the kind of bill is legible from the
    // number. The legacy page did this for staff runs only.
    for (const [value, prefix] of [
      ['0', 'STAFF'],
      ['1', 'EXP'],
      ['2', 'INV'],
      ['3', 'SRV'],
    ]) {
      const { unmount } = render(<VendorBillsPage />);
      await screen.findAllByText('VB-0012');
      await user.click(screen.getByRole('button', { name: /new bill/i }));
      await user.selectOptions(await screen.findByLabelText(/service type/i), value);

      const field = await screen.findByLabelText(/bill number/i);
      expect(field.value).toMatch(new RegExp(`^${prefix}-\\d{6}-\\d{6}$`));
      unmount();
    }
  });

  it('re-stamps a generated bill number when the service type changes', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));
    await user.selectOptions(await screen.findByLabelText(/service type/i), '0');
    expect((await screen.findByLabelText(/bill number/i)).value).toMatch(/^STAFF-/);

    // Switching type left the STAFF- number in place, so an inventory bill
    // went in labelled as a staff run.
    await user.selectOptions(screen.getByLabelText(/service type/i), '2');
    expect(screen.getByLabelText(/bill number/i).value).toMatch(/^INV-/);
  });

  it('keeps a bill number that was already typed', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));
    await user.selectOptions(await screen.findByLabelText(/service type/i), '2');

    const field = await screen.findByLabelText(/bill number/i);
    await user.clear(field);
    await user.type(field, 'SUPPLIER-778');
    // Re-picking the type must not overwrite a supplier's own number.
    await user.selectOptions(screen.getByLabelText(/service type/i), '3');
    expect(field).toHaveValue('SUPPLIER-778');
  });

  it('opens the rest of the form once a service type is picked', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));
    await user.selectOptions(await screen.findByLabelText(/service type/i), '1');

    expect(await screen.findByLabelText(/bill number/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/bill date/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /save bill/i })).toBeInTheDocument();
  });
});

describe('VendorBillsPage — sections per service type', () => {
  const openWith = async (user, value) => {
    render(<VendorBillsPage />);
    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));
    await user.selectOptions(await screen.findByLabelText(/service type/i), value);
  };

  it('gives Daily Expense a vendor, items and approvers', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${BASE}/accounts/vendor-bills`, () => ok({ items: [BILL], count: 1 })),
      http.get(`${BASE}/accounts/vendor-bills/form-data`, () =>
        ok({
          vendors: [],
          staff: [],
          staffRoles: [],
          approvers: [{ user_id: 9, name: 'Committee member' }],
          chargeHeads: [],
        }),
      ),
    );
    // ddlSevice_SelectedIndexChanged shows vendor + items + approvers for
    // Daily Expense as well as Inventory; it was treated as vendor-less here.
    await openWith(user, '1');

    expect(await screen.findByLabelText(/vendor name/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /add item/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /add approver/i })).toBeInTheDocument();
  });

  it('gives Service Payment a vendor but no items or approvers', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openWith(user, '3');

    expect(await screen.findByLabelText(/vendor name/i)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /add item/i })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /add approver/i })).not.toBeInTheDocument();
  });

  it('gives Staff Payment no vendor section at all', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openWith(user, '0');

    await screen.findByLabelText(/bill number/i);
    expect(screen.queryByLabelText(/vendor name/i)).not.toBeInTheDocument();
  });

  it('fills the GST number from the chosen vendor', async () => {
    const user = userEvent.setup();
    server.use(
      http.get(`${BASE}/accounts/vendor-bills`, () => ok({ items: [BILL], count: 1 })),
      http.get(`${BASE}/accounts/vendor-bills/form-data`, () =>
        ok({
          vendors: [{ vendor_id: 4, vendor_name: 'Acme Pumps', gst_no: '27ABCDE1234F1Z5' }],
          staff: [],
          staffRoles: [],
          approvers: [],
          chargeHeads: [],
        }),
      ),
    );
    await openWith(user, '2');

    // The legacy vendor row carried a read-only GST box filled from the
    // vendor; nothing here showed it at all.
    await user.selectOptions(await screen.findByLabelText(/vendor name/i), '4');
    expect(screen.getByLabelText(/gst number/i)).toHaveValue('27ABCDE1234F1Z5');
  });

  it('totals an item line from quantity, unit price and tax', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openWith(user, '2');

    await user.click(await screen.findByRole('button', { name: /add item/i }));
    await user.clear(screen.getByLabelText(/^qty$/i));
    await user.type(screen.getByLabelText(/^qty$/i), '10');
    await user.type(screen.getByLabelText(/unit price/i), '100');
    await user.type(screen.getByLabelText(/tax %/i), '18');

    // 10 x 100 + 18% = 1180. The amount used to be typed by hand, so it could
    // disagree with the line it was meant to total. Taken by id because the
    // payment section further down has an "Amount" of its own.
    expect(document.getElementById('f-it-amt-0')).toHaveValue('1,180.00');
  });

  it('removes an item line from its icon button', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openWith(user, '2');

    await user.click(await screen.findByRole('button', { name: /add item/i }));
    expect(document.getElementById('f-it-name-0')).toBeInTheDocument();

    // The control is an icon, so it carries its name in aria-label — without
    // one it would read as an unlabelled button.
    await user.click(screen.getByRole('button', { name: /remove item 1/i }));
    expect(document.getElementById('f-it-name-0')).not.toBeInTheDocument();
  });

  /*
   * Vendor is the one required box on this form that can actually reach a
   * submit empty — the Save button is hidden until a service type is picked,
   * picking one stamps the bill number, and the date defaults to today.
   *
   * It used to be reported as a banner reading "Select a vendor", which left
   * the box itself looking untouched.
   */
  it('marks the vendor box when a bill is saved without one', async () => {
    const user = userEvent.setup();
    const created = vi.fn();
    server.use(
      http.get(`${BASE}/accounts/vendor-bills`, () => ok({ items: [BILL], count: 1 })),
      http.post(`${BASE}/accounts/vendor-bills`, async ({ request }) => {
        created(await request.json());
        return ok({ bill_id: 1 });
      }),
      http.get(`${BASE}/accounts/vendor-bills/form-data`, () =>
        ok({
          vendors: [{ vendor_id: 4, vendor_name: 'Acme Pumps' }],
          staff: [],
          staffRoles: [],
          approvers: [],
          chargeHeads: [],
        }),
      ),
    );
    await openWith(user, '3');

    await user.click(await screen.findByRole('button', { name: /save bill/i }));

    expect(await screen.findByText('Select a vendor name')).toBeInTheDocument();
    expect(screen.getByText(/required field/i)).toBeInTheDocument();
    expect(created).not.toHaveBeenCalled();

    // ...and it clears once answered, rather than waiting for the next submit.
    await user.selectOptions(screen.getByLabelText(/vendor name/i), '4');
    expect(screen.queryByText('Select a vendor name')).not.toBeInTheDocument();
  });

  /*
   * A staff run has no vendor section, so the same rule must not block it —
   * that is what the showIf on the field descriptor is for.
   */
  it('does not ask for a vendor on a staff payment', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openWith(user, '0');

    await screen.findByLabelText(/bill number/i);
    await user.click(screen.getByRole('button', { name: /save bill/i }));

    // It stops for its own reason (no staff picked), never for the vendor.
    expect(screen.queryByText('Select a vendor name')).not.toBeInTheDocument();
  });
});

describe('VendorBillsPage — payment mode', () => {
  it('hides the payment fields until a mode is picked', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VendorBillsPage />);
    await screen.findAllByText('VB-0012');
    await user.click(screen.getByRole('button', { name: /new bill/i }));
    await user.selectOptions(await screen.findByLabelText(/service type/i), '1');

    // VendorBill.aspx opened with all three payment panels hidden.
    expect(screen.getByText(/pick a payment mode/i)).toBeInTheDocument();
    expect(screen.queryByLabelText(/cheque number/i)).not.toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: 'Cheque' }));
    expect(await screen.findByLabelText(/cheque number/i)).toBeInTheDocument();
  });
});

describe('VendorBillsPage — bill detail', () => {
  const detailHandler = () =>
    http.get(`${BASE}/accounts/vendor-bills/12`, () =>
      ok({
        bill: BILL,
        items: [
          {
            item_id: 5,
            item_name: 'Water pump',
            quantity: 2,
            purchase_cost: 1500,
            tax: 18,
            warranty: 12,
            // 1 is "New" in InventoryMaster.aspx's list.
            condition_status: 1,
            total_amount: 3540,
          },
        ],
        approvals: [],
        payments: [],
      }),
    );

  it('shows what each item was billed at', async () => {
    const user = userEvent.setup();
    server.use(...handlers({ extra: [detailHandler()] }));
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'View' })[0]);

    // The table used to show only item, quantity and amount.
    expect(await screen.findByText('Water pump')).toBeInTheDocument();
    expect(screen.getByText('12 mo')).toBeInTheDocument();
    expect(screen.getByText('18')).toBeInTheDocument();
  });

  it('leaves the item condition to the inventory screen', async () => {
    const user = userEvent.setup();
    server.use(...handlers({ extra: [detailHandler()] }));
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'View' })[0]);
    await screen.findByText('Water pump');

    // A bill records what was bought. Condition is the item's state today and
    // changes after the bill is raised, so showing it here would make the
    // same bill read differently later.
    const dialog = screen.getByRole('dialog');
    expect(within(dialog).queryByText('Condition')).not.toBeInTheDocument();
    expect(within(dialog).queryByText('New')).not.toBeInTheDocument();
  });

  it('lists payments taken against the bill', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/accounts/vendor-bills/12`, () =>
            ok({
              bill: BILL,
              items: [],
              approvals: [],
              payments: [
                {
                  payment_id: 24,
                  payment_no: 'RCPT-2026-0024',
                  payment_date: '2026-02-03',
                  pay_mode: 'Online',
                  transaction_ref: 'SBI-234254',
                  paid_amount: 1000,
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'View' })[0]);

    expect(await screen.findByText('RCPT-2026-0024')).toBeInTheDocument();
    expect(screen.getByText('Online')).toBeInTheDocument();
    // Cheque number or transaction reference — without it a payment cannot be
    // traced back to the bank entry it came from.
    expect(screen.getByText('SBI-234254')).toBeInTheDocument();
  });

  it('offers Print once the bill has loaded', async () => {
    const user = userEvent.setup();
    server.use(...handlers({ extra: [detailHandler()] }));
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'View' })[0]);

    await screen.findByText('Water pump');
    // The grid toolbar has a Print of its own, so this looks inside the
    // dialog rather than across the page.
    const dialog = screen.getByRole('dialog');
    expect(within(dialog).getByRole('button', { name: /^print$/i })).toBeInTheDocument();
  });
});

describe('VendorBillsPage — pay', () => {
  it('offers Pay only while a balance is outstanding', async () => {
    server.use(
      ...handlers({
        bills: [
          BILL,
          { ...BILL, bill_id: 13, bill_number: 'VB-0013', remaining_amount: 0, paid_amount: 5000 },
        ],
      }),
    );
    render(<VendorBillsPage />);

    const rows = await screen.findAllByRole('row');
    const outstanding = rows.find((r) => within(r).queryByText('VB-0012'));
    const settled = rows.find((r) => within(r).queryByText('VB-0013'));

    expect(within(outstanding).getByRole('button', { name: 'Pay' })).toBeInTheDocument();
    expect(within(settled).queryByRole('button', { name: 'Pay' })).not.toBeInTheDocument();
  });

  it('records a payment against an existing bill', async () => {
    const user = userEvent.setup();
    const paid = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/accounts/vendor-bills/12/payments`, async ({ request }) => {
            paid(await request.json());
            return ok({ bill_id: 12, payment_id: 3 });
          }),
        ],
      }),
    );
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'Pay' })[0]);

    // The dialog opens on the outstanding balance, which is what is being
    // paid in nearly every case.
    // The dialog opens with no mode picked, as the legacy panels did.
    await user.click(await screen.findByRole('button', { name: 'Cheque' }));
    // Matches on the field name only: the label now carries a trailing
    // "(required)", the screen-reader half of the asterisk.
    const amount = await screen.findByLabelText(/^amount\b/i);
    expect(amount).toHaveValue(4000);

    await user.clear(amount);
    await user.type(amount, '1500');

    // A cheque is only traceable with its own details, so they are required
    // once that mode is picked.
    await user.type(screen.getByLabelText(/cheque number/i), '112233');
    await user.type(screen.getByLabelText(/cheque date/i), '2026-08-13');
    await user.type(screen.getByLabelText(/bank name/i), 'HDFC');

    await user.click(screen.getByRole('button', { name: /record payment/i }));

    await waitFor(() => expect(paid).toHaveBeenCalled());
    expect(paid.mock.lastCall[0]).toMatchObject({
      mode: 'Cheque',
      amount: '1500',
      chequeNo: '112233',
      bankName: 'HDFC',
    });
  });

  /*
   * Cheque and online transfers are only traceable if their identifying
   * details are recorded — a cheque with no number cannot be matched to a bank
   * statement. Cash needs nothing beyond the amount.
   */
  it('will not record a cheque payment without the cheque details', async () => {
    const user = userEvent.setup();
    const paid = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/accounts/vendor-bills/12/payments`, async ({ request }) => {
            paid(await request.json());
            return ok({ bill_id: 12, payment_id: 3 });
          }),
        ],
      }),
    );
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'Pay' })[0]);
    await user.click(await screen.findByRole('button', { name: 'Cheque' }));
    await user.click(screen.getByRole('button', { name: /record payment/i }));

    expect(await screen.findByText('Enter the cheque number')).toBeInTheDocument();
    expect(screen.getByText('Enter the bank name')).toBeInTheDocument();
    expect(paid).not.toHaveBeenCalled();

    // Switching mode drops the old mode's complaints with its inputs, and
    // asks for what the new one needs instead.
    await user.click(screen.getByRole('button', { name: 'Online' }));
    expect(screen.queryByText('Enter the cheque number')).not.toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /record payment/i }));
    expect(await screen.findByText('Enter the transaction reference')).toBeInTheDocument();
    expect(paid).not.toHaveBeenCalled();
  });

  it('records a cash payment with no extra details', async () => {
    const user = userEvent.setup();
    const paid = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/accounts/vendor-bills/12/payments`, async ({ request }) => {
            paid(await request.json());
            return ok({ bill_id: 12, payment_id: 3 });
          }),
        ],
      }),
    );
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'Pay' })[0]);
    await user.click(await screen.findByRole('button', { name: 'Cash' }));
    await user.click(screen.getByRole('button', { name: /record payment/i }));

    await waitFor(() => expect(paid).toHaveBeenCalled());
    expect(paid.mock.lastCall[0]).toMatchObject({ mode: 'Cash' });
  });

  it('refuses to pay more than is outstanding', async () => {
    const user = userEvent.setup();
    const paid = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/accounts/vendor-bills/12/payments`, async ({ request }) => {
            paid(await request.json());
            return ok({ bill_id: 12, payment_id: 3 });
          }),
        ],
      }),
    );
    render(<VendorBillsPage />);

    await screen.findAllByText('VB-0012');
    await user.click(screen.getAllByRole('button', { name: 'Pay' })[0]);

    // The dialog opens with no mode picked, as the legacy panels did.
    await user.click(await screen.findByRole('button', { name: 'Cheque' }));
    // Matches on the field name only: the label now carries a trailing
    // "(required)", the screen-reader half of the asterisk.
    const amount = await screen.findByLabelText(/^amount\b/i);
    await user.clear(amount);
    await user.type(amount, '9999');
    await user.click(screen.getByRole('button', { name: /record payment/i }));

    expect(await screen.findByText(/more than the .* outstanding/i)).toBeInTheDocument();
    expect(paid).not.toHaveBeenCalled();
  });
});

/*
 * The quick-add vendor dialog ran no validation at all — not even the starred
 * Vendor name, which saved blank, so the contact number and e-mail took any
 * text at all.
 */
describe('VendorBillsPage — quick-add vendor', () => {
  const openVendorForm = async (user, onCreate) => {
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/accounts/vendors`, async ({ request }) => {
            onCreate?.(await request.json());
            return ok({ vendor_id: 9 });
          }),
        ],
      }),
    );
    render(<VendorBillsPage />);
    await user.click(await screen.findByRole('button', { name: /add vendor/i }));
    return screen.findByRole('dialog', { name: /add vendor/i });
  };

  it('refuses a blank vendor name', async () => {
    const user = userEvent.setup();
    const created = vi.fn();
    const dialog = await openVendorForm(user, created);

    await user.click(within(dialog).getByRole('button', { name: /save vendor/i }));

    expect(await within(dialog).findByText(/enter the vendor name/i)).toBeInTheDocument();
    expect(created).not.toHaveBeenCalled();
  });

  it('refuses a malformed e-mail and a short contact number', async () => {
    const user = userEvent.setup();
    const created = vi.fn();
    const dialog = await openVendorForm(user, created);

    await user.type(within(dialog).getByLabelText(/vendor name/i), 'Acme Pumps');
    await user.type(within(dialog).getByLabelText(/contact number/i), '98765');
    await user.type(within(dialog).getByLabelText(/^email/i), 'not-an-address');
    await user.click(within(dialog).getByRole('button', { name: /save vendor/i }));

    expect(await within(dialog).findByText(/10-digit contact number/i)).toBeInTheDocument();
    expect(within(dialog).getByText(/valid email address/i)).toBeInTheDocument();
    expect(created).not.toHaveBeenCalled();
  });

  it('keeps the contact box to ten digits and drops the letters', async () => {
    const user = userEvent.setup();
    const dialog = await openVendorForm(user);

    const contact = within(dialog).getByLabelText(/contact number/i);
    await user.type(contact, '98a76b543210999');
    expect(contact).toHaveValue('9876543210');
  });

  it('saves a vendor once the name and contact details are right', async () => {
    const user = userEvent.setup();
    const created = vi.fn();
    const dialog = await openVendorForm(user, created);

    await user.type(within(dialog).getByLabelText(/vendor name/i), 'Acme Pumps');
    await user.type(within(dialog).getByLabelText(/contact number/i), '9876543210');
    await user.type(within(dialog).getByLabelText(/^email/i), 'sales@acme.example');
    await user.click(within(dialog).getByRole('button', { name: /save vendor/i }));

    await waitFor(() => expect(created).toHaveBeenCalled());
    expect(created.mock.calls[0][0]).toMatchObject({
      name: 'Acme Pumps',
      contactNo: '9876543210',
      email: 'sales@acme.example',
    });
  });
});
