// Reject dialog (src/components/RejectDialog.tsx): a rejection always has a reason.
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { RejectDialog } from '../../src/components/RejectDialog';

function setup(busy = false) {
  const onConfirm = vi.fn();
  const onCancel = vi.fn();
  render(<RejectDialog businessName="GreenCycle" busy={busy} onCancel={onCancel} onConfirm={onConfirm} />);
  return { onConfirm, onCancel, user: userEvent.setup() };
}

describe('RejectDialog', () => {
  it('names the business being rejected', () => {
    setup();
    expect(screen.getByRole('dialog', { name: 'Reject GreenCycle?' })).toBeInTheDocument();
  });

  it('cannot reject without a reason of at least 3 characters', async () => {
    const { user } = setup();
    const reject = screen.getByRole('button', { name: 'Reject' });

    expect(reject).toBeDisabled();
    await user.type(screen.getByPlaceholderText('Reason for rejection'), 'no');
    expect(reject).toBeDisabled();
    await user.type(screen.getByPlaceholderText('Reason for rejection'), 'pe');
    expect(reject).toBeEnabled();
  });

  it('sends the trimmed reason', async () => {
    const { user, onConfirm } = setup();
    await user.type(screen.getByPlaceholderText('Reason for rejection'), '  Wrong registration number  ');
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(onConfirm).toHaveBeenCalledWith('Wrong registration number');
  });

  it('quick reasons fill in the text', async () => {
    const { user, onConfirm } = setup();
    await user.click(screen.getByRole('button', { name: 'Contact details could not be confirmed.' }));
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(onConfirm).toHaveBeenCalledWith('Contact details could not be confirmed.');
  });

  it('can be cancelled', async () => {
    const { user, onCancel } = setup();
    await user.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onCancel).toHaveBeenCalled();
  });

  it('disables the buttons while saving', () => {
    setup(true);
    expect(screen.getByRole('button', { name: 'Rejecting…' })).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeDisabled();
  });
});
