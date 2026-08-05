import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TextField } from './FormControls.jsx';

/**
 * Password inputs carry a show/hide toggle, matching the `visibility` icon the
 * legacy login and member forms had.
 */
describe('TextField password toggle', () => {
  it('starts masked and reveals on click', async () => {
    const user = userEvent.setup();
    render(<TextField label="Password" name="password" type="password" defaultValue="s3cret" />);

    const input = screen.getByLabelText(/^password/i);
    expect(input).toHaveAttribute('type', 'password');

    await user.click(screen.getByRole('button', { name: /show password/i }));
    expect(input).toHaveAttribute('type', 'text');

    await user.click(screen.getByRole('button', { name: /hide password/i }));
    expect(input).toHaveAttribute('type', 'password');
  });

  it('reports its state to assistive technology', async () => {
    const user = userEvent.setup();
    render(<TextField label="Password" name="password" type="password" />);

    const toggle = screen.getByRole('button', { name: /show password/i });
    expect(toggle).toHaveAttribute('aria-pressed', 'false');

    await user.click(toggle);
    expect(screen.getByRole('button', { name: /hide password/i })).toHaveAttribute(
      'aria-pressed',
      'true',
    );
  });

  it('does not add a toggle to ordinary fields', () => {
    render(<TextField label="Username" name="username" />);
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });

  it('keeps the toggle out of the tab order so it does not interrupt typing', () => {
    render(<TextField label="Password" name="password" type="password" />);
    expect(screen.getByRole('button', { name: /show password/i })).toHaveAttribute(
      'tabindex',
      '-1',
    );
  });
});
