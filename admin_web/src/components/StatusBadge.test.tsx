import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { StatusBadge } from './StatusBadge';

describe('StatusBadge', () => {

  it('displays Pending when verification status is Unverified', () => {
    render(<StatusBadge status="Unverified" />);

    expect(screen.getByText('Pending')).toBeInTheDocument();
  });

  it('displays Verified when verification status is Verified', () => {
    render(<StatusBadge status="Verified" />);

    expect(screen.getByText('Verified')).toBeInTheDocument();
  });

  it('displays Rejected when verification status is Rejected', () => {
    render(<StatusBadge status="Rejected" />);

    expect(screen.getByText('Rejected')).toBeInTheDocument();
  });

});