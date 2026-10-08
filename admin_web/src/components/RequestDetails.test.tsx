import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { RequestDetails } from './RequestDetails';
import { business } from '../test/fixtures';

describe('Request details actions', () => {
  it('RT-36: offers revocation instead of approval for a verified business', async () => {
    const user = userEvent.setup();
    const onReject = vi.fn();
    const onApprove = vi.fn();
    render(<RequestDetails request={{ ...business, status: 'Verified', isVerified: true }} busy={false} onApprove={onApprove} onReject={onReject} />);
    expect(screen.queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Revoke verification' }));
    expect(onReject).toHaveBeenCalledTimes(1);
    expect(onApprove).not.toHaveBeenCalled();
  });

  it('RT-37: shows the rejection note and allows a rejected business to be approved', async () => {
    const user = userEvent.setup();
    const onApprove = vi.fn();
    render(<RequestDetails request={{ ...business, status: 'Rejected', verificationNote: 'Registration mismatch' }} busy={false} onApprove={onApprove} onReject={vi.fn()} />);
    expect(screen.getByText(/Registration mismatch/)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Reject' })).not.toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Approve' }));
    expect(onApprove).toHaveBeenCalledTimes(1);
  });

  it('RT-38: prevents both review callbacks while a save is busy', async () => {
    const user = userEvent.setup();
    const onApprove = vi.fn();
    const onReject = vi.fn();
    render(<RequestDetails request={business} busy onApprove={onApprove} onReject={onReject} />);
    const save = screen.getByRole('button', { name: /Saving/ });
    const reject = screen.getByRole('button', { name: 'Reject' });
    expect(save).toBeDisabled();
    expect(reject).toBeDisabled();
    await user.click(save);
    await user.click(reject);
    expect(onApprove).not.toHaveBeenCalled();
    expect(onReject).not.toHaveBeenCalled();
  });

  it('RT-39: displays supplied website, owner and descriptive business information', () => {
    render(<RequestDetails request={{ ...business, websiteUrl: 'https://recycling.example.test', ownerName: 'Test Owner', ownerEmail: 'owner@example.test', bio: 'Local recycling', description: 'Accepts clean cardboard' }} busy={false} onApprove={vi.fn()} onReject={vi.fn()} />);
    const website = screen.getByRole('link', { name: 'https://recycling.example.test' });
    expect(website).toHaveAttribute('href', 'https://recycling.example.test');
    expect(website).toHaveAttribute('target', '_blank');
    expect(website).toHaveAttribute('rel', 'noreferrer');
    expect(screen.getByText(/Test Owner.*owner@example.test/)).toBeInTheDocument();
    expect(screen.getByText('Local recycling')).toBeInTheDocument();
    expect(screen.getByText('Accepts clean cardboard')).toBeInTheDocument();
  });
});
