import { test, expect } from '@playwright/test';

test.describe('EcoLoop Admin Verification E2E', () => {
  test('E2E-01: loads the EcoLoop admin application', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveURL(/localhost:5173/);

    await expect(page.locator('body')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'EcoLoop Admin' })).toBeVisible();
  });

  // Frontend browser coverage with controlled API responses, not backend integration.
  test('E2E-02: admin approves a pending business verification', async ({ page }) => {
    const token = 'ecoloop-e2e-test-only-token';
    const admin = {
      id: '00000000-0000-4000-8000-000000000001',
      name: 'EcoLoop E2E Admin',
      email: 'admin@ecoloop-e2e.example',
    };
    const pendingBusiness = {
      id: '00000000-0000-4000-8000-000000000002',
      businessName: 'EcoLoop E2E Recycling',
      businessType: 'Recycling',
      registrationNumber: 'E2E-PV-001',
      email: 'business@ecoloop-e2e.example',
      phone: '0770000000',
      address: '1 Test Road, Colombo, Sri Lanka',
      bio: 'Test-only recycling business',
      description: 'Controlled fixture for the admin approval browser workflow.',
      websiteUrl: null,
      logoUrl: null,
      coverPhotoUrl: null,
      isVerified: false,
      status: 'Unverified',
      verificationNote: null,
      verifiedAt: null,
      createdAt: '2026-10-01T10:00:00Z',
      updatedAt: '2026-10-01T10:00:00Z',
      ownerName: 'E2E Business Owner',
      ownerEmail: 'owner@ecoloop-e2e.example',
    };
    const approvedBusiness = {
      ...pendingBusiness,
      isVerified: true,
      status: 'Verified',
      verifiedAt: '2026-10-08T10:00:00Z',
      updatedAt: '2026-10-08T10:00:00Z',
    };
    const base = '/api/admin/business-verifications';
    const approvalPath = `${base}/${pendingBusiness.id}/approve`;
    let approved = false;
    let approvalCount = 0;

    // The frontend treats the access token as opaque; no Google login or real JWT is needed.
    await page.addInitScript((accessToken) => {
      localStorage.setItem('ecoloop_admin_token', accessToken);
    }, token);

    await page.route('**/api/admin/**', async (route) => {
      const request = route.request();
      const url = new URL(request.url());
      expect(request.headers().authorization).toBe(`Bearer ${token}`);

      if (url.pathname === '/api/admin/me' && request.method() === 'GET') {
        await route.fulfill({ json: admin });
      } else if (url.pathname === `${base}/summary` && request.method() === 'GET') {
        await route.fulfill({
          json: { pending: approved ? 0 : 1, verified: approved ? 1 : 0, rejected: 0 },
        });
      } else if (url.pathname === base && request.method() === 'GET') {
        const status = url.searchParams.get('status');
        expect(['Unverified', 'Verified']).toContain(status);
        const business = approved ? approvedBusiness : pendingBusiness;
        await route.fulfill({ json: status === business.status ? [business] : [] });
      } else if (url.pathname === approvalPath && request.method() === 'POST') {
        approvalCount += 1;
        approved = true;
        await route.fulfill({ json: approvedBusiness });
      } else {
        // Unexpected admin API calls must not reach a real backend.
        await route.abort();
        throw new Error(`Unexpected admin API request: ${request.method()} ${url.pathname}`);
      }
    });

    const sessionResponse = page.waitForResponse((response) =>
      new URL(response.url()).pathname === '/api/admin/me' && response.request().method() === 'GET'
    );
    await page.goto('/');
    expect((await sessionResponse).status()).toBe(200);
    await expect(page.getByRole('heading', { name: 'Business verification' })).toBeVisible();
    await expect(page.getByText(admin.email, { exact: true })).toBeVisible();

    const requests = page.getByRole('region', { name: 'Requests', exact: true });
    const details = page.getByRole('region', { name: 'Request details', exact: true });
    const filters = page.getByRole('navigation', { name: 'Filter by status' });
    const businessRow = requests.getByRole('button', { name: /EcoLoop E2E Recycling/ });
    await expect(businessRow).toBeVisible();
    await expect(businessRow).toContainText('Pending');
    await businessRow.click();
    await expect(details.getByRole('heading', { name: pendingBusiness.businessName })).toBeVisible();
    await expect(details.getByText(pendingBusiness.registrationNumber, { exact: true })).toBeVisible();
    await expect(details.getByText(pendingBusiness.email, { exact: true })).toBeVisible();
    await expect(details.getByText(pendingBusiness.address, { exact: true })).toBeVisible();
    await expect(filters.getByRole('button', { name: /^Pending/ })).toHaveText('Pending1');
    const approveButton = details.getByRole('button', { name: 'Approve', exact: true });
    await expect(approveButton).toBeEnabled();

    const approvalResponse = page.waitForResponse((response) =>
      new URL(response.url()).pathname === approvalPath && response.request().method() === 'POST'
    );
    await approveButton.click();
    expect((await approvalResponse).status()).toBe(200);
    expect(approvalCount).toBe(1);
    await expect(page.getByRole('status')).toHaveText(`${pendingBusiness.businessName} is now verified.`);
    await expect(requests.getByText('No pending requests. All caught up!', { exact: true })).toBeVisible();
    await expect(businessRow).toHaveCount(0);
    await expect(filters.getByRole('button', { name: /^Pending/ })).toHaveText('Pending0');
    const verifiedTab = filters.getByRole('button', { name: /^Verified/ });
    await expect(verifiedTab).toHaveText('Verified1');

    const verifiedResponse = page.waitForResponse((response) => {
      const url = new URL(response.url());
      return url.pathname === base && url.searchParams.get('status') === 'Verified'
        && response.request().method() === 'GET';
    });
    await verifiedTab.click();
    expect((await verifiedResponse).status()).toBe(200);
    await expect(businessRow).toBeVisible();
    await expect(businessRow).toContainText('Verified');
    await expect(details.getByRole('heading', { name: pendingBusiness.businessName })).toBeVisible();
    await expect(details.getByText('Verified', { exact: true })).toBeVisible();
    await expect(approveButton).toHaveCount(0);
  });
});
