## EcoLoop – Agentic AI Material Matching Workflow

Proposed Agentic AI contribution for the EcoLoop Circular Economy Marketplace

## 1. Overview

The proposed Agentic AI feature helps EcoLoop users discover useful matches between two marketplace post types: I HAVE posts, where a user or business offers a material, and I NEED posts, where a user or business requests a material. Instead of requiring users to manually search through many posts, the agentic workflow analyzes posts, discovers potential opposite-side matches, evaluates practical compatibility, and presents a potential match for user approval.

Core flow: Understand Search Compare Validate Recommend User Approval Connect

## 2. Example Scenario

| I HAVE | I NEED |
| --- | --- |
| 500 kg PET plastic bottles | 300 kg PET plastic bottles |
| Location: Colombo | Location: Gampaha |
| Available: Immediately | Required: Soon |

The AI can identify compatible material, sufficient quantity, and practical location factors, then produce a structured potential-match recommendation. It should not automatically connect users.

## 3. High-Level Architecture

Flutter and React communicate only with the ASP.NET Core Web API. The API controls access to the internal Python Agentic AI service. Flutter and React never call the Python AI service directly.

Flutter / React ASP.NET Core Web API Python Agentic AI Service Agents + Allow-listed Tools PostgreSQL / approved external services Structured Result ASP.NET Core Client

## 4. Four-Agent Workflow

| Agent | Responsibility | Input | Output |
| --- | --- | --- | --- |
| 1 – Material Understanding Normalize the marketplace post. |   | Post text + structured fields. | Material, quantity, unit, type and normalized requirement |
| 2 – Requirement Matching Find and compare opposite-side candidate posts.Normalized post + eligible candidates.Candidate matches and compatibility findings. |   |   |   |
| 3 – Location & Logistics | Evaluate practical location/logistics compatibility.Candidate pair + location/delivery data.Distance/logistics findings and constraints. |   |   |
| 4 – Match Evaluation | Combine results and prepare the recommendation.Agent outputs + deterministic checks.Potential match, reasons, warnings and required action. |   |   |


## 5. Agent 1 – Material Understanding

Converts natural-language marketplace content into a normalized structure. It can recognize related material terminology, subject to validation.

Example output:

{ "material": "PET plastic bottles", "quantity": 500, "unit": "kg", "postType": "I_HAVE" }

## 6. Agent 2 – Requirement Matching

Searches for posts of the opposite type and compares normalized requirements. I_HAVE is matched against I_NEED and vice versa. Factors include material compatibility, quantity, unit compatibility, availability, condition/type where applicable, and other structured requirements.

## 7. Agent 3 – Location & Logistics

Evaluates whether a candidate match is practical from a location/logistics perspective. EcoLoop does not operate its own delivery fleet, so existing EcoLoop delivery rules must be respected. Google Maps can later provide distance/route information through the backend where appropriate.

## 8. Agent 4 – Match Evaluation

Combines previous outputs and produces a structured potential-match assessment explaining why the posts were considered compatible and identifying warnings or missing information.

## Example:

{ "match": true, "matchScore": 0.91, "reasons": ["Material type matches", "Required quantity is available", "Locations are reasonably close"], "requiredAction": "USER_APPROVAL" }

## 9. End-to-End Workflow

- User creates an I_HAVE or I_NEED material post.

- ASP.NET Core validates and stores the post in PostgreSQL.

- API creates a matching workflow request.

- Agent 1 analyzes and normalizes the post.

- Agent 2 searches for opposite-side candidate posts.

- Agent 3 evaluates location/logistics considerations.

- Agent 4 evaluates the combined evidence.

- Deterministic validators check quantities, post types, authorization and required fields.

- Workflow state and agent outputs are persisted for auditability.

- EcoLoop presents the potential match to the user.

- User reviews the match and chooses whether to connect.

- Only after user approval does EcoLoop create the connection/contact action.

## 10. Human-in-the-Loop

The AI recommends; it does not automatically connect two users or initiate a transaction. The user reviews the proposed match and chooses Connect or Not Interested. This creates a clear human-approval boundary for a meaningful marketplace action.


## 11. Persisted Workflow States

| State | Meaning |
| --- | --- |
| MATCHING | Matching workflow created. |
| ANALYZING | Agent processing is in progress. |
| CANDIDATES_FOUND | Potential opposite-side candidates found. |
| VALIDATING | Deterministic checks are running. |
| MATCH_READY | Structured recommendation ready. |
| USER_APPROVAL | User must decide whether to connect. |
| CONNECTED | User approved and connection action was created. |
| SAFE_FAILURE | No safe/reliable recommendation could be produced. |

## 12. Allow-Listed Tools

Agents should have only the tools required for their responsibility. Examples: retrieve post details, search eligible marketplace posts, retrieve structured material data, calculate/obtain distance through an approved backend service, and save workflow results. Tool inputs and outputs must be validated.

## 13. Deterministic Validation

- Do not rely on the LLM alone for mathematical quantity compatibility.

- Validate that I_HAVE is matched only with I_NEED and vice versa.

- Validate quantities and units using deterministic application code.

- Validate that candidate posts are active and visible to the requesting user.

- Validate authorization before exposing user/business information.

- Reject malformed or incomplete agent outputs.

- Never allow an AI output to directly execute a connection or transaction.

## 14. Prompt-Injection Resistance

Marketplace post text is untrusted data. Instructions embedded inside a post must not alter system instructions, tool permissions, or authorization. Agent tools remain allow-listed and server-side authorization remains authoritative.

## 15. Safe Failure and Recovery

If an agent fails, returns invalid structured output, encounters ambiguous information, or an external service is unavailable, the workflow must not invent a result. It should safely retry where appropriate or return a clear 'No reliable match found' / 'Needs more information' result and persist the reason.

## 16. Example User Experience

Notification: “EcoLoop found a potential match for your PET plastic listing.”

Match: “300 kg PET bottles requested in Gampaha.”

Why: “Material matches; available quantity is sufficient; location is compatible.”

Actions: “View Match” “Connect” or “Not Interested”.


## 17. Evaluation Strategy

Evaluate the Agentic AI with predefined golden cases and deterministic validators. An LLM judge must not be the sole evaluation mechanism.

| Test case | Expected behavior |
| --- | --- |
| Exact material match | Identifies a compatible candidate. |
| Quantity mismatch | Does not claim a match when quantity is insufficient. |
| Opposite post type | Matches I_HAVE with I_NEED and vice versa. |
| Ambiguous material | Requests more information or safely avoids a confident match. |
| Different locations | Includes location/logistics considerations. |
| Prompt injection in post | Ignores malicious instructions embedded in marketplace text. |
| Malformed agent output | Deterministic validator rejects it safely. |
| External service unavailable | Recovers or produces safe failure. |
| Unauthorized candidate access | Does not expose protected information. |

## 18. Security and Privacy

- ASP.NET Core remains the authoritative authorization boundary.

- Send only the minimum data required for matching.

- Protect API keys and external-service credentials on the backend.

- Do not expose secrets in Flutter or React.

- Validate every agent tool request server-side.

- Log workflow decisions and failures without unnecessarily storing sensitive data.

## 19. Technology Responsibilities

| Layer | Responsibility |
| --- | --- |
| Flutter | Create/view posts, display match suggestions, let user approve/reject connection. |
| React | Management/admin interfaces as required; never a direct AI client. |
| ASP.NET Core | Authentication, authorization, post APIs, orchestration/gateway, validation and persistence. |
| PostgreSQL + EF Core | Posts, workflow state, candidates, results, audit information and connections. |
| Python Agentic AI | Four-agent workflow, structured analysis, controlled tools and recommendation generation. |
| Google Maps / external service Optional location/distance information through the backend. |   |

## 20. Recommended Implementation Order

- Finalize the I_HAVE / I_NEED post data model and API.

- Build the Python Agentic AI service skeleton.

- Implement Agent 1 and structured material extraction.

- Implement Agent 2 and controlled candidate search.

- Implement Agent 3 and location/logistics analysis.

- Implement Agent 4 and structured match evaluation.

- Add workflow-state persistence and deterministic validators.

- Connect ASP.NET Core to the Python service.

- Add Flutter match-suggestion UI.


- Add user approval and connection action.

- Add golden-case evaluation, security tests and failure/recovery tests.

- Document architecture, evaluation results and the AI usage log for the SE3090 report.

## 21. Key Design Principle

The AI recommends; EcoLoop's deterministic backend validates; the user decides. This separation keeps marketplace actions controlled while demonstrating a genuine multi-agent workflow with tools, state, validation, human approval, auditability and safe failure.
