import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { LoginPage } from './LoginPage';
import * as google from '../services/googleAuth';
import * as api from '../services/api';

vi.mock('../services/googleAuth', () => ({ isGoogleConfigured: true, waitForGoogle: vi.fn(), chooseGoogleAccount: vi.fn() }));
vi.mock('../services/api', () => ({ signInWithGoogleCode: vi.fn() }));

describe('Login dependency failures', () => {
  beforeEach(() => { vi.resetAllMocks(); });

  it('RT-47: reports Google initialization failure and keeps sign-in disabled', async () => {
    vi.mocked(google.waitForGoogle).mockRejectedValue(new Error('Google script unavailable'));
    render(<LoginPage onSignedIn={vi.fn()} />);
    expect(await screen.findByText('Google script unavailable')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Loading Google/ })).toBeDisabled();
    expect(google.chooseGoogleAccount).not.toHaveBeenCalled();
    expect(api.signInWithGoogleCode).not.toHaveBeenCalled();
  });

  it('RT-48: reports backend code-exchange failure without completing sign-in', async () => {
    const user = userEvent.setup();
    const onSignedIn = vi.fn();
    vi.mocked(google.waitForGoogle).mockResolvedValue(undefined);
    vi.mocked(google.chooseGoogleAccount).mockResolvedValue('test-google-code');
    vi.mocked(api.signInWithGoogleCode).mockRejectedValue(new Error('Code exchange failed'));
    render(<LoginPage onSignedIn={onSignedIn} />);
    await user.click(await screen.findByRole('button', { name: 'Sign in with Google' }));
    expect(await screen.findByText('Code exchange failed')).toBeInTheDocument();
    expect(api.signInWithGoogleCode).toHaveBeenCalledWith('test-google-code');
    expect(onSignedIn).not.toHaveBeenCalled();
    expect(screen.getByRole('button', { name: 'Sign in with Google' })).toBeEnabled();
  });
});
