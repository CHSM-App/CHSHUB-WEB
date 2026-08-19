import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render as rtlRender, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { http } from 'msw';
import { server, ok, fail } from '@/test/server';
import { writeSession } from '@/api/client';
import BillsPage from './BillsPage.jsx';

// The page links to the billing settings screen, so it needs a router.
const render = (ui) => rtlRender(<MemoryRouter>{ui}</MemoryRouter>);

const BASE = '/api/web';

const RUN = {
  bill_id: 12,
  month_name: 'November',
  year: 2025,
  gen_date: '2025-11-01',
  due_date: '2025-11-15',
  Status: 'Generated',
  bill_type: 1,
  bill_type_label: 'Regular',
};

const CHARGES = {
  flats: 26,
  count: 2,
  items: [
    { charge_id: 1, charges: 'sinking', amount: 3000, amount_per_flat: 115.38 },
    { charge_id: 2, charges: 'repair fund', amount: 1000, amount_per_flat: 38.46 },
  ],
};

function handlers({ runs = [RUN], charges = CHARGES, extra = [] } = {}) {
  return [
    http.get(`${BASE}/billing/bills`, () => ok({ items: runs, count: runs.length })),
    http.get(`${BASE}/billing/bills/charges`, () => ok(charges)),
    ...extra,
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { society_id: 'C10001' } });
});

describe('BillsPage', () => {
  it('lists each bill run with its period and dates', async () => {
    server.use(...handlers());
    render(<BillsPage />);

    expect(await screen.findByText('#12')).toBeInTheDocument();
    expect(screen.getByText('November 2025')).toBeInTheDocument();
    expect(screen.getAllByText('Generated').length).toBeGreaterThan(0);
  });

  it('keeps the charge heads inside the Add modal, not on the page', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    // maintenance_search.aspx showed these in its New Maintenance modal —
    // they describe what a run is about to bill, not the list of past runs.
    expect(screen.queryByText('sinking')).not.toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /^add$/i }));
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('sinking')).toBeInTheDocument();
    expect(within(dialog).getByText('115.38')).toBeInTheDocument();
  });

  it('stamps the Add modal with today’s date, read-only', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    // bind_date() filled this with today and disabled it — a run is stamped
    // when it happens, not backdated. dd-MM-yyyy throughout, matching the
    // dates printed on the bill itself.
    const now = new Date();
    const pad = (n) => String(n).padStart(2, '0');
    const dialog = await screen.findByRole('dialog');
    const date = within(dialog).getByLabelText(/^date/i);
    expect(date).toHaveAttribute('readonly');
    expect(date).toHaveValue(`${pad(now.getDate())}-${pad(now.getMonth() + 1)}-${now.getFullYear()}`);
  });

  it('bills the add-on charges the run will actually raise', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    // The modal runs sp_new_maintenance, which bills charges_type 0. Showing
    // the regular monthly set here named charges the run would not touch.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('sinking')).toBeInTheDocument();
    expect(within(dialog).getByRole('button', { name: /generate bill/i })).toBeEnabled();
  });

  it('works out the due date as the bill period is typed', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    const dialog = await screen.findByRole('dialog');
    const period = within(dialog).getByLabelText(/bill period/i);
    await user.clear(period);
    await user.type(period, '2');

    // The legacy form showed this beneath the box, so the effect of the
    // number is visible before the run happens.
    const expected = new Date();
    expected.setMonth(expected.getMonth() + 2);
    expect(
      within(dialog).getByText(`Due date: ${expected.toLocaleDateString()}`),
    ).toBeInTheDocument();
  });

  it('totals the charge heads in that modal', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    const footer = document.querySelector('[role="dialog"] tfoot');
    expect(within(footer).getByText('4,000.00')).toBeInTheDocument();
    expect(within(footer).getByText('153.84')).toBeInTheDocument();
  });

  it('offers the export actions', async () => {
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    expect(screen.getByRole('button', { name: /export to excel/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /download pdf/i })).toBeInTheDocument();
  });

  it('lists runs newest first, regular and add-on interleaved', async () => {
    server.use(
      ...handlers({
        // The API sorts by gen_date; the page must render that order as given
        // rather than regrouping. February's add-on belongs between February
        // and March, not below July.
        runs: [
          { ...RUN, bill_id: 55, month_name: 'July', gen_date: '2026-07-20', bill_type: 0, bill_type_label: 'Add-on' },
          { ...RUN, bill_id: 52, month_name: 'July', gen_date: '2026-07-01' },
          { ...RUN, bill_id: 53, month_name: 'February', gen_date: '2026-02-20', bill_type: 0, bill_type_label: 'Add-on' },
          { ...RUN, bill_id: 47, month_name: 'February', gen_date: '2026-02-01' },
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#47');
    // The first cell is the row number the table prepends; the bill no. is the
    // one after it.
    const ids = screen
      .getAllByRole('row')
      .map((r) => r.querySelectorAll('td')[1]?.textContent)
      .filter(Boolean);
    expect(ids).toEqual(['#55', '#52', '#53', '#47']);
  });

  describe('sorting the bill runs', () => {
    const SORT_RUNS = [
      { ...RUN, bill_id: 55, month_name: 'July', year: 2026, gen_date: '2026-07-20', due_date: '2026-08-04', bill_type: 0, bill_type_label: 'Add-on', Status: 'Bill Generated' },
      { ...RUN, bill_id: 9, month_name: 'February', year: 2026, gen_date: '2026-02-01', due_date: '2026-02-16', bill_type_label: 'Regular', Status: 'Paid' },
      { ...RUN, bill_id: 52, month_name: 'April', year: 2026, gen_date: '2026-04-01', due_date: '2026-04-16', bill_type_label: 'Regular', Status: 'Bill Generated' },
    ];

    // Cell 0 is the row number the table prepends, so the bill no. is cell 1.
    const billIds = () =>
      screen
        .getAllByRole('row')
        .slice(1)
        .map((r) => within(r).getAllByRole('cell')[1].textContent);

    const renderRuns = async () => {
      server.use(...handlers({ runs: SORT_RUNS }));
      const user = userEvent.setup();
      render(<BillsPage />);
      await screen.findByText('#55');
      return user;
    };

    it('keeps the API order until a heading is clicked', async () => {
      await renderRuns();
      expect(billIds()).toEqual(['#55', '#9', '#52']);
    });

    it('sorts Period chronologically, not by the month name', async () => {
      const user = await renderRuns();

      await user.click(screen.getByRole('button', { name: 'Sort by Period' }));
      // February, April, July. Sorting the rendered label would have put
      // "April 2026" first and "July 2026" before "February 2026".
      expect(billIds()).toEqual(['#9', '#52', '#55']);
    });

    it('sorts Bill no. numerically', async () => {
      const user = await renderRuns();

      await user.click(screen.getByRole('button', { name: 'Sort by Bill no.' }));
      // 9 before 52 — as text, "9" would have sorted last.
      expect(billIds()).toEqual(['#9', '#52', '#55']);
    });

    it('sorts the Due date by timestamp rather than its dd-mm-yyyy text', async () => {
      const user = await renderRuns();

      await user.click(screen.getByRole('button', { name: 'Sort by Due' }));
      expect(billIds()).toEqual(['#9', '#52', '#55']);
    });

    it('sorts by Type, and reverses on a second click', async () => {
      const user = await renderRuns();

      await user.click(screen.getByRole('button', { name: 'Sort by Type' }));
      expect(billIds()[0]).toBe('#55'); // the only Add-on

      await user.click(screen.getByRole('button', { name: 'Sort by Type' }));
      expect(billIds()[billIds().length - 1]).toBe('#55');
    });

    it('keeps the sort applied when the year filter narrows the list', async () => {
      const user = await renderRuns();

      await user.click(screen.getByRole('button', { name: 'Sort by Bill no.' }));
      expect(billIds()).toEqual(['#9', '#52', '#55']);

      await user.selectOptions(screen.getByLabelText(/filter by year/i), '2026');
      await waitFor(() => expect(billIds()).toEqual(['#9', '#52', '#55']));
    });
  });

  it('labels each run with the button that raised it', async () => {
    server.use(
      ...handlers({
        runs: [
          RUN,
          { ...RUN, bill_id: 20, bill_type: 0, bill_type_label: 'Add-on' },
          { ...RUN, bill_id: 21, bill_type: 0, bill_type_label: 'Add-on' },
        ],
      }),
    );
    render(<BillsPage />);

    // Three November runs — one monthly, two ad-hoc. Grid_Show returns no
    // bill_type, so all three read "Bill Generated" and there was no way to
    // tell the monthly maintenance from a one-off levy.
    await screen.findByText('#21');
    const rows = screen.getAllByRole('row');
    const cellsOf = (id) =>
      within(rows.find((r) => within(r).queryByText(`#${id}`))).getAllByRole('cell');

    // Cell 0 is the row number the table prepends, so Type shifts to cell 3.
    expect(cellsOf(12)[3]).toHaveTextContent('Regular');
    expect(cellsOf(20)[3]).toHaveTextContent('Add-on');
    expect(cellsOf(21)[3]).toHaveTextContent('Add-on');
  });

  it('filters the loaded runs as you type', async () => {
    const user = userEvent.setup();
    const listed = vi.fn();
    server.use(
      http.get(`${BASE}/billing/bills/charges`, () => ok(CHARGES)),
      http.get(`${BASE}/billing/bills`, ({ request }) => {
        listed(new URL(request.url).searchParams.get('search'));
        return ok({
          items: [RUN, { ...RUN, bill_id: 13, month_name: 'December' }],
          count: 2,
        });
      }),
    );
    render(<BillsPage />);

    await screen.findByText('December 2025');
    await user.type(screen.getByLabelText(/search bills/i), 'november');

    // maintenance_search.aspx filtered the rendered grid, so the term must
    // not become a query.
    await waitFor(() => expect(screen.queryByText('December 2025')).not.toBeInTheDocument());
    expect(screen.getByText('November 2025')).toBeInTheDocument();
    expect(listed).toHaveBeenCalledTimes(1);
    expect(listed).toHaveBeenCalledWith(null);
  });

  it('hides the manual generate button when auto generation is on', async () => {
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/settings/account`, () =>
            ok({ settings: { auto_bill_generation: true } }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    // showHideGenerateBillBtn() hid it for the same reason: the scheduled run
    // already raises this month's bill, and running it by hand as well would
    // bill the society twice.
    await waitFor(() =>
      expect(screen.queryByRole('button', { name: /generate regular bill/i })).not.toBeInTheDocument(),
    );
  });

  it('drops the generate button as soon as auto generation is switched on', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/settings/account`, () =>
            ok({
              settings: {
                rate_per_sqfeet: 2,
                two_wheeler_rate: 100,
                four_wheeler_rate: 300,
                bill_gen_date: 1,
                bill_due_period: 10,
                auto_bill_generation: false,
              },
            }),
          ),
          http.put(`${BASE}/settings/account`, () => ok({ saved: true })),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    expect(screen.getByRole('button', { name: /generate regular bill/i })).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /^settings$/i }));
    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByLabelText(/auto maintenance generation/i));
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    // Otherwise the button stays on screen until a reload, inviting a second
    // bill run in a month the schedule already covers.
    await waitFor(() =>
      expect(screen.queryByRole('button', { name: /generate regular bill/i })).not.toBeInTheDocument(),
    );
  });

  it('picks recipients and hands them to the mail app', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/masters/owners`, () =>
            ok({
              items: [
                { owner_id: 5, name: 'Ghanashyam Gawas', email: 'g@example.com', Unit: 'A-1 102' },
                { owner_id: 6, name: 'Shiv Kumar', email: 's@example.com', Unit: 'A-1 101' },
                // No address on file — cannot be written to.
                { owner_id: 9, name: 'No Email', email: '', Unit: 'A-2 201' },
              ],
              count: 3,
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));
    await user.click(await screen.findByRole('button', { name: /^email$/i }));

    const dialog = await screen.findByRole('dialog', { name: /select customer/i });
    expect(within(dialog).getByText(/Ghanashyam Gawas/)).toBeInTheDocument();
    // A resident with no address cannot receive anything, so they are left out.
    expect(within(dialog).queryByText(/No Email/)).not.toBeInTheDocument();

    // Everyone is selected on open; drop one and the draft carries the rest.
    await user.click(within(dialog).getByRole('checkbox', { name: /Shiv Kumar/ }));

    const opened = vi.spyOn(window, 'open').mockImplementation(() => null);
    await user.click(within(dialog).getByRole('button', { name: /^email$/i }));

    expect(opened).toHaveBeenCalled();
    const url = decodeURIComponent(opened.mock.lastCall[0]);
    expect(url).toMatch(/^mailto:/);
    expect(url).toContain('g@example.com');
    expect(url).not.toContain('s@example.com');
    opened.mockRestore();
  });

  it('carries the legacy actions, each in one place', async () => {
    server.use(...handlers());
    render(<BillsPage />);

    await screen.findByText('#12');
    for (const name of [/^add$/i, /generate regular bill/i, /^settings$/i]) {
      expect(screen.getByRole('button', { name })).toBeInTheDocument();
    }
    // Print and the PDF download belong to the grid toolbar. The legacy page
    // had them in its header too; repeating them would be two buttons for one
    // action, so getBy — not getAllBy — is the assertion that matters.
    expect(screen.getByRole('button', { name: /^print$/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /download pdf/i })).toBeInTheDocument();
  });

  it('opens the maintenance settings in a dialog, filled from the society', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/settings/account`, () =>
            ok({
              settings: {
                rate_per_sqfeet: 2.5,
                two_wheeler_rate: 100,
                four_wheeler_rate: 300,
                bill_gen_date: 5,
                bill_due_period: 15,
                auto_bill_generation: true,
              },
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    // maintenance_search.aspx kept these in a modal on this page, not on a
    // screen of its own.
    await user.click(screen.getByRole('button', { name: /^settings$/i }));

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByLabelText(/per sq\. ft\. rate/i)).toHaveValue(2.5);
    expect(within(dialog).getByLabelText(/2 wheeler rate/i)).toHaveValue(100);
    expect(within(dialog).getByLabelText(/generation day/i)).toHaveValue(5);
    expect(within(dialog).getByLabelText(/due date period/i)).toHaveValue(15);
    expect(within(dialog).getByLabelText(/auto maintenance generation/i)).toBeChecked();
  });

  it('saves the settings from that dialog', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/settings/account`, () =>
            ok({
              settings: {
                rate_per_sqfeet: 2,
                two_wheeler_rate: 100,
                four_wheeler_rate: 300,
                bill_gen_date: 1,
                bill_due_period: 10,
              },
            }),
          ),
          http.put(`${BASE}/settings/account`, async ({ request }) => {
            saved(await request.json());
            return ok({ saved: true });
          }),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^settings$/i }));

    const dialog = await screen.findByRole('dialog');
    const rate = within(dialog).getByLabelText(/per sq\. ft\. rate/i);
    await user.clear(rate);
    await user.type(rate, '3.5');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    // These values feed gen_bill, so what the dialog sends has to be what was
    // typed rather than the defaults it opened with.
    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({ ratePerSqFt: '3.5' });
  });

  it('asks before generating the regular bill, then runs it', async () => {
    const user = userEvent.setup();
    const ran = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/billing/generate/regular`, async ({ request }) => {
            ran(await request.json());
            return ok({ generated: true });
          }),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /generate regular bill/i }));

    // This writes real charges against every flat, so the click alone must
    // not run it.
    expect(ran).not.toHaveBeenCalled();
    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: /^generate$/i }));

    // The API rejects the request without confirm: true.
    await waitFor(() => expect(ran).toHaveBeenCalled());
    expect(ran.mock.lastCall[0]).toMatchObject({ confirm: true });

    // Generating is the whole point of the button, so say it worked.
    expect(await screen.findByRole('status')).toHaveTextContent(/generated/i);
  });

  it('says so when the month is already billed and nothing was generated', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/billing/generate/regular`, () =>
            ok({
              generated: false,
              message:
                'No bills generated — a run already exists for this month, or there are no eligible flats.',
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /generate regular bill/i }));
    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: /^generate$/i }));

    // gen_bill skips a society already billed this month and the API answers
    // 200. Without a message the dialog just closes over an unchanged grid,
    // which reads as a broken button rather than a bill that already exists.
    const notice = await screen.findByRole('status');
    expect(notice).toHaveTextContent(/already exists for this month/i);
  });

  it('raises an add-on run from the Add modal, over the month’s charges', async () => {
    const user = userEvent.setup();
    const ran = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/billing/generate/addon`, async ({ request }) => {
            ran(await request.json());
            return ok({ generated: true });
          }),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    // The modal shows what it is about to bill — the same charge heads as the
    // panel below the grid.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('sinking')).toBeInTheDocument();

    const period = within(dialog).getByLabelText(/bill period/i);
    await user.clear(period);
    await user.type(period, '3');
    await user.click(within(dialog).getByRole('button', { name: /generate bill/i }));

    await waitFor(() => expect(ran).toHaveBeenCalled());
    expect(ran.mock.lastCall[0]).toMatchObject({ confirm: true, duePeriodMonths: 3 });
  });

  it('refetches the charge heads each time the Add modal opens', async () => {
    const user = userEvent.setup();
    // Mirrors the procedure: the run retires whatever heads it billed, so the
    // server answers with the heads still live at the time of each request.
    let live = CHARGES;
    server.use(
      http.get(`${BASE}/billing/bills`, () => ok({ items: [RUN], count: 1 })),
      http.get(`${BASE}/billing/bills/charges`, () => ok(live)),
      http.post(`${BASE}/billing/generate/addon`, () => {
        live = { flats: 26, count: 0, items: [] };
        return ok({ generated: true });
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));
    expect(within(await screen.findByRole('dialog')).getByText('sinking')).toBeInTheDocument();

    await user.click(
      within(screen.getByRole('dialog')).getByRole('button', { name: /generate bill/i }),
    );

    // sp_new_maintenance switches a head off once it has billed it. Fetching
    // only at mount left the modal offering charges already spent, and hid a
    // head activated on the Charges page until the whole page was reloaded.
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    const reopened = await screen.findByRole('dialog');
    expect(within(reopened).queryByText('sinking')).not.toBeInTheDocument();
  });

  it('asks again when an add-on has already gone out today', async () => {
    const user = userEvent.setup();
    const bodies = [];
    server.use(
      ...handlers({
        extra: [
          http.post(`${BASE}/billing/generate/addon`, async ({ request }) => {
            const body = await request.json();
            bodies.push(body);
            // The API refuses a second run on the same day unless told.
            if (!body.allowDuplicate) {
              return fail(409, 'A bill run already exists for today.', 'CONFLICT');
            }
            return ok({ generated: true });
          }),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));
    await user.click(await screen.findByRole('button', { name: /generate bill/i }));

    // Swallowing the 409 would leave the button looking broken; running
    // regardless would bill everyone twice.
    const warning = await screen.findByText(/already gone out today/i);
    expect(warning).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /generate anyway/i }));

    await waitFor(() => expect(bodies).toHaveLength(2));
    expect(bodies[0].allowDuplicate).toBeUndefined();
    expect(bodies[1]).toMatchObject({ confirm: true, allowDuplicate: true });
  });

  it('will not raise an add-on run when the month has no charges', async () => {
    const user = userEvent.setup();
    server.use(...handlers({ charges: { flats: 26, count: 0, items: [] } }));
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^add$/i }));

    // Nothing to bill: sp_new_maintenance would still create a run, so the
    // action is closed off rather than left to fail server-side.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByRole('button', { name: /generate bill/i })).toBeDisabled();
    expect(within(dialog).getByText(/no expense for this month/i)).toBeInTheDocument();
  });

  it('opens the per-flat detail behind a run', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  Unit: 'Bird Wing 1 202',
                  owner_name: 'Vihan Raut',
                  flat_no: '202',
                  w_name: 'Bird Wing 1',
                  sq_ft: 2500,
                  society_name: 'Gokuldham CHS',
                  registration_no: 'REG-1234',
                  address1: 'Sagreshwar Beach Road',
                  col1_name: 'sinking',
                  col1_amount: 115.38,
                  tax_interest_amt: 0,
                  total_amount: 6518.16,
                  amt_forward: 0,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                  due: 0,
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // The legacy View opened a printable bill per flat, not a grid: society
    // header, the flat's particulars, charge lines, then the totals.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText('MAINTENANCE BILL')).toBeInTheDocument();
    expect(within(dialog).getByText('Gokuldham CHS')).toBeInTheDocument();
    expect(within(dialog).getByText(/Owner Name: Vihan Raut/)).toBeInTheDocument();
    expect(within(dialog).getByText(/Flat No: 202/)).toBeInTheDocument();
    expect(within(dialog).getByText(/Area: 2500 sq\.ft/)).toBeInTheDocument();
    // Charge lines are pivoted per society, so they come from the row.
    expect(within(dialog).getByText('sinking')).toBeInTheDocument();
  });

  it('lays every bill out for print, not just the visible ones', async () => {
    const user = userEvent.setup();
    const many = Array.from({ length: 8 }, (_, i) => ({
      flat_id: i + 1,
      bill_no: 400 + i,
      owner_name: `Owner ${i + 1}`,
      flat_no: String(101 + i),
      society_name: 'Gokuldham CHS',
      col1_name: 'sinking',
      col1_amount: 100,
      total_amount: 100,
      amt_forward: 0,
      gen_date: '2025-11-01',
      due_date: '2025-11-15',
    }));
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: many,
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // The dialog scrolls, so printing gave only the slice on screen — a run
    // of eight flats came out as two. Every sheet has to be in the document
    // for the print rules to lay them all down the page.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getAllByText('MAINTENANCE BILL')).toHaveLength(8);
    expect(within(dialog).getByText(/Owner Name: Owner 8/)).toBeInTheDocument();
  });

  it('offers Print and Download on the bill sheets', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Vihan Raut',
                  flat_no: '202',
                  society_name: 'Gokuldham CHS',
                  col1_name: 'sinking',
                  col1_amount: 100,
                  total_amount: 100,
                  amt_forward: 0,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByRole('button', { name: /^print$/i })).toBeInTheDocument();
    expect(within(dialog).getByRole('button', { name: /^download$/i })).toBeInTheDocument();
  });

  it('carries dues forward into the grand total, and spells it out', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Vihan Raut',
                  flat_no: '202',
                  society_name: 'Gokuldham CHS',
                  col1_name: 'sinking',
                  col1_amount: 1500,
                  total_amount: 1500,
                  amt_forward: 250,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // 1,500 charged plus 250 already owed. The words name the grand total, not
    // the month's charges: 1,750 is what the resident owes, and spelling it out
    // is what stops the figure being altered. Label and figure sit in separate
    // cells so the amounts line up in a column.
    const dialog = await screen.findByRole('dialog');
    const grandTotalRow = within(dialog).getByText('Grand Total:').closest('tr');
    expect(within(grandTotalRow).getByText('₹ 1,750.00')).toBeInTheDocument();
    expect(
      within(dialog).getByText('One Thousand Seven Hundred Fifty Rupees Only'),
    ).toBeInTheDocument();
  });

  it('does not count arrears twice on an add-on run', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [
                { nameKey: 'col1_name', amountKey: 'col1_amount' },
                { nameKey: 'col2_name', amountKey: 'col2_amount' },
              ],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Ghanashyam GAwas',
                  flat_no: '102',
                  society_name: 'Gokuldham',
                  col1_name: 'parking',
                  col1_amount: 76.92,
                  col2_name: 'water',
                  col2_amount: 769.23,
                  // sp_new_maintenance folds arrears into total_amount;
                  // due holds the run's own charges.
                  due: 846.15,
                  total_amount: 7955.15,
                  amt_forward: 7109,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // Lines add to 846.15, so that is the total — reading total_amount showed
    // 7,955.15 against them, the 7,109 of arrears already folded in and then
    // added again below.
    const dialog = await screen.findByRole('dialog');
    const totalRow = within(dialog).getByText('Total:').closest('tr');
    expect(within(totalRow).getByText('₹ 846.15')).toBeInTheDocument();

    const grandRow = within(dialog).getByText('Grand Total:').closest('tr');
    expect(within(grandRow).getByText('₹ 7,955.15')).toBeInTheDocument();
  });

  it('totals the printed lines, not what is left owing after a payment', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [
                { nameKey: 'col1_name', amountKey: 'col1_amount' },
                { nameKey: 'col2_name', amountKey: 'col2_amount' },
              ],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Ghanashyam GAwas',
                  flat_no: '102',
                  col1_name: 'gardening',
                  col1_amount: 769.23,
                  col2_name: 'sinking',
                  col2_amount: 115.38,
                  // Part-paid: sp_SettleMaintenancePayment has knocked the
                  // payment off due, leaving a remainder.
                  due: 31.49,
                  total_amount: 1765.38,
                  amt_forward: 1765.38,
                  gen_date: '2026-02-01',
                  due_date: '2026-02-16',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // due falls as receipts settle, so it cannot be the total: flat 102's
    // February bill showed 31.49 above lines adding to 884.61. The lines are
    // what was charged, so they are what the total has to say.
    const dialog = await screen.findByRole('dialog');
    const totalRow = within(dialog).getByText('Total:').closest('tr');
    expect(within(totalRow).getByText('₹ 884.61')).toBeInTheDocument();
  });

  it('lets the society set the interest charged on arrears', async () => {
    const user = userEvent.setup();
    const saved = vi.fn();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/settings/account`, () =>
            ok({
              settings: {
                rate_per_sqfeet: 5,
                two_wheeler_rate: 50,
                four_wheeler_rate: 100,
                bill_gen_date: 2,
                bill_due_period: 15,
                interest_rate: 21,
              },
            }),
          ),
          http.put(`${BASE}/settings/account`, async ({ request }) => {
            saved(await request.json());
            return ok({ settings: { interest_rate: 0 } });
          }),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /^settings$/i }));

    // gen_bill reads this rate; it was hardcoded to 21 in sp_account_setting's
    // INSERT and never written on update, so a society that had resolved on a
    // different rate had no way to apply it.
    const dialog = await screen.findByRole('dialog');
    const rate = within(dialog).getByLabelText(/interest on arrears/i);
    expect(rate).toHaveValue(21);

    await user.clear(rate);
    await user.type(rate, '0');
    await user.click(within(dialog).getByRole('button', { name: /^save$/i }));

    await waitFor(() => expect(saved).toHaveBeenCalled());
    expect(saved.mock.lastCall[0]).toMatchObject({ interestRate: '0' });
  });

  it('prints bill dates as dd-MM-yyyy, not the browser locale', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Ghanashyam GAwas',
                  flat_no: '102',
                  col1_name: 'sinking',
                  col1_amount: 1500,
                  due: 1500,
                  total_amount: 1500,
                  amt_forward: 1765.38,
                  gen_date: '2026-02-01',
                  due_date: '2026-02-16',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // toLocaleDateString() renders 1 February as "2/1/2026" under en-US, which
    // an Indian reader takes for 2 January. maintenance_search.aspx formatted
    // these {0:dd-MM-yyyy}; a demand for money cannot read differently
    // depending on who opens it.
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByText(/Bill Date: 01-02-2026/)).toBeInTheDocument();
    expect(within(dialog).getByText(/Due Date: 16-02-2026/)).toBeInTheDocument();
    expect(within(dialog).getByText(/Dues as of 01-02-2026/)).toBeInTheDocument();
  });

  it('drops the dues line only when nothing is owed', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Owes nothing',
                  flat_no: '101',
                  col1_name: 'sinking',
                  col1_amount: 1500,
                  due: 1500,
                  total_amount: 1500,
                  amt_forward: 0,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
                {
                  flat_id: 8,
                  bill_no: 490,
                  owner_name: 'Owes plenty',
                  flat_no: '102',
                  col1_name: 'sinking',
                  col1_amount: 1500,
                  due: 1500,
                  total_amount: 1500,
                  amt_forward: 15819.2,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // Repeater3_ItemDataBound hid the row at zero: "Dues as of ...: 0.00" says
    // nothing to a resident with a clean ledger. Arrears, though, are usually
    // most of what is payable and have to be on the bill.
    const dialog = await screen.findByRole('dialog');
    const dues = within(dialog).getAllByText(/dues as of/i);
    expect(dues).toHaveLength(1);
    expect(within(dialog).getByText('₹ 15,819.20')).toBeInTheDocument();
  });

  it('spells the paise out when the charge does not divide evenly', async () => {
    const user = userEvent.setup();
    server.use(
      ...handlers({
        extra: [
          http.get(`${BASE}/billing/bills/12`, () =>
            ok({
              run: RUN,
              chargeColumns: [{ nameKey: 'col1_name', amountKey: 'col1_amount' }],
              items: [
                {
                  flat_id: 7,
                  bill_no: 489,
                  owner_name: 'Vihan Raut',
                  flat_no: '202',
                  society_name: 'Gokuldham CHS',
                  col1_name: 'sinking',
                  col1_amount: 1765.38,
                  total_amount: 1765.38,
                  amt_forward: 42634.31,
                  gen_date: '2025-11-01',
                  due_date: '2025-11-15',
                },
              ],
            }),
          ),
        ],
      }),
    );
    render(<BillsPage />);

    await screen.findByText('#12');
    await user.click(screen.getByRole('button', { name: /view flats/i }));

    // Flat 102's real August bill. Shared charges divided across flats almost
    // never land on a whole rupee, so the paise clause is the common case, not
    // the exception — and the words follow the grand total, so arrears are in
    // the figure too. Spelling only the month's charges wrote "One Thousand
    // Seven Hundred Sixty Five Rupees Only" under an amount due of 44,399.69.
    const dialog = await screen.findByRole('dialog');
    const grandTotalRow = within(dialog).getByText('Grand Total:').closest('tr');
    expect(within(grandTotalRow).getByText('₹ 44,399.69')).toBeInTheDocument();
    expect(
      within(dialog).getByText(
        'Forty Four Thousand Three Hundred Ninety Nine Rupees and Sixty Nine Paise Only',
      ),
    ).toBeInTheDocument();
  });
});
