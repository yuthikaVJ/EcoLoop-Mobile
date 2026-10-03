"""Agent 4 - Match Evaluation: combines the evidence into recommendations."""

import json

from ..llm import Llm, LlmCall
from ..schemas import EvaluationLlmOutput, MatchEvaluation
from ..validators import known_ids

SYSTEM = (
    "You are the Match Evaluation agent of EcoLoop. Combine the evidence for each "
    "candidate pair and decide whether to recommend it to the user. matchScore is 0-1: "
    "material fit matters most, then how much of the requested quantity is covered, "
    "then logistics. Give 1-4 short, factual reasons a user can verify, and warnings "
    "for anything they should check (partial quantity, distance, missing details). "
    "requiredAction must always be USER_APPROVAL: you only recommend; the user decides."
)


class MatchEvaluationAgent:
    tools: list[str] = []  # works only from the evidence the other agents produced

    def __init__(self, llm: Llm):
        self._llm = llm

    def run(self, evidence: list[dict]) -> tuple[dict[str, MatchEvaluation], LlmCall]:
        result, call = self._llm.structured(
            SYSTEM,
            f"Evidence per candidate:\n{json.dumps(evidence, ensure_ascii=False)}",
            EvaluationLlmOutput,
        )
        evaluations = known_ids(result.evaluations, {e["candidateId"] for e in evidence}, "Match evaluation")
        return {e.candidateId: e for e in evaluations}, call
