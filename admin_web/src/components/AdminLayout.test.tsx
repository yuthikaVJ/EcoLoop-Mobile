import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { AdminLayout } from './AdminLayout';

const admin = { id: 'admin-test', name: 'Test Admin', email: 'admin@example.test' };

describe('Admin layout navigation', () => {
  it('RT-40: emits page navigation and marks the current admin section', async () => {
    const user = userEvent.setup();
    const onNavigate = vi.fn();
    const props = { admin, onNavigate, onSignOut: vi.fn(), children: <p>Page content</p> };
    const view = render(<AdminLayout {...props} page="verification" />);
    expect(screen.getByRole('button', { name: 'Business verification' })).toHaveAttribute('aria-current', 'page');
    await user.click(screen.getByRole('button', { name: 'AI matching' }));
    expect(onNavigate).toHaveBeenLastCalledWith('ai');
    view.rerender(<AdminLayout {...props} page="ai" />);
    expect(screen.getByRole('button', { name: 'AI matching' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByRole('button', { name: 'Business verification' })).not.toHaveAttribute('aria-current');
    await user.click(screen.getByRole('button', { name: 'Business verification' }));
    expect(onNavigate).toHaveBeenLastCalledWith('verification');
  });

  it('RT-41: dispatches sign out for the displayed admin without navigating', async () => {
    const user = userEvent.setup();
    const onSignOut = vi.fn();
    const onNavigate = vi.fn();
    render(<AdminLayout admin={admin} page="verification" onNavigate={onNavigate} onSignOut={onSignOut}><p>Protected content</p></AdminLayout>);
    expect(screen.getByText(admin.email)).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Sign out' }));
    expect(onSignOut).toHaveBeenCalledTimes(1);
    expect(onNavigate).not.toHaveBeenCalled();
  });
});
