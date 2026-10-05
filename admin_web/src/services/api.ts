// HTTP client for the EcoLoop backend: Google login, token storage and
// one automatic refresh when the 15-minute access token expires.

export const API_BASE_URL: string =
  import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5252';

const TOKEN_KEY = 'ecoloop_admin_token';
const REFRESH_KEY = 'ecoloop_admin_refresh_token';

export class ApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function signOut(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

/** Turns a server path such as `/uploads/...` into a full URL. */
export function resolveUrl(pathOrUrl?: string | null): string | null {
  if (!pathOrUrl) return null;
  if (/^https?:\/\//i.test(pathOrUrl)) return pathOrUrl;
  return `${API_BASE_URL}${pathOrUrl.startsWith('/') ? '' : '/'}${pathOrUrl}`;
}

/** Exchanges a Google authorization code for EcoLoop access and refresh tokens. */
export async function signInWithGoogleCode(code: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/auth/google-code`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code }),
  });
  if (!response.ok) throw new ApiError(response.status, await errorMessage(response));
  const data = await response.json();
  localStorage.setItem(TOKEN_KEY, data.token);
  localStorage.setItem(REFRESH_KEY, data.refreshToken);
}

let refreshing: Promise<boolean> | null = null;

// Refresh tokens are single use, so parallel 401s share one refresh.
function refreshTokens(): Promise<boolean> {
  refreshing ??= (async () => {
    const accessToken = getToken();
    const refreshToken = localStorage.getItem(REFRESH_KEY);
    if (!accessToken || !refreshToken) return false;
    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ accessToken, refreshToken }),
      });
      if (!response.ok) return false;
      const data = await response.json();
      localStorage.setItem(TOKEN_KEY, data.token);
      localStorage.setItem(REFRESH_KEY, data.refreshToken);
      return true;
    } catch {
      return false;
    }
  })().finally(() => {
    refreshing = null;
  });
  return refreshing;
}

export async function apiRequest<T>(path: string, init: RequestInit = {}): Promise<T> {
  const send = () =>
    fetch(`${API_BASE_URL}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        ...(getToken() ? { Authorization: `Bearer ${getToken()}` } : {}),
        ...init.headers,
      },
    });

  let response = await send();
  if (response.status === 401 && (await refreshTokens())) {
    response = await send();
  }
  if (response.status === 401) signOut();
  if (!response.ok) throw new ApiError(response.status, await errorMessage(response));
  return (response.status === 204 ? undefined : await response.json()) as T;
}

async function errorMessage(response: Response): Promise<string> {
  const text = await response.text();
  try {
    const body = JSON.parse(text);
    if (body.message) return body.message;
    if (body.errors) return Object.values(body.errors).flat().join(' ');
    if (body.title) return body.title;
  } catch {
    // Not JSON.
  }
  return text || `Request failed (${response.status}).`;
}
