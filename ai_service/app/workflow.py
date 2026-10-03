"""Orchestrates Understand -> Search/Compare -> Logistics -> Evaluate -> Validate.

Every step's output is checked by deterministic code before the next step sees it,
and any failure ends in a safe, explained outcome instead of an invented match."""

import httpx

from .agents import LogisticsAgent, MatchEvaluationAgent, MaterialUnderstandingAgent, RequirementMatchingAgent
from .config import settings
from .llm import Llm, LlmCall, LlmUnavailable
from .schemas import Compatibility, Post, PostType, WorkflowOutcome, WorkflowResult
from .tools import BackendTools
from .validators import ValidationError, check_opposite_types, finalize_match, normalize_unit, parse_quantity, quantity_coverage


def _call_trace(agent: str, call: LlmCall | None) -> dict | None:
    if call is None:
        return None
    return {"agent": agent, "model": call.model, "seconds": round(call.seconds, 2), "toolCalls": call.tool_calls}


def _near_miss_reason(shortlist: list) -> str:
    """Explains why the closest candidates were still not recommended."""
    count = len(shortlist)
    found = f"Found {count} similar post{'s' if count != 1 else ''}, but none was a close enough fit"
    best_coverage = max(coverage for _, _, coverage in shortlist)
    if best_coverage < 0.5:
        return f"{found}: the quantities differ too much (at best {round(best_coverage * 100)}% of the amount needed)."
    return f"{found}. We'll check again when new posts arrive."


def run_workflow(workflow_id: str, llm: Llm, backend: BackendTools) -> WorkflowResult:
    trace: dict = {"agents": {}, "llmCalls": []}

    def finish(outcome: WorkflowOutcome, reason: str | None = None, matches=None) -> WorkflowResult:
        return WorkflowResult(workflowId=workflow_id, outcome=outcome, reason=reason, matches=matches or [], trace=trace)

    try:
        post = backend.get_post()
        backend.report_state("ANALYZING")

        # Agent 1 - understand the post.
        profile, call = MaterialUnderstandingAgent(llm).run(post)
        trace["agents"]["materialUnderstanding"] = profile.model_dump(mode="json")
        trace["llmCalls"].append(_call_trace("materialUnderstanding", call))
        if profile.isAmbiguous:
            return finish(WorkflowOutcome.NEEDS_INFO, profile.ambiguityReason or "The material in this post is unclear.")
        if profile.quantity is None:
            return finish(WorkflowOutcome.NEEDS_INFO, "Add a numeric quantity (e.g. 500) so quantities can be compared.")

        # Agent 2 - search and compare materials.
        candidates, assessments, calls = RequirementMatchingAgent(llm, backend).run(post, profile)
        for c in calls:
            trace["llmCalls"].append(_call_trace("requirementMatching", c))

        shortlist: list[tuple[Post, Compatibility, float]] = []
        findings, unclear, incomparable = [], 0, 0
        for candidate in candidates:
            finding: dict = {"candidateId": candidate.id}
            findings.append(finding)
            try:
                check_opposite_types(post.type, candidate.type)
            except ValidationError as error:
                finding["rejected"] = str(error)
                continue
            assessment = assessments.get(candidate.id)
            compatibility = assessment.materialCompatibility if assessment else Compatibility.UNCLEAR
            finding["materialCompatibility"] = compatibility.value
            if compatibility == Compatibility.UNCLEAR:
                unclear += 1
            if compatibility not in (Compatibility.EXACT, Compatibility.RELATED):
                continue
            have, need = (post, candidate) if post.type == PostType.I_HAVE else (candidate, post)
            coverage = quantity_coverage(
                parse_quantity(have.quantity), normalize_unit(have.unit),
                parse_quantity(need.quantity), normalize_unit(need.unit),
            )
            finding["quantityCoverage"] = coverage
            if coverage is None:
                incomparable += 1
                continue
            shortlist.append((candidate, compatibility, coverage))

        # Exact material first, then the best quantity coverage.
        shortlist.sort(key=lambda s: (s[1] != Compatibility.EXACT, -s[2]))
        shortlist = shortlist[: settings.max_shortlist]
        trace["agents"]["requirementMatching"] = {"searched": len(candidates), "findings": findings}
        backend.report_state("CANDIDATES_FOUND", f"{len(shortlist)} candidate(s) shortlisted")

        if not candidates:
            wanted = "I NEED" if post.type == PostType.I_HAVE else "I HAVE"
            return finish(
                WorkflowOutcome.NO_MATCH,
                f"No other users have matching {wanted} posts yet. "
                "When someone posts one, EcoLoop checks it against your post automatically.",
            )
        if not shortlist:
            if unclear or incomparable:
                return finish(
                    WorkflowOutcome.NEEDS_INFO,
                    "Possible matches exist, but their material or quantity units can't be compared reliably.",
                )
            return finish(WorkflowOutcome.NO_MATCH, "No reliable match found right now.")

        # Agent 3 - location and logistics.
        posts = [s[0] for s in shortlist]
        distances, logistics, call = LogisticsAgent(llm, backend).run(post, posts)
        trace["llmCalls"].append(_call_trace("logistics", call))
        trace["agents"]["logistics"] = {
            "distancesKm": distances,
            "assessments": {k: v.model_dump() for k, v in logistics.items()},
        }

        # Agent 4 - evaluate the combined evidence.
        evidence = []
        for candidate, compatibility, coverage in shortlist:
            assessment = assessments[candidate.id]
            logistic = logistics.get(candidate.id)
            evidence.append({
                "candidateId": candidate.id,
                "materialCompatibility": compatibility.value,
                "materialExplanation": assessment.explanation,
                "quantityCoveragePercent": round(coverage * 100),
                "roadDistanceKm": distances.get(candidate.id),
                "logistics": logistic.model_dump() if logistic else "not assessed",
            })
        evaluations, call = MatchEvaluationAgent(llm).run(evidence)
        trace["llmCalls"].append(_call_trace("matchEvaluation", call))

        # Deterministic validation decides what may reach the user.
        backend.report_state("VALIDATING")
        matches, decisions = [], {}
        for candidate, compatibility, coverage in shortlist:
            evaluation = evaluations.get(candidate.id)
            if evaluation is None:
                decisions[candidate.id] = "no evaluation"
                continue
            try:
                result = finalize_match(evaluation, compatibility, coverage, distances.get(candidate.id), settings.min_match_score)
            except ValidationError as error:
                decisions[candidate.id] = f"rejected: {error}"
                continue
            decisions[candidate.id] = "recommended" if result else "below threshold or not a match"
            if result:
                matches.append(result)
        matches.sort(key=lambda m: m.matchScore, reverse=True)
        trace["agents"]["matchEvaluation"] = {
            "evaluations": {k: v.model_dump() for k, v in evaluations.items()},
            "validatorDecisions": decisions,
        }

        if not matches:
            return finish(WorkflowOutcome.NO_MATCH, _near_miss_reason(shortlist))
        return finish(WorkflowOutcome.MATCHES, matches=matches)

    except LlmUnavailable as error:
        trace["error"] = str(error)
        return finish(WorkflowOutcome.FAILED, "The AI model was unavailable or returned invalid output.")
    except ValidationError as error:
        trace["error"] = str(error)
        return finish(WorkflowOutcome.FAILED, "An agent returned output that failed validation.")
    except httpx.HTTPError as error:
        trace["error"] = f"{type(error).__name__}"
        return finish(WorkflowOutcome.FAILED, "EcoLoop data could not be read for this workflow.")
