"""Agent 1 - Material Understanding: normalizes a marketplace post."""

from ..llm import Llm, LlmCall, untrusted
from ..schemas import MaterialProfile, MaterialProfileLlm, Post
from ..validators import normalize_unit, parse_quantity

SYSTEM = (
    "You are the Material Understanding agent of EcoLoop, a circular-economy "
    "marketplace in Sri Lanka where businesses offer (I HAVE) or request (I NEED) "
    "recyclable materials. Identify exactly which material a post is about. Use "
    "standard recycling terminology (e.g. 'PET' for polyethylene terephthalate "
    "bottles, 'HDPE', 'OCC' for old corrugated cardboard). Set isAmbiguous=true when "
    "the post does not make the material clear enough to match it with confidence."
)


class MaterialUnderstandingAgent:
    tools: list[str] = []  # needs no tools: it reads the post it is given

    def __init__(self, llm: Llm):
        self._llm = llm

    def run(self, post: Post) -> tuple[MaterialProfile, LlmCall]:
        data = post.model_dump(include={"title", "category", "description", "condition"})
        result, call = self._llm.structured(
            SYSTEM,
            f"Normalize this {post.type.value} post.\n{untrusted(data)}",
            MaterialProfileLlm,
        )
        # Quantity, unit and post type are facts from the database, not LLM opinions.
        profile = MaterialProfile(
            **result.model_dump(),
            postType=post.type,
            quantity=parse_quantity(post.quantity),
            unit=normalize_unit(post.unit),
        )
        if not profile.material.strip():
            profile.isAmbiguous = True
            profile.ambiguityReason = profile.ambiguityReason or "The material could not be identified."
        return profile, call
