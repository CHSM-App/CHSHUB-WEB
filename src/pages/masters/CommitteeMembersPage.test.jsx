import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { CommitteeMembersPage } from './MasterPages.jsx';

const BASE = '/api/web';

/*
 * E-mail ID and Username carried a red asterisk that nothing enforced: neither
 * was in the page's field list, so a member saved with both blank and the
 * e-mail box took any text at all.
 */
const LOOKUPS = {
  types: [{ UserTypeId: 2, UserTypeName: 'Secretary' }],
  owners: [
    {
      owner_id: 7,
      name: 'Asha Kulkarni',
      contact_no: '9876500001',
      email: 'asha@example.com',
    },
  ],
};

function handlers({ onCreate } = {}) {
  return [
    http.get(`${BASE}/masters/members`, () => ok({ items: [] })),
    http.get(`${BASE}/masters/member-lookups`, () => ok(LOOKUPS)),
    http.post(`${BASE}/masters/members`, async ({ request }) => {
      onCreate?.(await request.json());
      return ok({ user_id: 42 });
    }),
  ];
}

/** Opens Add and fills everything the form insists on. */
async function openAndFill(user, dialog) {
  await user.selectOptions(within(dialog).getByLabelText(/^name/i), '7');
  await user.selectOptions(within(dialog).getByLabelText(/designation/i), '2');
}

beforeEach(() => {
  writeSession({
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    user: { society_id: 'C10001' },
  });
});

describe('CommitteeMembersPage', () => {
  const openForm = async (user, opts) => {
    server.use(...handlers(opts));
    render(<CommitteeMembersPage />);
    await user.click(await screen.findByRole('button', { name: /^add$/i }));
    return screen.findByRole('dialog');
  };

  it('refuses a member whose starred e-mail and username are blank', async () => {
    const user = userEvent.setup();
    let posted = null;
    const dialog = await openForm(user, { onCreate: (b) => (posted = b) });

    // Designation and contact are filled by hand; picking no resident leaves
    // the e-mail and username boxes empty, which used to save.
    await user.selectOptions(within(dialog).getByLabelText(/designation/i), '2');
    await user.type(within(dialog).getByLabelText(/contact no/i), '9876543210');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    expect(await within(dialog).findByText(/enter the e-mail id/i)).toBeInTheDocument();
    expect(within(dialog).getByText(/enter the username/i)).toBeInTheDocument();
    expect(posted).toBeNull();
  });

  it('refuses a malformed e-mail address', async () => {
    const user = userEvent.setup();
    let posted = null;
    const dialog = await openForm(user, { onCreate: (b) => (posted = b) });

    await openAndFill(user, dialog);
    const email = within(dialog).getByLabelText(/e-mail id/i);
    await user.clear(email);
    await user.type(email, 'not-an-address');
    await user.type(within(dialog).getByLabelText(/^password/i), 'secret123');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    expect(await within(dialog).findByText(/valid email address/i)).toBeInTheDocument();
    expect(posted).toBeNull();
  });

  it('keeps the contact box to ten digits and drops the letters', async () => {
    const user = userEvent.setup();
    const dialog = await openForm(user);

    const contact = within(dialog).getByLabelText(/contact no/i);
    await user.clear(contact);
    await user.type(contact, '98a76b543210999');
    expect(contact).toHaveValue('9876543210');
  });

  it('saves a member once every box is filled and well-formed', async () => {
    const user = userEvent.setup();
    let posted = null;
    const dialog = await openForm(user, { onCreate: (b) => (posted = b) });

    // Picking the resident fills contact, e-mail and username from their
    // record, as the legacy page did.
    await openAndFill(user, dialog);
    await user.type(within(dialog).getByLabelText(/^password/i), 'secret123');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    // The save is what matters here; the toast host is not mounted in a unit
    // test, so useToast is a no-op and there is no banner to look for.
    await waitFor(() => expect(posted).not.toBeNull());
    expect(posted).toMatchObject({ email: 'asha@example.com', contactNo: '9876500001' });
  });
});
