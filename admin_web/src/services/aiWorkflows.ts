import { apiRequest } from './api';

export type WorkflowState =
  | 'MATCHING'
  | 'ANALYZING'
  | 'CANDIDATES_FOUND'
  | 'VALIDATING'
  | 'MATCH_READY'
  | 'USER_APPROVAL'
  | 'CONNECTED'
  | 'SAFE_FAILURE';

export interface AiWorkflow {
  id: string;
  listingId: string;
  listingTitle: string;
  listingType: 'I_HAVE' | 'I_NEED';
  ownerName: string;
  state: WorkflowState;
  outcome?: 'MATCHES' | 'NO_MATCH' | 'NEEDS_INFO' | 'FAILED' | null;
  reason?: string | null;
  suggestionCount: number;
  createdAt: string;
  completedAt?: string | null;
}

export interface StateHistoryEntry {
  state: WorkflowState;
  at: string;
  note?: string | null;
}

export interface LlmCallTrace {
  agent: string;
  model: string;
  seconds: number;
  toolCalls: { tool: string; args: Record<string, unknown>; fallback?: boolean }[];
}

export interface WorkflowTrace {
  agents?: Record<string, unknown>;
  llmCalls?: (LlmCallTrace | null)[];
  error?: string;
}

export interface AiWorkflowDetails {
  workflow: AiWorkflow;
  stateHistory: StateHistoryEntry[];
  trace?: WorkflowTrace | null;
}

export const getAiWorkflows = (state: string) =>
  apiRequest<AiWorkflow[]>(`/api/admin/ai-workflows?${new URLSearchParams({ state })}`);

export const getAiWorkflow = (id: string) => apiRequest<AiWorkflowDetails>(`/api/admin/ai-workflows/${id}`);
