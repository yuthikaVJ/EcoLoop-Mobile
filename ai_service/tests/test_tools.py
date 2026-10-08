"""Allow-listed tools (app/tools.py): every tool call goes to the backend's
internal API for one workflow, authenticated with the shared secret."""

import json

import httpx
import pytest

from app.config import settings
from app.schemas import PostType
from app.tools import CATEGORIES, HttpBackendTools, validate_categories

POST = {"id": "p1", "type": "I_HAVE", "title": "PET", "category": "Plastics", "description": "",
        "quantity": "500", "unit": "Kgs", "location": "Colombo", "deliveryMethod": "Self Pickup",
        "sellerDeliveryAvailable": False}


def tools_with(handler) -> tuple[HttpBackendTools, list[httpx.Request]]:
    requests: list[httpx.Request] = []

    def record(request: httpx.Request) -> httpx.Response:
        requests.append(request)
        return handler(request)

    client = httpx.Client(transport=httpx.MockTransport(record), headers={"X-AI-Service-Key": "secret"})
    return HttpBackendTools("wf-1", client=client), requests


def test_get_post_reads_the_workflow_post():
    tools, requests = tools_with(lambda r: httpx.Response(200, json=POST))

    result = tools.get_post()

    assert result.type == PostType.I_HAVE and result.title == "PET"
    assert requests[0].method == "GET"
    assert requests[0].url.path == "/api/internal/ai/workflows/wf-1/post"
    assert requests[0].headers["X-AI-Service-Key"] == "secret"


def test_search_candidates_sends_categories_and_limit():
    tools, requests = tools_with(lambda r: httpx.Response(200, json=[POST | {"id": "n1", "type": "I_NEED"}]))

    found = tools.search_candidates(["Plastics", "Other"])

    assert [p.id for p in found] == ["n1"]
    body = json.loads(requests[0].content)
    assert body == {"categories": ["Plastics", "Other"], "limit": settings.max_candidates}
    assert requests[0].url.path.endswith("/candidates")


def test_get_distance_returns_kilometres_or_none():
    tools, _ = tools_with(lambda r: httpx.Response(200, json={"distanceKm": 25.4}))
    assert tools.get_distance_km("n1") == 25.4

    tools, requests = tools_with(lambda r: httpx.Response(200, json={"distanceKm": None}))
    assert tools.get_distance_km("n1") is None
    assert json.loads(requests[0].content) == {"candidateId": "n1"}


def test_backend_errors_are_raised_to_the_workflow():
    tools, _ = tools_with(lambda r: httpx.Response(403, json={"message": "not a candidate"}))
    with pytest.raises(httpx.HTTPStatusError):
        tools.get_distance_km("someone-elses-post")


def test_progress_reporting_never_breaks_the_workflow():
    def down(request):
        raise httpx.ConnectError("backend down")

    tools, _ = tools_with(down)
    tools.report_state("ANALYZING")  # no exception


def test_validate_categories_accepts_known_names_case_insensitively():
    assert validate_categories({"categories": ["plastics", "E-WASTE", "Plastics"]}) == ["Plastics", "E-Waste"]


@pytest.mark.parametrize("args", [
    {}, {"categories": []}, {"categories": "Plastics"}, {"categories": ["Users table"]},
    {"categories": [1]}, {"categories": CATEGORIES[:4]},
])
def test_validate_categories_rejects_anything_else(args):
    with pytest.raises(ValueError):
        validate_categories(args)
