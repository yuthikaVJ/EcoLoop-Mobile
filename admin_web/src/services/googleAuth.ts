// Google sign-in through Google Identity Services' authorization-code popup.
// `select_account: true` makes Google always show its account chooser, so an
// admin can pick any account instead of the one the browser is signed in to.
// The popup returns a one-time code that the backend exchanges with Google;
// it only needs this site's origin under "Authorized JavaScript origins".

const CLIENT_ID: string | undefined = import.meta.env.VITE_GOOGLE_CLIENT_ID;

export const isGoogleConfigured = Boolean(CLIENT_ID);

interface CodeResponse {
  code?: string;
  error?: string;
  error_description?: string;
}

interface CodeClient {
  requestCode(): void;
}

declare global {
  interface Window {
    google?: {
      accounts: {
        oauth2: {
          initCodeClient(config: {
            client_id: string;
            scope: string;
            ux_mode: 'popup';
            select_account: boolean;
            callback: (response: CodeResponse) => void;
            error_callback?: (error: { type: string }) => void;
          }): CodeClient;
        };
      };
    };
  }
}

/** Resolves once Google's script (loaded in index.html) is ready. */
export function waitForGoogle(timeoutMs = 10000): Promise<void> {
  return new Promise((resolve, reject) => {
    const started = Date.now();
    const check = () => {
      if (window.google?.accounts?.oauth2) resolve();
      else if (Date.now() - started > timeoutMs) reject(new Error('Could not load Google sign-in. Check your connection.'));
      else window.setTimeout(check, 100);
    };
    check();
  });
}

/**
 * Opens Google's account chooser and resolves with an authorization code.
 * Call directly from a click handler, or the browser may block the popup.
 */
export function chooseGoogleAccount(): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!CLIENT_ID) {
      reject(new Error('VITE_GOOGLE_CLIENT_ID is missing from admin_web/.env.'));
      return;
    }
    if (!window.google?.accounts?.oauth2) {
      reject(new Error('Google sign-in is still loading. Please try again.'));
      return;
    }

    window.google.accounts.oauth2
      .initCodeClient({
        client_id: CLIENT_ID,
        scope: 'openid email profile',
        ux_mode: 'popup',
        select_account: true,
        callback: (response) =>
          response.code
            ? resolve(response.code)
            : reject(new Error(response.error_description ?? response.error ?? 'Google sign-in failed.')),
        error_callback: (error) =>
          reject(
            new Error(
              error.type === 'popup_closed'
                ? 'Sign-in was cancelled.'
                : error.type === 'popup_failed_to_open'
                  ? 'The browser blocked the Google popup. Allow popups for this site and try again.'
                  : 'Google sign-in failed.',
            ),
          ),
      })
      .requestCode();
  });
}
