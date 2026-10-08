# EcoLoop – Test Suites

Each part of the project has its own test suite, and inside each suite every
feature (mobile), agent (AI service) or screen (admin web) has its **own test
file**, so each group member can show their part on its own.

| Part | Tool | Tests | Run from | Command |
| --- | --- | ---: | --- | --- |
| Mobile app – unit, widget, form validation, navigation, API integration | flutter_test | 140 | `mobile/` | `flutter test` |
| Mobile app – end-to-end on a device | integration_test | 2 | `mobile/` | `flutter test integration_test` |
| AI agentic workflow – behaviour with the real Gemini model | promptfoo | 31 | `ai_service/promptfoo/` | `npm run eval` |
| AI service (Python) | pytest | 126 | `ai_service/` | `.venv/Scripts/python -m pytest -v` |
| Admin web (React) | Vitest + Testing Library | 64 | `admin_web/` | `npm test` |
| Backend (ASP.NET) | xUnit | 55 | `backend.Tests/` | `dotnet test` |

Everything except promptfoo runs offline: no Gemini calls, no database server and
no Google sign-in are needed (the AI model, backend and browser are replaced by
test doubles). promptfoo deliberately calls the real Gemini model.

---

## AI service – `ai_service/tests/`

### One file per agent (`tests/agents/`)

| File | Agent | Tests | What it proves |
| --- | --- | ---: | --- |
| `test_agent1_material_understanding.py` | 1 – Material Understanding | 7 | Normalizes the material; quantity, unit and post type come from the database, not the LLM; ambiguity is reported; only material fields are sent, as untrusted data |
| `test_agent2_requirement_matching.py` | 2 – Requirement Matching | 9 | Searches the categories the model chooses through `search_candidates` only; rejects categories outside the allow-list; falls back to the post's own category; drops posts the tool never returned; caps candidates |
| `test_agent3_logistics.py` | 3 – Location & Logistics | 7 | Gets a distance for each shortlisted post through `get_distance`; routing outages leave distance unknown instead of failing; only location/delivery data is sent |
| `test_agent4_match_evaluation.py` | 4 – Match Evaluation | 6 | Scores every candidate from the earlier agents' evidence; drops unknown candidates; leaves a bad `requiredAction` for the validators to reject |

### One file per supporting part

| File | Part | Tests |
| --- | --- | ---: |
| `test_validators.py` | Deterministic rules: quantities, units (kg↔t), coverage, opposite types, score caps, threshold, user approval | 37 |
| `test_tools.py` | Allow-listed tools: internal API URLs, shared-secret header, category validation | 12 |
| `test_llm.py` | Gemini layer: untrusted-data wrapping, model fallback (503/429/404/timeout), call time limit, thinking-level retry, malformed-output repair, bounded tool loop | 15 |
| `test_workflow.py` | Orchestrator: agents run in order, progress states, early stops, shortlist, audit trace without post text | 9 |
| `test_api.py` | HTTP API: health check, shared-secret protection, result format | 5 |
| `test_golden_cases.py` | The spec's golden cases (section 17), including prompt injection and safe failure | 19 |

Live check against the real Gemini model (uses quota; not part of `pytest`):
`.venv/Scripts/python -m evals.run_golden_eval` → `evals/results.md`.

---

## AI agentic workflow – `ai_service/promptfoo/` (promptfoo)

`provider.py` runs the **real** workflow (agents 1–4, allow-listed tools,
deterministic validators) with the **real Gemini model**. Each test case is a
marketplace scenario: the post being matched plus the other users' posts. The
agents' tool calls are answered from the scenario instead of the database, and
outages can be simulated (`fail_tool`, `models`). One file per test category:

| File | Category | Cases | What it proves |
| --- | --- | ---: | --- |
| `tests/01_task_completion.yaml` | Task completion | 3 | I HAVE ↔ I NEED matches are found, with full coverage and reasons |
| `tests/02_agent_selection.yaml` | Agent selection | 3 | All 4 agents run in order; unclear posts stop after Agent 1; no candidates skips Agents 3–4 |
| `tests/03_tool_selection.yaml` | Tool selection | 4 | Agent 2 searches the right category; Agent 3 asks the distance for exactly the shortlist; only allow-listed tools are used |
| `tests/04_structured_output.yaml` | Structured output | 3 | The result matches a JSON schema; Agent 1's profile and Agent 2's labels are well formed |
| `tests/05_business_rules.yaml` | Business-rule compliance | 6 | Partial-quantity cap + warning, no I HAVE ↔ I HAVE, unit conversion, incomparable units, distance never blocks, missing quantity |
| `tests/06_prompt_injection.yaml` | Prompt injection | 3 | "SYSTEM OVERRIDE" text, fake `</untrusted_post>` tags and self-renaming posts are ignored |
| `tests/07_approval_enforcement.yaml` | Approval enforcement | 3 | Every match needs `USER_APPROVAL`; a post demanding auto-connect cannot skip it; no acting tools exist |
| `tests/08_failure_recovery.yaml` | Failure recovery | 2 | A retired model falls back to the next one; a routing outage still recommends, with a distance warning |
| `tests/09_safe_failure.yaml` | Safe failure | 4 | All models down, search down or post unreadable → `FAILED` with no matches; nothing suitable → an explained no-match |

Results are saved to `promptfoo/results/latest.html` (open in a browser) and
`latest.json`; `npm run view` opens the interactive promptfoo viewer.
The Gemini free tier allows a limited number of calls per minute and per day.
If Gemini is out of quota, the provider waits a minute and retries once; if it is
still unavailable the case is reported as an **error** (not a pass or a fail),
so rerun it later, or run one category at a time (see the commands below).
Only the safe-failure cases simulate an outage on purpose.

---

## Mobile app – `mobile/test/` and `mobile/integration_test/`

Tests are grouped first by **test type**, then by **feature** (one folder per
group member's part).

| Test type | Folder | Tests | Files |
| --- | --- | ---: | --- |
| Unit | `test/unit/` | 40 | `core/app_config_test` (server address, media links), `auth/session_token_test`, `materials_marketplace/material_listing_test`, `sustainable_products/product_test`, `profile/account_profile_test`, `ai_matching/match_suggestion_test`, `transactions_delivery/map_utils_test`, `business_hub/business_profile_test`, `business_hub/image_validator_test` |
| Widget | `test/widget/` | 47 | `materials_marketplace/{material_cards, materials_marketplace_page, my_listing_card}_test`, `ai_matching/matches_page_test`, `business_hub/{business_hub_landing_page, edit_business_profile_widget, post_as_selector}_test`, `shared/{image_carousel, seller_name}_test`, `transactions_delivery/{transactions_delivery, marketplace_integration}_test` |
| Form validation | `test/form_validation/` | 16 | `materials_marketplace/add_material_form_test`, `materials_marketplace/edit_material_form_test`, `profile/profile_form_test`, `business_hub/create_business_profile_form_test` |
| Navigation | `test/navigation/` | 10 | `materials_marketplace/marketplace_navigation_test` (card → details → back, AI Matches, My Listings, Add), `profile/profile_navigation_test` (Request verification / Business Hub), `core/notification_navigation_test` |
| API integration | `test/api_integration/` | 27 | `materials_marketplace/material_listing_repository_test` (auth header, token refresh + retry, multipart photos, status), `ai_matching/matches_repository_test`, `business_hub/business_repository_test`, `profile/profile_repository_test`, `transactions_delivery/component4_api_test` |
| Integration (on a device) | `integration_test/` | 2 | `marketplace_flow_test` – the real app screens, repositories and providers on an emulator or phone, against a fake EcoLoop server: browse I Have / I Need, review an AI match and mark it "Not interested" |

Shared helpers: `test/helpers/fake_server.dart` (fake HTTP server + signed-in
session) and `test/helpers/fakes.dart` (test listings and fake providers).

---

## Admin web – `admin_web/tests/` (mirrors `src/`)

| File | Covers | Tests |
| --- | --- | ---: |
| `services/api.test.ts` | Token handling, automatic refresh, sign-out, error messages | 11 |
| `services/googleAuth.test.ts` | Google account chooser (`select_account`), popup errors | 8 |
| `services/verifications.test.ts` | Verification API calls | 5 |
| `services/aiWorkflows.test.ts` | AI audit API calls | 2 |
| `components/StatusBadge.test.tsx` | Pending / Verified / Rejected labels | 1 (3 cases) |
| `components/RejectDialog.test.tsx` | Reason required, quick reasons, cancel | 6 |
| `components/RequestDetails.test.tsx` | Business details and the right buttons per status | 5 |
| `components/AdminLayout.test.tsx` | Top bar, section tabs, sign out | 2 |
| `pages/LoginPage.test.tsx` | Google sign-in flow and messages | 5 |
| `pages/VerificationRequestsPage.test.tsx` | List, approve, reject with reason, tabs, search | 6 |
| `pages/AiWorkflowsPage.test.tsx` | Runs, the four agents' calls and tools, validator decisions | 6 |
| `pages/App.test.tsx` | Only admins get in; non-admins and outages are explained | 5 |

---

## Backend – `backend.Tests/`

| File | Covers |
| --- | --- |
| `MatchingServiceTests.cs` | AI matching on the server: ownership, tool scoping, re-validation, Connect / Not interested, admin audit |
| `BusinessHubTests.cs` | Business verification and posting as a business |
| `MaterialListingImagesTests.cs` | Multiple photos, editing photos, photo paths that work on every device |
| `MaterialTransactionServiceTests.cs`, `ProductOrderServiceTests.cs`, `Component4EditingTests.cs`, `MarketplaceIntegrationTests.cs` | Transactions and orders |
| `DeliveryRouteTests.cs`, `DeliveryTrackingTests.cs` | Delivery routes and live tracking |

---

## Commands

```bash
# ---- Mobile app (Flutter) – from mobile/ ----
flutter test                                   # all 140 tests
flutter test test/unit                         # unit tests
flutter test test/widget                       # widget tests
flutter test test/form_validation              # form validation tests
flutter test test/navigation                   # navigation tests
flutter test test/api_integration              # API integration tests
flutter test test/widget/ai_matching           # one feature, e.g. AI matching
flutter emulators --launch Pixel_7             # start an emulator first, then:
flutter test integration_test                  # end-to-end on the device

# ---- AI agentic workflow (promptfoo, real Gemini) – from ai_service/promptfoo/ ----
npm install                                    # first time only
npm run eval                                   # all 9 categories (31 cases)
npx promptfoo eval --filter-metadata category=task-completion
npx promptfoo eval --filter-metadata category=agent-selection
npx promptfoo eval --filter-metadata category=tool-selection
npx promptfoo eval --filter-metadata category=structured-output
npx promptfoo eval --filter-metadata category=business-rules
npx promptfoo eval --filter-metadata category=prompt-injection
npx promptfoo eval --filter-metadata category=approval-enforcement
npx promptfoo eval --filter-metadata category=failure-recovery
npx promptfoo eval --filter-metadata category=safe-failure
npm run view                                   # open the results viewer

# ---- AI service (pytest, offline) – from ai_service/ ----
.venv/Scripts/python -m pytest -v

# ---- Admin web – from admin_web/ ----
npm test

# ---- Backend – from the repository root ----
dotnet test backend.Tests
```
