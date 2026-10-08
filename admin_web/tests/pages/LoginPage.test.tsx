// Login page (src/pages/LoginPage.tsx): Google account chooser -> EcoLoop session.
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../../src/services/googleAuth', () => ({
  isGoogleConfigured: true,
  waitForGoogle: vi.fn(),
  chooseGoogleAccount: vi.fn(),
}));
vi.mock('../../src/services/api', () => ({ signInWithGoogleCode: vi.fn() }));

import { signInWithGoogleCode } from '../../src/services/api';
import { chooseGoogleAccount, waitForGoogle } from '../../src/services/googleAuth';
import { LoginPage } from '../../src/pages/LoginPage';

beforeEach(() => {
  vi.mocked(waitForGoogle).mockResolvedValue();
});

describe('LoginPage', () => {
  it('enables the button once Google has loaded', async () => {
    render(<LoginPage onSignedIn={() => {}} />);
    expect(await screen.findByRole('button', { name: 'Sign in with Google' })).toBeEnabled();
    expect(screen.getByText('Google will ask which account to use.')).toBeInTheDocument();
  });

  it('exchanges the chosen account\'s code for a session', async () => {
    vi.mocked(chooseGoogleAccount).mockResolvedValue('one-time-code');
    vi.mocked(signInWithGoogleCode).mockResolvedValue();
    const onSignedIn = vi.fn();
    render(<LoginPage onSignedIn={onSignedIn} />);

    await userEvent.click(await screen.findByRole('button', { name: 'Sign in with Google' }));

    expect(signInWithGoogleCode).toHaveBeenCalledWith('one-time-code');
    expect(onSignedIn).toHaveBeenCalledOnce();
  });

  it('shows why sign-in did not work', async () => {
    vi.mocked(chooseGoogleAccount).mockRejectedValue(new Error('Sign-in was cancelled.'));
    const onSignedIn = vi.fn();
    render(<LoginPage onSignedIn={onSignedIn} />);

    await userEvent.click(await screen.findByRole('button', { name: 'Sign in with Google' }));

    expect(await screen.findByText('Sign-in was cancelled.')).toBeInTheDocument();
    expect(onSignedIn).not.toHaveBeenCalled();
  });

  it('shows the reason the last account was refused', () => {
    render(<LoginPage notice="someone@gmail.com is not an EcoLoop admin." onSignedIn={() => {}} />);
    expect(screen.getByText('someone@gmail.com is not an EcoLoop admin.')).toBeInTheDocument();
  });

  it('says so when the Google script cannot load', async () => {
    vi.mocked(waitForGoogle).mockRejectedValue(new Error('Could not load Google sign-in. Check your connection.'));
    render(<LoginPage onSignedIn={() => {}} />);
    expect(await screen.findByText('Could not load Google sign-in. Check your connection.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Loading Google…' })).toBeDisabled();
  });
});
