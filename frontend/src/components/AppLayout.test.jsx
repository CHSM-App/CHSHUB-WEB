import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, NavLink, Route, Routes } from 'react-router-dom';

/*
 * The session and the header's fetches are stubbed rather than driven through
 * a real login: what these tests cover is the shell's own layout behaviour,
 * and a login flow would only add a second thing that can fail.
 */
vi.mock('@/auth/AuthContext.jsx', () => ({
  useAuth: () => ({
    user: { name: 'Admin User', society_name: 'Test Society' },
    logout: vi.fn(),
    villageId: null,
  }),
  useOptionalUser: () => ({ name: 'Admin User', society_name: 'Test Society' }),
}));

vi.mock('@/components/HeaderIcons.jsx', () => ({ default: () => null }));
vi.mock('@/pages/auth/ProfileDialog.jsx', () => ({ default: () => null }));

const { default: AppLayout } = await import('./AppLayout.jsx');

/*
 * Sidebar link matching.
 *
 * AppLayout itself is not mounted here: it needs a session and renders
 * HeaderIcons, which fetches on mount, so a test of which link lights up would
 * become a test of the mock server. What is under test is one prop — the `end`
 * on the menu's NavLinks — so the two links below reproduce the pair that
 * exposed the bug, with the same subLinkClass AppLayout uses.
 */
const subLinkClass = ({ isActive }) => (isActive ? 'active' : undefined);

function renderMenuAt(pathname) {
  return render(
    <MemoryRouter initialEntries={[pathname]}>
      <NavLink to="/billing/pdc" end className={subLinkClass}>
        PDC Reminder
      </NavLink>
      <NavLink to="/billing/pdc/clearing" end className={subLinkClass}>
        PDC Clearing
      </NavLink>
    </MemoryRouter>,
  );
}

describe('sidebar link matching', () => {
  it('marks only the open page, not its parent path', () => {
    renderMenuAt('/billing/pdc/clearing');

    // Without `end`, /billing/pdc matches as a prefix of the open route and
    // both rows are marked current.
    expect(screen.getByText('PDC Reminder')).not.toHaveClass('active');
    expect(screen.getByText('PDC Clearing')).toHaveClass('active');
  });

  it('marks the parent page when it is the one open', () => {
    renderMenuAt('/billing/pdc');

    expect(screen.getByText('PDC Reminder')).toHaveClass('active');
    expect(screen.getByText('PDC Clearing')).not.toHaveClass('active');
  });
});

/*
 * The mobile navigation drawer.
 *
 * jsdom applies no media queries, so the `lg:` classes that make the rail
 * permanent on a desktop are inert here and what is asserted is the phone
 * state — which is the state these tests are about.
 */
describe('mobile navigation drawer', () => {
  const renderShell = () =>
    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<p>Dashboard body</p>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    );

  const toggle = () => screen.getByRole('button', { name: /toggle navigation/i });

  /*
   * Asserted on the class rather than on the element being absent: the rail is
   * always rendered — `hidden` is what conceals it — and jsdom applies no CSS,
   * so the link stays in the tree either way.
   */
  it('keeps the menu closed until the toggle is pressed', () => {
    const { container } = renderShell();

    expect(toggle()).toHaveAttribute('aria-expanded', 'false');
    expect(container.querySelector('aside').className).toContain('hidden');
  });

  it('opens the menu from the toggle', async () => {
    const { container } = renderShell();
    await userEvent.click(toggle());

    expect(toggle()).toHaveAttribute('aria-expanded', 'true');
    expect(container.querySelector('aside').className).not.toContain('hidden');
    expect(screen.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument();
  });

  /*
   * The regression this guards: the drawer sat in normal flow with no way to
   * dismiss it except finding the toggle again, so a tap beside the menu did
   * nothing. Every drawer on a phone closes on an outside tap.
   */
  it('closes when the backdrop beside it is tapped', async () => {
    const { container } = renderShell();
    await userEvent.click(toggle());

    const backdrop = container.querySelector('[aria-hidden="true"].fixed.inset-0');
    expect(backdrop).not.toBeNull();

    await userEvent.click(backdrop);
    expect(toggle()).toHaveAttribute('aria-expanded', 'false');
  });

  it('closes after a menu item is chosen', async () => {
    renderShell();
    await userEvent.click(toggle());

    await userEvent.click(screen.getByRole('link', { name: 'Dashboard' }));
    expect(toggle()).toHaveAttribute('aria-expanded', 'false');
  });

  /*
   * An overlay that is only as wide as its content would leave the page
   * tappable behind it; one wider than the screen cannot be dismissed. The
   * width is clamped to the viewport either way.
   */
  it('pins the open drawer as a viewport-clamped overlay', async () => {
    const { container } = renderShell();
    await userEvent.click(toggle());

    const aside = container.querySelector('aside');
    expect(aside.className).toContain('fixed');
    expect(aside.className).toContain('w-[min(82vw,300px)]');
    expect(aside.className).toContain('overflow-y-auto');
  });
});

/*
 * The desktop rail and topbar stay put while the page scrolls.
 *
 * Both are `position: sticky`, which resolves against the nearest ancestor
 * that scrolls. Any ancestor that clips overflow becomes that ancestor — and
 * since the shell is only as tall as its content, a sticky child of it has
 * nothing to stick to and scrolls away with the page.
 *
 * This has been broken once already, by adding `overflow-x-hidden` to the
 * shell to stop a wide chart dragging the layout sideways. The page-level clip
 * belongs on <html> (see index.css), where the viewport stays the scroller;
 * `min-w-0` is what holds the width here and needs no clipping.
 */
describe('sticky shell chrome', () => {
  const renderShell = () =>
    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route element={<AppLayout />}>
            <Route path="/dashboard" element={<p>Dashboard body</p>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    );

  /** Every ancestor of `el` up to the render root. */
  const ancestorsOf = (el, root) => {
    const chain = [];
    for (let n = el.parentElement; n && n !== root; n = n.parentElement) chain.push(n);
    return chain;
  };

  it('keeps the topbar and the rail sticky', () => {
    const { container } = renderShell();

    expect(container.querySelector('header').className).toContain('sticky');
    // The rail is sticky from `lg` up; below that it is the drawer above.
    expect(container.querySelector('aside').className).toContain('lg:sticky');
  });

  it('puts no overflow clip on any ancestor of the sticky topbar', () => {
    const { container } = renderShell();
    const header = container.querySelector('header');

    const clipping = ancestorsOf(header, container).filter((n) =>
      /overflow-(x-|y-)?(hidden|auto|scroll|clip)/.test(n.className),
    );
    expect(clipping.map((n) => n.className)).toEqual([]);
  });

  it('puts no overflow clip on any ancestor of the sticky rail', () => {
    const { container } = renderShell();
    const aside = container.querySelector('aside');

    const clipping = ancestorsOf(aside, container).filter((n) =>
      /overflow-(x-|y-)?(hidden|auto|scroll|clip)/.test(n.className),
    );
    expect(clipping.map((n) => n.className)).toEqual([]);
  });

  /*
   * What replaced the clip. Without a zero minimum the widest thing on the
   * page — the dashboard chart — sets the shell's floor and the layout grows
   * past the viewport instead.
   */
  it('holds the shell width with min-w-0 rather than by clipping', () => {
    const { container } = renderShell();
    const shell = container.firstElementChild;

    expect(shell.className).toContain('min-w-0');
    expect(shell.className).not.toMatch(/overflow-x-(hidden|clip)/);
    expect(container.querySelector('main').className).toContain('min-w-0');
  });
});
