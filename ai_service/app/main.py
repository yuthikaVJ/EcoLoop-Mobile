"""HTTP entry point. Only the ASP.NET backend calls this service (shared secret);
Flutter and React never reach it directly."""

import hmac

from fastapi import Depends, FastAPI, Header, HTTPException

from .config import settings
from .llm import GeminiLlm
from .schemas import RunWorkflowRequest, WorkflowResult
from .tools import HttpBackendTools
from .workflow import run_workflow

app = FastAPI(title="EcoLoop Agentic AI", version="1.0.0")


def require_backend(x_ai_service_key: str = Header(default="")) -> None:
    if not settings.service_key:
        raise HTTPException(503, "AI_SERVICE_KEY is not configured.")
    if not hmac.compare_digest(x_ai_service_key.encode(), settings.service_key.encode()):
        raise HTTPException(401, "Invalid service key.")


def get_llm():
    if not settings.gemini_api_key:
        raise HTTPException(503, "GEMINI_API_KEY is not configured.")
    return GeminiLlm()


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "models": settings.gemini_models}


# Plain `def`: FastAPI runs it in a worker thread, so slow model calls don't block.
@app.post("/workflows/run", response_model=WorkflowResult, dependencies=[Depends(require_backend)])
def run(request: RunWorkflowRequest, llm=Depends(get_llm)) -> WorkflowResult:
    return run_workflow(request.workflowId, llm, HttpBackendTools(request.workflowId))
