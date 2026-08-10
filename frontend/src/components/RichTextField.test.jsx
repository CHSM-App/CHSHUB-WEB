import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import RichTextField from './RichTextField.jsx';

const post = vi.fn();
vi.mock('@/api/client', () => ({ api: { post: (...args) => post(...args) } }));

beforeEach(() => {
  post.mockReset();
});

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

  // The last pair on the legacy TinyMCE toolbar: `... | link image`.
  describe('link and image', () => {
    it('passes the entered URL to the command', async () => {
      const user = userEvent.setup();
      const execCommand = vi.fn();
      // jsdom leaves execCommand undefined, so it is assigned rather than spied on.
      document.execCommand = execCommand;
      vi.spyOn(window, 'prompt').mockReturnValue('https://example.com/terms');

      render(<Harness />);
      await user.click(screen.getByRole('button', { name: 'Insert link' }));

      expect(execCommand).toHaveBeenCalledWith('createLink', false, 'https://example.com/terms');
      vi.restoreAllMocks();
      delete document.execCommand;
    });

    it('adds a scheme to a bare host', async () => {
      const user = userEvent.setup();
      const execCommand = vi.fn();
      // jsdom leaves execCommand undefined, so it is assigned rather than spied on.
      document.execCommand = execCommand;
      vi.spyOn(window, 'prompt').mockReturnValue('example.com/terms');

      render(<Harness />);
      await user.click(screen.getByRole('button', { name: 'Insert link' }));

      expect(execCommand).toHaveBeenCalledWith('createLink', false, 'https://example.com/terms');
      vi.restoreAllMocks();
      delete document.execCommand;
    });

    it('uploads a picked image and inserts it by its served URL', async () => {
      const execCommand = vi.fn();
      document.execCommand = execCommand;
      post.mockResolvedValue({
        items: [{ url: '/api/web/uploads/file/society-documents/17-9.png' }],
      });

      render(<Harness />);
      const file = new File(['x'], 'logo.png', { type: 'image/png' });
      // The hidden input the toolbar button clicks; fireEvent, because
      // userEvent.upload needs a visible control.
      const input = document.querySelector('input[type="file"]');
      fireEvent.change(input, { target: { files: [file] } });

      await waitFor(() => expect(post).toHaveBeenCalled());
      expect(post.mock.lastCall[0]).toBe('/uploads/society-documents');
      await waitFor(() =>
        expect(execCommand).toHaveBeenCalledWith(
          'insertImage',
          false,
          '/api/web/uploads/file/society-documents/17-9.png',
        ),
      );
      delete document.execCommand;
    });

    it('reports a failed upload instead of inserting anything', async () => {
      const execCommand = vi.fn();
      document.execCommand = execCommand;
      post.mockRejectedValue(new Error('File too large'));

      render(<Harness />);
      const file = new File(['x'], 'huge.png', { type: 'image/png' });
      fireEvent.change(document.querySelector('input[type="file"]'), {
        target: { files: [file] },
      });

      expect(await screen.findByRole('alert')).toHaveTextContent('File too large');
      expect(execCommand).not.toHaveBeenCalled();
      delete document.execCommand;
    });

    // The value is stored as markup and rendered back, so a javascript: URL
    // would execute on click.
    it('rejects a javascript: URL', async () => {
      const user = userEvent.setup();
      const execCommand = vi.fn();
      // jsdom leaves execCommand undefined, so it is assigned rather than spied on.
      document.execCommand = execCommand;
      // eslint-disable-next-line no-script-url
      vi.spyOn(window, 'prompt').mockReturnValue('javascript:alert(1)');

      render(<Harness />);
      await user.click(screen.getByRole('button', { name: 'Insert link' }));

      expect(execCommand).not.toHaveBeenCalled();
      vi.restoreAllMocks();
      delete document.execCommand;
    });

    it('does nothing when the prompt is cancelled', async () => {
      const user = userEvent.setup();
      const execCommand = vi.fn();
      // jsdom leaves execCommand undefined, so it is assigned rather than spied on.
      document.execCommand = execCommand;
      vi.spyOn(window, 'prompt').mockReturnValue(null);

      render(<Harness />);
      await user.click(screen.getByRole('button', { name: 'Insert link' }));

      expect(execCommand).not.toHaveBeenCalled();
      vi.restoreAllMocks();
      delete document.execCommand;
    });
  });
});
