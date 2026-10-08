// Business verification API (src/services/verifications.ts).
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { approve, getAdminMe, getRequests, getSummary, reject } from '../../src/services/verifications';

let fetchMock: ReturnType<typeof vi.fn>;

beforeEach(() => {
  fetchMock = vi.fn(async () => new Response(JSON.stringify({}), { status: 200 }));
  vi.stubGlobal('fetch', fetchMock);
});

const lastCall = () => fetchMock.mock.calls.at(-1) as unknown as [string, RequestInit];

describe('verification requests', () => {
  it('lists requests by status', async () => {
    await getRequests('Unverified', '');
    expect(lastCall()[0]).toBe('http://api.test/api/admin/business-verifications?status=Unverified');
  });

  it('adds the trimmed search text', async () => {
    await getRequests('all', '  GreenCycle ');
    expect(lastCall()[0]).toBe('http://api.test/api/admin/business-verifications?status=all&search=GreenCycle');
  });

  it('reads the summary counts and the signed-in admin', async () => {
    await getSummary();
    expect(lastCall()[0]).toBe('http://api.test/api/admin/business-verifications/summary');
    await getAdminMe();
    expect(lastCall()[0]).toBe('http://api.test/api/admin/me');
  });

  it('approves with a POST', async () => {
    await approve('b1');
    expect(lastCall()[0]).toBe('http://api.test/api/admin/business-verifications/b1/approve');
    expect(lastCall()[1].method).toBe('POST');
  });

  it('rejects with the reason the owner will see', async () => {
    await reject('b1', 'Registration number does not match.');
    expect(lastCall()[0]).toBe('http://api.test/api/admin/business-verifications/b1/reject');
    expect(JSON.parse(lastCall()[1].body as string)).toEqual({ reason: 'Registration number does not match.' });
  });
});
