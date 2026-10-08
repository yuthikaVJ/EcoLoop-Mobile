// AI matching audit API (src/services/aiWorkflows.ts).
import { describe, expect, it, vi } from 'vitest';
import { getAiWorkflow, getAiWorkflows } from '../../src/services/aiWorkflows';

describe('AI workflow audit', () => {
  it('lists workflow runs filtered by state', async () => {
    const fetchMock = vi.fn(async () => new Response('[]', { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    await getAiWorkflows('SAFE_FAILURE');

    expect(fetchMock.mock.calls[0][0]).toBe('http://api.test/api/admin/ai-workflows?state=SAFE_FAILURE');
  });

  it('loads one run with its trace', async () => {
    const details = { workflow: { id: 'w1' }, stateHistory: [], trace: { llmCalls: [] } };
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify(details), { status: 200 })));

    await expect(getAiWorkflow('w1')).resolves.toEqual(details);
  });
});
