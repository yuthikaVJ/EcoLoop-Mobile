// Admin layout (src/components/AdminLayout.tsx): top bar, section tabs, sign out.
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { AdminLayout } from '../../src/components/AdminLayout';

const admin = { id: 'a1', name: 'Haritha', email: 'harithageemal238@gmail.com' };

describe('AdminLayout', () => {
  it('shows the signed-in admin and the current section', () => {
    render(
      <AdminLayout admin={admin} page="verification" onNavigate={() => {}} onSignOut={() => {}}>
        <p>page content</p>
      </AdminLayout>,
    );
    expect(screen.getByText('harithageemal238@gmail.com')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Business verification' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByText('page content')).toBeInTheDocument();
  });

  it('switches sections and signs out', async () => {
    const onNavigate = vi.fn();
    const onSignOut = vi.fn();
    const user = userEvent.setup();
    render(
      <AdminLayout admin={admin} page="verification" onNavigate={onNavigate} onSignOut={onSignOut}>
        <p />
      </AdminLayout>,
    );

    await user.click(screen.getByRole('button', { name: 'AI matching' }));
    await user.click(screen.getByRole('button', { name: 'Sign out' }));

    expect(onNavigate).toHaveBeenCalledWith('ai');
    expect(onSignOut).toHaveBeenCalledOnce();
  });
});
