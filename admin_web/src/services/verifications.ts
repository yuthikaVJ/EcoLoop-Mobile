import { apiRequest } from './api';

export type VerificationStatus = 'Unverified' | 'Verified' | 'Rejected';
export type StatusFilter = VerificationStatus | 'all';

export interface AdminUser {
  id: string;
  name: string;
  email: string;
}

export interface VerificationRequest {
  id: string;
  businessName: string;
  businessType: string;
  registrationNumber: string;
  bio?: string | null;
  description?: string | null;
  email: string;
  phone: string;
  address: string;
  websiteUrl?: string | null;
  logoUrl?: string | null;
  coverPhotoUrl?: string | null;
  isVerified: boolean;
  status: VerificationStatus;
  verificationNote?: string | null;
  verifiedAt?: string | null;
  createdAt: string;
  updatedAt?: string | null;
  ownerName?: string | null;
  ownerEmail?: string | null;
}

export interface VerificationSummary {
  pending: number;
  verified: number;
  rejected: number;
}

const base = '/api/admin/business-verifications';

export const getAdminMe = () => apiRequest<AdminUser>('/api/admin/me');

export const getSummary = () => apiRequest<VerificationSummary>(`${base}/summary`);

export function getRequests(status: StatusFilter, search: string) {
  const query = new URLSearchParams({ status });
  if (search.trim()) query.set('search', search.trim());
  return apiRequest<VerificationRequest[]>(`${base}?${query}`);
}

export const approve = (id: string) =>
  apiRequest<VerificationRequest>(`${base}/${id}/approve`, { method: 'POST' });

export const reject = (id: string, reason: string) =>
  apiRequest<VerificationRequest>(`${base}/${id}/reject`, {
    method: 'POST',
    body: JSON.stringify({ reason }),
  });
