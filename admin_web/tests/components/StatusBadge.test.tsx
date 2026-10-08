// Verification status badge (src/components/StatusBadge.tsx).
import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { StatusBadge } from '../../src/components/StatusBadge';

describe('StatusBadge', () => {
  it.each([
    ['Unverified', 'Pending', 'badge-unverified'],
    ['Verified', 'Verified', 'badge-verified'],
    ['Rejected', 'Rejected', 'badge-rejected'],
  ] as const)('%s is shown as "%s"', (status, label, className) => {
    render(<StatusBadge status={status} />);
    expect(screen.getByText(label)).toHaveClass('badge', className);
  });
});
