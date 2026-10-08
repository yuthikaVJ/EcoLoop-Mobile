// API client (src/services/api.ts): tokens, automatic refresh and error messages.
import { describe, expect, it, vi } from 'vitest';
import { ApiError, apiRequest, getToken, resolveUrl, signInWithGoogleCode, signOut } from '../../src/services/api';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

function mockFetch(...responses: Response[]) {
  const fetchMock = vi.fn(async () => responses.shift() ?? json({}, 500));
  vi.stubGlobal('fetch', fetchMock);
  return fetchMock;
}

describe('resolveUrl', () => {
  it('turns server paths into full URLs', () => {
    expect(resolveUrl('/uploads/logo.png')).toBe('http://api.test/uploads/logo.png');
    expect(resolveUrl('uploads/logo.png')).toBe('http://api.test/uploads/logo.png');
  });

  it('keeps full URLs and ignores empty values', () => {
    expect(resolveUrl('https://cdn.example/x.png')).toBe('https://cdn.example/x.png');
    expect(resolveUrl(null)).toBeNull();
    expect(resolveUrl('')).toBeNull();
  });
});

describe('signInWithGoogleCode', () => {
  it('stores the EcoLoop tokens', async () => {
    const fetchMock = mockFetch(json({ token: 'access-1', refreshToken: 'refresh-1' }));

    await signInWithGoogleCode('google-code');

    expect(getToken()).toBe('access-1');
    const [url, init] = fetchMock.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe('http://api.test/api/auth/google-code');
    expect(JSON.parse(init.body as string)).toEqual({ code: 'google-code' });
  });

  it('reports the backend message when Google rejects the code', async () => {
    mockFetch(json({ message: 'Google rejected the sign-in code.' }, 401));

    await expect(signInWithGoogleCode('bad')).rejects.toThrow('Google rejected the sign-in code.');
    expect(getToken()).toBeNull();
  });
});

describe('apiRequest', () => {
  it('sends the access token', async () => {
    localStorage.setItem('ecoloop_admin_token', 'access-1');
    const fetchMock = mockFetch(json({ ok: true }));

    await apiRequest('/api/admin/me');

    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer access-1');
  });

  it('refreshes an expired token once and retries', async () => {
    localStorage.setItem('ecoloop_admin_token', 'old');
    localStorage.setItem('ecoloop_admin_refresh_token', 'refresh-1');
    const fetchMock = mockFetch(
      new Response(null, { status: 401 }),
      json({ token: 'new', refreshToken: 'refresh-2' }),
      json({ id: 'admin' }),
    );

    const result = await apiRequest<{ id: string }>('/api/admin/me');

    expect(result.id).toBe('admin');
    expect(fetchMock.mock.calls[1][0]).toBe('http://api.test/api/auth/refresh');
    expect(getToken()).toBe('new');
  });

  it('signs out when the session cannot be refreshed', async () => {
    localStorage.setItem('ecoloop_admin_token', 'old');
    localStorage.setItem('ecoloop_admin_refresh_token', 'expired');
    mockFetch(new Response(null, { status: 401 }), new Response(null, { status: 401 }));

    await expect(apiRequest('/api/admin/me')).rejects.toBeInstanceOf(ApiError);
    expect(getToken()).toBeNull();
  });

  it('turns validation errors into a readable message', async () => {
    mockFetch(json({ errors: { Reason: ['A reason is required so the owner knows what to fix.'] } }, 400));

    await expect(apiRequest('/x')).rejects.toThrow('A reason is required so the owner knows what to fix.');
  });

  it('keeps the HTTP status on errors', async () => {
    mockFetch(json({ message: 'Forbidden' }, 403));

    const error = await apiRequest('/x').catch((e) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect(error.status).toBe(403);
  });

  it('returns nothing for 204 No Content', async () => {
    mockFetch(new Response(null, { status: 204 }));
    await expect(apiRequest('/x')).resolves.toBeUndefined();
  });
});

describe('signOut', () => {
  it('removes both tokens', () => {
    localStorage.setItem('ecoloop_admin_token', 'a');
    localStorage.setItem('ecoloop_admin_refresh_token', 'b');
    signOut();
    expect(localStorage.length).toBe(0);
  });
});
