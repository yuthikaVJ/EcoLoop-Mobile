import type { ReactNode } from 'react';
import type { AdminUser } from '../services/verifications';

export type AdminPage = 'verification' | 'ai';

interface Props {
  admin: AdminUser;
  page: AdminPage;
  onNavigate: (page: AdminPage) => void;
  onSignOut: () => void;
  children: ReactNode;
}

const PAGES: { id: AdminPage; label: string }[] = [
  { id: 'verification', label: 'Business verification' },
  { id: 'ai', label: 'AI matching' },
];

export function AdminLayout({ admin, page, onNavigate, onSignOut, children }: Props) {
  return (
    <div className="app">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark small">♻</span>
          <span>EcoLoop Admin</span>
        </div>
        <nav className="topnav" aria-label="Admin sections">
          {PAGES.map((p) => (
            <button
              key={p.id}
              type="button"
              className={`topnav-item ${page === p.id ? 'active' : ''}`}
              aria-current={page === p.id ? 'page' : undefined}
              onClick={() => onNavigate(p.id)}
            >
              {p.label}
            </button>
          ))}
        </nav>
        <div className="topbar-user">
          <span className="muted">{admin.email}</span>
          <button type="button" className="btn" onClick={onSignOut}>
            Sign out
          </button>
        </div>
      </header>
      {children}
    </div>
  );
}
