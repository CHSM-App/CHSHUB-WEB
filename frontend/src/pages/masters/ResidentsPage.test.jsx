import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok, fail } from '@/test/server';
import { writeSession } from '@/api/client';
import ResidentsPage from './ResidentsPage.jsx';

const BASE = '/api/web';

const OWNER = {
  owner_id: 5,
  name: 'Asha Kulkarni',
  Unit: 'W-1 301',
  build_name: 'Kohinoor Square',
  pre_mob: '9876500001',
  email: 'asha@example.com',
  flat_id: 3,
  wing_id: 1,
  married_id: 1,
  type: 'Owner',
};

const LOOKUPS = {
  wings: [{ wing_id: 1, name: 'Kohinoor Square W-1' }],
  docs: [{ doc_id: 1, doc_name: 'Pan Card' }],
  marital: [
    { married_id: 1, married_name: 'married' },
    { married_id: 2, married_name: 'unmarried' },
  ],
  availableFlats: [{ flat_id: 9, flat_type: '302 Residential 2 BED 1200' }],
};

function handlers({ items = [OWNER], onCreate } = {}) {
  return [
    http.get(`${BASE}/masters/owners`, ({ request }) => {
      const type = new URL(request.url).searchParams.get('type');
      return ok({ items, count: items.length, type });
    }),
    http.get(`${BASE}/masters/owners/lookups`, () => ok(LOOKUPS)),
    http.post(`${BASE}/masters/owners`, async ({ request }) => {
      const body = await request.json();
      onCreate?.(body);
      return ok({ owner: { ...OWNER, ...body }, owner_id: 99 });
    }),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1', user: { society_id: 'C10001' } });
});

describe('ResidentsPage', () => {
  it('lists owners', async () => {
    server.use(...handlers());
    render(<ResidentsPage type="Owner" />);

    expect((await screen.findAllByText('Asha Kulkarni')).length).toBeGreaterThan(0);
    expect(screen.getByRole('heading', { name: /owners/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /add owner/i })).toBeInTheDocument();
  });

  it('requests the Rent type on the tenants route', async () => {
    let seenType = null;
    server.use(
      http.get(`${BASE}/masters/owners`, ({ request }) => {
        seenType = new URL(request.url).searchParams.get('type');
        return ok({ items: [], count: 0, type: seenType });
      }),
      http.get(`${BASE}/masters/owners/lookups`, () => ok(LOOKUPS)),
    );

    render(<ResidentsPage type="Rent" />);

    await waitFor(() => expect(seenType).toBe('Rent'));
    expect(await screen.findByRole('heading', { name: /tenants/i })).toBeInTheDocument();
  });

  it('submits a new owner with numeric ids', async () => {
    const user = userEvent.setup();
    let created = null;
    server.use(...handlers({ onCreate: (b) => { created = b; } }));

    render(<ResidentsPage type="Owner" />);
    await screen.findAllByText('Asha Kulkarni');
    await user.click(screen.getByRole('button', { name: /add owner/i }));

    const dialog = await screen.findByRole('dialog');
    await user.type(within(dialog).getByLabelText(/full name/i), 'New Person');
    await user.type(within(dialog).getByLabelText(/^mobile/i), '9000000000');
    await user.selectOptions(within(dialog).getByLabelText(/wing/i), '1');
    await user.selectOptions(within(dialog).getByLabelText(/flat/i), '9');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    await waitFor(() => expect(created).not.toBeNull());
    expect(created).toMatchObject({
      name: 'New Person',
      mobile: '9000000000',
      type: 'Owner',
      wingId: 1, // numbers, not strings — the API rejects non-integers
      flatId: 9,
    });
  });

  it('allows editing marital status (deployed SP persists married_id)', async () => {
    const user = userEvent.setup();
    server.use(...handlers());

    render(<ResidentsPage type="Owner" />);
    await screen.findAllByText('Asha Kulkarni');
    // DataGrid renders a table row and a card for the same record (the card is
    // the below-`sm` layout), so row actions appear twice in the DOM.
    await user.click(screen.getAllByRole('button', { name: /^edit$/i })[0]);

    const dialog = await screen.findByRole('dialog');
    const marital = within(dialog).getByLabelText(/marital status/i);
    expect(marital).toBeEnabled();

    await user.selectOptions(marital, '2');
    expect(marital).toHaveValue('2');
  });

  it('shows a conflict error from the API inside the form', async () => {
    const user = userEvent.setup();
    // The POST override must come first: msw matches the earliest registered
    // handler, and handlers() also registers a POST for this path.
    server.use(
      http.post(`${BASE}/masters/owners`, () =>
        fail(409, 'This flat already has an owner assigned', 'CONFLICT'),
      ),
      ...handlers(),
    );

    render(<ResidentsPage type="Owner" />);
    await screen.findAllByText('Asha Kulkarni');
    await user.click(screen.getByRole('button', { name: /add owner/i }));

    const dialog = await screen.findByRole('dialog');
    await user.type(within(dialog).getByLabelText(/full name/i), 'Dup');
    await user.type(within(dialog).getByLabelText(/^mobile/i), '9000000000');
    await user.selectOptions(within(dialog).getByLabelText(/wing/i), '1');
    await user.selectOptions(within(dialog).getByLabelText(/flat/i), '9');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    expect(await within(dialog).findByRole('alert')).toHaveTextContent(/already has an owner/i);
  });

  // rental_search.aspx showed "View Docs" only where a document existed.
  describe('View Docs', () => {
    it('is hidden for a resident with no documents', async () => {
      server.use(...handlers());
      render(<ResidentsPage type="Owner" />);

      await screen.findAllByText('Asha Kulkarni');
      expect(screen.queryByRole('button', { name: /view documents/i })).not.toBeInTheDocument();
    });

    it('appears when the row carries a document path', async () => {
      const withDocs = {
        ...OWNER,
        id_proof: 'owner-documents/id-1.pdf',
        agreement_path: 'agreements/rent-1.pdf',
      };
      server.use(...handlers({ items: [withDocs] }));
      render(<ResidentsPage type="Owner" />);

      await screen.findAllByText('Asha Kulkarni');
      expect(screen.getAllByRole('button', { name: /view documents/i }).length).toBeGreaterThan(0);
    });

    it('lists only the documents that exist, and explains an unreachable one', async () => {
      const user = userEvent.setup();
      const withDocs = {
        ...OWNER,
        id_proof: 'owner-documents/id-1.pdf',
        // A path on the old server's disk — cannot be served over HTTP.
        police_verification_path: 'D:\\VengurlaTech\\society\\police.pdf',
      };
      server.use(...handlers({ items: [withDocs] }));
      render(<ResidentsPage type="Owner" />);

      await screen.findAllByText('Asha Kulkarni');
      await user.click(screen.getAllByRole('button', { name: /view documents/i })[0]);

      const dialog = await screen.findByRole('dialog');
      expect(within(dialog).getByText('ID proof')).toBeInTheDocument();
      expect(within(dialog).getByText('Police verification')).toBeInTheDocument();
      // No agreement on this row, so it is not listed at all.
      expect(within(dialog).queryByText('Rent agreement')).not.toBeInTheDocument();
      // The disk path is explained rather than linked.
      expect(within(dialog).getByText(/stored as a path on the old server/i)).toBeInTheDocument();
    });
  });

  /*
   * The form renders an email and two extra numbers that the page's field list
   * did not mention, so nothing checked them — a tenant saved with "abc" as an
   * address. The tenant route is used here because that is where it was found;
   * both routes render the same form.
   */
  describe('contact validation', () => {
    const openForm = async (user) => {
      server.use(...handlers({ items: [] }));
      render(<ResidentsPage type="Rent" />);
      await user.click(await screen.findByRole('button', { name: /add tenant/i }));
      return screen.findByRole('dialog');
    };

    it('complains about a malformed email as soon as the box is left', async () => {
      const user = userEvent.setup();
      const dialog = await openForm(user);

      await user.type(within(dialog).getByLabelText(/^email/i), 'not-an-address');
      // Focus moves on: the complaint is due now, not at Submit.
      await user.tab();

      expect(await within(dialog).findByText(/valid email address/i)).toBeInTheDocument();
    });

    it('clears the complaint once the address is corrected', async () => {
      const user = userEvent.setup();
      const dialog = await openForm(user);
      const email = within(dialog).getByLabelText(/^email/i);

      await user.type(email, 'nope');
      await user.tab();
      expect(await within(dialog).findByText(/valid email address/i)).toBeInTheDocument();

      await user.clear(email);
      await user.type(email, 'tenant@example.com');
      await user.tab();
      await waitFor(() =>
        expect(within(dialog).queryByText(/valid email address/i)).not.toBeInTheDocument(),
      );
    });

    it('keeps a mobile box to ten digits and refuses the letters', async () => {
      const user = userEvent.setup();
      const dialog = await openForm(user);
      const mobile = within(dialog).getByLabelText(/^mobile/i);

      await user.type(mobile, '98a76b543210999');
      // Letters dropped on the way in, and the rest stops at ten.
      expect(mobile).toHaveValue('9876543210');
    });

    it('blocks Save on a short alternate mobile, which nothing checked before', async () => {
      const user = userEvent.setup();
      let posted = null;
      server.use(
        ...handlers({ items: [], onCreate: (body) => (posted = body) }),
      );
      render(<ResidentsPage type="Rent" />);
      await user.click(await screen.findByRole('button', { name: /add tenant/i }));
      const dialog = await screen.findByRole('dialog');

      await user.type(within(dialog).getByLabelText(/full name/i), 'R Deshpande');
      await user.type(within(dialog).getByLabelText(/^mobile/i), '9876543210');
      await user.selectOptions(within(dialog).getByLabelText(/wing/i), '1');
      await user.type(within(dialog).getByLabelText(/alternate mobile/i), '98765');

      await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

      expect(await within(dialog).findByText(/10-digit contact number/i)).toBeInTheDocument();
      expect(posted).toBeNull();
    });
  });
});
