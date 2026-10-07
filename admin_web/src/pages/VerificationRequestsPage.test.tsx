import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';

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

  // RT-10: Initial loading state
  it('displays loading state before verification requests are loaded', async () => {
    vi.mocked(verifications.getRequests).mockResolvedValue([]);

    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 0,
      verified: 0,
      rejected: 0,
    });

    render(<VerificationRequestsPage />);

    expect(
      screen.getByText('Loading…')
    ).toBeInTheDocument();

    expect(
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();
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
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();
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
      await screen.findByText(
        'Could not load verification requests.'
      )
    ).toBeInTheDocument();
  });

  // RT-14: Status filter interaction
  it('loads verified requests when the Verified tab is clicked', async () => {
    const user = userEvent.setup();

    vi.mocked(verifications.getRequests).mockResolvedValue([]);

    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 0,
      verified: 2,
      rejected: 0,
    });

    render(<VerificationRequestsPage />);

    // Wait for initial Unverified request.
    expect(
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();

    expect(
      verifications.getRequests
    ).toHaveBeenCalledWith(
      'Unverified',
      ''
    );

    // Click Verified filter.
    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 0,
      verified: 3,
      rejected: 0,
    });

    await user.click(
      screen.getByRole('button', { name: /Verified/ })
    );

    // Wait for the debounced request and its updated summary to render.
    await waitFor(
      () => {
        expect(
          verifications.getRequests
        ).toHaveBeenCalledWith(
          'Verified',
          ''
        );
        expect(
          screen.getByRole('button', { name: /^Verified/ })
        ).toHaveTextContent('Verified3');
      },
      {
        timeout: 1500,
      }
    );

    expect(
      await screen.findByText('Nothing here.')
    ).toBeInTheDocument();
  });

  // RT-15: Search functionality
  it('searches verification requests when the user enters a search term', async () => {
    const user = userEvent.setup();

    vi.mocked(verifications.getRequests).mockResolvedValue([]);

    vi.mocked(verifications.getSummary).mockResolvedValue({
      pending: 0,
      verified: 0,
      rejected: 0,
    });

    render(<VerificationRequestsPage />);

    expect(
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();

    const searchBox = screen.getByPlaceholderText(
      'Search name, reg. no. or email'
    );

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

    await user.type(
      searchBox,
      'Green Lanka'
    );

    expect(searchBox).toHaveValue('Green Lanka');

    // Wait for the debounced search request and its results to render.
    await waitFor(
      () => {
        expect(
          verifications.getRequests
        ).toHaveBeenCalledWith(
          'Unverified',
          'Green Lanka'
        );
        expect(
          screen.getAllByText('Green Lanka Recycling')
        ).toHaveLength(2);
      },
      {
        timeout: 1500,
      }
    );
  });

  // RT-16: Approve business workflow
  it('approves a pending business when the Approve button is clicked', async () => {
    const user = userEvent.setup();

    const pendingBusiness = {
      id: 'req-001',
      businessName: 'Green Lanka Recycling',
      businessType: 'Recycling',
      registrationNumber: 'PV12345',
      email: 'greenlanka@example.com',
      phone: '0771234567',
      address: 'Colombo, Sri Lanka',
      isVerified: false,
      status: 'Unverified',
      createdAt: '2026-10-01T10:00:00Z',
      logoUrl: null,
      coverPhotoUrl: null,
    } as verifications.VerificationRequest;

    const approvedBusiness = {
      ...pendingBusiness,
      isVerified: true,
      status: 'Verified',
      verifiedAt: '2026-10-07T10:00:00Z',
    } as verifications.VerificationRequest;

    vi.mocked(verifications.getRequests)
      .mockResolvedValueOnce([pendingBusiness])
      .mockResolvedValueOnce([]);

    vi.mocked(verifications.getSummary)
      .mockResolvedValueOnce({
        pending: 1,
        verified: 0,
        rejected: 0,
      })
      .mockResolvedValueOnce({
        pending: 0,
        verified: 1,
        rejected: 0,
      });

    vi.mocked(verifications.approve).mockResolvedValue(
      approvedBusiness
    );

    render(<VerificationRequestsPage />);

    await screen.findAllByText(
      'Green Lanka Recycling'
    );

    await user.click(
      screen.getByRole('button', { name: 'Approve' })
    );

    await waitFor(() => {
      expect(
        verifications.approve
      ).toHaveBeenCalledWith('req-001');
    });

    expect(
      await screen.findByText(
        'Green Lanka Recycling is now verified.'
      )
    ).toBeInTheDocument();
  });

  // RT-17: Reject business workflow
  it('rejects a pending business with a rejection reason', async () => {
    const user = userEvent.setup();

    const pendingBusiness = {
      id: 'req-001',
      businessName: 'Green Lanka Recycling',
      businessType: 'Recycling',
      registrationNumber: 'PV12345',
      email: 'greenlanka@example.com',
      phone: '0771234567',
      address: 'Colombo, Sri Lanka',
      isVerified: false,
      status: 'Unverified',
      createdAt: '2026-10-01T10:00:00Z',
      logoUrl: null,
      coverPhotoUrl: null,
    } as verifications.VerificationRequest;

    const rejectedBusiness = {
      ...pendingBusiness,
      status: 'Rejected',
      verificationNote:
        'Registration number does not match.',
    } as verifications.VerificationRequest;

    vi.mocked(verifications.getRequests)
      .mockResolvedValueOnce([pendingBusiness])
      .mockResolvedValueOnce([]);

    vi.mocked(verifications.getSummary)
      .mockResolvedValueOnce({
        pending: 1,
        verified: 0,
        rejected: 0,
      })
      .mockResolvedValueOnce({
        pending: 0,
        verified: 0,
        rejected: 1,
      });

    vi.mocked(verifications.reject).mockResolvedValue(
      rejectedBusiness
    );

    render(<VerificationRequestsPage />);

    await screen.findAllByText(
      'Green Lanka Recycling'
    );

    await user.click(
      screen.getByRole('button', { name: 'Reject' })
    );

    const dialog = screen.getByRole('dialog');

    expect(
      within(dialog).getByText(
        'Reject Green Lanka Recycling?'
      )
    ).toBeInTheDocument();

    const reasonBox = within(dialog).getByPlaceholderText(
      'Reason for rejection'
    );

    await user.type(
      reasonBox,
      'Registration number does not match.'
    );

    expect(reasonBox).toHaveValue(
      'Registration number does not match.'
    );

    await user.click(
      within(dialog).getByRole(
        'button',
        { name: 'Reject' }
      )
    );

    await waitFor(() => {
      expect(
        verifications.reject
      ).toHaveBeenCalledWith(
        'req-001',
        'Registration number does not match.'
      );
    });

    expect(
      await screen.findByText(
        'Green Lanka Recycling was rejected.'
      )
    ).toBeInTheDocument();
  });
});
