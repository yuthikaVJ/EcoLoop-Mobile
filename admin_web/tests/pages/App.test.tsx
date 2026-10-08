// App shell (src/App.tsx): only admins get past the login page.
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ApiError } from '../../src/services/api';

vi.mock('../../src/services/verifications', () => ({
  getAdminMe: vi.fn(),
  getRequests: vi.fn().mockResolvedValue([]),
  getSummary: vi.fn().mockResolvedValue({ pending: 0, verified: 0, rejected: 0 }),
  approve: vi.fn(),
  reject: vi.fn(),
}));
vi.mock('../../src/services/aiWorkflows', () => ({
  getAiWorkflows: vi.fn().mockResolvedValue([]),
  getAiWorkflow: vi.fn(),
}));
vi.mock('../../src/services/googleAuth', () => ({
  isGoogleConfigured: true,
  waitForGoogle: vi.fn().mockResolvedValue(undefined),
  chooseGoogleAccount: vi.fn(),
}));

import App from '../../src/App';
import { getAdminMe } from '../../src/services/verifications';

// A token whose payload names the account, as the backend issues it.
const token = (email: string) =>
  `x.${btoa(JSON.stringify({ 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress': email }))}.y`;

beforeEach(() => {
  vi.mocked(getAdminMe).mockReset();
});

describe('App', () => {
  it('shows the login page when nobody is signed in', async () => {
    render(<App />);
    expect(await screen.findByRole('heading', { name: 'EcoLoop Admin' })).toBeInTheDocument();
    expect(getAdminMe).not.toHaveBeenCalled();
  });

  it('lets an admin in and switches between sections', async () => {
    localStorage.setItem('ecoloop_admin_token', token('admin@gmail.com'));
    vi.mocked(getAdminMe).mockResolvedValue({ id: 'a1', name: 'Admin', email: 'admin@gmail.com' });
    render(<App />);

    expect(await screen.findByRole('heading', { name: 'Business verification' })).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'AI matching' }));
    expect(await screen.findByRole('heading', { name: 'AI matching' })).toBeInTheDocument();
  });

  it('refuses a non-admin account and names it', async () => {
    localStorage.setItem('ecoloop_admin_token', token('someone@gmail.com'));
    vi.mocked(getAdminMe).mockRejectedValue(new ApiError(403, 'Forbidden'));
    render(<App />);

    expect(await screen.findByText(/someone@gmail.com is not an EcoLoop admin/)).toBeInTheDocument();
    expect(localStorage.getItem('ecoloop_admin_token')).toBeNull();
  });

  it('explains when the backend is down', async () => {
    localStorage.setItem('ecoloop_admin_token', token('admin@gmail.com'));
    vi.mocked(getAdminMe).mockRejectedValue(new TypeError('Failed to fetch'));
    render(<App />);
    expect(await screen.findByText('Cannot reach the EcoLoop backend. Is it running?')).toBeInTheDocument();
  });

  it('signing out returns to the login page', async () => {
    localStorage.setItem('ecoloop_admin_token', token('admin@gmail.com'));
    vi.mocked(getAdminMe).mockResolvedValue({ id: 'a1', name: 'Admin', email: 'admin@gmail.com' });
    render(<App />);

    await userEvent.click(await screen.findByRole('button', { name: 'Sign out' }));
    expect(await screen.findByRole('button', { name: /Sign in with Google|Loading Google/ })).toBeInTheDocument();
    expect(localStorage.getItem('ecoloop_admin_token')).toBeNull();
  });
});
