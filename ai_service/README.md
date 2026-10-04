# EcoLoop Agentic AI – Material Matching Service

Python (FastAPI) service that runs the four-agent matching workflow from
`EcoLoop_Agentic_AI_Material_Matching_Workflow.md`. It finds opposite-side
matches for I HAVE / I NEED posts and returns **recommendations only**:
the ASP.NET backend re-validates them and the user decides.

```
Flutter / React ──► ASP.NET Core API ──► Python AI service ──► Gemini
                          ▲                    │
                          └── allow-listed tool calls (internal API, shared secret)
```

Flutter and React never call this service; only the backend does.

## Run it

```sh
cd ai_service
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt   # Windows (use .venv/bin on macOS/Linux)
cp .env.example .env    # then fill in GEMINI_API_KEY and AI_SERVICE_KEY
.venv/Scripts/python -m uvicorn app.main:app --port 8000
```

`AI_SERVICE_KEY` must equal `AiService__ApiKey` in `backend/.env`, and
`backend/.env` needs `AiService__BaseUrl=http://localhost:8000`.
Health check: `GET http://localhost:8000/health`.

## The workflow

| Step | Agent / code | Uses the LLM for | Tools (allow-list) |
| --- | --- | --- | --- |
| 1 | Material Understanding | Normalizing the material; flagging ambiguity | none |
| 2 | Requirement Matching | Choosing which categories to search; judging material fit (EXACT / RELATED / INCOMPATIBLE / UNCLEAR) | `search_candidates` |
| – | Deterministic code | Quantity parsing, kg↔t conversion, coverage, opposite-type check, shortlist (max 5) | – |
| 3 | Location & Logistics | Practicality given distance, delivery method, timing | `get_distance` |
| 4 | Match Evaluation | Score, reasons, warnings | none |
| – | Deterministic validators | Final say on what may reach users | – |

The backend tracks the spec's states: `MATCHING → ANALYZING → CANDIDATES_FOUND →
VALIDATING → MATCH_READY → USER_APPROVAL → CONNECTED`, or `SAFE_FAILURE` with an
outcome (`NO_MATCH`, `NEEDS_INFO`, `FAILED`) and a reason. Every run's state
history and agent trace is stored and shown in the admin web (**AI matching**).

## Safety rules (enforced in code, not prompts)

- Quantities, units and post types come from the database and are compared by
  code; the LLM never does the arithmetic (`app/validators.py`).
- `requiredAction` must be `USER_APPROVAL`; anything else is rejected.
- Agents can only reference posts their tools returned (hallucinated ids are dropped).
- Tools are scoped to one running workflow; the backend re-checks eligibility
  (active, opposite type, not the requester's own posts) on every call and
  again when results come back.
- Post text is wrapped in `<untrusted_post>` tags as escaped JSON, so text in a
  post can't close the tag or act as instructions.
- Only the minimum post data is sent to the model: no names, emails or phones.
- Any model outage, malformed output or backend error ends in `SAFE_FAILURE`
  with a reason – never an invented match.
- The AI never connects users: only the user's **Connect** tap starts a chat.

## Design decisions (differences from the spec)

- **Partial quantity** – a smaller offer is still suggested, but its score is
  capped (`0.4 + 0.5 × coverage`) and it carries a "Covers N% of the requested
  quantity" warning, so it is never presented as a full match.
- **Distance** – never blocks a match; it lowers the score and adds a warning.
  Distances come from the backend's free OpenStreetMap routing (no Google key).
- **Connect** – opens the listing chat with an intro message and notifies the
  other owner. Each owner decides independently; "Not interested" is remembered.
- **Models** – `GEMINI_MODELS` is a fallback list; a busy, rate-limited or
  retired model hands over to the next. `GEMINI_THINKING_LEVEL=low` makes
  answers ~3× faster on these structured tasks.

## Evaluation

```sh
.venv/Scripts/python -m pytest                 # 17 offline golden cases (scripted model)
.venv/Scripts/python -m evals.run_golden_eval  # live golden cases against real Gemini
```

The live run writes `evals/results.md`. Verdicts are decided by deterministic
checks (no LLM judge), and a model outage is reported as **ERROR**, never as a
pass. Each workflow makes about 5 model calls, so the Gemini free tier's daily
quota is used up quickly while testing; for production use enable billing on
the Google AI Studio project.
