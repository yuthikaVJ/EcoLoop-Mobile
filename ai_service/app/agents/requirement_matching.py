"""Agent 2 - Requirement Matching: finds opposite-side posts (choosing which
categories to search through an allow-listed tool) and judges material fit."""

import json

from ..config import settings
from ..llm import Llm, LlmCall, Tool, untrusted
from ..schemas import MaterialProfile, MatchingLlmOutput, Post
from ..tools import CATEGORIES, BackendTools, validate_categories
from ..validators import known_ids

SEARCH_SYSTEM = (
    "You are the Requirement Matching agent of EcoLoop. Use the search_candidates "
    "tool to find opposite-side marketplace posts that could match the given "
    "material. Search the material's own category first; add related categories "
    "only when the material is commonly listed there too (e.g. mixed recyclables "
    "under 'Other'). When you have searched, reply with the word DONE."
)

ASSESS_SYSTEM = (
    "You are the Requirement Matching agent of EcoLoop. For each candidate post, "
    "judge only whether its material is compatible with the requirement: EXACT (same "
    "material), RELATED (a substitute the other side could plausibly use), "
    "INCOMPATIBLE, or UNCLEAR (the candidate does not say clearly what it is). Do not "
    "judge quantity, price or location; other steps check those."
)


class RequirementMatchingAgent:
    tools = ["search_candidates"]

    def __init__(self, llm: Llm, backend: BackendTools):
        self._llm = llm
        self._backend = backend

    def run(self, post: Post, profile: MaterialProfile) -> tuple[list[Post], dict, list[LlmCall]]:
        found: dict[str, Post] = {}
        searched = False

        def search(args: dict):
            nonlocal searched
            categories = validate_categories(args)
            results = self._backend.search_candidates(categories)
            searched = True
            for candidate in results:
                found[candidate.id] = candidate
            return {"count": len(results), "posts": [self._summary(c) for c in results]}

        tool = Tool(
            name="search_candidates",
            description="Search active, opposite-side posts (not the requester's own) in up to 3 categories.",
            parameters={
                "type": "object",
                "properties": {
                    "categories": {"type": "array", "items": {"type": "string", "enum": CATEGORIES}, "maxItems": 3}
                },
                "required": ["categories"],
            },
            run=search,
        )
        _, search_call = self._llm.with_tools(
            SEARCH_SYSTEM,
            f"Material to match: {json.dumps(profile.model_dump(mode='json'))}\n"
            f"The post was listed under category '{post.category}'.",
            [tool],
        )
        if not searched:
            # The model must search; if it didn't (or only tried rejected
            # arguments), search the post's own category.
            fallback = post.category if post.category in CATEGORIES else "Other"
            search({"categories": [fallback]})
            search_call.tool_calls.append({"tool": "search_candidates", "args": {"categories": [fallback]}, "fallback": True})

        candidates = list(found.values())[: settings.max_candidates]
        if not candidates:
            return [], {}, [search_call]

        posts = "\n".join(untrusted(self._summary(c)) for c in candidates)
        result, assess_call = self._llm.structured(
            ASSESS_SYSTEM,
            f"Requirement: {json.dumps(profile.model_dump(mode='json'))}\nCandidates:\n{posts}",
            MatchingLlmOutput,
        )
        assessments = known_ids(result.assessments, set(found), "Requirement matching")
        return candidates, {a.candidateId: a for a in assessments}, [search_call, assess_call]

    @staticmethod
    def _summary(post: Post) -> dict:
        return post.model_dump(include={"id", "title", "category", "description", "quantity", "unit", "condition"})
