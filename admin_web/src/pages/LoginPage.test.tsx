import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';

import * as googleAuth from '../services/googleAuth';
import * as api from '../services/api';

vi.mock('../services/googleAuth', () => ({
  isGoogleConfigured: true,
  waitForGoogle: vi.fn(),
  chooseGoogleAccount: vi.fn(),
}));

vi.mock('../services/api', () => ({
  signInWithGoogleCode: vi.fn(),
}));

import { LoginPage } from './LoginPage';

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();

    vi.mocked(googleAuth.waitForGoogle).mockResolvedValue(
      undefined
    );
  });

  // RT-18: Google authentication readiness
  it('displays the Google sign-in button when Google authentication is ready', async () => {
    render(
      <LoginPage
        notice={null}
        onSignedIn={vi.fn()}
      />
    );

    expect(
      await screen.findByRole('button', {
        name: /Sign in with Google/i,
      })
    ).toBeEnabled();
  });

  // RT-19: Successful Google sign-in
  it('signs in successfully using the Google authorization code', async () => {
    const user = userEvent.setup();
    const onSignedIn = vi.fn();

    vi.mocked(
      googleAuth.chooseGoogleAccount
    ).mockResolvedValue('google-auth-code-123');

    vi.mocked(
      api.signInWithGoogleCode
    ).mockResolvedValue(undefined);

    render(
      <LoginPage
        notice={null}
        onSignedIn={onSignedIn}
      />
    );

    const signInButton =
      await screen.findByRole('button', {
        name: /Sign in with Google/i,
      });

    await user.click(signInButton);

    expect(
      googleAuth.chooseGoogleAccount
    ).toHaveBeenCalledTimes(1);

    expect(
      api.signInWithGoogleCode
    ).toHaveBeenCalledWith(
      'google-auth-code-123'
    );

    expect(
      onSignedIn
    ).toHaveBeenCalledTimes(1);
  });
// RT-20: Google sign-in failure handling
it('displays an error message when Google sign-in fails', async () => {
  const user = userEvent.setup();
  const onSignedIn = vi.fn();

  vi.mocked(
    googleAuth.chooseGoogleAccount
  ).mockRejectedValue(
    new Error('Sign-in was cancelled.')
  );

  render(
    <LoginPage
      notice={null}
      onSignedIn={onSignedIn}
    />
  );

  const signInButton =
    await screen.findByRole('button', {
      name: /Sign in with Google/i,
    });

  await user.click(signInButton);

  expect(
    await screen.findByText('Sign-in was cancelled.')
  ).toBeInTheDocument();

  expect(
    api.signInWithGoogleCode
  ).not.toHaveBeenCalled();

  expect(
    onSignedIn
  ).not.toHaveBeenCalled();
});
// RT-21: Login notice display
it('displays a notice message provided to the login page', async () => {
  render(
    <LoginPage
      notice="Admin access required."
      onSignedIn={vi.fn()}
    />
  );

  expect(
    screen.getByText('Admin access required.')
  ).toBeInTheDocument();

  expect(
    await screen.findByRole('button', {
      name: /Sign in with Google/i,
    })
  ).toBeEnabled();
});
});