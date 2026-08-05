import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import ContactsPage from './ContactsPage.jsx';

const BASE = '/api/web';

const CONTACT = {
  usefull_contact_id: 1,
  p_name: 'Raj Kumar',
  p_type: 2,
  p_type_name: 'Electrician',
  org_name: 'Test Electricals',
  contact_no: '9876500001',
  email: 'raj@example.com',
  contact_address: 'Shop 4, Main Road',
  remark: 'Available evenings',
  id_path: '',
};

function handlers({ items = [CONTACT] } = {}) {
  return [
    http.get(`${BASE}/masters/contacts`, () => ok({ items, count: items.length })),
    http.get(`${BASE}/masters/contact-types`, () =>
      ok({ items: [{ p_type_id: 2, p_type_name: 'Electrician' }] }),
    ),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('ContactsPage', () => {
  it('renders each contact as a card with its details', async () => {
    server.use(...handlers());
    render(<ContactsPage />);

    expect(await screen.findByText('Raj Kumar')).toBeInTheDocument();
    expect(screen.getByText('Electrician')).toBeInTheDocument();
    expect(screen.getByText('Test Electricals')).toBeInTheDocument();
    expect(screen.getByText('9876500001')).toBeInTheDocument();
    expect(screen.getByText('Available evenings')).toBeInTheDocument();
  });

  it('omits detail rows the contact has no value for', async () => {
    server.use(...handlers({ items: [{ ...CONTACT, remark: '', email: '' }] }));
    render(<ContactsPage />);

    await screen.findByText('Raj Kumar');
    expect(screen.queryByText('raj@example.com')).not.toBeInTheDocument();
    expect(screen.queryByText('Available evenings')).not.toBeInTheDocument();
    // The rows that do have values are still shown.
    expect(screen.getByText('Test Electricals')).toBeInTheDocument();
  });

  it('shows View ID only when a document is stored', async () => {
    server.use(...handlers());
    const { unmount } = render(<ContactsPage />);
    await screen.findByText('Raj Kumar');
    expect(screen.queryByRole('button', { name: /view id/i })).not.toBeInTheDocument();
    unmount();

    server.use(...handlers({ items: [{ ...CONTACT, id_path: 'society-documents/id.pdf' }] }));
    render(<ContactsPage />);
    await screen.findByText('Raj Kumar');
    expect(screen.getByRole('button', { name: /view id/i })).toBeInTheDocument();
  });

  it('explains a document stored as a path on the old server', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({ items: [{ ...CONTACT, id_path: 'D:\\VengurlaTech\\society\\id.pdf' }] }),
    );
    render(<ContactsPage />);

    await screen.findByText('Raj Kumar');
    await user.click(screen.getByRole('button', { name: /view id/i }));

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText(/stored as a path on the old server/i)).toBeInTheDocument();
  });

  it('opens the add form with the legacy fields, including the upload', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<ContactsPage />);

    await screen.findByText('Raj Kumar');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByLabelText(/^name/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/type/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/organisation/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/contact number/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/email/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/remark/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/address line 1/i)).toBeInTheDocument();
    expect(within(dialog).getByLabelText(/address line 2/i)).toBeInTheDocument();
    // The FileUpload contact_master.aspx had, which the form was missing.
    expect(within(dialog).getByText(/id document/i)).toBeInTheDocument();
  });
});
