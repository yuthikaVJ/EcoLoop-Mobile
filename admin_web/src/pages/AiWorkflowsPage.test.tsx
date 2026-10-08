import { act, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AiWorkflowsPage } from './AiWorkflowsPage';
import * as api from '../services/aiWorkflows';
import { deferred, workflow, workflowDetails } from '../test/fixtures';

vi.mock('../services/aiWorkflows', () => ({ getAiWorkflows: vi.fn(), getAiWorkflow: vi.fn() }));

describe('AI workflow audit UI', () => {
  beforeEach(() => {
    vi.resetAllMocks();
    vi.mocked(api.getAiWorkflows).mockResolvedValue([workflow]);
    vi.mocked(api.getAiWorkflow).mockResolvedValue(workflowDetails);
  });

  it('RT-26: disables refresh while the initial workflow request is pending', async () => {
    const pending = deferred<api.AiWorkflow[]>();
    vi.mocked(api.getAiWorkflows).mockReturnValue(pending.promise);
    render(<AiWorkflowsPage />);
    expect(screen.getByRole('button', { name: /Refreshing/ })).toBeDisabled();
    expect(screen.getByText(/Loading/)).toBeInTheDocument();
    expect(api.getAiWorkflow).not.toHaveBeenCalled();
    await act(async () => { pending.resolve([]); });
    expect(await screen.findByRole('button', { name: 'Refresh' })).toBeEnabled();
  });

  it('RT-27: shows an empty audit view without requesting details for an empty list', async () => {
    vi.mocked(api.getAiWorkflows).mockResolvedValue([]);
    render(<AiWorkflowsPage />);
    expect(await screen.findByText('No workflow runs yet.')).toBeInTheDocument();
    expect(screen.getByText('Select a run to inspect it.')).toBeInTheDocument();
    expect(api.getAiWorkflows).toHaveBeenCalledWith('all');
    expect(api.getAiWorkflow).not.toHaveBeenCalled();
  });

  it('RT-28: automatically opens the first run with outcome, duration and state history', async () => {
    render(<AiWorkflowsPage />);
    const details = within(screen.getByRole('region', { name: 'Workflow details' }));
    expect(await details.findByRole('heading', { name: workflow.listingTitle })).toBeInTheDocument();
    expect(api.getAiWorkflow).toHaveBeenCalledWith('run-1');
    expect(details.getByText('MATCHES')).toBeInTheDocument();
    expect(details.getByText('2', { exact: true })).toBeInTheDocument();
    expect(details.getByText('1m 5s')).toBeInTheDocument();
    expect(details.getByText(/User accepted the suggestion/)).toBeInTheDocument();
  });

  it('RT-29: filters awaiting-user runs and clears details when none match', async () => {
    const user = userEvent.setup();
    render(<AiWorkflowsPage />);
    await screen.findByRole('heading', { name: workflow.listingTitle });
    vi.mocked(api.getAiWorkflows).mockResolvedValue([]);
    await user.click(screen.getByRole('button', { name: 'Awaiting user' }));
    expect(await screen.findByText('No workflow runs yet.')).toBeInTheDocument();
    expect(api.getAiWorkflows).toHaveBeenLastCalledWith('USER_APPROVAL');
    expect(screen.queryByRole('heading', { name: workflow.listingTitle })).not.toBeInTheDocument();
    expect(screen.getByText('Select a run to inspect it.')).toBeInTheDocument();
  });

  it('RT-30: opens a different selected run and displays its details', async () => {
    const user = userEvent.setup();
    const second = { ...workflow, id: 'run-2', listingTitle: 'Test plastic', listingType: 'I_NEED' as const };
    vi.mocked(api.getAiWorkflows).mockResolvedValue([workflow, second]);
    vi.mocked(api.getAiWorkflow).mockImplementation(async (id) => ({ ...workflowDetails, workflow: id === second.id ? second : workflow }));
    render(<AiWorkflowsPage />);
    await screen.findByRole('heading', { name: workflow.listingTitle });
    await user.click(screen.getByRole('button', { name: /Test plastic/ }));
    expect(await screen.findByRole('heading', { name: second.listingTitle })).toBeInTheDocument();
    expect(api.getAiWorkflow).toHaveBeenLastCalledWith(second.id);
    expect(within(screen.getByRole('region', { name: 'Workflow details' })).getByText(/I NEED/)).toBeInTheDocument();
  });

  it('RT-31: recovers from a list error when Refresh succeeds', async () => {
    const user = userEvent.setup();
    vi.mocked(api.getAiWorkflows).mockRejectedValueOnce(new Error('Audit service unavailable'));
    render(<AiWorkflowsPage />);
    expect(await screen.findByText('Audit service unavailable')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Refresh' }));
    expect(await screen.findByRole('heading', { name: workflow.listingTitle })).toBeInTheDocument();
    expect(screen.queryByText('Audit service unavailable')).not.toBeInTheDocument();
    expect(api.getAiWorkflows).toHaveBeenCalledTimes(2);
  });

  it('RT-32: reports a selected-run failure while retaining the previous details', async () => {
    const user = userEvent.setup();
    vi.mocked(api.getAiWorkflows).mockResolvedValue([workflow, { ...workflow, id: 'run-2', listingTitle: 'Unavailable run' }]);
    render(<AiWorkflowsPage />);
    await screen.findByRole('heading', { name: workflow.listingTitle });
    vi.mocked(api.getAiWorkflow).mockRejectedValueOnce(new Error('Run details unavailable'));
    await user.click(screen.getByRole('button', { name: /Unavailable run/ }));
    expect(await screen.findByText('Run details unavailable')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: workflow.listingTitle })).toBeInTheDocument();
    expect(screen.queryByRole('heading', { name: 'Unavailable run' })).not.toBeInTheDocument();
  });

  it('RT-33: renders non-null agent calls, fallback tools and validator decisions', async () => {
    vi.mocked(api.getAiWorkflow).mockResolvedValue({ ...workflowDetails, trace: {
      llmCalls: [null, { agent: 'Match evaluator', model: 'test-model', seconds: 1.5,
        toolCalls: [{ tool: 'lookup', args: { material: 'paper' }, fallback: true }] }],
      agents: { matchEvaluation: { validatorDecisions: { 'candidate-123456': 'Accepted by validator' } } },
    } });
    render(<AiWorkflowsPage />);
    const table = await screen.findByRole('table');
    expect(within(table).getAllByRole('row')).toHaveLength(2);
    expect(within(table).getByText('Match evaluator')).toBeInTheDocument();
    expect(within(table).getByText('test-model')).toBeInTheDocument();
    expect(within(table).getByText('1.5s')).toBeInTheDocument();
    expect(within(table).getByText('lookup({"material":"paper"}) [fallback]')).toBeInTheDocument();
    expect(screen.getByText(/Accepted by validator/, { selector: 'li' })).toBeInTheDocument();
    expect(screen.getByText('candidat', { exact: true })).toBeInTheDocument();
  });

  it('RT-34: displays safe-failure reasons and trace errors without an agent table', async () => {
    const failed = { ...workflow, state: 'SAFE_FAILURE' as const, outcome: 'FAILED' as const, reason: 'Material could not be validated' };
    vi.mocked(api.getAiWorkflows).mockResolvedValue([failed]);
    vi.mocked(api.getAiWorkflow).mockResolvedValue({ ...workflowDetails, workflow: failed, trace: { error: 'Validator timed out', llmCalls: [null] } });
    render(<AiWorkflowsPage />);
    expect(await screen.findByText('Material could not be validated')).toBeInTheDocument();
    expect(screen.getByText(/Validator timed out/)).toBeInTheDocument();
    expect(screen.getByText('FAILED', { exact: true })).toBeInTheDocument();
    expect(screen.queryByRole('table')).not.toBeInTheDocument();
    expect(screen.queryByText('Raw agent outputs (audit trace)')).not.toBeInTheDocument();
  });

  it('RT-35: presents an unfinished run as running with no agent trace', async () => {
    const running = { ...workflow, state: 'MATCHING' as const, outcome: null, completedAt: null, suggestionCount: 0 };
    vi.mocked(api.getAiWorkflows).mockResolvedValue([running]);
    vi.mocked(api.getAiWorkflow).mockResolvedValue({ workflow: running, stateHistory: [], trace: null });
    render(<AiWorkflowsPage />);
    const details = within(screen.getByRole('region', { name: 'Workflow details' }));
    await details.findByRole('heading', { name: workflow.listingTitle });
    expect(details.getByText(/running/)).toBeInTheDocument();
    expect(details.getByText('matching')).toHaveClass('badge-running');
    expect(details.getByText('0', { exact: true })).toBeInTheDocument();
    expect(screen.queryByRole('table')).not.toBeInTheDocument();
  });
});
