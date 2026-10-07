import { render, screen } from '@testing-library/react';
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

    // Wait for the initial Pending request to finish.
    expect(
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();

    // User clicks the Verified tab.
    await user.click(
      screen.getByRole('button', { name: /Verified/ })
    );

    // Verify that the correct status is passed to the service.
    await vi.waitFor(() => {
      expect(
        verifications.getRequests
      ).toHaveBeenCalledWith(
        'Verified',
        ''
      );
    });

    // Wait for the UI to finish updating.
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

    // Wait for the initial request to finish.
    expect(
      await screen.findByText(
        'No pending requests. All caught up!'
      )
    ).toBeInTheDocument();

    const searchBox = screen.getByPlaceholderText(
      'Search name, reg. no. or email'
    );

    // User types a search term.
    await user.type(
      searchBox,
      'Green Lanka'
    );

    // Verify what the user typed.
    expect(
      searchBox
    ).toHaveValue('Green Lanka');

    // Verify that the search term is sent to the service.
    await vi.waitFor(() => {
      expect(
        verifications.getRequests
      ).toHaveBeenCalledWith(
        'Unverified',
        'Green Lanka'
      );
    });
  });
});