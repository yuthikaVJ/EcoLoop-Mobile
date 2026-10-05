import { useCallback, useEffect, useState } from 'react';
import { AdminLayout, type AdminPage } from './components/AdminLayout';
import { AiWorkflowsPage } from './pages/AiWorkflowsPage';
import { LoginPage } from './pages/LoginPage';
import { VerificationRequestsPage } from './pages/VerificationRequestsPage';
import { ApiError, getToken, signOut } from './services/api';
import { getAdminMe, type AdminUser } from './services/verifications';

type State =
  | { kind: 'checking' }
  | { kind: 'signedOut'; notice?: string }
  | { kind: 'admin'; admin: AdminUser };

const notAdminMessage = (email?: string) =>
  `${email ?? 'This Google account'} is not an EcoLoop admin. ` +
  'Set IsAdmin = true for it in the database, then sign in again.';

/** Email inside our own access token, to name the account that was refused. */
function tokenEmail(): string | undefined {
  try {
    const payload = getToken()!.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const claims = JSON.parse(atob(payload));
    return claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ?? claims.email;
  } catch {
    return undefined;
  }
}

export default function App() {
  const [state, setState] = useState<State>({ kind: 'checking' });
  const [page, setPage] = useState<AdminPage>('verification');

  const checkSession = useCallback(async () => {
    if (!getToken()) {
      setState({ kind: 'signedOut' });
      return;
    }
    setState({ kind: 'checking' });
    try {
      setState({ kind: 'admin', admin: await getAdminMe() });
    } catch (e) {
      const email = tokenEmail();
      signOut();
      const notice =
        e instanceof ApiError && e.status === 403
          ? notAdminMessage(email)
          : e instanceof ApiError && e.status === 401
            ? undefined
            : 'Cannot reach the EcoLoop backend. Is it running?';
      setState({ kind: 'signedOut', notice });
    }
  }, []);

  useEffect(() => {
    void checkSession();
  }, [checkSession]);

  if (state.kind === 'checking') {
    return <main className="login"><p className="muted">Loading…</p></main>;
  }

  if (state.kind === 'signedOut') {
    return <LoginPage notice={state.notice} onSignedIn={checkSession} />;
  }

  return (
    <AdminLayout
      admin={state.admin}
      page={page}
      onNavigate={setPage}
      onSignOut={() => {
        signOut();
        setState({ kind: 'signedOut' });
      }}
    >
      {page === 'verification' ? <VerificationRequestsPage /> : <AiWorkflowsPage />}
    </AdminLayout>
  );
}
