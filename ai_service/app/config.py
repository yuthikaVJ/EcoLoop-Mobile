"""Settings read from ai_service/.env (never committed)."""

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env")


def _models() -> list[str]:
    raw = os.getenv("GEMINI_MODELS", "gemini-flash-latest,gemini-3.5-flash,gemini-flash-lite-latest")
    return [m.strip() for m in raw.split(",") if m.strip()]


@dataclass(frozen=True)
class Settings:
    gemini_api_key: str = field(default_factory=lambda: os.getenv("GEMINI_API_KEY", ""))
    # Tried in order; the next one is used when a model is overloaded or rate-limited.
    gemini_models: list[str] = field(default_factory=_models)
    # "low" answers ~3x faster than the default on these structured tasks.
    thinking_level: str = field(default_factory=lambda: os.getenv("GEMINI_THINKING_LEVEL", "low"))
    # Shared secret: the backend sends it to us, and we send it back on tool calls.
    service_key: str = field(default_factory=lambda: os.getenv("AI_SERVICE_KEY", ""))
    backend_url: str = field(default_factory=lambda: os.getenv("BACKEND_URL", "http://localhost:5252").rstrip("/"))
    # Hard limits that keep a single workflow cheap and bounded.
    max_candidates: int = 15
    max_shortlist: int = 5
    max_tool_calls: int = 3
    llm_rounds: int = 2  # passes over the model list before giving up
    llm_timeout_seconds: int = 60  # per model call
    min_match_score: float = 0.5


settings = Settings()
