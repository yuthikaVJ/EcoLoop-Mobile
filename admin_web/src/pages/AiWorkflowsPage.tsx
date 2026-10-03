import { useCallback, useEffect, useState } from 'react';
import {
  getAiWorkflow,
  getAiWorkflows,
  type AiWorkflow,
  type AiWorkflowDetails,
  type LlmCallTrace,
} from '../services/aiWorkflows';

const FILTERS: { value: string; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'USER_APPROVAL', label: 'Awaiting user' },
  { value: 'CONNECTED', label: 'Connected' },
  { value: 'SAFE_FAILURE', label: 'Safe failure' },
];

const formatTime = (iso?: string | null) =>
  iso ? new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'medium' }) : '—';

function duration(w: AiWorkflow): string {
  if (!w.completedAt) return 'running…';
  const seconds = Math.round((new Date(w.completedAt).getTime() - new Date(w.createdAt).getTime()) / 1000);
  return seconds >= 60 ? `${Math.floor(seconds / 60)}m ${seconds % 60}s` : `${seconds}s`;
}

function StateBadge({ state, outcome }: { state: string; outcome?: string | null }) {
  const tone =
    state === 'SAFE_FAILURE' ? (outcome === 'FAILED' ? 'rejected' : 'unverified') : state === 'MATCHING' || state === 'ANALYZING' || state === 'CANDIDATES_FOUND' || state === 'VALIDATING' ? 'running' : 'verified';
  return <span className={`badge badge-${tone}`}>{state.replace(/_/g, ' ').toLowerCase()}</span>;
}

/** Audit view of every agentic matching run: states, agent calls and validator decisions. */
export function AiWorkflowsPage() {
  const [filter, setFilter] = useState('all');
  const [items, setItems] = useState<AiWorkflow[]>([]);
  const [selected, setSelected] = useState<AiWorkflowDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const list = await getAiWorkflows(filter);
      setItems(list);
      if (list.length > 0) setSelected(await getAiWorkflow(list[0].id));
      else setSelected(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load AI workflows.');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    void load();
  }, [load]);

  const open = async (id: string) => {
    try {
      setSelected(await getAiWorkflow(id));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load the workflow.');
    }
  };

  return (
    <main className="content">
      <div className="page-header">
        <div>
          <h1>AI matching</h1>
          <p className="muted">
            Every agentic matching run, with its states, agent calls and validator decisions. The AI only
            recommends; users decide.
          </p>
        </div>
        <button type="button" className="btn" onClick={() => void load()} disabled={loading}>
          {loading ? 'Refreshing…' : 'Refresh'}
        </button>
      </div>

      <nav className="tabs" aria-label="Filter by state">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            type="button"
            className={`tab ${filter === f.value ? 'active' : ''}`}
            onClick={() => setFilter(f.value)}
          >
            {f.label}
          </button>
        ))}
      </nav>

      {error && <p className="error banner">{error}</p>}

      <div className="layout">
        <section className="list" aria-label="Workflow runs">
          {loading && items.length === 0 ? (
            <p className="muted pad">Loading…</p>
          ) : items.length === 0 ? (
            <div className="empty">
              <p className="muted">No workflow runs yet.</p>
            </div>
          ) : (
            items.map((w) => (
              <button
                key={w.id}
                type="button"
                className={`row ${selected?.workflow.id === w.id ? 'selected' : ''}`}
                onClick={() => void open(w.id)}
              >
                <div className="row-main">
                  <strong>{w.listingTitle}</strong>
                  <span className="muted small">
                    {w.listingType === 'I_HAVE' ? 'I HAVE' : 'I NEED'} · {w.ownerName} · {duration(w)}
                  </span>
                </div>
                <StateBadge state={w.state} outcome={w.outcome} />
              </button>
            ))
          )}
        </section>

        <section className="detail-pane" aria-label="Workflow details">
          {selected ? <WorkflowDetails details={selected} /> : (
            <div className="empty">
              <p className="muted">Select a run to inspect it.</p>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}

function WorkflowDetails({ details }: { details: AiWorkflowDetails }) {
  const { workflow: w, stateHistory, trace } = details;
  const calls = (trace?.llmCalls ?? []).filter((c): c is LlmCallTrace => c != null);
  const decisions = (trace?.agents?.matchEvaluation as { validatorDecisions?: Record<string, string> } | undefined)
    ?.validatorDecisions;

  return (
    <article className="details-body">
      <div className="details-title">
        <h2>{w.listingTitle}</h2>
        <StateBadge state={w.state} outcome={w.outcome} />
      </div>
      <dl className="facts">
        <div><dt>Post</dt><dd>{w.listingType === 'I_HAVE' ? 'I HAVE' : 'I NEED'} · {w.ownerName}</dd></div>
        <div><dt>Outcome</dt><dd>{w.outcome ?? '—'}</dd></div>
        <div><dt>Suggestions</dt><dd>{w.suggestionCount}</dd></div>
        <div><dt>Duration</dt><dd>{duration(w)}</dd></div>
        {w.reason && <div className="wide"><dt>Reason</dt><dd>{w.reason}</dd></div>}
      </dl>

      <h3>State history</h3>
      <ol className="timeline">
        {stateHistory.map((h, i) => (
          <li key={i}>
            <span className="mono small">{formatTime(h.at)}</span>
            <strong>{h.state}</strong>
            {h.note && <span className="muted"> — {h.note}</span>}
          </li>
        ))}
      </ol>

      {calls.length > 0 && (
        <>
          <h3>Agent calls</h3>
          <table className="calls">
            <thead>
              <tr><th>Agent</th><th>Model</th><th>Time</th><th>Tools used</th></tr>
            </thead>
            <tbody>
              {calls.map((c, i) => (
                <tr key={i}>
                  <td>{c.agent}</td>
                  <td className="mono">{c.model}</td>
                  <td>{c.seconds}s</td>
                  <td className="mono small">
                    {c.toolCalls.length === 0
                      ? '—'
                      : c.toolCalls.map((t) => `${t.tool}(${JSON.stringify(t.args)})${t.fallback ? ' [fallback]' : ''}`).join(', ')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}

      {decisions && (
        <>
          <h3>Validator decisions</h3>
          <ul className="plain">
            {Object.entries(decisions).map(([id, decision]) => (
              <li key={id}><span className="mono small">{id.slice(0, 8)}</span> — {decision}</li>
            ))}
          </ul>
        </>
      )}

      {trace?.error && <p className="note note-rejected"><strong>Error:</strong> {trace.error}</p>}

      {trace?.agents && (
        <details className="raw">
          <summary>Raw agent outputs (audit trace)</summary>
          <pre>{JSON.stringify(trace.agents, null, 2)}</pre>
        </details>
      )}
    </article>
  );
}
