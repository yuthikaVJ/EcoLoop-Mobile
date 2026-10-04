# EcoLoop Admin Web

React (Vite + TypeScript) site where EcoLoop admins review Business Hub
verification requests: check each business against the eROC register, then
**Approve** it (the owner can post listings and products as the business) or
**Reject** it with a reason (shown to the owner, who can edit and resubmit).

## Setup

1. Start the backend (`backend/`, http://localhost:5252).
2. Make your Google account an admin. Sign in to the mobile app once so the
   account exists, then in PostgreSQL:

   ```sql
   UPDATE "Businesses" SET "IsAdmin" = true
   WHERE "Email" = 'you@gmail.com' AND "UserId" IS NULL;
   ```

3. The OAuth **Web client** used by the backend (`Authentication__Google__ClientId`)
   must list `http://localhost:5173` under **Authorized JavaScript origins**
   (Google Cloud Console → APIs & Services → Credentials).

   Sign-in opens Google's account chooser in a popup (`select_account`), so you
   can pick any Google account rather than the one the browser uses. The popup
   returns a one-time code that the backend exchanges with Google
   (`POST /api/auth/google-code`, using `Authentication__Google__ClientSecret`).
4. Run the site:

   ```sh
   cd admin_web
   cp .env.example .env   # adjust if your backend URL differs
   npm install
   npm run dev            # http://localhost:5173
   ```

## Structure

- `src/services/` — API client (token refresh), Google account-chooser popup, admin endpoints
- `src/pages/` — login and verification requests pages
- `src/components/` — request details, reject dialog, status badge

The backend endpoints live in `backend/src/Controllers/AdminController.cs` and
require the `Admin` role, which the login token carries when `IsAdmin` is true.
