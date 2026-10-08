# EcoLoop — Member 1 React test inventory

Kirindigoda I.C · IT24102492 · SE3110 · Branch: `se3110-react-testing`

Final execution: **50/50 Vitest tests (12 files), 2/2 Playwright tests; 52/52 overall.**

25 new tests: RT-26–RT-50. Existing RT-01–RT-25 and E2E-01–E2E-02 are unchanged.

Evidence: `react-test-results.log` and `playwright-test-results.log` (actual execution output; ignored by existing `*.log` rule).

AI cases cover the React audit UI only. E2E-02 uses controlled API responses and a test-only session; it does not prove real Google login, backend authorization, database persistence, or cross-system integration.

No confirmed production defects were discovered by the newly implemented tests. No production or configuration changes. No staging, commit or push.

## Status labels

Files: `src/components/StatusBadge.test.tsx`

3 cases · 3 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-01 | StatusBadge | displays Pending when verification status is Unverified | Unverified status is displayed as Pending. | Same as expected. | PASS |
| RT-02 | StatusBadge | displays Verified when verification status is Verified | Verified status is displayed as Verified. | Same as expected. | PASS |
| RT-03 | StatusBadge | displays Rejected when verification status is Rejected | Rejected status is displayed as Rejected. | Same as expected. | PASS |

## Rejection form and input boundaries

Files: `src/components/RejectDialog.test.tsx`, `src/components/RejectDialog.boundaries.test.tsx`

8 cases · 8 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-04 | RejectDialog | displays the business name in the rejection dialog | The rejection dialog identifies the business by name. | Same as expected. | PASS |
| RT-05 | RejectDialog | disables Reject when the reason is empty or too short | Reject is disabled for an empty reason and a two-character reason. | Same as expected. | PASS |
| RT-06 | RejectDialog | enables Reject when a valid reason is entered | A valid rejection reason enables Reject. | Same as expected. | PASS |
| RT-07 | RejectDialog | fills the textarea when a quick reason is selected | Selecting a quick reason fills the reason field with that text. | Same as expected. | PASS |
| RT-08 | RejectDialog | sends the trimmed reason when Reject is clicked | Confirmation receives the rejection reason without surrounding whitespace. | Same as expected. | PASS |
| RT-09 | RejectDialog | disables actions and displays Rejecting when busy | Busy state disables Cancel and Reject and displays Rejecting. | Same as expected. | PASS |
| RT-45 | RejectDialog | rejects whitespace-only input and accepts exactly three trimmed characters | Whitespace-only input cannot submit; exactly three trimmed characters enable submission and are sent trimmed. | Same as expected. | PASS |
| RT-46 | RejectDialog | limits a pasted rejection reason to 500 characters | Pasting 501 characters retains and submits only the 500-character maximum. | Same as expected. | PASS |

## Verification requests and review error handling

Files: `src/pages/VerificationRequestsPage.test.tsx`, `src/pages/VerificationRequestsPage.errors.test.tsx`

11 cases · 11 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-10 | Verification requests | displays loading state before verification requests are loaded | Loading is visible before the debounced response; the empty result then appears. | Same as expected. | PASS |
| RT-11 | Verification requests | displays verification requests returned by the API | The returned business name and registration number appear in the list and details, with Pending status. | Same as expected. | PASS |
| RT-12 | Verification requests | displays an empty message when there are no pending requests | An empty pending response displays No pending requests. All caught up! | Same as expected. | PASS |
| RT-13 | Verification requests | displays an error message when loading verification requests fails | A failed verification-list request displays the service error. | Same as expected. | PASS |
| RT-14 | Verification requests | loads verified requests when the Verified tab is clicked | Verified selection requests Verified data, renders the updated count, and shows the empty result. | Same as expected. | PASS |
| RT-15 | Verification requests | searches verification requests when the user enters a search term | Typing a search term requests that term after the debounce and renders the returned business. | Same as expected. | PASS |
| RT-16 | Verification requests | approves a pending business when the Approve button is clicked | Approve calls the service with the selected ID and displays the verified success toast. | Same as expected. | PASS |
| RT-17 | Verification requests | rejects a pending business with a rejection reason | Reject submits the selected ID and entered reason and displays the rejected success toast. | Same as expected. | PASS |
| RT-42 | Verification requests | preserves the pending business and restores actions when approval fails | Approval failure shows an error, preserves the pending business, restores actions, and emits no success toast or reload. | Same as expected. | PASS |
| RT-43 | Verification requests | preserves the rejection reason for retry when rejection fails | Rejection failure preserves the dialog and reason for retry, re-enables Reject, and emits no success toast or reload. | Same as expected. | PASS |
| RT-44 | Verification requests | cancels a review dialog without rejecting or reloading the business | Cancel closes the rejection dialog while preserving the business, without rejecting or reloading. | Same as expected. | PASS |

## Login UI and dependency failures

Files: `src/pages/LoginPage.test.tsx`, `src/pages/LoginPage.errors.test.tsx`

6 cases · 6 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-18 | LoginPage | displays the Google sign-in button when Google authentication is ready | Google readiness enables the Sign in with Google button. | Same as expected. | PASS |
| RT-19 | LoginPage | signs in successfully using the Google authorization code | The selected authorization code is passed to backend sign-in and onSignedIn is called once. | Same as expected. | PASS |
| RT-20 | LoginPage | displays an error message when Google sign-in fails | Google cancellation displays its error; backend sign-in and onSignedIn are not called. | Same as expected. | PASS |
| RT-21 | LoginPage | displays a notice message provided to the login page | The supplied login notice appears and the ready sign-in button is enabled. | Same as expected. | PASS |
| RT-47 | LoginPage | reports Google initialization failure and keeps sign-in disabled | Google initialization failure displays its error and keeps sign-in disabled without starting authentication. | Same as expected. | PASS |
| RT-48 | LoginPage | reports backend code-exchange failure without completing sign-in | Backend code-exchange failure displays its error, restores the sign-in button, and does not complete sign-in. | Same as expected. | PASS |

## Application authentication and access control

Files: `src/App.test.tsx`

4 cases · 4 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-22 | App | shows the login page when no authentication token exists | No token displays the mocked login page without requesting admin validation. | Same as expected. | PASS |
| RT-23 | App | shows the admin interface when a valid authenticated admin session exists | A valid mocked admin session displays the admin layout and identity; validation occurs once. | Same as expected. | PASS |
| RT-24 | App | denies access when the authenticated user is not an EcoLoop admin | A mocked 403 clears the session, shows the non-admin notice, and hides the admin layout. | Same as expected. | PASS |
| RT-25 | App | returns the user to the login page when the authentication token is invalid or expired | A mocked 401 clears the session and returns to login without the admin layout. | Same as expected. | PASS |

## AI workflow audit UI

Files: `src/pages/AiWorkflowsPage.test.tsx`

10 cases · 10 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-26 | AI workflow UI | disables refresh while the initial workflow request is pending | While the initial list promise is pending, Loading appears and Refresh is disabled; completion re-enables Refresh. | Same as expected. | PASS |
| RT-27 | AI workflow UI | shows an empty audit view without requesting details for an empty list | An empty all-state response shows both empty prompts and makes no detail request. | Same as expected. | PASS |
| RT-28 | AI workflow UI | automatically opens the first run with outcome, duration and state history | The first run opens automatically and shows its outcome, suggestion count, 1m 5s duration, and history note. | Same as expected. | PASS |
| RT-29 | AI workflow UI | filters awaiting-user runs and clears details when none match | Awaiting user requests USER_APPROVAL; an empty result clears the previous selected details. | Same as expected. | PASS |
| RT-30 | AI workflow UI | opens a different selected run and displays its details | Selecting the second row requests its ID and replaces details with that run, including I NEED. | Same as expected. | PASS |
| RT-31 | AI workflow UI | recovers from a list error when Refresh succeeds | An initial list failure is displayed; a successful Refresh clears the error and loads the first run. | Same as expected. | PASS |
| RT-32 | AI workflow UI | reports a selected-run failure while retaining the previous details | A failed request for another run displays the error while preserving the previously loaded details. | Same as expected. | PASS |
| RT-33 | AI workflow UI | renders non-null agent calls, fallback tools and validator decisions | Null agent-call entries are skipped; the real call shows model, timing, fallback tool arguments and validator decision. | Same as expected. | PASS |
| RT-34 | AI workflow UI | displays safe-failure reasons and trace errors without an agent table | A failed safe-failure run displays its reason, FAILED outcome and trace error without an empty agent table. | Same as expected. | PASS |
| RT-35 | AI workflow UI | presents an unfinished run as running with no agent trace | An incomplete run displays running, a matching-state badge and zero suggestions, without an agent table. | Same as expected. | PASS |

## Business details and status-specific actions

Files: `src/components/RequestDetails.test.tsx`

4 cases · 4 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-36 | RequestDetails | offers revocation instead of approval for a verified business | Verified businesses hide Approve and dispatch the rejection callback through Revoke verification. | Same as expected. | PASS |
| RT-37 | RequestDetails | shows the rejection note and allows a rejected business to be approved | Rejected businesses show the rejection note, hide Reject, and can dispatch Approve. | Same as expected. | PASS |
| RT-38 | RequestDetails | prevents both review callbacks while a save is busy | Busy state disables both actions; attempted clicks do not invoke either callback. | Same as expected. | PASS |
| RT-39 | RequestDetails | displays supplied website, owner and descriptive business information | Website URL, new-tab/noreferrer attributes, owner identity, bio and description match the supplied business. | Same as expected. | PASS |

## Admin navigation and sign-out dispatch

Files: `src/components/AdminLayout.test.tsx`

2 cases · 2 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-40 | AdminLayout | emits page navigation and marks the current admin section | Navigation emits ai and verification; rerendering the selected page updates aria-current correctly. | Same as expected. | PASS |
| RT-41 | AdminLayout | dispatches sign out for the displayed admin without navigating | The displayed admin can dispatch Sign out once without invoking navigation. | Same as expected. | PASS |

## HTTP client session refresh

Files: `src/services/api.test.ts`

2 cases · 2 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| RT-49 | API client | refreshes an expired session and retries with the replacement bearer token | A 401 triggers one refresh POST; replacement tokens are saved and the original request retries with the new Bearer token. | Same as expected. | PASS |
| RT-50 | API client | clears both tokens and exposes the original API error when refresh is rejected | Rejected refresh clears both tokens and exposes the original 401 ApiError without retrying the protected request. | Same as expected. | PASS |

## Playwright browser workflows

File: `e2e/admin-verification.spec.ts` · Installed Google Chrome · 2 passed · 0 failed

| Test ID | Module | Test Case | Expected Result | Actual Result | Status |
|---|---|---|---|---|---|
| E2E-01 | Admin browser UI | loads the EcoLoop admin application | At localhost:5173 the page body is visible and the EcoLoop Admin login heading is rendered. | Same as expected. | PASS |
| E2E-02 | Admin browser UI | admin approves a pending business verification | A test-only session validates through controlled /api/admin/me; details appear, exactly one approval POST uses the correct ID and Bearer header, a success toast and refreshed counts appear, Pending clears, and Verified shows the business without Approve. | Same as expected. | PASS |
