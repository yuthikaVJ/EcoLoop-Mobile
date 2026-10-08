import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { API_BASE_URL, ApiError, apiRequest } from './api';

describe('API session refresh', () => {
  const fetchMock = vi.fn<typeof fetch>();
  beforeEach(() => {
    fetchMock.mockReset();
    vi.stubGlobal('fetch', fetchMock);
    localStorage.clear();
    localStorage.setItem('ecoloop_admin_token', 'expired-test-token');
    localStorage.setItem('ecoloop_admin_refresh_token', 'test-refresh-token');
  });
  afterEach(() => { vi.unstubAllGlobals(); localStorage.clear(); });

  it('RT-49: refreshes an expired session and retries with the replacement bearer token', async () => {
    fetchMock.mockResolvedValueOnce(new Response('', { status: 401 }))
      .mockResolvedValueOnce(Response.json({ token: 'new-test-token', refreshToken: 'new-refresh-token' }))
      .mockResolvedValueOnce(Response.json({ id: 'test-admin' }));
    expect(await apiRequest('/api/admin/me')).toEqual({ id: 'test-admin' });
    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock.mock.calls[0][1]?.headers).toMatchObject({ Authorization: 'Bearer expired-test-token' });
    expect(fetchMock.mock.calls[1][0]).toBe(`${API_BASE_URL}/api/auth/refresh`);
    expect(fetchMock.mock.calls[1][1]?.method).toBe('POST');
    expect(JSON.parse(fetchMock.mock.calls[1][1]?.body as string)).toEqual({ accessToken: 'expired-test-token', refreshToken: 'test-refresh-token' });
    expect(fetchMock.mock.calls[2][0]).toBe(`${API_BASE_URL}/api/admin/me`);
    expect(fetchMock.mock.calls[2][1]?.headers).toMatchObject({ Authorization: 'Bearer new-test-token' });
    expect(localStorage.getItem('ecoloop_admin_token')).toBe('new-test-token');
    expect(localStorage.getItem('ecoloop_admin_refresh_token')).toBe('new-refresh-token');
  });

  it('RT-50: clears both tokens and exposes the original API error when refresh is rejected', async () => {
    fetchMock.mockResolvedValueOnce(Response.json({ message: 'Session expired' }, { status: 401 }))
      .mockResolvedValueOnce(new Response('', { status: 401 }));
    const error = await apiRequest('/api/admin/me').catch((reason: unknown) => reason);
    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({ status: 401, message: 'Session expired' });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(localStorage.getItem('ecoloop_admin_token')).toBeNull();
    expect(localStorage.getItem('ecoloop_admin_refresh_token')).toBeNull();
  });
});
