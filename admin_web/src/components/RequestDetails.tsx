import { resolveUrl } from '../services/api';
import type { VerificationRequest } from '../services/verifications';
import { StatusBadge } from './StatusBadge';

interface Props {
  request: VerificationRequest;
  busy: boolean;
  onApprove: () => void;
  onReject: () => void;
}

const formatDate = (iso?: string | null) =>
  iso ? new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }) : '—';

/** Everything an admin needs to check a business against the eROC register. */
export function RequestDetails({ request, busy, onApprove, onReject }: Props) {
  const cover = resolveUrl(request.coverPhotoUrl);
  const logo = resolveUrl(request.logoUrl);

  const rows: [string, React.ReactNode][] = [
    ['Registration no. (eROC/ROC)', <strong className="mono">{request.registrationNumber || '—'}</strong>],
    ['Business type', request.businessType || '—'],
    ['Business email', request.email || '—'],
    ['Phone', request.phone || '—'],
    ['Address', request.address || '—'],
    [
      'Website',
      request.websiteUrl ? (
        <a href={request.websiteUrl} target="_blank" rel="noreferrer">
          {request.websiteUrl}
        </a>
      ) : (
        '—'
      ),
    ],
    ['Owner account', `${request.ownerName ?? 'Unknown'}${request.ownerEmail ? ` · ${request.ownerEmail}` : ''}`],
    ['Submitted', formatDate(request.createdAt)],
    ['Last updated', formatDate(request.updatedAt)],
    ...(request.verifiedAt ? [['Verified on', formatDate(request.verifiedAt)] as [string, React.ReactNode]] : []),
  ];

  return (
    <article className="details">
      <div className="cover" style={cover ? { backgroundImage: `url(${cover})` } : undefined}>
        <div className="logo">
          {logo ? <img src={logo} alt="" /> : <span>{request.businessName.charAt(0).toUpperCase()}</span>}
        </div>
      </div>

      <div className="details-body">
        <div className="details-title">
          <h2>{request.businessName}</h2>
          <StatusBadge status={request.status} />
        </div>
        {request.bio && <p className="bio">{request.bio}</p>}

        {request.status === 'Rejected' && request.verificationNote && (
          <p className="note note-rejected">
            <strong>Rejection reason:</strong> {request.verificationNote}
          </p>
        )}

        <dl className="facts">
          {rows.map(([label, value]) => (
            <div key={label}>
              <dt>{label}</dt>
              <dd>{value}</dd>
            </div>
          ))}
        </dl>

        {request.description && (
          <>
            <h3>About</h3>
            <p className="description">{request.description}</p>
          </>
        )}

        <div className="details-actions">
          {request.status !== 'Verified' && (
            <button type="button" className="btn btn-primary" disabled={busy} onClick={onApprove}>
              {busy ? 'Saving…' : 'Approve'}
            </button>
          )}
          {request.status !== 'Rejected' && (
            <button type="button" className="btn btn-danger-outline" disabled={busy} onClick={onReject}>
              {request.status === 'Verified' ? 'Revoke verification' : 'Reject'}
            </button>
          )}
        </div>
      </div>
    </article>
  );
}
