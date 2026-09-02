import { beforeEach, describe, expect, it } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import { VisitorsPage } from './CommunityPages.jsx';

const BASE = '/api/web';

/*
 * sp_flat_master Grid_Show rows, as the `flat` view returns them: the building
 * is `name`, the wing `w_name`, and the two joined `build_wing`.
 *
 * Two buildings, and two wings in the first — both running a flat 9, which is
 * the case that makes a bare flat number ambiguous.
 */
const FLATS = {
  items: [
    { flat_id: 7, flat_no: '10', name: 'Ganesh Bhavan', w_name: 'A', build_wing: 'Ganesh Bhavan A' },
    { flat_id: 5, flat_no: '9', name: 'Ganesh Bhavan', w_name: 'A', build_wing: 'Ganesh Bhavan A' },
    { flat_id: 9, flat_no: '9', name: 'Ganesh Bhavan', w_name: 'B', build_wing: 'Ganesh Bhavan B' },
    { flat_id: 8, flat_no: '2', name: 'Shiv Kunj', w_name: 'A', build_wing: 'Shiv Kunj A' },
  ],
};

function handlers({ onCreate } = {}) {
  return [
    http.get(`${BASE}/community/visitors`, () => ok({ items: [], count: 0 })),
    http.get(`${BASE}/masters/flats`, () => ok(FLATS)),
    http.post(`${BASE}/community/visitors`, async ({ request }) => {
      const body = await request.json();
      onCreate?.(body);
      // The route answers with the push summary beside the saved row.
      return ok({ visitor: { visitor_id: 21 }, notified: { sent: 2, recipients: 3 } }, 201);
    }),
  ];
}

const buildingField = () => screen.getByLabelText(/Building/);
const flatField = () => screen.getByLabelText(/^Flat$/);

/** The flat picker's choices, minus its leading placeholder. */
const flatChoices = () =>
  within(flatField())
    .getAllByRole('option')
    .map((o) => o.textContent)
    .slice(1);

/** Opens the register form and waits for the flats to arrive. */
async function openForm() {
  render(<VisitorsPage />);
  await userEvent.click(await screen.findByRole('button', { name: 'Register visitor' }));
  await waitFor(() =>
    expect(within(buildingField()).getAllByRole('option').length).toBeGreaterThan(1),
  );
}

beforeEach(() => {
  writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1', user: { society_id: 'C10001' } });
});

describe('VisitorsPage unit picker', () => {
  it('offers each building once, not one entry per flat', async () => {
    server.use(...handlers());
    await openForm();

    // Three of the four flats are in Ganesh Bhavan, across two wings.
    expect(
      within(buildingField())
        .getAllByRole('option')
        .map((o) => o.textContent)
        .slice(1),
    ).toEqual(['Ganesh Bhavan', 'Shiv Kunj']);
  });

  it('leaves the flat disabled until a building is chosen', async () => {
    server.use(...handlers());
    await openForm();

    expect(flatField()).toBeDisabled();
    await userEvent.selectOptions(buildingField(), 'Ganesh Bhavan');
    expect(flatField()).toBeEnabled();
  });

  it('lists only that building\'s flats, wing named and in number order', async () => {
    server.use(...handlers());
    await openForm();

    await userEvent.selectOptions(buildingField(), 'Ganesh Bhavan');

    // Wing first, then 9 before 10 — the number compared as a number. Each
    // label names its wing because A and B each run a flat 9.
    expect(flatChoices()).toEqual(['A · 9', 'A · 10', 'B · 9']);

    await userEvent.selectOptions(buildingField(), 'Shiv Kunj');
    expect(flatChoices()).toEqual(['A · 2']);
  });

  it('drops a flat left over from the previous building', async () => {
    server.use(...handlers());
    await openForm();

    await userEvent.selectOptions(buildingField(), 'Ganesh Bhavan');
    await userEvent.selectOptions(flatField(), '7');
    expect(flatField()).toHaveValue('7');

    // Flat 7 is not Shiv Kunj's — kept, it would notify the wrong residents.
    await userEvent.selectOptions(buildingField(), 'Shiv Kunj');
    expect(flatField()).toHaveValue('');
  });

  it('sends the chosen flat, so the API can notify its residents', async () => {
    const created = [];
    server.use(...handlers({ onCreate: (body) => created.push(body) }));
    await openForm();

    await userEvent.type(screen.getByLabelText(/Visitor name/), 'Ramesh');
    await userEvent.selectOptions(buildingField(), 'Ganesh Bhavan');
    await userEvent.selectOptions(flatField(), '9');
    await userEvent.click(screen.getByRole('button', { name: 'Save' }));

    // The flat is what the notification is addressed to — the field used to be
    // a raw id box, left blank, which reached no one.
    await waitFor(() => expect(created).toHaveLength(1));
    expect(created[0].flatId).toBe('9');
    expect(created[0].name).toBe('Ramesh');
  });

  it('saves a visitor with no flat against them', async () => {
    const created = [];
    server.use(...handlers({ onCreate: (body) => created.push(body) }));
    await openForm();

    // A contractor for the society itself belongs to no flat. The gate still
    // needs telling, so the form must not insist on one.
    await userEvent.type(screen.getByLabelText(/Visitor name/), 'Painter');
    await userEvent.click(screen.getByRole('button', { name: 'Save' }));

    await waitFor(() => expect(created).toHaveLength(1));
    expect(created[0].flatId).toBe('');
  });

  it('holds Save shut until the visitor is named', async () => {
    const created = [];
    server.use(...handlers({ onCreate: (body) => created.push(body) }));
    await openForm();

    /*
     * Save is disabled outright while the name is empty, so the guard is the
     * button rather than a message — the validator behind it never gets to
     * run, which is why its key being wrong went unnoticed for so long.
     */
    const save = screen.getByRole('button', { name: 'Save' });
    expect(save).toBeDisabled();
    await userEvent.click(save);
    expect(created).toHaveLength(0);

    // Once named, the same button saves — the half that was broken. Keyed on
    // the column's `v_name` while the form holds `name`, the required check
    // read undefined however much was typed and refused every save.
    await userEvent.type(screen.getByLabelText(/Visitor name/), 'Painter');
    expect(save).toBeEnabled();
  });
});
