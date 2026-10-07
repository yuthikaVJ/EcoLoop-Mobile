import type { ReactNode } from 'react';
import { render, screen } from '@testing-library/react';
import {
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';

import * as api from './services/api';
import * as verifications from './services/verifications';


// ======================================================
// MOCK: API SERVICE
// ======================================================

vi.mock('./services/api', async () => {
  const actual = await vi.importActual<
    typeof import('./services/api')
  >('./services/api');

  return {
    ...actual,
    getToken: vi.fn(),
    signOut: vi.fn(),
  };
});


// ======================================================
// MOCK: VERIFICATION SERVICE
// ======================================================

vi.mock('./services/verifications', async () => {
  const actual = await vi.importActual<
    typeof import('./services/verifications')
  >('./services/verifications');

  return {
    ...actual,
    getAdminMe: vi.fn(),
  };
});


// ======================================================
// MOCK: LOGIN PAGE
// ======================================================
// Displays the notice too, so later we can test
// unauthorized / non-admin messages.

vi.mock('./pages/LoginPage', () => ({
  LoginPage: ({
    notice,
  }: {
    notice?: string | null;
  }) => (
    <div>
      <div>Mock Login Page</div>

      {notice && (
        <div>{notice}</div>
      )}
    </div>
  ),
}));


// ======================================================
// MOCK: ADMIN LAYOUT
// ======================================================
// Allows us to verify that an authenticated admin
// reaches the protected admin area.

vi.mock('./components/AdminLayout', () => ({
  AdminLayout: ({
    admin,
    children,
  }: {
    admin: {
      name: string;
      email: string;
    };
    children: ReactNode;
  }) => (
    <div>
      <div>Mock Admin Layout</div>

      <div>{admin.name}</div>

      <div>{admin.email}</div>

      {children}
    </div>
  ),
}));


import App from './App';


// ======================================================
// APP ACCESS CONTROL TESTS
// ======================================================

describe('App access control', () => {

  beforeEach(() => {
    vi.clearAllMocks();
  });


  // ====================================================
  // RT-22: Unauthenticated User Protection
  // ====================================================

  it('shows the login page when no authentication token exists', async () => {

    // Simulate a user who is not logged in.
    vi.mocked(api.getToken).mockReturnValue(null);

    render(<App />);

    // Login page should be displayed.
    expect(
      await screen.findByText('Mock Login Page')
    ).toBeInTheDocument();

    // Admin verification should NOT be attempted.
    expect(
      verifications.getAdminMe
    ).not.toHaveBeenCalled();
  });


  // ====================================================
  // RT-23: Authorized Admin Access
  // ====================================================

  it('shows the admin interface when a valid authenticated admin session exists', async () => {

    // Simulate an existing authentication token.
    vi.mocked(api.getToken).mockReturnValue(
      'valid-admin-token'
    );

    // Backend confirms that this user is an EcoLoop admin.
    vi.mocked(
      verifications.getAdminMe
    ).mockResolvedValue({
      id: 'admin-001',
      name: 'EcoLoop Admin',
      email: 'admin@ecoloop.com',
    });

    render(<App />);

    // Protected admin area should be displayed.
    expect(
      await screen.findByText('Mock Admin Layout')
    ).toBeInTheDocument();

    // Admin information should be available.
    expect(
      screen.getByText('EcoLoop Admin')
    ).toBeInTheDocument();

    expect(
      screen.getByText('admin@ecoloop.com')
    ).toBeInTheDocument();

    // App should verify the authenticated user.
    expect(
      verifications.getAdminMe
    ).toHaveBeenCalledTimes(1);
  });
// ====================================================
// RT-24: Non-Admin User Access Denied
// ====================================================

it('denies access when the authenticated user is not an EcoLoop admin', async () => {

  // Simulate an existing authentication token.
  vi.mocked(api.getToken).mockReturnValue(
    'invalid-admin-token'
  );

  // Backend rejects the user with HTTP 403 Forbidden.
  vi.mocked(
    verifications.getAdminMe
  ).mockRejectedValue(
    new api.ApiError(403, 'Forbidden')
  );

  render(<App />);

  // User should be returned to the login page.
  expect(
    await screen.findByText('Mock Login Page')
  ).toBeInTheDocument();

  // The application should remove the invalid session.
  expect(
    api.signOut
  ).toHaveBeenCalledTimes(1);

  // Admin area must NOT be displayed.
  expect(
    screen.queryByText('Mock Admin Layout')
  ).not.toBeInTheDocument();

  // User should see the authorization error.
  expect(
    screen.getByText(/not an EcoLoop admin/i)
  ).toBeInTheDocument();
});
// ====================================================
// RT-25: Invalid / Expired Authentication Token
// ====================================================

it('returns the user to the login page when the authentication token is invalid or expired', async () => {

  // Simulate an existing but invalid/expired token.
  vi.mocked(api.getToken).mockReturnValue(
    'expired-auth-token'
  );

  // Backend responds with HTTP 401 Unauthorized.
  vi.mocked(
    verifications.getAdminMe
  ).mockRejectedValue(
    new api.ApiError(401, 'Unauthorized')
  );

  render(<App />);

  // User should be returned to the login page.
  expect(
    await screen.findByText('Mock Login Page')
  ).toBeInTheDocument();

  // Invalid session should be cleared.
  expect(
    api.signOut
  ).toHaveBeenCalledTimes(1);

  // Protected admin interface must not be displayed.
  expect(
    screen.queryByText('Mock Admin Layout')
  ).not.toBeInTheDocument();
});
});