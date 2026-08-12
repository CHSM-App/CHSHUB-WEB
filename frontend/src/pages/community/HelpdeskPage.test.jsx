import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import HelpdeskPage from './HelpdeskPage.jsx';

const BASE = '/api/web';

/** sp_helpdesk GetTickets. urgency is the 0/1 flag HelpdeskRequest stores. */
const TICKETS = {
  items: [
    {
      helpdesk_id: 11,
      query: 'Lift stuck on 3rd floor',
      p_type_name: 'Electrical',
      name: 'Munna Tripathi',
      flat_no: '101',
      build_name: 'Ganga',
      Unit: 'A 101',
      flat_id: 5,
      urgency: 1,
      status: 1,
      // GetTickets does not CONVERT this one, so it arrives with a time on it.
      req_service_date: '2026-08-12T00:00:00',
    },
    {
      helpdesk_id: 12,
      query: 'Corridor bulb fused',
      p_type_name: 'Electrical',
      name: 'Kaleen Bhaiya',
      flat_no: 'B-204',
      build_name: 'Yamuna',
      flat_id: 6,
      urgency: 0,
      status: 4,
      req_service_date: '10 Aug 2026',
    },
  ],
};

const STATUSES = {
  items: [
    { id: 1, status: 'New' },
    { id: 2, status: 'In-Progress' },
    { id: 3, status: 'On-Hold' },
    { id: 4, status: 'Closed' },
  ],
};

const TICKET_11 = {
  ticket: {
    helpdesk_id: 11,
    query: 'Lift stuck on 3rd floor',
    status: 1,
    name: 'Munna Tripathi',
    Unit: 'A-101',
    image: 'helpdesk/lift.jpg',
  },
  /*
   * dateTime as GetComments actually returns it: CONVERT(varchar, .., 100),
   * i.e. "Aug 12 2026  9:10AM" — two spaces, no space before the meridiem.
   */
  comments: [
    { comment_id: 1, name: 'Munna Tripathi', type: 'owner', description: 'Been stuck since 9am', dateTime: 'Aug 12 2026  9:10AM' },
    { comment_id: 2, name: 'Office (admin)', type: 'Admin', description: 'Technician on the way', dateTime: 'Aug 12 2026  9:40AM' },
  ],
};

/*
 * Overrides come first: msw uses the first handler that matches, so an `extra`
 * appended after the defaults would be shadowed by them rather than replacing
 * them. Note also that /helpdesk/statuses must precede /helpdesk/:id, which
 * would otherwise swallow it with id="statuses".
 */
const handlers = (extra = []) => [
  ...extra,
  http.get(`${BASE}/community/helpdesk/statuses`, () => ok(STATUSES)),
  http.get(`${BASE}/community/helpdesk/:id`, () => ok(TICKET_11)),
  http.get(`${BASE}/community/helpdesk`, () => ok(TICKETS)),
];

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

/*
 * DataGrid renders the same rows twice — a <table> and, for narrow screens, a
 * stacked card list. Both are in the DOM at once (CSS decides which is shown),
 * so every query here is scoped to the table to avoid matching both copies.
 */
const table = () => screen.getByRole('table');

/**
 * Click the View button under one of the two button columns, on the row whose
 * query is `text`. Both buttons read "View", so they are told apart by which
 * column they sit in rather than by their label.
 */
async function clickRowView(text, columnLabel) {
  await screen.findByRole('table');
  const headers = within(table()).getAllByRole('columnheader');
  const index = headers.findIndex((h) => h.textContent.trim().startsWith(columnLabel));
  expect(index, `no "${columnLabel}" column`).toBeGreaterThan(-1);

  const row = within(table()).getByText(text).closest('tr');
  await userEvent.click(within(row.cells[index]).getByRole('button', { name: 'View' }));
}

describe('HelpdeskPage', () => {
  it('reads urgency as the Minor/Urgent flag it is, not a 1-3 scale', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    // urgency 1 is Urgent. Mapped as a scale it read "Low" — the inverse.
    await screen.findByRole('table');
    expect(within(table()).getByText('Urgent')).toBeInTheDocument();

    // urgency 0 is Minor, and showed "—" when 0 was absent from the map.
    await userEvent.click(screen.getByRole('button', { name: /all/i }));
    expect(await within(table()).findByText('Minor')).toBeInTheDocument();
  });

  it('shows the building and unit the legacy grid led with', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    await screen.findByRole('table');
    expect(within(table()).getByText('Ganga')).toBeInTheDocument();
    expect(within(table()).getByText('A 101')).toBeInTheDocument();
  });

  /*
   * Unit comes from the CTE widened by FIX_helpdesk_tickets_building_unit.sql.
   * Against a database without it the column must still say something, so it
   * falls back to flat_no rather than showing a dash.
   */
  it('falls back to the flat number when Unit is not returned', async () => {
    server.use(
      ...handlers([
        http.get(`${BASE}/community/helpdesk`, () =>
          ok({
            items: TICKETS.items.map(({ Unit, build_name, ...rest }) => rest),
          }),
        ),
      ]),
    );
    render(<HelpdeskPage />);

    await screen.findByRole('table');
    expect(within(table()).getByText('101')).toBeInTheDocument();
  });

  it('shows the service date without a time of day', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    await screen.findByRole('table');
    const expected = new Date('2026-08-12T00:00:00').toLocaleDateString();
    expect(within(table()).getByText(expected)).toBeInTheDocument();
    // The stored smalldatetime dragged 00:00:00 along behind the date.
    expect(within(table()).queryByText(/00:00:00/)).not.toBeInTheDocument();
  });

  it('changes status from the row, without opening anything', async () => {
    const saved = vi.fn();
    server.use(
      ...handlers([
        http.put(`${BASE}/community/helpdesk/:id/status`, async ({ request, params }) => {
          saved({ id: params.id, ...(await request.json()) });
          return ok({ helpdesk_id: Number(params.id) });
        }),
      ]),
    );
    render(<HelpdeskPage />);

    await screen.findByRole('table');
    const select = within(table()).getByLabelText('Status for ticket 11');
    await userEvent.selectOptions(select, '2');

    await waitFor(() => expect(saved).toHaveBeenCalledWith({ id: '11', status: 2 }));
  });

  /*
   * The row keeps its place after a status change. Reloading the list would
   * re-sort and re-page it, moving the row out from under the operator.
   */
  it('keeps the ticket on screen after its status is saved', async () => {
    server.use(
      ...handlers([
        http.put(`${BASE}/community/helpdesk/:id/status`, ({ params }) =>
          ok({ helpdesk_id: Number(params.id) }),
        ),
      ]),
    );
    render(<HelpdeskPage />);

    await screen.findByRole('table');
    const select = within(table()).getByLabelText('Status for ticket 11');
    await userEvent.selectOptions(select, '2');

    await waitFor(() => expect(select).toHaveValue('2'));
    expect(within(table()).getByText('Lift stuck on 3rd floor')).toBeInTheDocument();
  });

  it('opens the comment thread from the row and separates resident from office', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    await clickRowView('Lift stuck on 3rd floor', 'Comments');

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('Been stuck since 9am')).toBeInTheDocument();
    expect(within(dialog).getByText('Technician on the way')).toBeInTheDocument();

    // type 'owner' hugs the left; anything else is the office and is pushed right.
    const resident = within(dialog).getByText('Been stuck since 9am').closest('li');
    const office = within(dialog).getByText('Technician on the way').closest('li');
    expect(resident.className).not.toMatch(/ml-auto/);
    expect(office.className).toMatch(/ml-auto/);
  });

  /*
   * The SP hands back a display string, not a timestamp. Passing it through
   * new Date() gave Invalid Date, so the line under each comment was blank.
   */
  it('shows the timestamp SQL already formatted', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    await clickRowView('Lift stuck on 3rd floor', 'Comments');

    // Testing Library collapses the double space when matching, so the
    // expected text is normalised the same way rather than quoted verbatim.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('Aug 12 2026 9:10AM')).toBeInTheDocument();
    expect(within(dialog).getByText('Aug 12 2026 9:40AM')).toBeInTheDocument();
    expect(within(dialog).queryByText(/invalid date/i)).not.toBeInTheDocument();
  });

  it('posts a reply and reloads the thread', async () => {
    const posted = vi.fn();
    server.use(
      ...handlers([
        http.post(`${BASE}/community/helpdesk/:id/comments`, async ({ request }) => {
          posted(await request.json());
          return ok({ added: true }, 201);
        }),
      ]),
    );
    render(<HelpdeskPage />);

    await clickRowView('Lift stuck on 3rd floor', 'Comments');

    const dialog = await screen.findByRole('dialog');
    await userEvent.type(within(dialog).getByLabelText(/write a reply/i), 'Lift restored');
    await userEvent.click(within(dialog).getByRole('button', { name: /^send$/i }));

    await waitFor(() =>
      expect(posted).toHaveBeenCalledWith(
        expect.objectContaining({ comment: 'Lift restored', flatId: 5, type: 'Admin' }),
      ),
    );
  });

  it('opens attachments from the row', async () => {
    server.use(...handlers());
    render(<HelpdeskPage />);

    await clickRowView('Lift stuck on 3rd floor', 'Image');

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText(/helpdesk images/i)).toBeInTheDocument();
  });

  it('says so when a ticket has no attachments', async () => {
    server.use(
      ...handlers([
        http.get(`${BASE}/community/helpdesk/11`, () =>
          ok({ ticket: { ...TICKET_11.ticket, image: null }, comments: [] }),
        ),
      ]),
    );
    render(<HelpdeskPage />);

    await clickRowView('Lift stuck on 3rd floor', 'Image');

    expect(await screen.findByText('No images found.')).toBeInTheDocument();
  });
});
