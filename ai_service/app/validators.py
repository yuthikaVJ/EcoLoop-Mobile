"""Deterministic checks. Quantities, units, post types and agent outputs are never
trusted to the LLM (spec section 13)."""

import re

from .schemas import (
    Compatibility,
    MatchEvaluation,
    MatchResult,
    PostType,
)


class ValidationError(Exception):
    """An agent output that must be rejected."""


# ---- Quantities and units -------------------------------------------------------------

_UNIT_ALIASES = {
    "kg": "kg", "kgs": "kg", "kilogram": "kg", "kilograms": "kg",
    "t": "t", "ton": "t", "tons": "t", "tonne": "t", "tonnes": "t",
    "unit": "units", "units": "units", "pcs": "units", "pieces": "units",
    "bale": "bales", "bales": "bales",
}
_TO_KG = {"kg": 1.0, "t": 1000.0}


def normalize_unit(unit: str) -> str:
    return _UNIT_ALIASES.get((unit or "").strip().lower(), "unknown")


def parse_quantity(raw: str) -> float | None:
    """'500', '1,200', '2.5' -> number; anything else (ranges, words) -> None."""
    text = (raw or "").strip().replace(",", "")
    if not re.fullmatch(r"\d+(\.\d+)?", text):
        return None
    value = float(text)
    return value if value > 0 else None


def quantity_coverage(have_qty: float | None, have_unit: str, need_qty: float | None, need_unit: str) -> float | None:
    """Share of the need the offer covers (capped at 1.0), or None when the two
    quantities can't be compared (unknown amount, or e.g. bales vs kg)."""
    if have_qty is None or need_qty is None:
        return None
    if have_unit in _TO_KG and need_unit in _TO_KG:
        have, need = have_qty * _TO_KG[have_unit], need_qty * _TO_KG[need_unit]
    elif have_unit == need_unit and have_unit in ("units", "bales"):
        have, need = have_qty, need_qty
    else:
        return None
    return round(min(have / need, 1.0), 3)


def opposite(post_type: PostType) -> PostType:
    return PostType.I_NEED if post_type == PostType.I_HAVE else PostType.I_HAVE


def check_opposite_types(trigger_type: PostType, candidate_type: PostType) -> None:
    if candidate_type != opposite(trigger_type):
        raise ValidationError("I_HAVE can only be matched with I_NEED and vice versa.")


# ---- Agent output checks -------------------------------------------------------------

def known_ids(assessed: list, allowed: set[str], what: str) -> list:
    """Drops entries about posts the tools never returned (hallucinated ids)."""
    unknown = [a.candidateId for a in assessed if a.candidateId not in allowed]
    if unknown and len(unknown) == len(assessed):
        raise ValidationError(f"{what} only referred to unknown posts.")
    seen: set[str] = set()
    kept = []
    for a in assessed:
        if a.candidateId in allowed and a.candidateId not in seen:
            seen.add(a.candidateId)
            kept.append(a)
    return kept


def _clean_lines(lines: list[str], limit: int = 5, length: int = 160) -> list[str]:
    cleaned = []
    for line in lines:
        text = " ".join(str(line).split())[:length]
        if text and text not in cleaned:
            cleaned.append(text)
    return cleaned[:limit]


def finalize_match(
    evaluation: MatchEvaluation,
    compatibility: Compatibility,
    coverage: float | None,
    distance_km: float | None,
    min_score: float,
) -> MatchResult | None:
    """Turns Agent 4's verdict into a recommendation only if every rule holds.
    Returns None when the pair must not be recommended."""
    if evaluation.requiredAction != "USER_APPROVAL":
        raise ValidationError("Agent output tried to skip user approval.")
    if not evaluation.match:
        return None
    # Material and quantity must be established by the earlier, checked steps.
    if compatibility not in (Compatibility.EXACT, Compatibility.RELATED):
        return None
    if coverage is None:
        return None

    reasons = _clean_lines(evaluation.reasons)
    if not reasons:
        raise ValidationError("A recommended match must explain why.")
    warnings = _clean_lines(evaluation.warnings)

    score = max(0.0, min(1.0, float(evaluation.matchScore)))
    if compatibility == Compatibility.RELATED:
        score = min(score, 0.8)
    if coverage < 1.0:
        # Partial supply is still useful, but ranks below full matches.
        score = min(score, round(0.4 + 0.5 * coverage, 3))
        partial = f"Covers {round(coverage * 100)}% of the requested quantity."
        if partial not in warnings:
            warnings.insert(0, partial)
    if distance_km is None:
        unknown = "Distance between the locations could not be determined."
        if unknown not in warnings:
            warnings.append(unknown)

    if score < min_score:
        return None
    return MatchResult(
        candidateId=evaluation.candidateId,
        matchScore=round(score, 2),
        reasons=reasons,
        warnings=warnings[:5],
        quantityCoverage=coverage,
        distanceKm=None if distance_km is None else round(distance_km, 1),
    )
