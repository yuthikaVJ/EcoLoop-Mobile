// Verification request details (src/components/RequestDetails.tsx).
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { RequestDetails } from '../../src/components/RequestDetails';
import type { VerificationRequest } from '../../src/services/verifications';

const base: VerificationRequest = {
  id: 'b1',
  businessName: 'GreenCycle',
  businessType: 'Recycling Company',
  registrationNumber: 'PV-12345',
  email: 'green@ecoloop.lk',
  phone: '0771234567',
  address: 'Colombo',
  websiteUrl: 'https://greencycle.lk',
  logoUrl: '/uploads/business_profiles/b1/logo.png',
  isVerified: false,
  status: 'Unverified',
  createdAt: '2026-10-01T10:00:00Z',
  ownerName: 'Haritha',
  ownerEmail: 'haritha@example.com',
};

function setup(overrides: Partial<VerificationRequest> = {}) {
  const onApprove = vi.fn();
  const onReject = vi.fn();
  render(<RequestDetails request={{ ...base, ...overrides }} busy={false} onApprove={onApprove} onReject={onReject} />);
  return { onApprove, onReject, user: userEvent.setup() };
}

describe('RequestDetails', () => {
  it('shows what an admin checks against the eROC register', () => {
    setup();
    expect(screen.getByRole('heading', { name: 'GreenCycle' })).toBeInTheDocument();
    expect(screen.getByText('PV-12345')).toBeInTheDocument();
    expect(screen.getByText('Haritha · haritha@example.com')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'https://greencycle.lk' })).toHaveAttribute('target', '_blank');
  });

  it('loads the logo from the backend server', () => {
    const { container } = render(
      <RequestDetails request={base} busy={false} onApprove={() => {}} onReject={() => {}} />,
    );
    expect(container.querySelector('.logo img')).toHaveAttribute(
      'src', 'http://api.test/uploads/business_profiles/b1/logo.png');
  });

  it('a pending request can be approved or rejected', async () => {
    const { user, onApprove, onReject } = setup();
    await user.click(screen.getByRole('button', { name: 'Approve' }));
    await user.click(screen.getByRole('button', { name: 'Reject' }));
    expect(onApprove).toHaveBeenCalledOnce();
    expect(onReject).toHaveBeenCalledOnce();
  });

  it('a verified business can only have its verification revoked', () => {
    setup({ status: 'Verified', isVerified: true });
    expect(screen.queryByRole('button', { name: 'Approve' })).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Revoke verification' })).toBeInTheDocument();
  });

  it('a rejected business shows the reason and can still be approved', () => {
    setup({ status: 'Rejected', verificationNote: 'Registration number does not match.' });
    expect(screen.getByText('Registration number does not match.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Approve' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Reject' })).not.toBeInTheDocument();
  });
});
