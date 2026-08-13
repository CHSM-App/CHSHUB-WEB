import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ConfirmDialog, Field, Modal } from './ui.jsx';

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

  /*
   * Tab used to walk straight out of the dialog: three presses from the last
   * field and focus was on the sidebar behind the overlay, typing into a page
   * the user could not see.
   */
  it('keeps Tab inside the dialog', async () => {
    const user = userEvent.setup();
    render(
      <>
        <button type="button">behind the overlay</button>
        <Modal open title="Society" onClose={() => {}} footer={<button type="button">Save</button>}>
          <input aria-label="Name" />
        </Modal>
      </>,
    );

    const outside = screen.getByRole('button', { name: 'behind the overlay' });
    // Forward off the last control wraps to the first, rather than escaping.
    await user.tab();
    await user.tab();
    await user.tab();
    await user.tab();
    expect(document.activeElement).not.toBe(outside);

    // And backwards off the first does the same.
    await user.tab({ shift: true });
    await user.tab({ shift: true });
    await user.tab({ shift: true });
    expect(document.activeElement).not.toBe(outside);
  });

  it('starts focus on the form rather than the close button', () => {
    render(
      <Modal open title="Society" onClose={() => {}} footer={<button type="button">Save</button>}>
        <input aria-label="Name" />
      </Modal>,
    );
    expect(document.activeElement).toBe(screen.getByLabelText('Name'));
  });

  /*
   * Scrolling a dialog to its end used to hand the wheel to the list behind it,
   * so the page crept away underneath a form the user had not finished.
   */
  it('freezes the page behind it and restores the scroll on close', () => {
    const { rerender } = render(
      <Modal open title="Society" onClose={() => {}}>
        <p>content</p>
      </Modal>,
    );
    expect(document.body.style.overflow).toBe('hidden');

    rerender(
      <Modal open={false} title="Society" onClose={() => {}}>
        <p>content</p>
      </Modal>,
    );
    expect(document.body.style.overflow).not.toBe('hidden');
  });

  it('closes on a backdrop click but not on one that began inside the panel', async () => {
    const onClose = vi.fn();
    const user = userEvent.setup();
    const { rerender } = render(
      <Modal open title="Society" onClose={onClose}>
        <input aria-label="Name" />
      </Modal>,
    );

    // A press that starts on the field and releases over the backdrop — the
    // shape of selecting text and overshooting — must not discard the form.
    await user.pointer([
      { keys: '[MouseLeft>]', target: screen.getByLabelText('Name') },
      { keys: '[/MouseLeft]', target: document.querySelector('.modal-root') },
    ]);
    expect(onClose).not.toHaveBeenCalled();

    await user.click(document.querySelector('.modal-root'));
    expect(onClose).toHaveBeenCalled();

    // Opt out for the dialogs guarding something irreversible.
    onClose.mockClear();
    rerender(
      <Modal open title="Society" onClose={onClose} closeOnBackdrop={false}>
        <input aria-label="Name" />
      </Modal>,
    );
    await user.click(document.querySelector('.modal-root'));
    expect(onClose).not.toHaveBeenCalled();
  });

  it('names the dialog by its heading for screen readers', () => {
    render(
      <Modal open title="Society" description="Registration details" onClose={() => {}}>
        <p>content</p>
      </Modal>,
    );

    const dialog = screen.getByRole('dialog');
    const heading = screen.getByRole('heading', { name: 'Society' });
    // aria-labelledby beats aria-label: the heading stays the single source of
    // the name, so the two cannot drift apart.
    expect(dialog.getAttribute('aria-labelledby')).toBe(heading.id);
    expect(dialog.getAttribute('aria-describedby')).toBe(
      screen.getByText('Registration details').id,
    );
  });
});

/*
 * A Field wrapping a bare <input> is the shape most of the master screens use.
 * The input carries no name or id of its own, so without this anchor a failed
 * submit marked the box and then jumped nowhere — focusFirstInvalid had
 * nothing to find.
 */
describe('Field', () => {
  it('anchors itself by name so a failed submit can scroll to it', () => {
    render(
      <Field label="Wing name" name="name" required error="Enter the wing name">
        <input className="field-input" defaultValue="" />
      </Field>,
    );

    const anchor = document.querySelector('[data-field="name"]');
    expect(anchor).not.toBeNull();
    // The control has to be inside it: focusFirstInvalid scrolls to the anchor
    // and then focuses the input within.
    expect(anchor.querySelector('input')).not.toBeNull();
  });

  it('marks the wrapper invalid so the control itself turns red', () => {
    const { rerender } = render(
      <Field label="Wing name" name="name" required error="Enter the wing name">
        <input className="field-input" />
      </Field>,
    );
    expect(document.querySelector('[data-invalid]')).not.toBeNull();

    rerender(
      <Field label="Wing name" name="name" required>
        <input className="field-input" />
      </Field>,
    );
    expect(document.querySelector('[data-invalid]')).toBeNull();
  });

  /*
   * WCAG 3.3.1: the error has to be tied to the control that caused it, not
   * merely sitting near it. Field renders the message but not the input, so it
   * clones the wiring onto whatever child it was given.
   */
  it('ties the message to the control for screen readers', () => {
    render(
      <Field label="Wing name" name="name" required error="Enter the wing name">
        <input className="field-input" aria-label="Wing name" />
      </Field>,
    );

    const input = screen.getByLabelText('Wing name');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input.getAttribute('aria-describedby')).toBe(
      screen.getByText('Enter the wing name').id,
    );
  });
});

/**
 * The prompt before something irreversible. A misplaced click must not answer
 * it, and the weight of the action has to be readable before the sentence is.
 */
describe('ConfirmDialog', () => {
  it('focuses the confirm button so Enter answers it', () => {
    render(
      <ConfirmDialog open title="Delete record" message="This cannot be undone." onConfirm={() => {}} onCancel={() => {}} />,
    );
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'Delete' }));
  });

  it('ignores a click on the backdrop', async () => {
    const onCancel = vi.fn();
    const user = userEvent.setup();
    render(
      <ConfirmDialog open title="Delete record" message="This cannot be undone." onConfirm={() => {}} onCancel={onCancel} />,
    );

    await user.click(document.querySelector('.modal-root'));
    expect(onCancel).not.toHaveBeenCalled();
  });

  it('shows progress on the confirm button while the delete is in flight', () => {
    render(
      <ConfirmDialog open title="Delete record" message="Gone for good." onConfirm={() => {}} onCancel={() => {}} busy />,
    );

    const confirm = screen.getByRole('button', { name: /Working/ });
    expect(confirm).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeDisabled();
  });

  it('carries a danger button for a delete and a neutral one for a warning', () => {
    const { rerender } = render(
      <ConfirmDialog open title="Delete" message="m" onConfirm={() => {}} onCancel={() => {}} />,
    );
    expect(screen.getByRole('button', { name: 'Delete' }).className).toMatch(/btn-danger/);

    rerender(
      <ConfirmDialog
        open
        title="Generate"
        message="m"
        confirmLabel="Generate"
        tone="warning"
        onConfirm={() => {}}
        onCancel={() => {}}
      />,
    );
    expect(screen.getByRole('button', { name: 'Generate' }).className).not.toMatch(/btn-danger/);
  });
});
