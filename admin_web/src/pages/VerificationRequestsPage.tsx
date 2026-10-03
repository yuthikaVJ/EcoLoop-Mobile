import { useCallback, useEffect, useState } from 'react';
import { RejectDialog } from '../components/RejectDialog';
import { RequestDetails } from '../components/RequestDetails';
import { StatusBadge } from '../components/StatusBadge';
import { resolveUrl } from '../services/api';
import {
  approve,
  getRequests,
  getSummary,
  reject,
  type StatusFilter,
  type VerificationRequest,
  type VerificationSummary,
} from '../services/verifications';

const TABS: { status: StatusFilter; label: string; count?: keyof VerificationSummary }[] = [
  { status: 'Unverified', label: 'Pending', count: 'pending' },
  { status: 'Verified', label: 'Verified', count: 'verified' },
  { status: 'Rejected', label: 'Rejected', count: 'rejected' },
  { status: 'all', label: 'All' },
];

export function VerificationRequestsPage() {
  const [status, setStatus] = useState<StatusFilter>('Unverified');
  const [search, setSearch] = useState('');
  const [requests, setRequests] = useState<VerificationRequest[]>([]);
  const [summary, setSummary] = useState<VerificationSummary | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [rejecting, setRejecting] = useState<VerificationRequest | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [items, counts] = await Promise.all([getRequests(status, search), getSummary()]);
      setRequests(items);
      setSummary(counts);
      setSelectedId((current) => (items.some((r) => r.id === current) ? current : items[0]?.id ?? null));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load requests.');
    } finally {
      setLoading(false);
    }
  }, [status, search]);

  // Debounce typing in the search box.
  useEffect(() => {
    const timer = window.setTimeout(load, 250);
    return () => window.clearTimeout(timer);
  }, [load]);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 3500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const review = async (action: () => Promise<VerificationRequest>, message: (r: VerificationRequest) => string) => {
    setBusy(true);
    setError(null);
    try {
      const updated = await action();
      setToast(message(updated));
      setRejecting(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Action failed.');
    } finally {
      setBusy(false);
    }
  };

  const selected = requests.find((r) => r.id === selectedId) ?? null;

  return (
    <>
      <main className="content">
        <div className="page-header">
          <div>
            <h1>Business verification</h1>
            <p className="muted">Check each business against the eROC register, then approve or reject it.</p>
          </div>
          <input
            className="search"
            type="search"
            placeholder="Search name, reg. no. or email"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <nav className="tabs" aria-label="Filter by status">
          {TABS.map((tab) => (
            <button
              key={tab.status}
              type="button"
              className={`tab ${status === tab.status ? 'active' : ''}`}
              onClick={() => setStatus(tab.status)}
            >
              {tab.label}
              {tab.count && summary && <span className="tab-count">{summary[tab.count]}</span>}
            </button>
          ))}
        </nav>

        {error && <p className="error banner">{error}</p>}

        <div className="layout">
          <section className="list" aria-label="Requests">
            {loading && requests.length === 0 ? (
              <p className="muted pad">Loading…</p>
            ) : requests.length === 0 ? (
              <div className="empty">
                <p>{status === 'Unverified' ? 'No pending requests. All caught up!' : 'Nothing here.'}</p>
              </div>
            ) : (
              requests.map((r) => {
                const logo = resolveUrl(r.logoUrl);
                return (
                  <button
                    key={r.id}
                    type="button"
                    className={`row ${r.id === selectedId ? 'selected' : ''}`}
                    onClick={() => setSelectedId(r.id)}
                  >
                    <div className="row-logo">
                      {logo ? <img src={logo} alt="" /> : r.businessName.charAt(0).toUpperCase()}
                    </div>
                    <div className="row-main">
                      <strong>{r.businessName}</strong>
                      <span className="muted mono">{r.registrationNumber}</span>
                    </div>
                    <StatusBadge status={r.status} />
                  </button>
                );
              })
            )}
          </section>

          <section className="detail-pane" aria-label="Request details">
            {selected ? (
              <RequestDetails
                request={selected}
                busy={busy}
                onApprove={() =>
                  review(() => approve(selected.id), (r) => `${r.businessName} is now verified.`)
                }
                onReject={() => setRejecting(selected)}
              />
            ) : (
              <div className="empty">
                <p className="muted">Select a request to review it.</p>
              </div>
            )}
          </section>
        </div>
      </main>

      {rejecting && (
        <RejectDialog
          businessName={rejecting.businessName}
          busy={busy}
          onCancel={() => setRejecting(null)}
          onConfirm={(reason) =>
            review(() => reject(rejecting.id, reason), (r) => `${r.businessName} was rejected.`)
          }
        />
      )}

      {toast && (
        <div className="toast" role="status">
          {toast}
        </div>
      )}
    </>
  );
}
