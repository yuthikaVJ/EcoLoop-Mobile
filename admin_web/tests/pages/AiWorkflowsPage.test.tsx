// AI matching audit page (src/pages/AiWorkflowsPage.tsx): what each agent did.
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { AiWorkflow, AiWorkflowDetails } from '../../src/services/aiWorkflows';

vi.mock('../../src/services/aiWorkflows', () => ({ getAiWorkflows: vi.fn(), getAiWorkflow: vi.fn() }));

import { getAiWorkflow, getAiWorkflows } from '../../src/services/aiWorkflows';
import { AiWorkflowsPage } from '../../src/pages/AiWorkflowsPage';

const run: AiWorkflow = {
  id: 'w1',
  listingId: 'l1',
  listingTitle: 'Old Gpu',
  listingType: 'I_NEED',
  ownerName: 'Haritha',
  state: 'USER_APPROVAL',
  outcome: 'MATCHES',
  reason: null,
  suggestionCount: 1,
  createdAt: '2026-10-02T09:17:00Z',
  completedAt: '2026-10-02T09:17:12Z',
};

const details: AiWorkflowDetails = {
  workflow: run,
  stateHistory: [
    { state: 'MATCHING', at: '2026-10-02T09:17:00Z', note: 'Matching workflow created.' },
    { state: 'CANDIDATES_FOUND', at: '2026-10-02T09:17:05Z', note: '1 candidate(s) shortlisted' },
    { state: 'USER_APPROVAL', at: '2026-10-02T09:17:12Z', note: null },
  ],
  trace: {
    llmCalls: [
      { agent: 'materialUnderstanding', model: 'gemini-flash-latest', seconds: 1.5, toolCalls: [] },
      { agent: 'requirementMatching', model: 'gemini-flash-latest', seconds: 1.7,
        toolCalls: [{ tool: 'search_candidates', args: { categories: ['E-Waste'] } }] },
      { agent: 'logistics', model: 'gemini-flash-latest', seconds: 1.1,
        toolCalls: [{ tool: 'get_distance', args: { candidateId: '7b096736' } }] },
      { agent: 'matchEvaluation', model: 'gemini-flash-latest', seconds: 1.2, toolCalls: [] },
    ],
    agents: { matchEvaluation: { validatorDecisions: { '7b096736-0000': 'recommended' } } },
  },
};

beforeEach(() => {
  vi.mocked(getAiWorkflows).mockResolvedValue([run]);
  vi.mocked(getAiWorkflow).mockResolvedValue(details);
});

describe('AiWorkflowsPage', () => {
  it('lists runs with their state and duration', async () => {
    render(<AiWorkflowsPage />);
    const list = await screen.findByRole('region', { name: 'Workflow runs' });
    expect(within(list).getByText('Old Gpu')).toBeInTheDocument();
    expect(within(list).getByText(/I NEED · Haritha · 12s/)).toBeInTheDocument();
  });

  it('shows all four agents with their models and tool calls', async () => {
    render(<AiWorkflowsPage />);
    const table = await screen.findByRole('table');
    for (const agent of ['materialUnderstanding', 'requirementMatching', 'logistics', 'matchEvaluation']) {
      expect(within(table).getByText(agent)).toBeInTheDocument();
    }
    expect(within(table).getByText('search_candidates({"categories":["E-Waste"]})')).toBeInTheDocument();
    expect(within(table).getByText('get_distance({"candidateId":"7b096736"})')).toBeInTheDocument();
  });

  it('shows the state history and the validator decisions', async () => {
    render(<AiWorkflowsPage />);
    expect(await screen.findByText(/1 candidate\(s\) shortlisted/)).toBeInTheDocument();
    const decisions = screen.getByRole('heading', { name: 'Validator decisions' }).nextElementSibling as HTMLElement;
    expect(within(decisions).getByText(/recommended/)).toBeInTheDocument();
  });

  it('filters runs by state', async () => {
    render(<AiWorkflowsPage />);
    await screen.findByRole('table');
    await userEvent.click(screen.getByRole('button', { name: 'Safe failure' }));
    await vi.waitFor(() => expect(getAiWorkflows).toHaveBeenLastCalledWith('SAFE_FAILURE'));
  });

  it('shows the error of a failed run', async () => {
    vi.mocked(getAiWorkflow).mockResolvedValue({
      ...details,
      workflow: { ...run, state: 'SAFE_FAILURE', outcome: 'FAILED', reason: 'The AI model was unavailable.' },
      trace: { llmCalls: [], error: 'No Gemini model answered: 429 RESOURCE_EXHAUSTED' },
    });
    render(<AiWorkflowsPage />);
    expect(await screen.findByText(/429 RESOURCE_EXHAUSTED/)).toBeInTheDocument();
    expect(screen.getByText('The AI model was unavailable.')).toBeInTheDocument();
  });

  it('says when there are no runs yet', async () => {
    vi.mocked(getAiWorkflows).mockResolvedValue([]);
    render(<AiWorkflowsPage />);
    expect(await screen.findByText('No workflow runs yet.')).toBeInTheDocument();
  });
});
