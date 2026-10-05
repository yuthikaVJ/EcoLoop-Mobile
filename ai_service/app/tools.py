"""Allow-listed tools. Every tool calls the ASP.NET backend's internal API, scoped
to one workflow; the backend re-checks eligibility and authorization, so a tool
can never reach data outside that workflow (spec sections 12 and 18)."""

from typing import Protocol

import httpx

from .config import settings
from .schemas import Post

CATEGORIES = ["Plastics", "Paper", "Metals", "Glass", "E-Waste", "Wood", "Other"]


class BackendTools(Protocol):
    def get_post(self) -> Post: ...

    def search_candidates(self, categories: list[str]) -> list[Post]: ...

    def get_distance_km(self, candidate_id: str) -> float | None: ...

    def report_state(self, state: str, note: str | None = None) -> None: ...


class HttpBackendTools:
    def __init__(self, workflow_id: str, client: httpx.Client | None = None):
        self._base = f"{settings.backend_url}/api/internal/ai/workflows/{workflow_id}"
        self._client = client or httpx.Client(
            timeout=30.0, headers={"X-AI-Service-Key": settings.service_key}
        )

    def get_post(self) -> Post:
        response = self._client.get(f"{self._base}/post")
        response.raise_for_status()
        return Post.model_validate(response.json())

    def search_candidates(self, categories: list[str]) -> list[Post]:
        response = self._client.post(
            f"{self._base}/candidates",
            json={"categories": categories, "limit": settings.max_candidates},
        )
        response.raise_for_status()
        return [Post.model_validate(item) for item in response.json()]

    def get_distance_km(self, candidate_id: str) -> float | None:
        response = self._client.post(f"{self._base}/distance", json={"candidateId": candidate_id})
        response.raise_for_status()
        value = response.json().get("distanceKm")
        return None if value is None else float(value)

    def report_state(self, state: str, note: str | None = None) -> None:
        # Progress reporting is best-effort; the final result is what counts.
        try:
            self._client.post(f"{self._base}/state", json={"state": state, "note": note})
        except httpx.HTTPError:
            pass


def validate_categories(args: dict) -> list[str]:
    """Rejects anything but 1-3 known category names."""
    categories = args.get("categories")
    if not isinstance(categories, list) or not 1 <= len(categories) <= 3:
        raise ValueError("categories must list 1 to 3 categories.")
    cleaned = []
    for value in categories:
        match = next((c for c in CATEGORIES if isinstance(value, str) and c.lower() == value.strip().lower()), None)
        if match is None:
            raise ValueError(f"Unknown category. Allowed: {', '.join(CATEGORIES)}.")
        if match not in cleaned:
            cleaned.append(match)
    return cleaned
