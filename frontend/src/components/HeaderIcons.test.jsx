import { describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';

/*
 * The alerts dropdown, driven off a stubbed API rather than the mock server:
 * what is under test is where the panel is placed and how a row behaves when
 * tapped, and the two endpoints behind it are one line each.
 */
const notifications = vi.fn();
const markNotificationSeen = vi.fn();
const messagesCount = vi.fn();

vi.mock('@/api/modules', () => ({
  community: {
    notifications: () => notifications(),
    markNotificationSeen: (id) => markNotificationSeen(id),
    messagesCount: () => messagesCount(),
  },
}));

vi.mock('@/auth/AuthContext.jsx', () => ({ useAuth: () => ({ villageId: null }) }));

const navigate = vi.fn();
vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useNavigate: () => navigate,
}));

const { default: HeaderIcons } = await import('./HeaderIcons.jsx');

const ALERT = {
  notify_status_id: 7,
  title: 'Helpdesk',
  body: 'Ticket #4821 was updated',
  timestamp: '5 minutes ago',
};

function renderIcons(items = [ALERT]) {
  notifications.mockResolvedValue({ items });
  messagesCount.mockResolvedValue({ unread: 0 });
  markNotificationSeen.mockResolvedValue({});
  return render(
    <MemoryRouter>
      <HeaderIcons />
    </MemoryRouter>,
  );
}

const bell = () => screen.getByRole('button', { name: /notifications/i });

describe('notifications dropdown', () => {
  it('opens the alerts panel from the bell', async () => {
    renderIcons();
    await waitFor(() => expect(notifications).toHaveBeenCalled());

    await userEvent.click(bell());

    expect(bell()).toHaveAttribute('aria-expanded', 'true');
    expect(screen.getByRole('menu')).toBeInTheDocument();
    expect(screen.getByText('Ticket #4821 was updated')).toBeInTheDocument();
  });

  /*
   * The regression this guards.
   *
   * The panel used to be `absolute right-0` at every width, anchored to the
   * bell — which sits inset from the right of the screen by the messages icon
   * and the profile control. Measured leftward from there, a 328px panel began
   * off the left edge of a 360px phone and its left side was unreachable.
   *
   * Pinned to the viewport with both insets set, the panel no longer depends
   * on where in the row the button happens to sit.
   */
  it('pins the panel to the viewport on a phone, not to the bell', async () => {
    renderIcons();
    await waitFor(() => expect(notifications).toHaveBeenCalled());
    await userEvent.click(bell());

    const panel = screen.getByRole('menu');
    expect(panel.className).toContain('fixed');
    expect(panel.className).toContain('inset-x-3');
    // From `sm` up it goes back to hanging off the bell.
    expect(panel.className).toContain('sm:absolute');
    expect(panel.className).toContain('sm:right-0');
  });

  it('shows an empty message when there is nothing to report', async () => {
    renderIcons([]);
    await waitFor(() => expect(notifications).toHaveBeenCalled());
    await userEvent.click(bell());

    expect(screen.getByText('No Notification Found')).toBeInTheDocument();
  });

  it('marks an alert seen and opens the helpdesk when tapped', async () => {
    renderIcons();
    await waitFor(() => expect(notifications).toHaveBeenCalled());
    await userEvent.click(bell());

    await userEvent.click(screen.getByRole('menuitem'));

    expect(markNotificationSeen).toHaveBeenCalledWith(7);
    expect(navigate).toHaveBeenCalledWith('/community/helpdesk');
    // Tapping a row closes the panel behind it.
    expect(bell()).toHaveAttribute('aria-expanded', 'false');
  });

  /*
   * Marking the row read is best-effort — it reappears on the next refresh —
   * so a failing PUT must still open the ticket rather than dead-ending the tap.
   */
  it('still opens the helpdesk when marking the alert seen fails', async () => {
    renderIcons();
    await waitFor(() => expect(notifications).toHaveBeenCalled());
    markNotificationSeen.mockRejectedValue(new Error('offline'));

    await userEvent.click(bell());
    await userEvent.click(screen.getByRole('menuitem'));

    await waitFor(() => expect(navigate).toHaveBeenCalledWith('/community/helpdesk'));
  });

  it('closes when the area beside the panel is tapped', async () => {
    const { container } = renderIcons();
    await waitFor(() => expect(notifications).toHaveBeenCalled());
    await userEvent.click(bell());

    const backdrop = container.querySelector('.fixed.inset-0[aria-hidden="true"]');
    expect(backdrop).not.toBeNull();

    await userEvent.click(backdrop);
    expect(bell()).toHaveAttribute('aria-expanded', 'false');
  });
});
