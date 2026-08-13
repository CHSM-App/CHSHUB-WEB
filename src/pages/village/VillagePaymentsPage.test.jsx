import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { VillagePaymentsPage } from './VillagePages.jsx';

const BASE = '/api/web';

/** One house with an unpaid property-tax bill against it. */
const PENDING = [
  {
    house_id: 1,
    house_no: '101',
    owner_name: 'Sunita Patil',
    pre_mob: '9800000000',
    pending_property_tax: 6000,
    pending_water_charges: 0,
    pending_waste_charges: 0,
    pending_other_charges: 0,
  },
];

/** Field names follow what the dialog reads off each row. */
const BILLS = [
  {
    house_receipt_id: 51,
    receipt_no: 'R-51',
    payment_type: 1,
    payment_type_name: 'Property Tax',
    pending_amount: 6000,
    payment_status: 0,
    Month: 'April',
    year: 2026,
  },
];

function handlers({ onPay } = {}) {
  return [
    http.get(`${BASE}/village/house-tax/pending`, () => ok({ items: PENDING })),
    http.get(`${BASE}/village/house-tax/receipts`, () => ok({ items: [] })),
    http.get(`${BASE}/village/house-tax/by-type`, () => ok({ items: BILLS })),
    http.post(`${BASE}/village/house-tax/pay`, async ({ request }) => {
      onPay?.(await request.json());
      return ok({ receipt_id: 900 });
    }),
  ];
}

/** Open the pay dialog on the one pending house, with its bill already ticked. */
async function openPayDialog(user) {
  render(<VillagePaymentsPage />);
  // The name shows in the grid and again in the SMS panel beside it.
  await screen.findAllByText('Sunita Patil');

  // The pending amount is the link that opens the dialog, as gvPending's
  // LinkButtons were.
  await user.click(screen.getAllByRole('button', { name: /6,000|6000/ })[0]);

  // Every unpaid bill opens already ticked, so nothing needs clicking — the
  // dialog shows the whole amount the grid cell just reported.
  const dialog = await screen.findByRole('dialog');
  await within(dialog).findByText('Property Tax');
  return dialog;
}

beforeEach(() => {
  writeSession({ token: 't', user: { name: 'Village admin', village_id: 3 } });
});

/*
 * A tax receipt is only traceable if the payment's own details are recorded —
 * a cheque with no number cannot be matched to a bank statement, and a UPI
 * transfer with no reference cannot be found at all. The dialog starred those
 * boxes but reported them as one sentence, leaving the box itself unmarked.
 */
describe('VillagePaymentsPage — payment details', () => {
  it('marks the cheque boxes when a cheque payment has none', async () => {
    const user = userEvent.setup();
    const onPay = vi.fn();
    server.use(...handlers({ onPay }));
    await openPayDialog(user);

    await user.selectOptions(screen.getByLabelText(/payment method/i), '2');
    await user.click(screen.getByRole('button', { name: /process payment/i }));

    expect(await screen.findByText('Enter the cheque no.')).toBeInTheDocument();
    expect(screen.getByText('Enter the cheque date')).toBeInTheDocument();
    expect(screen.getByText(/required field/i)).toBeInTheDocument();
    expect(onPay).not.toHaveBeenCalled();
  });

  it('asks a UPI payment for its reference instead', async () => {
    const user = userEvent.setup();
    const onPay = vi.fn();
    server.use(...handlers({ onPay }));
    await openPayDialog(user);

    await user.selectOptions(screen.getByLabelText(/payment method/i), '4');
    await user.click(screen.getByRole('button', { name: /process payment/i }));

    expect(await screen.findByText('Enter the transaction reference')).toBeInTheDocument();
    expect(screen.queryByText('Enter the cheque no.')).not.toBeInTheDocument();
    expect(onPay).not.toHaveBeenCalled();
  });

  it('drops the old method’s complaints when the method changes', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    await openPayDialog(user);

    await user.selectOptions(screen.getByLabelText(/payment method/i), '2');
    await user.click(screen.getByRole('button', { name: /process payment/i }));
    expect(await screen.findByText('Enter the cheque no.')).toBeInTheDocument();

    // Switching swaps the inputs, so the complaints go with them rather than
    // hanging over boxes that are no longer shown.
    await user.selectOptions(screen.getByLabelText(/payment method/i), '1');
    expect(screen.queryByText('Enter the cheque no.')).not.toBeInTheDocument();
    expect(screen.queryByText(/required field/i)).not.toBeInTheDocument();
  });

  it('records a cash payment, which needs no extra details', async () => {
    const user = userEvent.setup();
    const onPay = vi.fn();
    server.use(...handlers({ onPay }));
    await openPayDialog(user);

    // Cash is the default; nothing beyond the ticked bill is asked for.
    await user.click(screen.getByRole('button', { name: /process payment/i }));

    await waitFor(() => expect(onPay).toHaveBeenCalled());
    expect(onPay.mock.lastCall[0]).toMatchObject({ payMode: 1, receiptIds: [51] });
  });

  it('records a cheque payment once its details are given', async () => {
    const user = userEvent.setup();
    const onPay = vi.fn();
    server.use(...handlers({ onPay }));
    await openPayDialog(user);

    await user.selectOptions(screen.getByLabelText(/payment method/i), '2');
    await user.type(screen.getByLabelText(/cheque no/i), '445566');
    await user.type(screen.getByLabelText(/cheque date/i), '2026-08-13');
    await user.click(screen.getByRole('button', { name: /process payment/i }));

    await waitFor(() => expect(onPay).toHaveBeenCalled());
    expect(onPay.mock.lastCall[0]).toMatchObject({ payMode: 2, chequeNo: '445566' });
  });
});
