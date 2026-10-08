import type { VerificationRequest } from '../services/verifications';
import type { AiWorkflow, AiWorkflowDetails } from '../services/aiWorkflows';

export const business: VerificationRequest = {
  id: 'test-business-1', businessName: 'Test Recycling', businessType: 'Recycling',
  registrationNumber: 'TEST-PV-001', email: 'business@example.test', phone: '0770000000',
  address: '1 Test Road, Colombo', isVerified: false, status: 'Unverified',
  createdAt: '2026-10-01T10:00:00Z', logoUrl: null, coverPhotoUrl: null,
};

export const workflow: AiWorkflow = {
  id: 'run-1', listingId: 'listing-1', listingTitle: 'Test cardboard', listingType: 'I_HAVE',
  ownerName: 'Test Owner', state: 'CONNECTED', outcome: 'MATCHES', suggestionCount: 2,
  createdAt: '2026-10-01T10:00:00Z', completedAt: '2026-10-01T10:01:05Z',
};

export const workflowDetails: AiWorkflowDetails = {
  workflow,
  stateHistory: [{ state: 'CONNECTED', at: '2026-10-01T10:01:05Z', note: 'User accepted the suggestion.' }],
  trace: null,
};

export function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => { resolve = done; });
  return { promise, resolve };
}
