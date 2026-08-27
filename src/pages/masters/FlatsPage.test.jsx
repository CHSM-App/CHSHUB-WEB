import { describe, expect, it, beforeEach } from 'vitest';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import FlatsPage from './FlatsPage.jsx';

const BASE = '/api/web';

const BUILDINGS = [
  { build_id: 1, name: 'Ganesh Bhavan' },
  { build_id: 2, name: 'Shiv Kunj' },
];

/*
 * Wings come from the wing master, not from flats.lookups() — only this
 * endpoint returns build_id, which is what says a wing belongs to a building.
 * Both buildings name a wing "A", which is the case that makes the bare wing
 * name ambiguous in an unfiltered list.
 */
const WINGS = [
  { wing_id: 10, w_name: 'A', build_id: 1, name: 'Ganesh Bhavan' },
  { wing_id: 11, w_name: 'B', build_id: 1, name: 'Ganesh Bhavan' },
  { wing_id: 20, w_name: 'A', build_id: 2, name: 'Shiv Kunj' },
];

const FLAT = {
  flat_id: 3,
  flat_no: '101',
  build_wing: 'Ganesh Bhavan A',
  flat_type: 'Residential',
  bed: 2,
  sq_ft: '900',
  wing_id: 10,
  build_id: 1,
};

const LOOKUPS = {
  // Deliberately the shape Fill_list returns — a joined name and no build_id —
  // so a page that cascaded off this list would fail the tests below.
  wings: [
    { wing_id: 10, name: 'Ganesh Bhavan A' },
    { wing_id: 11, name: 'Ganesh Bhavan B' },
    { wing_id: 20, name: 'Shiv Kunj A' },
  ],
  flatTypes: [{ flat_type_id: 1, flat_type: 'Residential' }],
  usages: [{ usage_id: 1, usage: 'Self' }],
  bedrooms: [{ bed_id: 2, bed: 2 }],
};

/** Records the query the list was last fetched with, so a test can assert it. */
function handlers({ items = [FLAT], onList } = {}) {
  return [
    http.get(`${BASE}/masters/flats`, ({ request }) => {
      const params = new URL(request.url).searchParams;
      onList?.({ buildingId: params.get('buildingId'), wingId: params.get('wingId') });
      return ok({ items, count: items.length });
    }),
    http.get(`${BASE}/masters/flats/lookups`, () => ok(LOOKUPS)),
    http.get(`${BASE}/masters/buildings`, () => ok({ items: BUILDINGS, count: BUILDINGS.length })),
    http.get(`${BASE}/masters/wings`, () => ok({ items: WINGS, count: WINGS.length })),
  ];
}

const buildingFilter = () => screen.getByLabelText('Filter by building');
const wingFilter = () => screen.getByLabelText('Filter by wing');

/** The wing filter's choices, minus its leading "all" entry. */
const wingChoices = () =>
  within(wingFilter())
    .getAllByRole('option')
    .map((o) => o.textContent)
    .slice(1);

beforeEach(() => {
  writeSession({ accessToken: 'access-1', refreshToken: 'refresh-1', user: { society_id: 'C10001' } });
});

describe('FlatsPage building and wing cascade', () => {
  it('names the building on each wing until one is chosen', async () => {
    server.use(...handlers());
    render(<FlatsPage />);

    // Both buildings have a wing A, so the name alone would offer the same
    // label twice with no way to tell them apart.
    await waitFor(() => expect(wingChoices()).toEqual(['Ganesh Bhavan A', 'Ganesh Bhavan B', 'Shiv Kunj A']));

    await userEvent.selectOptions(buildingFilter(), '1');

    // The building is stated in the filter beside it now, so repeating it on
    // every wing would only be noise.
    await waitFor(() => expect(wingChoices()).toEqual(['A', 'B']));
  });

  it('narrows the wing filter to the chosen building', async () => {
    server.use(...handlers());
    render(<FlatsPage />);

    await waitFor(() => expect(wingChoices()).toHaveLength(3));

    await userEvent.selectOptions(buildingFilter(), '2');
    await waitFor(() => expect(wingChoices()).toEqual(['A']));
  });

  it('asks the server for every flat in the building, across its wings', async () => {
    const calls = [];
    server.use(...handlers({ onList: (q) => calls.push(q) }));
    render(<FlatsPage />);

    await waitFor(() => expect(calls.length).toBeGreaterThan(0));
    await userEvent.selectOptions(buildingFilter(), '1');

    // buildingId alone — no wing — so the list holds both of its wings' flats
    // rather than being narrowed to one of them.
    await waitFor(() => {
      const last = calls.at(-1);
      expect(last.buildingId).toBe('1');
      expect(last.wingId).toBeNull();
    });
  });

  it('drops a wing that does not belong to the newly chosen building', async () => {
    const calls = [];
    server.use(...handlers({ onList: (q) => calls.push(q) }));
    render(<FlatsPage />);

    await waitFor(() => expect(wingChoices()).toHaveLength(3));

    await userEvent.selectOptions(buildingFilter(), '1');
    await waitFor(() => expect(wingChoices()).toEqual(['A', 'B']));
    await userEvent.selectOptions(wingFilter(), '11');
    await waitFor(() => expect(calls.at(-1).wingId).toBe('11'));

    // Wing 11 is Ganesh Bhavan's. Left set, the two filters would contradict
    // each other and the list would come back empty.
    await userEvent.selectOptions(buildingFilter(), '2');
    await waitFor(() => {
      const last = calls.at(-1);
      expect(last.buildingId).toBe('2');
      expect(last.wingId).toBeNull();
    });
    expect(wingFilter()).toHaveValue('');
  });
});

describe('FlatsPage add-flat form', () => {
  /*
   * Scoped to the dialog: "Building" and "Wing" also name a filter and a table
   * heading on the page behind it, so an unscoped query matches three elements.
   */
  const form = () => within(screen.getByRole('dialog'));
  const formBuilding = () => form().getByLabelText(/Building/);
  const formWing = () => form().getByLabelText(/Wing/);

  /** Opens the modal and waits for its building picker. */
  async function openForm() {
    server.use(...handlers());
    render(<FlatsPage />);
    await waitFor(() => expect(wingChoices()).toHaveLength(3));
    await userEvent.click(screen.getByRole('button', { name: 'Add flat' }));
    await screen.findByRole('dialog');
  }

  it('leaves the wing disabled until a building is chosen', async () => {
    await openForm();

    expect(formWing()).toBeDisabled();

    await userEvent.selectOptions(formBuilding(), '1');
    expect(formWing()).toBeEnabled();
  });

  it('offers only the chosen building\'s wings', async () => {
    await openForm();

    await userEvent.selectOptions(formBuilding(), '1');
    const choices = () =>
      within(formWing())
        .getAllByRole('option')
        .map((o) => o.textContent)
        .slice(1);
    expect(choices()).toEqual(['A', 'B']);

    await userEvent.selectOptions(formBuilding(), '2');
    expect(choices()).toEqual(['A']);
  });

  it('clears a wing left over from the previous building', async () => {
    await openForm();

    await userEvent.selectOptions(formBuilding(), '1');
    await userEvent.selectOptions(formWing(), '11');
    expect(formWing()).toHaveValue('11');

    // Wing 11 is not Shiv Kunj's, so keeping it would save the flat under a
    // building the form no longer shows.
    await userEvent.selectOptions(formBuilding(), '2');
    expect(formWing()).toHaveValue('');
  });
});
