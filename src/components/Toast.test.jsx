import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import { ToastProvider, useToast } from './Toast.jsx';

/**
 * Saving used to say nothing at all — the modal closed and the list redrew,
 * which is indistinguishable from a dialog dismissed by accident. These cover
 * the confirmation actually appearing, clearing itself, and staying put when
 * it reports a failure.
 */
function Harness({ onReady }) {
  const toast = useToast();
  onReady(toast);
  return null;
}

function renderWithToast() {
  let api;
  render(
    <ToastProvider>
      <Harness onReady={(t) => { api = t; }} />
    </ToastProvider>,
  );
  return () => api;
}

describe('ToastProvider', () => {
  beforeEach(() => vi.useFakeTimers({ shouldAdvanceTime: true }));
  afterEach(() => vi.useRealTimers());

  it('shows a success confirmation and clears it on its own', async () => {
    const toast = renderWithToast();

    act(() => {
      toast().success('Building added successfully.');
    });

    expect(await screen.findByText('Building added successfully.')).toBeInTheDocument();
    // Announced politely rather than as an alert — a save is expected news.
    expect(screen.getByRole('status')).toBeInTheDocument();

    // Past the 3.2s lifetime plus the exit transition.
    act(() => {
      vi.advanceTimersByTime(3600);
    });
    expect(screen.queryByText('Building added successfully.')).not.toBeInTheDocument();
  });

  /*
   * A failure that vanished after three seconds would be worse than none: the
   * user looks up from the form and the reason is gone. Errors wait to be read.
   */
  it('keeps an error on screen until it is dismissed', async () => {
    const toast = renderWithToast();

    act(() => {
      toast().error('The change could not be saved.');
    });

    expect(await screen.findByRole('alert')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(10000);
    });
    expect(screen.getByText('The change could not be saved.')).toBeInTheDocument();
  });

  it('caps the stack so a runaway caller cannot bury the page', async () => {
    const toast = renderWithToast();

    act(() => {
      for (let i = 0; i < 8; i += 1) toast().success(`save ${i}`);
    });

    const cards = await screen.findAllByRole('status');
    expect(cards).toHaveLength(4);
    // The most recent survive; the oldest are dropped.
    expect(screen.getByText('save 7')).toBeInTheDocument();
    expect(screen.queryByText('save 0')).not.toBeInTheDocument();
  });

  /*
   * Pages render standalone in unit tests, with no provider above them. The
   * hook has to degrade to no-ops there rather than throwing, or every screen
   * test would need a wrapper it does not otherwise care about.
   */
  it('is a no-op outside a provider', () => {
    let api;
    render(<Harness onReady={(t) => { api = t; }} />);
    expect(() => api.success('nothing to host this')).not.toThrow();
  });
});
