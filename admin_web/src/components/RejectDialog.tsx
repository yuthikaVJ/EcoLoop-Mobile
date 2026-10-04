import { useState } from 'react';

interface Props {
  businessName: string;
  busy: boolean;
  onCancel: () => void;
  onConfirm: (reason: string) => void;
}

const QUICK_REASONS = [
  'Registration number does not match the eROC record.',
  'Business name does not match the registration.',
  'Contact details could not be confirmed.',
];

/** Asks for the reason the owner will see in the app. */
export function RejectDialog({ businessName, busy, onCancel, onConfirm }: Props) {
  const [reason, setReason] = useState('');
  const valid = reason.trim().length >= 3;

  return (
    <div className="overlay" role="dialog" aria-modal="true" aria-labelledby="reject-title">
      <div className="dialog">
        <h2 id="reject-title">Reject {businessName}?</h2>
        <p className="muted">The owner sees this reason and can fix their details to resubmit.</p>
        <div className="chips">
          {QUICK_REASONS.map((text) => (
            <button key={text} type="button" className="chip" onClick={() => setReason(text)}>
              {text}
            </button>
          ))}
        </div>
        <textarea
          autoFocus
          rows={4}
          maxLength={500}
          value={reason}
          placeholder="Reason for rejection"
          onChange={(e) => setReason(e.target.value)}
        />
        <div className="dialog-actions">
          <button type="button" className="btn" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-danger"
            disabled={!valid || busy}
            onClick={() => onConfirm(reason.trim())}
          >
            {busy ? 'Rejecting…' : 'Reject'}
          </button>
        </div>
      </div>
    </div>
  );
}
