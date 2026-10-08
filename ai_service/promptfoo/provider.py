"""promptfoo provider for the EcoLoop agentic matching workflow.

Each promptfoo test case describes a marketplace scenario (the post being
matched and the other users' posts). This provider runs the REAL workflow
(app/workflow.py: agents 1-4, allow-listed tools, deterministic validators)
with the REAL Gemini model, answering the agents' tool calls from the scenario
instead of the EcoLoop database. It returns everything the assertions need.

Test-case vars:
  post        the post being matched (type, title, category, quantity, unit, ...)
  candidates  other users' posts the search tool can find
  distances   {candidateId: km | null}   road distances for get_distance
  fail_tool   "get_post" | "search" | "distance"   simulate a backend outage
  models      comma list overriding GEMINI_MODELS; "DEFAULT" expands to it
"""

import json
import sys
import time
from pathlib import Path

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import settings  # noqa: E402
from app.llm import GeminiLlm  # noqa: E402
from app.schemas import Post  # noqa: E402
from app.workflow import run_workflow  # noqa: E402

ALLOWED_TOOLS = ["search_candidates", "get_distance"]
OUTAGE_RETRY_SECONDS = 65


def _post(data: dict, default_id: str) -> Post:
    values = {
        "id": default_id, "category": "Plastics", "quantity": "500", "unit": "Kgs",
        "location": "Colombo", "deliveryMethod": "Self Pickup", "description": "",
    }
    values.update(data or {})
    return Post.model_validate(values)


class ScenarioBackend:
    """Answers the allow-listed tools from the test scenario (no database)."""

    def __init__(self, trigger: Post, candidates: list[Post], distances: dict, fail_tool: str | None):
        self.trigger, self.candidates = trigger, candidates
        self.distances, self.fail_tool = distances, fail_tool
        self.states: list[str] = []
        self.searches: list[list[str]] = []

    def _maybe_fail(self, tool: str) -> None:
        if self.fail_tool == tool:
            raise httpx.ConnectError(f"simulated outage of {tool}")

    def get_post(self) -> Post:
        self._maybe_fail("get_post")
        return self.trigger

    def search_candidates(self, categories: list[str]) -> list[Post]:
        self._maybe_fail("search")
        self.searches.append(categories)
        wanted = {c.lower() for c in categories}
        return [c for c in self.candidates if c.category.lower() in wanted]

    def get_distance_km(self, candidate_id: str) -> float | None:
        self._maybe_fail("distance")
        return self.distances.get(candidate_id, 15.0)

    def report_state(self, state: str, note: str | None = None) -> None:
        self.states.append(state)


def _models(value) -> list[str]:
    if not value:
        return settings.gemini_models
    names = value if isinstance(value, list) else [m.strip() for m in str(value).split(",")]
    expanded: list[str] = []
    for name in names:
        expanded.extend(settings.gemini_models if name == "DEFAULT" else [name])
    return expanded


def _gemini_outage(result, models: list[str]) -> bool:
    """True when real Gemini models were meant to answer but none could (quota,
    overload). Tests that list only non-existent models simulate this on purpose."""
    error = result.trace.get("error") or ""
    uses_real_models = any(m in settings.gemini_models for m in models)
    return uses_real_models and error.startswith("No Gemini model answered") and "NOT_FOUND" not in error


def call_api(prompt: str, options: dict, context: dict) -> dict:
    v = context.get("vars", {})
    trigger = _post(v["post"], "trigger-post")
    candidates = [_post(c, f"candidate-{i + 1}") for i, c in enumerate(v.get("candidates") or [])]
    models = _models(v.get("models"))

    started = time.monotonic()
    for attempt in range(2):
        backend = ScenarioBackend(trigger, candidates, v.get("distances") or {}, v.get("fail_tool"))
        result = run_workflow("promptfoo-eval", GeminiLlm(models=models), backend)
        if not _gemini_outage(result, models):
            break
        if attempt == 0:
            time.sleep(OUTAGE_RETRY_SECONDS)  # per-minute quotas reset
    else:
        # Not a verdict on the workflow: report it as an error so promptfoo
        # neither passes nor fails the case.
        return {"error": f"Gemini unavailable, rerun later: {result.trace['error'][:200]}"}
    calls = [c for c in result.trace.get("llmCalls", []) if c]
    agents = result.trace.get("agents", {})

    output = {
        "outcome": result.outcome.value,
        "reason": result.reason,
        "matches": [m.model_dump() for m in result.matches],
        "agentsRun": list(dict.fromkeys(c["agent"] for c in calls)),
        "toolCalls": [{"agent": c["agent"], **t} for c in calls for t in c["toolCalls"]],
        "allowedTools": ALLOWED_TOOLS,
        "searchedCategories": backend.searches,
        "modelsUsed": [c["model"] for c in calls],
        "states": backend.states,
        "materialUnderstanding": agents.get("materialUnderstanding"),
        "findings": (agents.get("requirementMatching") or {}).get("findings", []),
        "evaluations": (agents.get("matchEvaluation") or {}).get("evaluations", {}),
        "validatorDecisions": (agents.get("matchEvaluation") or {}).get("validatorDecisions", {}),
        "error": result.trace.get("error"),
        "seconds": round(time.monotonic() - started, 1),
    }
    return {"output": json.dumps(output, ensure_ascii=False)}
