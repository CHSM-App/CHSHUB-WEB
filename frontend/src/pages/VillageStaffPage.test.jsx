import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { VillageStaffPage } from './screens.jsx';

const BASE = '/api/web';

const STAFF = {
  staff_id: 4,
  staff_name: 'Jay Dhuri',
  role: 'Clerk',
  role_id: 2,
  contact_no: '9876543210',
  email: 'jay@example.com',
  address: 'Adeli',
  joined_date: '2026-01-12T00:00:00.000Z',
  salary: 12000,
  id_path: '/Documents/village_Docs/Adeli/MaintenanceReport.pdf',
};

// Sushant, staff_id 1 in the live data — saved through v_staff_management.aspx
// without picking a file, whose UploadId() then wrote an empty id_path.
const STAFF_NO_ID = { ...STAFF, staff_id: 1, staff_name: 'Sushant', id_path: '' };

function handlers({ items = [STAFF], extra = [] } = {}) {
  return [
    http.get(`${BASE}/village/staff`, () => ok({ items, count: items.length })),
    http.get(`${BASE}/village/staff/roles`, () =>
      ok({
        items: [
          { role_id: 1, role: 'Sweeper' },
          { role_id: 2, role: 'Clerk' },
        ],
      }),
    ),
    ...extra,
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V1' } });
});

describe('VillageStaffPage', () => {
  it('blocks the save and names each empty required field', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageStaffPage />);

    await screen.findByText('Jay Dhuri');
    await user.click(screen.getByRole('button', { name: 'Add' }));
    await user.click(await screen.findByRole('button', { name: 'Save' }));

    // The form carries noValidate, so nothing enforced `required` — an empty
    // Add saved a blank staff row.
    expect(await screen.findByText('Name is required')).toBeInTheDocument();
    expect(screen.getByText('Role is required')).toBeInTheDocument();
    expect(screen.getByText('Contact number is required')).toBeInTheDocument();
    expect(screen.getByText('Address is required')).toBeInTheDocument();
    expect(screen.getByText('Salary is required')).toBeInTheDocument();
    expect(screen.getByText('Joined date is required')).toBeInTheDocument();

    // Email and ID proof are optional, as on v_staff_management.aspx.
    expect(screen.queryByText('Email is required')).not.toBeInTheDocument();
    expect(screen.queryByText('ID proof is required')).not.toBeInTheDocument();
  });

  it('clears a field complaint as soon as it is answered', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageStaffPage />);

    await screen.findByText('Jay Dhuri');
    await user.click(screen.getByRole('button', { name: 'Add' }));
    await user.click(await screen.findByRole('button', { name: 'Save' }));

    await screen.findByText('Name is required');
    await user.type(screen.getByLabelText(/^name/i), 'Aniket');

    await waitFor(() => expect(screen.queryByText('Name is required')).not.toBeInTheDocument());
    // The ones still blank keep theirs until they are answered too.
    expect(screen.getByText('Role is required')).toBeInTheDocument();
  });

  it('preselects the role, which Grid_Show returns only by name', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageStaffPage />);

    await screen.findByText('Jay Dhuri');
    await user.click(screen.getByRole('button', { name: 'Edit' }));

    // Without role_id the dropdown opened blank, and saving blanked the role.
    expect(await screen.findByLabelText(/^role/i)).toHaveValue('2');
  });

  it('takes ten digits for the contact number and no more', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageStaffPage />);

    await screen.findByText('Jay Dhuri');
    await user.click(screen.getByRole('button', { name: 'Add' }));

    const contact = await screen.findByLabelText(/contact number/i);
    // Letters and punctuation are dropped as they are typed, and the eleventh
    // digit never lands — the legacy field's onkeypress plus MaxLength="10".
    await user.type(contact, '98a76-543210999');
    expect(contact).toHaveValue('9876543210');
  });

  it('offers ID proof only for the rows that have one', async () => {
    server.use(...handlers({ items: [STAFF, STAFF_NO_ID] }));
    render(<VillageStaffPage />);

    await screen.findByText('Jay Dhuri');
    // One View button — Sushant's id_path is empty, so his cell is a dash.
    expect(screen.getAllByRole('button', { name: 'View' })).toHaveLength(1);
  });
});
