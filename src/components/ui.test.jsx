import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Modal } from './ui.jsx';

/**
 * A tall modal used to cut off its own header and push the footer out of reach:
 * the panel was vertically centred but free to grow past the viewport, so the
 * overflow split evenly above and below. The panel is now height-capped with a
 * scrolling body, so the header and footer stay visible however long the form.
 */
describe('Modal', () => {
  it('caps the panel height and scrolls the body, not the whole dialog', () => {
    render(
      <Modal open title="Society" onClose={() => {}} footer={<button type="button">Save</button>}>
        <p>content</p>
      </Modal>,
    );

    const panel = screen.getByRole('dialog');
    expect(panel.className).toMatch(/max-h-\[calc\(100vh-2rem\)\]/);
    expect(panel.className).toMatch(/flex-col/);

    // The body scrolls...
    const body = screen.getByText('content').parentElement;
    expect(body.className).toMatch(/overflow-y-auto/);
    expect(body.className).toMatch(/flex-1/);
    // ...and min-h-0 is what actually lets a flex child shrink enough to scroll.
    expect(body.className).toMatch(/min-h-0/);
  });

  it('keeps the header and footer from being squeezed away', () => {
    render(
      <Modal open title="Society" onClose={() => {}} footer={<button type="button">Save</button>}>
        <p>content</p>
      </Modal>,
    );

    const header = screen.getByRole('heading', { name: 'Society' }).closest('header');
    const footer = screen.getByRole('button', { name: 'Save' }).closest('footer');
    expect(header.className).toMatch(/shrink-0/);
    expect(footer.className).toMatch(/shrink-0/);
  });

  it('renders footer actions outside the scrolling body', () => {
    render(
      <Modal open title="Society" onClose={() => {}} footer={<button type="button">Save</button>}>
        <p>content</p>
      </Modal>,
    );

    const body = screen.getByText('content').parentElement;
    const save = screen.getByRole('button', { name: 'Save' });
    expect(body.contains(save)).toBe(false);
  });

  it('closes on Escape', async () => {
    const onClose = vi.fn();
    const user = userEvent.setup();
    render(
      <Modal open title="Society" onClose={onClose}>
        <p>content</p>
      </Modal>,
    );

    await user.keyboard('{Escape}');
    expect(onClose).toHaveBeenCalled();
  });

  it('renders nothing when closed', () => {
    render(
      <Modal open={false} title="Society" onClose={() => {}}>
        <p>content</p>
      </Modal>,
    );
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
