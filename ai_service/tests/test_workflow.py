"""Workflow orchestrator (app/workflow.py): runs agents 1-4 in order, applies the
deterministic checks between them, reports progress states and always ends in an
explained outcome. Golden cases from the spec are in test_golden_cases.py."""

from app.schemas import Compatibility, PostType, WorkflowOutcome
from app.workflow import run_workflow

from .fakes import FakeBackend, FakeLlm, post

HAVE, NEED = PostType.I_HAVE, PostType.I_NEED


def run(trigger, candidates, llm=None, **backend_args):
    backend = FakeBackend(trigger, candidates, **backend_args)
    return run_workflow("wf-1", llm or FakeLlm(), backend), backend


def agents_called(result):
    return [c["agent"] for c in result.trace["llmCalls"] if c]


def test_a_full_run_uses_all_four_agents_in_order():
    result, backend = run(post("t", HAVE, "PET"), [post("n1", NEED, "PET")])

    assert result.outcome == WorkflowOutcome.MATCHES
    assert agents_called(result) == ["materialUnderstanding", "requirementMatching", "requirementMatching",
                                     "logistics", "matchEvaluation"]
    assert backend.states == ["ANALYZING", "CANDIDATES_FOUND", "VALIDATING"]
    assert set(result.trace["agents"]) == {"materialUnderstanding", "requirementMatching", "logistics", "matchEvaluation"}


def test_an_unclear_post_stops_after_agent_1():
    result, backend = run(post("t", HAVE, "Stuff"), [post("n1", NEED, "PET")], llm=FakeLlm(ambiguous=True))

    assert result.outcome == WorkflowOutcome.NEEDS_INFO
    assert agents_called(result) == ["materialUnderstanding"]
    assert backend.searches == []


def test_a_post_without_a_numeric_quantity_needs_more_information():
    result, _ = run(post("t", HAVE, "PET", quantity="lots"), [post("n1", NEED, "PET")])

    assert result.outcome == WorkflowOutcome.NEEDS_INFO
    assert "numeric quantity" in result.reason


def test_no_other_posts_stops_after_agent_2_with_a_clear_reason():
    result, _ = run(post("t", NEED, "PET"), [])

    assert result.outcome == WorkflowOutcome.NO_MATCH
    assert result.reason.startswith("No other users have matching I HAVE posts yet.")
    assert "logistics" not in agents_called(result)


def test_shortlist_puts_exact_material_first_and_is_limited():
    candidates = [post(f"n{i}", NEED, "PET", quantity=str(100 + i)) for i in range(8)]
    llm = FakeLlm(compatibility={"n7": Compatibility.RELATED})

    result, _ = run(post("t", HAVE, "PET", quantity="1000"), candidates, llm=llm)

    distances = result.trace["agents"]["logistics"]["distancesKm"]
    assert len(distances) == 5  # max shortlist
    assert "n7" not in distances  # RELATED ranks after the EXACT ones


def test_matches_are_sorted_by_score():
    llm = FakeLlm(evaluation={"n1": {"matchScore": 0.6}, "n2": {"matchScore": 0.95}})

    result, _ = run(post("t", HAVE, "PET"), [post("n1", NEED, "PET"), post("n2", NEED, "PET")], llm=llm)

    assert [m.candidateId for m in result.matches] == ["n2", "n1"]


def test_trace_records_tool_calls_and_validator_decisions():
    result, _ = run(post("t", HAVE, "PET"), [post("n1", NEED, "PET")])

    matching_calls = [c for c in result.trace["llmCalls"] if c and c["agent"] == "requirementMatching"]
    assert matching_calls[0]["toolCalls"][0]["tool"] == "search_candidates"
    assert result.trace["agents"]["matchEvaluation"]["validatorDecisions"] == {"n1": "recommended"}


def test_the_trace_never_contains_post_text():
    secret = "call me on 0771234567"
    result, _ = run(post("t", HAVE, "PET"), [post("n1", NEED, "PET", description=secret)])

    assert secret not in str(result.trace)


def test_backend_unreachable_at_start_is_a_safe_failure():
    result, _ = run(post("t", HAVE, "PET"), [], fail_on="get_post")

    assert result.outcome == WorkflowOutcome.FAILED
    assert result.matches == []
