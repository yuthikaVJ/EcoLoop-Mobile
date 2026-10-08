// Google account chooser (src/services/googleAuth.ts).
import { afterEach, describe, expect, it, vi } from 'vitest';
import { chooseGoogleAccount, isGoogleConfigured, waitForGoogle } from '../../src/services/googleAuth';

type CodeClientConfig = {
  client_id: string;
  scope: string;
  select_account: boolean;
  callback: (r: { code?: string; error?: string }) => void;
  error_callback?: (e: { type: string }) => void;
};

function installGoogle(onRequest: (config: CodeClientConfig) => void) {
  const configs: CodeClientConfig[] = [];
  window.google = {
    accounts: {
      oauth2: {
        initCodeClient: (config: CodeClientConfig) => {
          configs.push(config);
          return { requestCode: () => onRequest(config) };
        },
      },
    },
  } as unknown as Window['google'];
  return configs;
}

afterEach(() => {
  delete window.google;
});

describe('Google sign-in', () => {
  it('is configured from VITE_GOOGLE_CLIENT_ID', () => {
    expect(isGoogleConfigured).toBe(true);
  });

  it('always asks Google to show the account chooser', async () => {
    const configs = installGoogle((config) => config.callback({ code: 'one-time-code' }));

    await expect(chooseGoogleAccount()).resolves.toBe('one-time-code');
    expect(configs[0]).toMatchObject({ client_id: 'test-client-id', select_account: true, scope: 'openid email profile' });
  });

  it('explains a closed popup', async () => {
    installGoogle((config) => config.error_callback?.({ type: 'popup_closed' }));
    await expect(chooseGoogleAccount()).rejects.toThrow('Sign-in was cancelled.');
  });

  it('explains a blocked popup', async () => {
    installGoogle((config) => config.error_callback?.({ type: 'popup_failed_to_open' }));
    await expect(chooseGoogleAccount()).rejects.toThrow('The browser blocked the Google popup');
  });

  it('reports a Google error answer', async () => {
    installGoogle((config) => config.callback({ error: 'access_denied' }));
    await expect(chooseGoogleAccount()).rejects.toThrow('access_denied');
  });

  it('refuses to start before the Google script has loaded', async () => {
    await expect(chooseGoogleAccount()).rejects.toThrow('still loading');
  });

  it('waits for the Google script', async () => {
    const ready = waitForGoogle(1000);
    setTimeout(() => installGoogle(() => {}), 50);
    await expect(ready).resolves.toBeUndefined();
  });

  it('gives up if the script never loads', async () => {
    await expect(waitForGoogle(150)).rejects.toThrow('Could not load Google sign-in');
  });
});
