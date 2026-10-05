"""Data exchanged with the backend and the structured outputs each agent must return."""

from enum import Enum

from pydantic import BaseModel, Field


class PostType(str, Enum):
    I_HAVE = "I_HAVE"
    I_NEED = "I_NEED"


class Post(BaseModel):
    """A marketplace post as the backend's internal API returns it (untrusted text)."""

    id: str
    type: PostType
    title: str = ""
    category: str = ""
    description: str = ""
    quantity: str = ""
    unit: str = ""
    location: str = ""
    deliveryMethod: str = ""
    sellerDeliveryAvailable: bool = False
    availability: str | None = None
    condition: str | None = None
    createdAt: str | None = None


# ---- Agent 1: Material Understanding -------------------------------------------------

class MaterialProfileLlm(BaseModel):
    """What the LLM may decide. Quantity/unit/type come from deterministic code."""

    material: str = Field(description="Specific material, e.g. 'PET plastic bottles'.")
    materialFamily: str = Field(description="Broad family, e.g. 'PET plastic', 'Corrugated cardboard'.")
    form: str | None = Field(default=None, description="Physical form, e.g. bottles, flakes, bales, sheets.")
    isAmbiguous: bool = Field(description="True when the post does not say clearly what the material is.")
    ambiguityReason: str | None = None


class MaterialProfile(MaterialProfileLlm):
    postType: PostType
    quantity: float | None
    unit: str  # kg | t | units | bales | unknown


# ---- Agent 2: Requirement Matching ---------------------------------------------------

class Compatibility(str, Enum):
    EXACT = "EXACT"
    RELATED = "RELATED"
    INCOMPATIBLE = "INCOMPATIBLE"
    UNCLEAR = "UNCLEAR"


class CandidateAssessment(BaseModel):
    candidateId: str
    materialCompatibility: Compatibility
    explanation: str


class MatchingLlmOutput(BaseModel):
    assessments: list[CandidateAssessment]


# ---- Agent 3: Location & Logistics ---------------------------------------------------

class LogisticsAssessment(BaseModel):
    candidateId: str
    logisticsFeasible: bool
    constraints: list[str] = []
    warnings: list[str] = []


class LogisticsLlmOutput(BaseModel):
    assessments: list[LogisticsAssessment]


# ---- Agent 4: Match Evaluation -------------------------------------------------------

class MatchEvaluation(BaseModel):
    candidateId: str
    match: bool
    matchScore: float
    reasons: list[str]
    warnings: list[str] = []
    requiredAction: str = Field(description="Must be USER_APPROVAL.")


class EvaluationLlmOutput(BaseModel):
    evaluations: list[MatchEvaluation]


# ---- Workflow result returned to the backend -----------------------------------------

class WorkflowOutcome(str, Enum):
    MATCHES = "MATCHES"
    NO_MATCH = "NO_MATCH"
    NEEDS_INFO = "NEEDS_INFO"
    FAILED = "FAILED"


class MatchResult(BaseModel):
    candidateId: str
    matchScore: float
    reasons: list[str]
    warnings: list[str]
    quantityCoverage: float | None
    distanceKm: float | None
    requiredAction: str = "USER_APPROVAL"


class WorkflowResult(BaseModel):
    workflowId: str
    outcome: WorkflowOutcome
    reason: str | None = None
    matches: list[MatchResult] = []
    trace: dict = {}


class RunWorkflowRequest(BaseModel):
    workflowId: str
