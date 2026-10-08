# SE3090 – Software Engineering Frameworks
## Assignment 1 Specification 2026
### INTEGRATED FULL-STACK AND AGENTIC AI APPLICATION DEVELOPMENT

## 1. Assignment Overview
Each group must design, implement, integrate, test and deploy one coherent software system that combines a web application, mobile application, RESTful backend, relational database and a meaningful Agentic AI workflow. 

### 1.1 Assignment Objectives
- Apply ASP.NET Core, PostgreSQL, React and Flutter to a realistic full-stack problem.
- Design secure REST APIs, relational data models, web interfaces and mobile workflows.
- Implement a controlled Agentic AI workflow that plans, delegates, uses tools, validates results and requests human approval.
- Use Git, GitHub, automated testing, code review, CI/CD, documentation and deployment.
- Justify framework and architecture decisions in an Architecture Decision Record (ADR).

## 2. Required Technology Stack
- **Backend**: C# and ASP.NET Core Web API.
- **Data Access**: Entity Framework Core with PostgreSQL provider.
- **Database**: PostgreSQL.
- **Web Application**: React using functional components, hooks, routing and state-management.
- **Mobile Application**: Flutter and Dart using a justified state-management approach.
- **Agentic AI**: Any suitable framework (LangGraph, Microsoft Agent Framework, LlamaIndex agents, Google ADK, etc.).
- **Version Control**: Git and GitHub, including GitHub Actions CI.
- **Testing**: Tools for backend, React, Flutter, integration, performance and Agentic AI evaluation.

## 3. Group Structure and Individual Contribution
Standard group size is four students. Each student must take primary ownership of one business component (Component A, B, C, D) including Backend, database, React, Flutter, tests, Git evidence, documentation and a distinct Agentic AI contribution.

## 4. Domain and Functional Scope
Select a unique real-world domain (e.g., healthcare appointments, event management, travel planning).
- At least three user roles.
- Four major business components with relational data.
- CRUD operations, status workflows, search, filtering, pagination, etc.
- At least one third-party service integration.
- At least one complete cross-platform workflow involving all stack layers.

## 5. Part 1 – Secure ASP.NET Core RESTful API Backend
- **Architecture**: Controllers, DTOs, service/application layer, data-access abstraction.
- **Security**: JWT authentication, role-based authorization, protected endpoints, password hashing.
- **Data Operations**: CRUD, search, filtering, pagination, history.
- **Agent Integration**: Endpoints for starting workflows, reviewing status, human approval, execution summaries.

## 6. Part 2 – PostgreSQL Database
- Normalized relational database with an ER diagram.
- Primary keys, foreign keys, relationships, constraints, indexes.
- Entity Framework Core migrations and seed data.
- Audit fields such as CreatedAt and UpdatedAt.

## 7. Part 3 – React Web Application
- Dashboard, reporting, business-data management, Agentic AI monitoring.
- Complete ASP.NET Core API integration.
- Responsive UI, loading/empty/error states.

## 8. Part 4 – Flutter Mobile Application
- User-facing or operational workflows.
- Forms, validation, search, main business transactions, status tracking.
- Agentic task submission and workflow status.
- Device features like camera/image picker, GPS/map, QR scanning.

## 9. Part 5 – Agentic AI Subsystem
- Multi-step problem solving. Structured plan, distinct agent roles, allow-listed tools, deterministic validation, human approval, observability, and security.

## 10. Required Integrated Architecture
React Web Application and Flutter Mobile Application communicating with ASP.NET Core Web API, which interacts with PostgreSQL database, Controlled Agentic AI, and Third-Party Services.

## 11. Third-Party Integration
Integrate at least one external service (maps, weather, currency, email/SMS, etc.).

## 12. Testing Requirements
- **Backend**: Unit, service-layer, validation, controller and API integration tests.
- **Database**: PostgreSQL integration tests.
- **React/Flutter**: Component, validation, API-integration tests.
- **End to End**: Complete workflow testing.
- **Agent Evaluation**: Prompt-injection resistance, safe failure, business-rule compliance.

## 13. Git, CI/CD and Collaborative Development
- GitHub Actions CI workflow to restore, build and test on push/pull to main branch.
- Meaningful commits, task allocation, merge management.

## 14. Deployment and Documentation
- Deploy API to a cloud platform with Swagger URL.
- Deploy PostgreSQL securely.
- Deploy React app.
- Submit runnable Android APK.
- README and Technical Documentation.
- Architecture Decision Record (ADR).

## 15. Submission Guidelines
- Group leader submission via Course Web.
- Consolidated report (PDF) combining Group Report and Individual Report sections.
- Source code, repository URL, demonstration video link.
