Of course. This is the perfect next step. A clear, phased implementation plan will turn the PRD into an actionable roadmap.

Given the choice of Elixir/Phoenix, we can leverage its strengths in building robust APIs and real-time internal tools (with LiveView) to create the MVP efficiently.

Here is a high-level implementation plan outline for the `guided.dev` MVP.

---

### **Guided.dev MVP: Elixir/Phoenix Implementation Plan**

This plan outlines the key phases and tasks required to build and launch the Minimum Viable Product.

#### **Core Technologies**
*   **Backend:** Elixir / Phoenix Framework
*   **Database:** PostgreSQL with the **Apache AGE** extension
*   **Deployment (Target):** Cloud provider with managed Postgres and extension support (e.g., Fly.io, Gigalixir, AWS RDS).

---

### **Phase 0: Foundation & Setup (1 Week)**

The goal of this phase is to establish a stable and consistent development environment.

*   **1. Environment Setup:**
    *   Standardize Elixir and Erlang versions using `asdf`.
    *   Set up a local PostgreSQL instance.
    *   **Crucial:** Install the Apache AGE extension into the local PostgreSQL instance. This may involve compiling from source. A `Dockerfile` to create a reusable development image with Postgres + AGE is highly recommended.

*   **2. Phoenix Project Initialization:**
    *   Generate the new Phoenix project: `mix phx.new guided_dev`.
    *   Configure `Ecto` and the `Postgrex` adapter to connect to the AGE-enabled database.
    *   Establish a basic application structure with clear separation for the internal admin and public MCP contexts.

*   **3. Graph Query Interface:**
    *   Create a simple Elixir module (e.g., `GuidedDev.Graph`) to serve as an adapter for executing `openCypher` queries.
    *   This module will primarily use `Ecto.Adapters.SQL.query/4` to send raw Cypher commands to AGE and parse the results. This abstracts the raw queries from the business logic.

---

### **Phase 1: The Knowledge Core - Admin CRUD Interface (2-3 Weeks)**

The goal is to build the internal tool for populating and managing the knowledge graph. We will use **Phoenix LiveView** for a rich, real-time single-page application experience without writing custom JavaScript.

*   **1. Authentication:**
    *   Implement basic authentication for the admin area using `mix phx.gen.auth`. This will be a simple email/password system to protect the CRUD interface.

*   **2. Data Modeling (In Elixir):**
    *   Define Elixir `structs` that represent the logical graph nodes (`Technology`, `Vulnerability`, `BestPractice`, etc.). These are *not* Ecto schemas but will be used for handling data within the application.

*   **3. CRUD for Graph Nodes (LiveView):**
    *   Build a LiveView for managing each node type (e.g., `/admin/technologies`, `/admin/vulnerabilities`).
    *   Each view will support:
        *   **C**reating new nodes (e.g., a form to add a new `Technology` with its properties).
        *   **R**eading/listing all nodes of that type.
        *   **U**pdating an existing node's properties.
        *   **D**eleting a node.

*   **4. Relationship Management (LiveView):**
    *   This is the most critical part of the admin interface.
    *   Create a dedicated "Relationship Manager" LiveView.
    *   This UI will allow an admin to select two existing nodes (e.g., a `Vulnerability` and a `SecurityControl`) and create a labeled edge (`MITIGATED_BY`) between them.
    *   The interface should use dynamic selects or search boxes to make finding nodes easy.

*   **5. Initial Data Seeding:**
    *   Create a `mix` task (`mix guided_dev.seed`) that runs a script of `openCypher` commands to populate the database with the initial, foundational set of knowledge (Python, Streamlit, SQL Injection, etc.).

---

### **Phase 2: The Public Interface - MCP Server (2 Weeks)**

The goal is to build the public-facing API that AI agents will interact with, based on the `AGENTS.md` specification.

*   **1. API Scaffolding:**
    *   Create a new route scope in the Phoenix router for `/mcp/v1`.
    *   Implement a single `MCPController` to handle all incoming requests.
    *   Set up a JSON view to render responses, ensuring consistent formatting.

*   **2. Implement `tech_stack_recommendation` Endpoint:**
    *   Create an action in the `MCPController` for this capability.
    *   The action will:
        1.  Validate the incoming JSON payload (`intent`, `context`).
        2.  Construct a read-only `openCypher` query based on the parameters.
        3.  Execute the query via the `GuidedDev.Graph` module.
        4.  Format the graph results into the specified JSON response structure.

*   **3. Implement `secure_coding_pattern` Endpoint:**
    *   Create a new action in the controller.
    *   Logic will be similar: validate parameters (`technology`, `task`), build a Cypher query to find relevant `BestPractice` nodes linked to the technology, and format the response.

*   **4. Implement `deployment_guidance` Endpoint:**
    *   Create the final action for the MVP.
    *   This will likely involve a more complex Cypher query that traverses from a set of `Technology` nodes to find recommended `DeploymentPattern` nodes.

*   **5. API Documentation:**
    *   Create a simple, clear document (e.g., in a `docs` folder) that explains how to use the MCP API, mirroring the `AGENTS.md` spec.

---

### **Phase 3: Deployment & Launch (1 Week)**

The goal is to get the MVP running in a production environment.

*   **1. Infrastructure Provisioning:**
    *   Select a hosting provider (e.g., Fly.io).
    *   Provision a production-ready PostgreSQL database and ensure the Apache AGE extension is installed and enabled. This is a critical prerequisite.

*   **2. CI/CD Pipeline:**
    *   Set up a basic CI/CD pipeline using GitHub Actions.
    *   The pipeline should:
        1.  Install dependencies (`mix deps.get`).
        2.  Run the test suite (`mix test`).
        3.  Build a production-ready Elixir release (`mix release`).
        4.  Deploy the release to the hosting provider.

*   **3. Final Launch Tasks:**
    *   Configure the `guided.dev` domain DNS to point to the production server.
    *   Set up SSL/TLS.
    *   Run the production data seed script.
    *   Perform final end-to-end testing against the live MCP server.
