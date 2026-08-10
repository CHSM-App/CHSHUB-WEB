import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { LoansPage } from './screens.jsx';

const BASE = '/api/web';

const LOAN = {
  loan_id: 6,
  flat_id: 1,
  flat_no: '301',
  bank: 'State Bank Of India',
  type_id: 2,
  loan_type: 'Home Loan',
  cert_id: 1,
  c_name: 'ABC',
  noc_issued: 'Society',
  society_noc: '2026-01-12',
  loan_clearance: '2026-01-27',
};

function handlers({ items = [LOAN], extra = [] } = {}) {
  return [
    http.get(`${BASE}/masters/loans`, () => ok({ items, count: items.length })),
    http.get(`${BASE}/masters/loans-lookups`, () =>
      ok({
        flats: [
          { flat_id: 1, flat_no: '301' },
          { flat_id: 5, flat_no: '502' },
        ],
        loanTypes: [
          { type_id: 1, loan_type: 'Morgage' },
          { type_id: 2, loan_type: 'Home Loan' },
        ],
        certificates: [
          { cert_id: 1, c_name: 'ABC' },
          { cert_id: 2, c_name: 'XYZ' },
        ],
      }),
    ),
    ...extra,
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('LoansPage', () => {
  it('names the flat, loan type and certificate holder rather than their ids', async () => {
    server.use(...handlers());
    render(<LoansPage />);

    // The grid could only show flat_id / type_id / cert_id — numbers that
    // name nothing — because Grid_Show returns the loan row alone.
    expect(await screen.findByText('301')).toBeInTheDocument();
    expect(screen.getByText('Home Loan')).toBeInTheDocument();
    expect(screen.getByText('State Bank Of India')).toBeInTheDocument();
  });

  it('fills the edit form from the row, loan type and certificate included', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<LoansPage />);

    await screen.findByText('State Bank Of India');
    await user.click(screen.getByRole('button', { name: 'Edit' }));

    expect(await screen.findByLabelText(/name of the bank/i)).toHaveValue('State Bank Of India');
    expect(screen.getByLabelText(/flat number/i)).toHaveValue('1');
    // typeId and certificateId were missing from the form entirely.
    expect(screen.getByLabelText(/type of loan/i)).toHaveValue('2');
    expect(screen.getByLabelText(/share certificate with/i)).toHaveValue('1');
    expect(screen.getByLabelText(/first noc issued by/i)).toHaveValue('Society');
    expect(screen.getByLabelText(/date of loan clearance/i)).toHaveValue('2026-01-27');
  });

  it('keeps the loan type and certificate when saved', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.put(`${BASE}/masters/loans/6`, async ({ request }) => {
            saved(await request.json());
            return ok({ updated: true, id: 6 });
          }),
        ],
      }),
    );
    render(<LoansPage />);

    await screen.findByText('State Bank Of India');
    await user.click(screen.getByRole('button', { name: 'Edit' }));
    await screen.findByLabelText(/name of the bank/i);
    await user.click(screen.getByRole('button', { name: /^save$/i }));

    // Without these on the form a plain edit sent 0 for both, losing the loan
    // type and who holds the share certificate.
    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({
      typeId: 2,
      certificateId: 1,
      loanClearanceDate: '2026-01-27',
    });
  });

  it('deletes a loan', async () => {
    const user = userEvent.setup();
    const removed = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.delete(`${BASE}/masters/loans/6`, () => {
            removed();
            return ok({ deleted: true, loan_id: 6 });
          }),
        ],
      }),
    );
    render(<LoansPage />);

    await screen.findByText('State Bank Of India');
    // Delete used to be hidden: sp_loan's Delete branch sets active_status = 0,
    // which is the live value, so the row came straight back.
    await user.click(screen.getByRole('button', { name: 'Delete' }));

    // The row's own Delete is still on screen behind the dialog.
    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: /^delete$/i }));

    await waitFor(() => expect(removed).toHaveBeenCalled());
  });
});
