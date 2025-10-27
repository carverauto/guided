# Guided.dev

<img width="1470" height="278" alt="Screenshot 2025-10-26 at 10 09 55 PM" src="https://github.com/user-attachments/assets/4967c133-620b-421c-adde-d01855253c02" />

> A Protocol and Service for Building Great and Secure Software with AI Agents

Guided.dev provides the missing link between AI coding assistants and best-practice software development: a curated knowledge graph of secure coding patterns, vulnerabilities, and architectural guidance, accessible via a standardized protocol.

## What is Guided.dev?

Guided.dev consists of two key innovations:

1. **A Curated Knowledge Graph**: A security-first knowledge base built on PostgreSQL with Apache AGE, containing:
   - Technologies and frameworks
   - Security vulnerabilities (OWASP Top 10)
   - Best practices and secure coding patterns
   - Deployment strategies
   - Architectural guidance

2. **The AGENTS.md Protocol**: A machine-readable specification that tells AI agents how to discover and interact with our guidance service, enabling structured, secure, and expert-informed development.

## Current Status

**Phase 0** (Foundation & Setup) - **Complete** ✓
**Phase 1** (Admin CRUD Interface) - **Complete** ✓
**Phase 2** (MCP Server) - **Complete** ✓

### Completed
- ✓ PostgreSQL with Apache AGE graph database
- ✓ Graph query interface (`Guided.Graph`)
- ✓ Initial knowledge base (24 nodes, 24 relationships)
- ✓ Custom mix tasks for setup and seeding
- ✓ Admin CRUD interface with Phoenix LiveView
- ✓ Knowledge graph management UI
- ✓ MCP Server with three core tools:
  - `tech_stack_recommendation` - Get tech stack advice for use cases
  - `secure_coding_pattern` - Retrieve secure code patterns
  - `deployment_guidance` - Get deployment recommendations
- ✓ AGENTS.md protocol specification

## Quick Start

<img width="1252" height="768" alt="Knowledge Graph Dashboard" src="https://github.com/user-attachments/assets/d0ea6b01-493f-462d-bfb8-f1efbe204c14" />

**Prerequisites**: Erlang/OTP 28+, Elixir 1.19.1+, Docker

```bash
# Clone the repository
git clone https://github.com/carverauto/guided.git
cd guided

# Run the automated setup script
./scripts/dev_setup.sh

# Start the Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

For detailed setup instructions and manual installation, see [**docs/DEVELOPMENT.md**](guided/docs/DEVELOPMENT.md).

## Project Vision

### The Problem

LLMs are powerful code generators but they operate in a vacuum. They often produce code that is functional but naive in its architecture, security, and scalability. There's no standardized way for AI agents to discover and consume curated best-practice knowledge.

### The Solution

**Guided.dev** provides:
- A **trusted source** of security-first, opinionated guidance
- A **clear protocol** (AGENTS.md) for AI agents to consume this guidance
- A **graph-based knowledge model** for complex relationships between technologies, vulnerabilities, and mitigations

### Example Use Case

An AI agent building a Python web app:
1. Discovers the project's `AGENTS.md` file
2. Queries guided.dev's MCP server for tech stack recommendations
3. Receives guidance on Streamlit + SQLite with security advisories
4. Queries for secure coding patterns specific to those technologies
5. Generates code using parameterized queries and proper input validation

## Tech Stack

- **Backend**: Elixir / Phoenix Framework
- **Database**: PostgreSQL with Apache AGE extension (graph database)
- **Frontend**: Phoenix LiveView
- **Query Language**: openCypher
- **API**: Model Context Protocol (MCP)

## Features

### Completed

**Phase 0** (Foundation):
- ✓ PostgreSQL with Apache AGE graph database
- ✓ openCypher query interface
- ✓ Initial knowledge base covering:
  - Python, Streamlit, SQLite, FastAPI
  - OWASP Top 10 vulnerabilities
  - Security controls and mitigations
  - Best practices and deployment patterns

**Phase 1** (Admin Interface):
- ✓ LiveView-based admin CRUD interface
- ✓ Node and relationship management
- ✓ Knowledge graph dashboard
- ✓ Graph visualization

**Phase 2** (MCP Server):
- ✓ Public-facing MCP API at `/mcp` endpoint
- ✓ Three core tools (capabilities):
  - `tech_stack_recommendation` - Opinionated tech stack advice with security advisories
  - `secure_coding_pattern` - Secure code snippets and best practices
  - `deployment_guidance` - Deployment pattern recommendations
- ✓ AGENTS.md protocol specification for AI agent discovery
- ✓ Integration with Hermes MCP library
- ✓ Streamable HTTP transport

### Future Roadmap

- Expanded knowledge domains (JavaScript, Go, Rust, etc.)
- Community contribution system
- IDE integrations
- Advanced graph analytics and insights

## Development

For detailed setup instructions, see [**docs/DEVELOPMENT.md**](docs/DEVELOPMENT.md).

### Quick Commands

```bash
# Run tests
mix test

# Format code
mix format

# Full pre-commit check (compile, format, test)
mix precommit

# Reset database and graph
mix ecto.reset
mix graph.setup
mix graph.seed

# Start Phoenix server
mix phx.server

# Start with IEx (interactive Elixir)
iex -S mix phx.server
```

### Testing the Graph

```elixir
# In IEx
iex> Guided.Graph.query("MATCH (t:Technology) RETURN t.name")
{:ok, [["Python"], ["Streamlit"], ["SQLite"], ["FastAPI"]]}

iex> Guided.Graph.query("""
  MATCH (t:Technology {name: 'Streamlit'})-[:HAS_VULNERABILITY]->(v:Vulnerability)
  RETURN v.name, v.severity
  """)
{:ok, [["Cross-Site Scripting (XSS)", "high"], ["Path Traversal", "high"]]}
```

## Contributing

We welcome contributors! To get started:

1. Read the [Development Setup Guide](docs/DEVELOPMENT.md)
2. Check out [GitHub Issue #1](https://github.com/carverauto/guided/issues/1) for the full PRD
3. Review [docs/implementation_plan.md](docs/implementation_plan.md) for the roadmap
4. Look for issues labeled `good-first-issue`

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Run `mix precommit` to ensure quality
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Documentation

- [Development Setup](guided/docs/DEVELOPMENT.md) - Complete setup guide
- [MCP Server Guide](guided/docs/MCP_SERVER.md) - MCP server documentation and API reference
- [AGENTS.md Specification](AGENTS.md) - The protocol spec for AI agents
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [Implementation Plan](guided/docs/implementation_plan.md) - Phased roadmap
- [Phase 0 Completion](SETUP_COMPLETE.md) - Current progress
- [Security Policy](SECURITY.md) - Security guidelines

## Architecture

```
guided/
├── lib/
│   ├── guided/
│   │   ├── graph.ex           # Graph database interface
│   │   └── repo.ex            # Ecto repository
│   ├── guided_web/            # Phoenix web interface
│   └── mix/tasks/             # Custom mix tasks
├── priv/repo/                 # Database migrations
├── config/                    # Configuration files
├── docs/                      # Documentation
└── scripts/                   # Setup and utility scripts
```

## Learn More

- **Phoenix Framework**: https://www.phoenixframework.org/
- **Apache AGE**: https://age.apache.org/
- **openCypher**: https://opencypher.org/
- **Model Context Protocol**: https://modelcontextprotocol.io/

## License

Apache 2.0

## Contact

- **Issues**: [GitHub Issues](https://github.com/carverauto/guided/issues)
- **Discussions**: [GitHub Discussions](https://github.com/carverauto/guided/discussions)

---

Built with ❤️ by the Guided.dev team
