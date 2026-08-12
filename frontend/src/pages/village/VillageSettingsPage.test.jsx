import { describe, expect, it, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { server, ok } from '@/test/server';
import { writeSession } from '@/api/client';
import VillageSettingsPage from './VillageSettingsPage.jsx';

const BASE = '/api/web';

const SETTINGS = {
  village_setting_id: 1,
  village_id: 'V10004',
  auto_bill_generation: false,
  bill_gen_day: 1,
  property_tax_month: 4,
  due_days: 30,
  interest_rate: 0,
  interest_after_days: 30,
};

function handlers({ settings = SETTINGS, onSave } = {}) {
  return [
    http.get(`${BASE}/village/settings`, () => ok({ settings })),
    http.put(`${BASE}/village/settings`, async ({ request }) => {
      onSave?.(await request.json());
      return ok({ saved: true });
    }),
  ];
}

beforeEach(() => {
  writeSession({ accessToken: 'a', refreshToken: 'r', user: { village_id: 'V10004' } });
});

describe('VillageSettingsPage', () => {
  it('shows the stored settings', async () => {
    server.use(...handlers());
    render(<VillageSettingsPage />);

    expect(await screen.findByLabelText(/day of the month/i)).toHaveValue(1);
    // Property tax is yearly, and April is the financial year a gram
    // panchayat works to.
    expect(screen.getByLabelText(/property tax month/i)).toHaveValue('4');
    expect(screen.getByLabelText(/days to pay/i)).toHaveValue(30);
  });

  it('saves what was changed', async () => {
    const user = userEvent.setup();
    const onSave = vi.fn();
    server.use(...handlers({ onSave }));
    render(<VillageSettingsPage />);

    const dueDays = await screen.findByLabelText(/days to pay/i);
    await user.clear(dueDays);
    await user.type(dueDays, '45');
    await user.click(screen.getByRole('button', { name: /save settings/i }));

    await waitFor(() => expect(onSave).toHaveBeenCalled());
    expect(onSave.mock.calls[0][0]).toMatchObject({ dueDays: '45' });
  });

  /*
   * The switch governs a daily run in the API. Saying when it happens is what
   * stops someone raising the same month by hand as well — and the page has to
   * say it only when the switch is on, or it reads as a promise about a
   * setting that is off.
   */
  it('says when automatic generation runs, once it is switched on', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageSettingsPage />);

    const toggle = await screen.findByRole('checkbox', { name: /generate bills automatically/i });
    expect(screen.queryByText(/raised automatically/i)).not.toBeInTheDocument();

    await user.click(toggle);
    expect(await screen.findByText(/raised overnight/i)).toBeInTheDocument();
  });

  it('warns that a stored interest rate is not charged yet', async () => {
    const user = userEvent.setup();
    server.use(...handlers());
    render(<VillageSettingsPage />);

    const rate = await screen.findByLabelText(/interest rate/i);
    await user.clear(rate);
    await user.type(rate, '2');

    expect(await screen.findByText(/not applied to bills yet/i)).toBeInTheDocument();
  });

  it('re-reads after saving, so a clamped value is not left on screen', async () => {
    const user = userEvent.setup();
    let saved = false;
    server.use(
      http.get(`${BASE}/village/settings`, () =>
        // The column is capped at 28; the SP stores 28 whatever was sent.
        ok({ settings: { ...SETTINGS, bill_gen_day: saved ? 28 : 1 } }),
      ),
      http.put(`${BASE}/village/settings`, () => {
        saved = true;
        return ok({ saved: true });
      }),
    );
    render(<VillageSettingsPage />);

    const day = await screen.findByLabelText(/day of the month/i);
    await user.clear(day);
    await user.type(day, '31');
    await user.click(screen.getByRole('button', { name: /save settings/i }));

    await waitFor(() => expect(screen.getByLabelText(/day of the month/i)).toHaveValue(28));
  });
});
