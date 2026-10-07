import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { RejectDialog } from './RejectDialog';

describe('RejectDialog', () => {

  it('displays the business name in the rejection dialog', () => {
    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={false}
        onCancel={vi.fn()}
        onConfirm={vi.fn()}
      />
    );

    expect(
      screen.getByText('Reject Green Lanka?')
    ).toBeInTheDocument();
  });

  it('disables Reject when the reason is empty or too short', async () => {
    const user = userEvent.setup();

    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={false}
        onCancel={vi.fn()}
        onConfirm={vi.fn()}
      />
    );

    const rejectButton = screen.getByRole('button', { name: 'Reject' });
    const textarea = screen.getByPlaceholderText('Reason for rejection');

    expect(rejectButton).toBeDisabled();

    await user.type(textarea, 'ab');

    expect(rejectButton).toBeDisabled();
  });

  it('enables Reject when a valid reason is entered', async () => {
    const user = userEvent.setup();

    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={false}
        onCancel={vi.fn()}
        onConfirm={vi.fn()}
      />
    );

    const textarea = screen.getByPlaceholderText('Reason for rejection');

    await user.type(textarea, 'Invalid registration details');

    expect(
      screen.getByRole('button', { name: 'Reject' })
    ).toBeEnabled();
  });

  it('fills the textarea when a quick reason is selected', async () => {
    const user = userEvent.setup();

    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={false}
        onCancel={vi.fn()}
        onConfirm={vi.fn()}
      />
    );

    const quickReason =
      'Business name does not match the registration.';

    await user.click(
      screen.getByRole('button', { name: quickReason })
    );

    expect(
      screen.getByPlaceholderText('Reason for rejection')
    ).toHaveValue(quickReason);
  });

  it('sends the trimmed reason when Reject is clicked', async () => {
    const user = userEvent.setup();
    const onConfirm = vi.fn();

    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={false}
        onCancel={vi.fn()}
        onConfirm={onConfirm}
      />
    );

    const textarea = screen.getByPlaceholderText('Reason for rejection');

    await user.type(textarea, '  Invalid registration details  ');

    await user.click(
      screen.getByRole('button', { name: 'Reject' })
    );

    expect(onConfirm).toHaveBeenCalledWith(
      'Invalid registration details'
    );
  });

  it('disables actions and displays Rejecting when busy', () => {
    render(
      <RejectDialog
        businessName="Green Lanka"
        busy={true}
        onCancel={vi.fn()}
        onConfirm={vi.fn()}
      />
    );

    expect(
      screen.getByRole('button', { name: 'Cancel' })
    ).toBeDisabled();

    expect(
      screen.getByRole('button', { name: 'Rejecting…' })
    ).toBeDisabled();
  });

});