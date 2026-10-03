"""Agent 3 - Location & Logistics: practical feasibility of each shortlisted pair."""

import json

from ..llm import Llm, LlmCall
from ..schemas import LogisticsAssessment, LogisticsLlmOutput, Post
from ..tools import BackendTools
from ..validators import known_ids

SYSTEM = (
    "You are the Location & Logistics agent of EcoLoop. EcoLoop has NO delivery fleet: "
    "the buyer collects (Self Pickup) unless the seller offers Seller Delivery. For "
    "each pair, judge whether the exchange is practical given the road distance, who "
    "can transport the material, and the availability/timing both sides state. "
    "Distance never rules a pair out on its own; describe it as a constraint or "
    "warning instead. Keep each constraint or warning under 20 words."
)


class LogisticsAgent:
    tools = ["get_distance"]

    def __init__(self, llm: Llm, backend: BackendTools):
        self._llm = llm
        self._backend = backend

    def run(self, post: Post, shortlist: list[Post]) -> tuple[dict, dict, LlmCall | None]:
        # Distances come from the backend's routing service, not from the model.
        distances: dict[str, float | None] = {}
        for candidate in shortlist:
            try:
                distances[candidate.id] = self._backend.get_distance_km(candidate.id)
            except Exception:  # routing service down: continue without distance
                distances[candidate.id] = None
        if not shortlist:
            return distances, {}, None

        def logistics(p: Post) -> dict:
            return p.model_dump(include={"id", "type", "location", "deliveryMethod", "sellerDeliveryAvailable", "availability"})

        pairs = [
            {"candidateId": c.id, "roadDistanceKm": distances[c.id], "candidate": logistics(c)}
            for c in shortlist
        ]
        result, call = self._llm.structured(
            SYSTEM,
            f"Requesting post: {json.dumps(logistics(post))}\nPairs: {json.dumps(pairs)}",
            LogisticsLlmOutput,
        )
        call.tool_calls = [{"tool": "get_distance", "args": {"candidateId": c.id}} for c in shortlist]
        assessments = known_ids(result.assessments, {c.id for c in shortlist}, "Logistics")
        by_id: dict[str, LogisticsAssessment] = {a.candidateId: a for a in assessments}
        return distances, by_id, call
