"""Agent 4 - Match Evaluation (app/agents/match_evaluation.py).

Combines the evidence from agents 1-3 into a score, reasons and warnings per
candidate. It only recommends: the deterministic validators decide what reaches
users (see test_validators.py)."""

import json

import pytest

from app.agents import MatchEvaluationAgent
from app.schemas import EvaluationLlmOutput, MatchEvaluation
from app.validators import ValidationError

from ..fakes import ScriptedLlm

EVIDENCE = [
    {"candidateId": "n1", "materialCompatibility": "EXACT", "quantityCoveragePercent": 100, "roadDistanceKm": 25.0},
    {"candidateId": "n2", "materialCompatibility": "RELATED", "quantityCoveragePercent": 40, "roadDistanceKm": None},
]


def evaluation(cid, score=0.9, action="USER_APPROVAL"):
    return MatchEvaluation(candidateId=cid, match=True, matchScore=score,
                           reasons=["Material type matches"], warnings=[], requiredAction=action)


def test_returns_one_evaluation_per_candidate():
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(
        evaluations=[evaluation("n1", 0.95), evaluation("n2", 0.6)])})

    evaluations, call = MatchEvaluationAgent(llm).run(EVIDENCE)

    assert {k: v.matchScore for k, v in evaluations.items()} == {"n1": 0.95, "n2": 0.6}
    assert call.model == "scripted"


def test_receives_all_the_evidence_from_the_earlier_agents():
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(evaluations=[evaluation("n1")])})

    MatchEvaluationAgent(llm).run(EVIDENCE)

    sent = json.loads(llm.structured_calls[0][1].split("\n", 1)[1])
    assert sent == EVIDENCE


def test_drops_evaluations_of_unknown_candidates():
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(
        evaluations=[evaluation("n1"), evaluation("not-in-evidence")])})

    evaluations, _ = MatchEvaluationAgent(llm).run(EVIDENCE)

    assert list(evaluations) == ["n1"]


def test_rejects_an_answer_only_about_unknown_candidates():
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(evaluations=[evaluation("ghost")])})

    with pytest.raises(ValidationError):
        MatchEvaluationAgent(llm).run(EVIDENCE)


def test_keeps_whatever_action_the_model_asked_for_so_validators_can_reject_it():
    # The agent does not silently "fix" a bad requiredAction; the validator refuses it.
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(evaluations=[evaluation("n1", action="AUTO_CONNECT")])})

    evaluations, _ = MatchEvaluationAgent(llm).run(EVIDENCE)

    assert evaluations["n1"].requiredAction == "AUTO_CONNECT"


def test_system_prompt_requires_user_approval_and_uses_no_tools():
    llm = ScriptedLlm(answers={EvaluationLlmOutput: EvaluationLlmOutput(evaluations=[evaluation("n1")])})

    MatchEvaluationAgent(llm).run(EVIDENCE)

    assert "USER_APPROVAL" in llm.structured_calls[0][0]
    assert MatchEvaluationAgent.tools == []
