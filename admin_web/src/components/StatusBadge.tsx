import type { VerificationStatus } from '../services/verifications';

const LABELS: Record<VerificationStatus, string> = {
  Unverified: 'Pending',
  Verified: 'Verified',
  Rejected: 'Rejected',
};

export function StatusBadge({ status }: { status: VerificationStatus }) {
  return <span className={`badge badge-${status.toLowerCase()}`}>{LABELS[status] ?? status}</span>;
}
