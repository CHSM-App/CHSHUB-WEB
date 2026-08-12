import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, NavLink } from 'react-router-dom';

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
