"""Scripted stand-ins for Gemini and the backend, so golden cases run offline."""

import json
import re

import httpx

from app.llm import LlmCall, LlmUnavailable
from app.schemas import (
    CandidateAssessment,
    Compatibility,
    EvaluationLlmOutput,
    LogisticsAssessment,
    LogisticsLlmOutput,
    MatchEvaluation,
    MatchingLlmOutput,
    MaterialProfileLlm,
    Post,
    PostType,
)


def post(id: str, type: PostType, title: str, quantity="500", unit="Kgs", category="Plastics", **extra) -> Post:
    return Post(id=id, type=type, title=title, category=category, quantity=quantity, unit=unit,
                location=extra.pop("location", "Colombo"), deliveryMethod="Self Pickup", **extra)


class FakeBackend:
    def __init__(self, trigger: Post, candidates: list[Post], distances: dict | None = None,
                 fail_on: str | None = None):
        self.trigger, self.candidates = trigger, candidates
        self.distances = distances or {}
        self.fail_on = fail_on
        self.states: list[str] = []
        self.searches: list[list[str]] = []

    def _maybe_fail(self, name: str):
        if self.fail_on == name:
            raise httpx.ConnectError("backend down")

    def get_post(self) -> Post:
        self._maybe_fail("get_post")
        return self.trigger

    def search_candidates(self, categories: list[str]) -> list[Post]:
        self._maybe_fail("search")
        self.searches.append(categories)
        return [c for c in self.candidates if c.category in categories]

    def get_distance_km(self, candidate_id: str) -> float | None:
        self._maybe_fail("distance")
        return self.distances.get(candidate_id, 12.0)

    def report_state(self, state: str, note: str | None = None) -> None:
        self.states.append(state)


class FakeLlm:
    """Behaves like a well-instructed model by default; every answer can be overridden
    to simulate a confused, compromised or broken model."""

    def __init__(self, ambiguous: bool = False, compatibility: dict | None = None,
                 evaluation: dict | None = None, extra_ids: list[str] | None = None,
                 search: bool = True, broken: bool = False):
        self.ambiguous = ambiguous
        self.compatibility = compatibility or {}
        self.evaluation = evaluation or {}
        self.extra_ids = extra_ids or []
        self.search = search
        self.broken = broken
        self.prompts: list[str] = []

    @staticmethod
    def _ids(prompt: str) -> list[str]:
        return list(dict.fromkeys(re.findall(r'"(?:id|candidateId)": "([^"]+)"', prompt)))

    def structured(self, system, prompt, schema):
        self.prompts.append(prompt)
        if self.broken:
            raise LlmUnavailable("Model returned malformed output twice.")
        call = LlmCall(model="fake", seconds=0.0)
        if schema is MaterialProfileLlm:
            return MaterialProfileLlm(material="PET plastic bottles", materialFamily="PET plastic", form="bottles",
                                      isAmbiguous=self.ambiguous,
                                      ambiguityReason="Material not stated." if self.ambiguous else None), call
        if schema is MatchingLlmOutput:
            ids = self._ids(prompt.split("Candidates:")[1]) + self.extra_ids
            return MatchingLlmOutput(assessments=[
                CandidateAssessment(candidateId=i, materialCompatibility=self.compatibility.get(i, Compatibility.EXACT),
                                    explanation="Same material.") for i in ids]), call
        if schema is LogisticsLlmOutput:
            ids = self._ids(prompt.split("Pairs:")[1])
            return LogisticsLlmOutput(assessments=[
                LogisticsAssessment(candidateId=i, logisticsFeasible=True, warnings=[]) for i in ids]), call
        if schema is EvaluationLlmOutput:
            evidence = json.loads(prompt.split("\n", 1)[1])
            return EvaluationLlmOutput(evaluations=[
                MatchEvaluation(**{"candidateId": e["candidateId"], "match": True, "matchScore": 0.92,
                                   "reasons": ["Material type matches", "Quantity is available"],
                                   "warnings": [], "requiredAction": "USER_APPROVAL",
                                   **self.evaluation.get(e["candidateId"], {})})
                for e in evidence]), call
        raise AssertionError(f"unexpected schema {schema}")

    def with_tools(self, system, prompt, tools):
        call = LlmCall(model="fake", seconds=0.0)
        if self.search:
            tool = next(t for t in tools if t.name == "search_candidates")
            tool.run({"categories": ["Plastics"]})
            call.tool_calls.append({"tool": "search_candidates", "args": {"categories": ["Plastics"]}})
        return "DONE", call


class ScriptedLlm:
    """For single-agent tests: returns the given answer for each output schema and
    performs the given tool calls, recording every prompt it was sent."""

    def __init__(self, answers: dict | None = None, tool_calls: list[tuple[str, dict]] | None = None):
        self.answers = answers or {}
        self.tool_calls = tool_calls or []
        self.structured_calls: list[tuple[str, str, type]] = []
        self.tool_results: list = []
        self.tools_offered: list[list[str]] = []

    def structured(self, system, prompt, schema):
        self.structured_calls.append((system, prompt, schema))
        answer = self.answers[schema]
        return (answer(prompt) if callable(answer) else answer), LlmCall(model="scripted", seconds=0.0)

    def with_tools(self, system, prompt, tools):
        self.tools_offered.append([t.name for t in tools])
        call = LlmCall(model="scripted", seconds=0.0)
        by_name = {t.name: t for t in tools}
        for name, args in self.tool_calls:
            tool = by_name.get(name)
            try:
                result = tool.run(args) if tool else {"error": f"Tool '{name}' is not allowed."}
            except ValueError as error:
                result = {"error": str(error)}
            self.tool_results.append(result)
            call.tool_calls.append({"tool": name, "args": args})
        return "DONE", call
