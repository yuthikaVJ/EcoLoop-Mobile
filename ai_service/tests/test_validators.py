"""Deterministic validators (app/validators.py): the rules the LLM can never override."""

import pytest

from app.schemas import CandidateAssessment, Compatibility, MatchEvaluation, PostType
from app.validators import (
    ValidationError,
    check_opposite_types,
    finalize_match,
    known_ids,
    normalize_unit,
    parse_quantity,
    quantity_coverage,
)


def evaluation(**overrides) -> MatchEvaluation:
    values = dict(candidateId="n1", match=True, matchScore=0.9, reasons=["Material matches"],
                  warnings=[], requiredAction="USER_APPROVAL")
    values.update(overrides)
    return MatchEvaluation(**values)


# ---- Quantities and units ------------------------------------------------------------

@pytest.mark.parametrize("raw, expected", [
    ("500", 500.0), ("1,200", 1200.0), ("2.5", 2.5), (" 30 ", 30.0),
    ("about 50", None), ("10-20", None), ("", None), ("0", None), ("-5", None),
])
def test_parse_quantity(raw, expected):
    assert parse_quantity(raw) == expected


@pytest.mark.parametrize("raw, expected", [
    ("Kgs", "kg"), ("kilograms", "kg"), ("Tons", "t"), ("tonnes", "t"),
    ("Units", "units"), ("pcs", "units"), ("Bales", "bales"), ("sacks", "unknown"), ("", "unknown"),
])
def test_normalize_unit(raw, expected):
    assert normalize_unit(raw) == expected


def test_coverage_converts_tons_and_kilograms():
    assert quantity_coverage(1, "t", 300, "kg") == 1.0
    assert quantity_coverage(150, "kg", 0.3, "t") == 0.5


def test_coverage_is_capped_at_100_percent():
    assert quantity_coverage(500, "kg", 300, "kg") == 1.0


def test_coverage_compares_units_and_bales_only_like_for_like():
    assert quantity_coverage(10, "bales", 20, "bales") == 0.5
    assert quantity_coverage(20, "bales", 300, "kg") is None
    assert quantity_coverage(5, "units", 5, "bales") is None


def test_coverage_needs_both_quantities():
    assert quantity_coverage(None, "kg", 300, "kg") is None
    assert quantity_coverage(300, "kg", None, "kg") is None


def test_opposite_types_only():
    check_opposite_types(PostType.I_HAVE, PostType.I_NEED)
    check_opposite_types(PostType.I_NEED, PostType.I_HAVE)
    with pytest.raises(ValidationError):
        check_opposite_types(PostType.I_HAVE, PostType.I_HAVE)


# ---- Agent output checks -------------------------------------------------------------

def assessment(cid):
    return CandidateAssessment(candidateId=cid, materialCompatibility=Compatibility.EXACT, explanation="x")


def test_known_ids_drops_unknown_and_duplicate_entries():
    kept = known_ids([assessment("a"), assessment("ghost"), assessment("a"), assessment("b")], {"a", "b"}, "test")
    assert [k.candidateId for k in kept] == ["a", "b"]


def test_known_ids_rejects_answers_only_about_unknown_posts():
    with pytest.raises(ValidationError):
        known_ids([assessment("ghost")], {"a"}, "test")


def test_full_exact_match_is_recommended_unchanged():
    result = finalize_match(evaluation(), Compatibility.EXACT, 1.0, 12.0, 0.5)
    assert (result.matchScore, result.quantityCoverage, result.distanceKm) == (0.9, 1.0, 12.0)
    assert result.requiredAction == "USER_APPROVAL"


def test_a_match_that_skips_user_approval_is_rejected():
    with pytest.raises(ValidationError):
        finalize_match(evaluation(requiredAction="AUTO_CONNECT"), Compatibility.EXACT, 1.0, 1.0, 0.5)


def test_a_recommendation_must_explain_itself():
    with pytest.raises(ValidationError):
        finalize_match(evaluation(reasons=["   "]), Compatibility.EXACT, 1.0, 1.0, 0.5)


@pytest.mark.parametrize("compatibility", [Compatibility.INCOMPATIBLE, Compatibility.UNCLEAR])
def test_unproven_material_is_never_recommended(compatibility):
    assert finalize_match(evaluation(matchScore=1.0), compatibility, 1.0, 1.0, 0.5) is None


def test_incomparable_quantities_are_never_recommended():
    assert finalize_match(evaluation(), Compatibility.EXACT, None, 1.0, 0.5) is None


def test_a_model_saying_no_match_is_respected():
    assert finalize_match(evaluation(match=False), Compatibility.EXACT, 1.0, 1.0, 0.5) is None


def test_related_material_is_capped_below_exact():
    assert finalize_match(evaluation(matchScore=0.99), Compatibility.RELATED, 1.0, 1.0, 0.5).matchScore == 0.8


def test_partial_quantity_is_capped_and_flagged():
    result = finalize_match(evaluation(matchScore=0.95), Compatibility.EXACT, 0.4, 1.0, 0.5)
    assert result.matchScore == 0.6  # 0.4 + 0.5 x 0.4
    assert result.warnings[0] == "Covers 40% of the requested quantity."


def test_scores_below_the_threshold_are_not_recommended():
    assert finalize_match(evaluation(matchScore=0.95), Compatibility.EXACT, 0.067, 1.0, 0.5) is None
    assert finalize_match(evaluation(matchScore=0.3), Compatibility.EXACT, 1.0, 1.0, 0.5) is None


def test_unknown_distance_adds_a_warning():
    result = finalize_match(evaluation(), Compatibility.EXACT, 1.0, None, 0.5)
    assert "Distance between the locations could not be determined." in result.warnings


def test_scores_are_clamped_and_text_is_cleaned():
    result = finalize_match(
        evaluation(matchScore=7.0, reasons=["  Material   matches ", "Material matches", "x" * 300]),
        Compatibility.EXACT, 1.0, 1.0, 0.5)
    assert result.matchScore == 1.0
    assert result.reasons[0] == "Material matches"
    assert len(result.reasons) == 2 and len(result.reasons[1]) == 160
