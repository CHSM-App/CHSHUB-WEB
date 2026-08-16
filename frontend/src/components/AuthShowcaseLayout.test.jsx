import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

import AuthShowcaseLayout from './AuthShowcaseLayout.jsx';

/*
 * The mark above the login box.
 *
 * The signed-out screens used to lead with BuildingMark — a red buildings glyph
 * that appears nowhere else in the product — so the first mark you saw was one
 * the app never wears, and the real CHS HUB tile only after signing in. The
 * badge is the tile now; the buildings glyph stays on the showcase panel beside
 * it, where it sits under the SOCIETY / Management wordmark.
 *
 * jsdom applies no stylesheet, so what is asserted here is the markup that the
 * CSS hangs off — the class the rules target and which element is in the slot —
 * rather than the painted result.
 */
describe('the mark above the login form', () => {
  const renderLayout = () =>
    render(
      <MemoryRouter>
        <AuthShowcaseLayout heading="Welcome" tagline="back" title="Sign in">
          <p>Form body</p>
        </AuthShowcaseLayout>
      </MemoryRouter>,
    );

  it('puts the CHS HUB tile in the badge slot', () => {
    const { container } = renderLayout();
    const badge = container.querySelector('.auth-showcase-card__badge');

    expect(badge).not.toBeNull();
    const mark = badge.querySelector('.chs-mark');
    expect(mark).not.toBeNull();
    expect(mark.textContent).toBe('CHSHUB');
  });

  /*
   * The tile has its own square silhouette and its own shadow, so a disc behind
   * it read as a second, mismatched object. The badge is a bare centring slot
   * now — and because the mark must be free to size itself from the stylesheet's
   * clamp, it must NOT carry an inline --chs-mark-size, which would outrank it.
   */
  it('leaves the tile free to be sized by the stylesheet', () => {
    const { container } = renderLayout();
    const mark = container.querySelector('.auth-showcase-card__badge > .chs-mark');

    expect(mark.style.getPropertyValue('--chs-mark-size')).toBe('');
  });

  /*
   * The panel's lockup carries the same tile beside SOCIETY / Management, so
   * the page shows one logo throughout rather than the buildings glyph here and
   * the real mark at the form.
   */
  it('uses the same tile in the showcase wordmark', () => {
    const { container } = renderLayout();
    const mark = container.querySelector('.auth-wordmark > .chs-mark');

    expect(mark).not.toBeNull();
    expect(mark.textContent).toBe('CHSHUB');
    expect(screen.getByText('SOCIETY')).toBeInTheDocument();
  });

  /*
   * Both marks are decorative — the words beside and below them carry the
   * meaning — so neither should be announced. Two "CHS HUB" readings before the
   * form is reached is noise, not information.
   */
  it('hides both marks from screen readers', () => {
    const { container } = renderLayout();

    for (const mark of container.querySelectorAll('.chs-mark')) {
      expect(mark).toHaveAttribute('aria-hidden', 'true');
    }
  });
});
