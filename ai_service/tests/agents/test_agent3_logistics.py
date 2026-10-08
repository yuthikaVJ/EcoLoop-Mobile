"""Agent 3 - Location & Logistics (app/agents/logistics.py).

Gets the road distance for each shortlisted pair through its only tool
(get_distance, answered by the backend's routing service) and judges whether the
exchange is practical. Distance is a warning, never a blocker."""

import httpx

from app.agents import LogisticsAgent
from app.schemas import LogisticsAssessment, LogisticsLlmOutput, PostType

from ..fakes import FakeBackend, ScriptedLlm, post

HAVE, NEED = PostType.I_HAVE, PostType.I_NEED


def answer(*ids, warnings=()):
    return LogisticsLlmOutput(assessments=[
        LogisticsAssessment(candidateId=i, logisticsFeasible=True, warnings=list(warnings)) for i in ids])


def test_gets_a_distance_for_every_shortlisted_post():
    shortlist = [post("n1", NEED, "PET", location="Gampaha"), post("n2", NEED, "PET", location="Jaffna")]
    backend = FakeBackend(post("t", HAVE, "PET"), shortlist, distances={"n1": 25.0, "n2": 395.0})
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1", "n2")})

    distances, assessments, call = LogisticsAgent(llm, backend).run(post("t", HAVE, "PET"), shortlist)

    assert distances == {"n1": 25.0, "n2": 395.0}
    assert set(assessments) == {"n1", "n2"}
    assert call.tool_calls == [{"tool": "get_distance", "args": {"candidateId": "n1"}},
                               {"tool": "get_distance", "args": {"candidateId": "n2"}}]


def test_distances_come_from_the_tool_and_reach_the_model():
    shortlist = [post("n1", NEED, "PET")]
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1")})

    LogisticsAgent(llm, FakeBackend(post("t", HAVE, "PET"), shortlist, distances={"n1": 42.5})).run(
        post("t", HAVE, "PET"), shortlist)

    assert '"roadDistanceKm": 42.5' in llm.structured_calls[0][1]


def test_routing_failure_leaves_the_distance_unknown():
    class RoutingDown(FakeBackend):
        def get_distance_km(self, candidate_id):
            raise httpx.ConnectError("routing service down")

    shortlist = [post("n1", NEED, "PET")]
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1")})

    distances, assessments, _ = LogisticsAgent(llm, RoutingDown(post("t", HAVE, "PET"), shortlist)).run(
        post("t", HAVE, "PET"), shortlist)

    assert distances == {"n1": None}
    assert "n1" in assessments


def test_warnings_from_the_model_are_kept():
    shortlist = [post("n1", NEED, "PET")]
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1", warnings=["Buyer must collect: 395 km away."])})

    _, assessments, _ = LogisticsAgent(llm, FakeBackend(post("t", HAVE, "PET"), shortlist)).run(
        post("t", HAVE, "PET"), shortlist)

    assert assessments["n1"].warnings == ["Buyer must collect: 395 km away."]


def test_drops_assessments_about_posts_outside_the_shortlist():
    shortlist = [post("n1", NEED, "PET")]
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1", "someone-else")})

    _, assessments, _ = LogisticsAgent(llm, FakeBackend(post("t", HAVE, "PET"), shortlist)).run(
        post("t", HAVE, "PET"), shortlist)

    assert list(assessments) == ["n1"]


def test_empty_shortlist_makes_no_model_call():
    llm = ScriptedLlm()

    distances, assessments, call = LogisticsAgent(llm, FakeBackend(post("t", HAVE, "PET"), [])).run(
        post("t", HAVE, "PET"), [])

    assert (distances, assessments, call) == ({}, {}, None)
    assert llm.structured_calls == []


def test_only_location_and_delivery_data_is_sent():
    shortlist = [post("n1", NEED, "PET", description="Very private notes")]
    llm = ScriptedLlm(answers={LogisticsLlmOutput: answer("n1")})

    LogisticsAgent(llm, FakeBackend(post("t", HAVE, "PET"), shortlist)).run(post("t", HAVE, "PET"), shortlist)

    prompt = llm.structured_calls[0][1]
    assert "deliveryMethod" in prompt and "location" in prompt
    assert "Very private notes" not in prompt
    assert LogisticsAgent.tools == ["get_distance"]
