import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { VerificationRequestsPage } from './VerificationRequestsPage';
import * as api from '../services/verifications';
import { business } from '../test/fixtures';

vi.mock('../services/verifications', () => ({ getRequests: vi.fn(), getSummary: vi.fn(), approve: vi.fn(), reject: vi.fn() }));

describe('Verification review failures and cancellation', () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(api.getRequests).mockResolvedValue([business]);
    vi.mocked(api.getSummary).mockResolvedValue({ pending: 1, verified: 0, rejected: 0 });
  });

  it('RT-42: preserves the pending business and restores actions when approval fails', async () => {
    const user = userEvent.setup();
    vi.mocked(api.approve).mockRejectedValue(new Error('Approval service unavailable'));
    render(<VerificationRequestsPage />);
    await user.click(await screen.findByRole('button', { name: 'Approve' }));
    expect(await screen.findByText('Approval service unavailable')).toBeInTheDocument();
    expect(api.approve).toHaveBeenCalledWith(business.id);
    expect(screen.getByRole('heading', { name: business.businessName })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Approve' })).toBeEnabled();
    expect(screen.getByRole('button', { name: 'Reject' })).toBeEnabled();
    expect(screen.queryByRole('status')).not.toBeInTheDocument();
    expect(api.getRequests).toHaveBeenCalledTimes(1);
  });

  it('RT-43: preserves the rejection reason for retry when rejection fails', async () => {
    const user = userEvent.setup();
    vi.mocked(api.reject).mockRejectedValue(new Error('Rejection service unavailable'));
    render(<VerificationRequestsPage />);
    await user.click(await screen.findByRole('button', { name: 'Reject' }));
    const dialog = within(screen.getByRole('dialog'));
    await user.type(dialog.getByRole('textbox'), 'Registration does not match');
    await user.click(dialog.getByRole('button', { name: 'Reject' }));
    expect(await screen.findByText('Rejection service unavailable')).toBeInTheDocument();
    expect(api.reject).toHaveBeenCalledWith(business.id, 'Registration does not match');
    expect(dialog.getByRole('textbox')).toHaveValue('Registration does not match');
    expect(dialog.getByRole('button', { name: 'Reject' })).toBeEnabled();
    expect(screen.queryByRole('status')).not.toBeInTheDocument();
    expect(api.getRequests).toHaveBeenCalledTimes(1);
  });

  it('RT-44: cancels a review dialog without rejecting or reloading the business', async () => {
    const user = userEvent.setup();
    render(<VerificationRequestsPage />);
    await user.click(await screen.findByRole('button', { name: 'Reject' }));
    await user.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'Cancel' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(screen.getByRole('heading', { name: business.businessName })).toBeInTheDocument();
    expect(api.reject).not.toHaveBeenCalled();
    expect(api.getRequests).toHaveBeenCalledTimes(1);
  });
});
