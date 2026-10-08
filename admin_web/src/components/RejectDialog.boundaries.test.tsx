import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { RejectDialog } from './RejectDialog';

describe('Rejection input boundaries', () => {
  it('RT-45: rejects whitespace-only input and accepts exactly three trimmed characters', async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();
    render(<RejectDialog businessName="Test Business" busy={false} onCancel={vi.fn()} onConfirm={onConfirm} />);
    const input = screen.getByRole('textbox');
    const reject = screen.getByRole('button', { name: 'Reject' });
    await user.type(input, '   ');
    expect(reject).toBeDisabled();
    await user.click(reject);
    expect(onConfirm).not.toHaveBeenCalled();
    await user.type(input, 'abc  ');
    expect(reject).toBeEnabled();
    await user.click(reject);
    expect(onConfirm).toHaveBeenCalledExactlyOnceWith('abc');
  });

  it('RT-46: limits a pasted rejection reason to 500 characters', async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();
    render(<RejectDialog businessName="Test Business" busy={false} onCancel={vi.fn()} onConfirm={onConfirm} />);
    const input = screen.getByRole('textbox');
    await user.click(input);
    await user.paste('x'.repeat(501));
    expect(input).toHaveValue('x'.repeat(500));
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(onConfirm).toHaveBeenCalledExactlyOnceWith('x'.repeat(500));
  });
});
