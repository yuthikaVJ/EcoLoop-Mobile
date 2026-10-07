import { render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { VerificationRequestsPage } from './VerificationRequestsPage';
import * as verifications from '../services/verifications';

vi.mock('../services/verifications', async () => {
  const actual = await vi.importActual<
    typeof import('../services/verifications')
  >('../services/verifications');

  return {
    ...actual,
    getRequests: vi.fn(),
    getSummary: vi.fn(),
    approve: vi.fn(),
    reject: vi.fn(),
  };
});

describe('VerificationRequestsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  // RT-10: Loading state
  it('displays loading state while verification requests are being loaded', () => {
    vi.mocked(verifications.getRequests).mockReturnValue(
      new Promise(() => {})
    );

    vi.mocked(verifications.getSummary).mockReturnValue(
      new Promise(() => {})
    );

    render(<VerificationRequestsPage />);

    expect(screen.getByText('Loading…')).toBeInTheDocument();
  });

  // RT-11: Successful API response
  it('displays verification requests returned by the API', async () => {
    vi.mocked(verifications.getRequests).mockResolvedValue([
      {
        id: 'req-001',
        businessName: 'Green Lanka Recycling',
        registrationNumber: 'PV12345',
        status: 'Unverified',
        logoUrl: null,
        email: 'greenlanka@example.com',
      } as verifications.VerificationRequest,
    ]);

    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 1,
      verified: 0,
      rejected: 0,
    });

    render(<VerificationRequestsPage />);

    const businessNames = await screen.findAllByText(
      'Green Lanka Recycling'
    );

    expect(businessNames).toHaveLength(2);

    expect(
      screen.getAllByText('PV12345')
    ).toHaveLength(2);

    expect(
      screen.getAllByText('Pending').length
    ).toBeGreaterThanOrEqual(2);
  });

  // RT-12: Empty API response
  it('displays an empty message when there are no pending requests', async () => {
    vi.mocked(verifications.getRequests).mockResolvedValue([]);

    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 0,
      verified: 0,
      rejected: 0,
    });

    render(<VerificationRequestsPage />);

    expect(
      await screen.findByText('No pending requests. All caught up!')
    ).toBeInTheDocument();
  });
});

// RT-13: API error handling
it('displays an error message when loading verification requests fails', async () => {
  vi.mocked(verifications.getRequests).mockRejectedValue(
    new Error('Could not load verification requests.')
  );

  vi.mocked(verifications.getSummary).mockResolvedValue({
    pending: 0,
    verified: 0,
    rejected: 0,
  });

  render(<VerificationRequestsPage />);

  expect(
    await screen.findByText('Could not load verification requests.')
  ).toBeInTheDocument();
});