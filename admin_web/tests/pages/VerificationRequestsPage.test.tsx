// Business verification page (src/pages/VerificationRequestsPage.tsx).
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { VerificationRequest } from '../../src/services/verifications';

vi.mock('../../src/services/verifications', () => ({
  getRequests: vi.fn(),
  getSummary: vi.fn(),
  approve: vi.fn(),
  reject: vi.fn(),
}));

import { approve, getRequests, getSummary, reject } from '../../src/services/verifications';
import { VerificationRequestsPage } from '../../src/pages/VerificationRequestsPage';

const request = (id: string, name: string): VerificationRequest => ({
  id,
  businessName: name,
  businessType: 'Recycling Company',
  registrationNumber: `REG-${id}`,
  email: `${id}@ecoloop.lk`,
  phone: '0771234567',
  address: 'Colombo',
  isVerified: false,
  status: 'Unverified',
  createdAt: '2026-10-01T10:00:00Z',
  ownerName: 'Owner',
});

beforeEach(() => {
  vi.mocked(getRequests).mockResolvedValue([request('b1', 'GreenCycle'), request('b2', 'PlastiCo')]);
  vi.mocked(getSummary).mockResolvedValue({ pending: 2, verified: 5, rejected: 1 });
});

describe('VerificationRequestsPage', () => {
  it('lists pending requests with counts and opens the oldest', async () => {
    render(<VerificationRequestsPage />);

    const list = await screen.findByRole('region', { name: 'Requests' });
    expect(await within(list).findByText('GreenCycle')).toBeInTheDocument();
    expect(within(list).getByText('PlastiCo')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Pending\s*2/ })).toHaveClass('active');
    expect(screen.getByRole('heading', { name: 'GreenCycle' })).toBeInTheDocument();
    expect(getRequests).toHaveBeenCalledWith('Unverified', '');
  });

  it('approves a business and refreshes the list', async () => {
    vi.mocked(approve).mockResolvedValue({ ...request('b1', 'GreenCycle'), status: 'Verified', isVerified: true });
    render(<VerificationRequestsPage />);

    await userEvent.click(await screen.findByRole('button', { name: 'Approve' }));

    expect(approve).toHaveBeenCalledWith('b1');
    expect(await screen.findByRole('status')).toHaveTextContent('GreenCycle is now verified.');
    expect(vi.mocked(getRequests).mock.calls.length).toBeGreaterThan(1);
  });

  it('rejects with a reason', async () => {
    vi.mocked(reject).mockResolvedValue({ ...request('b1', 'GreenCycle'), status: 'Rejected' });
    const user = userEvent.setup();
    render(<VerificationRequestsPage />);

    await user.click(await screen.findByRole('button', { name: 'Reject' }));
    const dialog = screen.getByRole('dialog');
    await user.type(within(dialog).getByPlaceholderText('Reason for rejection'), 'Wrong registration number');
    await user.click(within(dialog).getByRole('button', { name: 'Reject' }));

    expect(reject).toHaveBeenCalledWith('b1', 'Wrong registration number');
    expect(await screen.findByRole('status')).toHaveTextContent('GreenCycle was rejected.');
  });

  it('switches status tabs and searches', async () => {
    const user = userEvent.setup();
    render(<VerificationRequestsPage />);
    await screen.findByRole('heading', { name: 'GreenCycle' });

    await user.click(screen.getByRole('button', { name: /Verified\s*5/ }));
    await user.type(screen.getByPlaceholderText('Search name, reg. no. or email'), 'Green');

    await vi.waitFor(() => expect(getRequests).toHaveBeenLastCalledWith('Verified', 'Green'));
  });

  it('shows an empty state when nothing is pending', async () => {
    vi.mocked(getRequests).mockResolvedValue([]);
    render(<VerificationRequestsPage />);
    expect(await screen.findByText('No pending requests. All caught up!')).toBeInTheDocument();
  });

  it('shows backend errors', async () => {
    vi.mocked(getRequests).mockRejectedValue(new Error('Cannot reach the backend.'));
    render(<VerificationRequestsPage />);
    expect(await screen.findByText('Cannot reach the backend.')).toBeInTheDocument();
  });
});
