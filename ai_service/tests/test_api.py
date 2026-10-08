"""HTTP API (app/main.py): only the backend may call the service, using the
shared secret; the response is the structured workflow result."""

import dataclasses

import pytest
from fastapi.testclient import TestClient

from app import main
from app.schemas import PostType

from .fakes import FakeBackend, FakeLlm, post


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setattr(main, "settings", dataclasses.replace(main.settings, service_key="test-key", gemini_api_key="x"))
    backend = FakeBackend(post("t", PostType.I_HAVE, "PET"), [post("n1", PostType.I_NEED, "PET")])
    monkeypatch.setattr(main, "HttpBackendTools", lambda workflow_id: backend)
    main.app.dependency_overrides[main.get_llm] = lambda: FakeLlm()
    yield TestClient(main.app)
    main.app.dependency_overrides.clear()


def test_health_lists_the_models(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_run_requires_the_service_key(client):
    assert client.post("/workflows/run", json={"workflowId": "wf-1"}).status_code == 401
    wrong = client.post("/workflows/run", json={"workflowId": "wf-1"}, headers={"X-AI-Service-Key": "guess"})
    assert wrong.status_code == 401


def test_run_returns_the_workflow_result(client):
    response = client.post("/workflows/run", json={"workflowId": "wf-1"}, headers={"X-AI-Service-Key": "test-key"})

    assert response.status_code == 200
    body = response.json()
    assert body["workflowId"] == "wf-1" and body["outcome"] == "MATCHES"
    assert body["matches"][0]["candidateId"] == "n1"
    assert body["matches"][0]["requiredAction"] == "USER_APPROVAL"


def test_missing_service_key_configuration_is_refused(monkeypatch, client):
    monkeypatch.setattr(main, "settings", dataclasses.replace(main.settings, service_key=""))
    response = client.post("/workflows/run", json={"workflowId": "wf-1"}, headers={"X-AI-Service-Key": ""})
    assert response.status_code == 503


def test_missing_gemini_key_is_refused(monkeypatch):
    monkeypatch.setattr(main, "settings", dataclasses.replace(main.settings, service_key="k", gemini_api_key=""))
    response = TestClient(main.app).post("/workflows/run", json={"workflowId": "wf-1"},
                                         headers={"X-AI-Service-Key": "k"})
    assert response.status_code == 503
