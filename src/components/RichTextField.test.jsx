import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import RichTextField from './RichTextField.jsx';

/** Mirrors how GenericCrudPage drives the field — value in, HTML back out. */
function Harness({ initial = '', ...rest }) {
  const [value, setValue] = useState(initial);
  return <RichTextField label="Details" value={value} onChange={setValue} {...rest} />;
}

describe('RichTextField', () => {
  it('shows the stored HTML when opened', () => {
    render(<Harness initial="<p>Agenda for <b>Monday</b></p>" />);
    expect(screen.getByRole('textbox')).toContainHTML('<b>Monday</b>');
  });

  it('reports edits as HTML', async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    render(<RichTextField label="Details" value="" onChange={onChange} />);

    await user.click(screen.getByRole('textbox'));
    await user.keyboard('Quarterly review');

    expect(onChange).toHaveBeenCalled();
    expect(onChange.mock.lastCall[0]).toContain('Quarterly review');
  });

  it('counts the markup against the column limit and flags an overflow', () => {
    const { rerender } = render(
      <RichTextField label="Details" value="<p>hi</p>" onChange={() => {}} maxLength={300} />,
    );
    expect(screen.getByText('9/300')).toBeInTheDocument();

    // meeting_master.details is nvarchar(300); the save fails past that, so the
    // counter has to warn rather than silently truncate.
    rerender(
      <RichTextField
        label="Details"
        value={`<p>${'x'.repeat(400)}</p>`}
        onChange={() => {}}
        maxLength={300}
      />,
    );
    expect(screen.getByText('407/300')).toHaveClass('text-red-600');
  });

  it('stores typed spaces as spaces, not &nbsp; entities', async () => {
    const user = userEvent.setup();
    const onChange = vi.fn();
    render(<RichTextField label="Details" value="" onChange={onChange} />);

    const box = screen.getByRole('textbox');
    await user.click(box);
    // What a browser leaves behind for typed spaces. Six stored characters
    // each against a 300-character column, and visible as an entity wherever
    // the value is read as plain text.
    box.innerHTML = '<p>Agenda&nbsp;for&nbsp;Monday</p>';
    await user.type(box, ' ');

    const emitted = onChange.mock.lastCall[0];
    expect(emitted).not.toContain('&nbsp;');
    expect(emitted).toContain('Agenda for Monday');
  });

  it('applies a toolbar command without stealing focus from the editor', async () => {
    const user = userEvent.setup();
    render(<Harness />);
    const box = screen.getByRole('textbox');

    await user.click(box);
    await user.click(screen.getByRole('button', { name: 'Bold' }));

    expect(box).toHaveFocus();
  });
});
