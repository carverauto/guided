# MCP Server Documentation

## Overview

The **guided.dev MCP (Model Context Protocol) Server** provides AI coding assistants with access to our curated knowledge graph of secure coding patterns, vulnerabilities, and architectural guidance.

This document explains how the MCP server works, how to test it, and how AI agents can interact with it.

## Architecture

### Components

1. **Guided.MCPServer** (`lib/guided/mcp_server.ex`)
   - Implements the Hermes.Server behavior
   - Exposes three tools (capabilities) to AI agents
   - Queries the knowledge graph using openCypher
   - Returns structured JSON responses

2. **Hermes MCP** (dependency)
   - Elixir implementation of Model Context Protocol
   - Handles transport (streamable HTTP)
   - Manages tool registration and invocation
   - Provides frame-based state management

3. **Graph Database** (Apache AGE on PostgreSQL)
   - Stores knowledge graph with nodes and relationships
   - Queried using openCypher via `Guided.Graph`

4. **Router Integration** (`lib/guided_web/router.ex`)
   - Mounts MCP endpoint at `/mcp`
   - Uses `Hermes.Server.Transport.StreamableHTTP.Plug`

### Data Flow

```
AI Agent → HTTP Request → /mcp endpoint
         → Hermes Transport Layer
         → Guided.MCPServer.handle_tool_call/3
         → Guided.Graph.query/2 (openCypher)
         → Apache AGE Graph Database
         → Parse & Format Results
         → JSON Response → AI Agent
```

## Available Tools (Capabilities)

### 1. tech_stack_recommendation

**Purpose**: Get opinionated tech stack advice for a use case

**Input Parameters**:
- `intent` (required, string): What you want to build
- `context` (optional, map): Additional context (topic, users, complexity)

**Example Request**:
```json
{
  "intent": "build a web app for small team",
  "context": {
    "topic": "fantasy football tracker",
    "users": "small_team"
  }
}
```

**Example Response**:
```json
{
  "status": "success",
  "use_case": "web_app_small_team",
  "intent": "build a web app for small team",
  "recommendations": [
    {
      "technology": "Streamlit",
      "category": "framework",
      "description": "Python framework for building data apps",
      "security_rating": "good",
      "security_advisories": [
        {
          "name": "Cross-Site Scripting (XSS)",
          "severity": "high",
          "description": "Injection of malicious scripts into web pages",
          "mitigations": ["Output Encoding", "Input Sanitization"]
        }
      ]
    },
    {
      "technology": "SQLite",
      "category": "database",
      "description": "Lightweight embedded SQL database",
      "security_rating": "good",
      "security_advisories": [
        {
          "name": "SQL Injection",
          "severity": "critical",
          "description": "Injection of malicious SQL code through user input",
          "mitigations": ["Parameterized Queries", "Input Sanitization"]
        }
      ]
    }
  ],
  "guidance": "For a web application serving a small team, we recommend Streamlit, SQLite..."
}
```

**Graph Query**:
```cypher
MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: $use_case})
OPTIONAL MATCH (t)-[:HAS_VULNERABILITY]->(v:Vulnerability)
OPTIONAL MATCH (v)-[:MITIGATED_BY]->(sc:SecurityControl)
RETURN t.name, t.category, t.description, t.security_rating,
       collect(DISTINCT {name: v.name, severity: v.severity, ...})
```

### 2. secure_coding_pattern

**Purpose**: Retrieve secure code patterns for specific technologies

**Input Parameters**:
- `technology` (required, string): Technology name (e.g., "Streamlit", "SQLite")
- `task` (optional, string): Specific task or concern (e.g., "database query")

**Example Request**:
```json
{
  "technology": "Streamlit",
  "task": "secret management"
}
```

**Example Response**:
```json
{
  "status": "success",
  "technology": "Streamlit",
  "task": "secret management",
  "count": 1,
  "patterns": [
    {
      "name": "Streamlit Secret Management",
      "category": "configuration",
      "description": "Use st.secrets for sensitive configuration",
      "code_example": "db_password = st.secrets['database']['password']",
      "security_control": "Input Sanitization"
    }
  ]
}
```

**Graph Query**:
```cypher
MATCH (t:Technology {name: $technology})-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
OPTIONAL MATCH (bp)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
RETURN bp.name, bp.category, bp.description, bp.code_example, sc.name
```

### 3. deployment_guidance

**Purpose**: Get deployment recommendations for a tech stack

**Input Parameters**:
- `stack` (required, array): List of technologies (e.g., ["Streamlit", "SQLite"])
- `requirements` (optional, map): Requirements (user_load, budget, https, etc.)

**Example Request**:
```json
{
  "stack": ["Streamlit", "SQLite"],
  "requirements": {
    "budget": "free",
    "complexity": "low",
    "https": true
  }
}
```

**Example Response**:
```json
{
  "status": "success",
  "stack": ["Streamlit", "SQLite"],
  "requirements": {"budget": "free", "complexity": "low", "https": true},
  "deployment_patterns": [
    {
      "name": "Streamlit Cloud",
      "platform": "streamlit_cloud",
      "cost": "free_tier_available",
      "complexity": "low",
      "description": "Official Streamlit hosting platform",
      "https_support": true,
      "use_cases": ["web_app_small_team", "data_dashboard"]
    }
  ],
  "recommendation": {
    "name": "Streamlit Cloud",
    "platform": "streamlit_cloud",
    ...
  }
}
```

**Graph Query**:
```cypher
MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
WHERE t.name IN $technologies
RETURN DISTINCT dp.name, dp.platform, dp.cost, dp.complexity, ...
```

## Testing the MCP Server

### Prerequisites

1. Database must be running (Docker container with Apache AGE)
2. Graph must be seeded with knowledge data

```bash
# Ensure Docker container is running
docker ps | grep age

# Seed the graph if needed
mix graph.setup
mix graph.seed
```

### Manual Testing with curl

The MCP server uses the **Model Context Protocol** which has a specific message format. Here's how to test it:

#### 1. Initialize the MCP session

```bash
curl -X POST http://localhost:4000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {
        "name": "test-client",
        "version": "1.0.0"
      }
    }
  }'
```

#### 2. List available tools

```bash
curl -X POST http://localhost:4000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'
```

#### 3. Call tech_stack_recommendation

```bash
curl -X POST http://localhost:4000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "tech_stack_recommendation",
      "arguments": {
        "intent": "build a data dashboard",
        "context": {
          "topic": "analytics",
          "users": "small_team"
        }
      }
    }
  }'
```

#### 4. Call secure_coding_pattern

```bash
curl -X POST http://localhost:4000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "tools/call",
    "params": {
      "name": "secure_coding_pattern",
      "arguments": {
        "technology": "SQLite",
        "task": "database query"
      }
    }
  }'
```

#### 5. Call deployment_guidance

```bash
curl -X POST http://localhost:4000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 5,
    "method": "tools/call",
    "params": {
      "name": "deployment_guidance",
      "arguments": {
        "stack": ["Streamlit", "SQLite"],
        "requirements": {
          "budget": "free",
          "https": true
        }
      }
    }
  }'
```

### Testing with IEx

You can also test the MCP server functions directly from IEx:

```elixir
# Start Phoenix with IEx
iex -S mix phx.server

# Test tech stack recommendation (private function, but you can call it through handle_tool_call)
# The server will be running and accessible via HTTP

# Or test graph queries directly:
Guided.Graph.query("""
  MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: 'data_dashboard'})
  RETURN t.name
""")
```

### Expected Behaviors

**Successful Response**:
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"status\":\"success\",\"use_case\":\"data_dashboard\",...}"
      }
    ]
  }
}
```

**Error Response**:
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "error": {
    "code": -32602,
    "message": "Invalid params"
  }
}
```

## Integration with AI Agents

### Claude Desktop Integration

Claude Desktop can connect to the guided.dev MCP server to provide secure coding guidance during development conversations.

#### Prerequisites

1. **Claude Desktop** installed ([download here](https://claude.ai/download))
2. **guided.dev server running** locally:
   ```bash
   cd /path/to/guided
   mix phx.server
   ```
3. **Node.js** installed (for `npx`)

#### Configuration Steps

**1. Locate your Claude Desktop config file:**

The config file location depends on your OS:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**2. Add guided.dev to your config:**

Since guided.dev runs as an HTTP server, use `npx mcp-remote` to connect:

```json
{
  "mcpServers": {
    "guided-dev": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "http://localhost:4000/mcp"
      ]
    }
  }
}
```

**Full example with multiple servers:**

```json
{
  "mcpServers": {
    "guided-dev": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "http://localhost:4000/mcp"
      ]
    },
    "github": {
      "command": "/path/to/github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
      }
    }
  }
}
```

**3. Restart Claude Desktop**

Close and reopen Claude Desktop to load the new configuration.

**4. Verify the connection**

In a new conversation with Claude, you can verify the tools are available:

```
You: Do you have access to guided.dev tools?
Claude: Yes, I have access to three guided.dev tools:
- tech_stack_recommendation
- secure_coding_pattern
- deployment_guidance
```

#### Using guided.dev with Claude

Once configured, Claude can automatically use guided.dev during development conversations:

**Example 1: Getting tech stack recommendations**

```
You: I want to build a data dashboard to track my team's metrics
Claude: [Uses tech_stack_recommendation tool]
       Based on guided.dev's recommendations, I suggest using Streamlit
       with SQLite for your team dashboard. However, be aware of these
       security concerns:
       - SQL Injection (critical): Use parameterized queries
       - XSS (high): Validate and sanitize all user inputs
```

**Example 2: Getting secure coding patterns**

```
You: How do I safely query the SQLite database in my Streamlit app?
Claude: [Uses secure_coding_pattern tool for SQLite]
       Here's the secure way using parameterized queries:
       ```python
       import sqlite3

       # Good - Uses parameterized query
       conn = sqlite3.connect('database.db')
       cursor = conn.execute(
           "SELECT * FROM users WHERE name = ?",
           (user_input,)
       )
       ```
```

**Example 3: Getting deployment guidance**

```
You: Where should I deploy my Streamlit + SQLite app?
Claude: [Uses deployment_guidance tool]
       For a Streamlit + SQLite stack, guided.dev recommends:
       1. Streamlit Cloud (free tier, low complexity, HTTPS included)
       2. Fly.io (free tier, low complexity, automatic HTTPS)
```

#### Troubleshooting

**Problem**: Claude says it doesn't have access to guided.dev tools

**Solutions**:
1. Check that Phoenix server is running: `curl http://localhost:4000/mcp`
2. Verify `npx` is available: `npx --version`
3. Check Claude Desktop logs:
   - **macOS**: `~/Library/Logs/Claude/`
   - **Windows**: `%APPDATA%\Claude\logs\`
   - **Linux**: `~/.config/Claude/logs/`
4. Ensure `mcp-remote` package is installed: `npx mcp-remote --help`

**Problem**: Connection timeout or refused

**Solutions**:
1. Verify server is running on correct port:
   ```bash
   lsof -i :4000
   ```
2. Check firewall settings aren't blocking localhost connections
3. Try accessing directly:
   ```bash
   curl -X POST http://localhost:4000/mcp \
     -H 'Content-Type: application/json' \
     -H 'Accept: application/json, text/event-stream' \
     -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
   ```

**Problem**: `npx: command not found`

**Solution**: Install Node.js from [nodejs.org](https://nodejs.org)

#### Advanced Configuration

**Using a different port:**

If your Phoenix server runs on a different port, update the config:

```json
{
  "mcpServers": {
    "guided-dev": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "http://localhost:4001/mcp"
      ]
    }
  }
}
```

**Connecting to a remote server:**

For production deployments:

```json
{
  "mcpServers": {
    "guided-dev": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://guided.dev/mcp"
      ]
    }
  }
}
```

**Adding authentication (future):**

When authentication is added:

```json
{
  "mcpServers": {
    "guided-dev": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://guided.dev/mcp",
        "--header",
        "Authorization: Bearer ${API_KEY}"
      ],
      "env": {
        "API_KEY": "your_api_key_here"
      }
    }
  }
}
```

### Custom AI Agent Integration

See the `AGENTS.md` file for the complete protocol specification.

**Basic workflow**:
1. Agent discovers `AGENTS.md` file in project
2. Agent reads MCP server endpoint URL
3. Agent initializes MCP session
4. Agent calls tools as needed during development
5. Agent uses guidance to inform code generation

## Implementation Details

### State Management

The MCP server uses Hermes frame-based state:

```elixir
def init(_client_info, frame) do
  {:ok,
   frame
   |> assign(query_count: 0)
   |> register_tool("tech_stack_recommendation", ...)
   |> register_tool("secure_coding_pattern", ...)
   |> register_tool("deployment_guidance", ...)
  }
end
```

Each tool call increments the `query_count` in the frame.

### Use Case Inference

The `tech_stack_recommendation` tool infers the use case from the intent string:

- Contains "dashboard", "visualization", "chart" → `data_dashboard`
- Contains "api", "rest", "service" → `api_service`
- Contains "web app", "small", "personal" → `web_app_small_team`
- Default → `web_app_small_team`

This can be extended with more sophisticated NLP or additional context parameters.

### Security Considerations

1. **Input Validation**: All tool inputs are validated by Hermes schema validation
2. **Query Injection**: We use parameterized Cypher queries to prevent injection attacks
3. **Rate Limiting**: Should be implemented in production (not yet added)
4. **Authentication**: Currently public; should add auth for production
5. **CORS**: Configure appropriately for your deployment

## Production Deployment

### Environment Variables

```bash
# Database configuration
DATABASE_URL="postgresql://user:pass@host:5432/dbname"

# MCP Server configuration
MCP_SERVER_URL="https://guided.dev/mcp"
```

### Scaling Considerations

1. **Database Connection Pooling**: Configured via Ecto repo
2. **Stateless Design**: MCP server is stateless (frame state is per-session)
3. **Caching**: Consider caching common graph queries
4. **CDN**: Serve AGENTS.md file via CDN

### Monitoring

Monitor these metrics:
- Tool call count by type
- Query execution time
- Error rate
- Graph database performance

Add telemetry in production:

```elixir
defp tech_stack_recommendation(params) do
  :telemetry.execute(
    [:guided, :mcp, :tool_call],
    %{count: 1},
    %{tool: "tech_stack_recommendation"}
  )

  # ... implementation
end
```

## Troubleshooting

### MCP Server Won't Start

**Issue**: Server fails to start in supervision tree

**Check**:
1. Is `Hermes.Server.Registry` in supervision tree before `Guided.MCPServer`?
2. Is the transport configured correctly?
3. Check logs for compilation errors

### Tools Not Showing Up

**Issue**: `tools/list` returns empty

**Check**:
1. Are tools registered in `init/2`?
2. Are capabilities set to `[:tools]` in `use Hermes.Server`?
3. Check MCP debug logs

### Graph Queries Failing

**Issue**: Tool calls return errors

**Check**:
1. Is the graph database seeded? Run `mix graph.seed`
2. Is the Docker container running? `docker ps | grep age`
3. Test queries directly: `Guided.Graph.query("MATCH (n) RETURN count(n)")`

### Empty Results

**Issue**: Tool returns success but empty results

**Possible causes**:
1. No matching data in graph (check your query)
2. Task filter too restrictive (try without `task` parameter)
3. Technology name doesn't match exactly (case-sensitive)

## Future Enhancements

### Planned Features

1. **Expanded Knowledge Graph**
   - JavaScript/TypeScript ecosystems
   - Go, Rust, Java stacks
   - More deployment platforms

2. **Advanced Querying**
   - Semantic search for best practices
   - Context-aware recommendations
   - Multi-stack comparisons

3. **Additional Tools**
   - `dependency_check_guidance`
   - `secrets_management_patterns`
   - `testing_strategy`

4. **Analytics Dashboard**
   - Tool usage statistics
   - Popular queries
   - Knowledge gaps

5. **Community Contributions**
   - API for submitting new patterns
   - Voting/rating system
   - Moderation workflow

## References

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Hermes MCP GitHub](https://github.com/cloudwalk/hermes-mcp)
- [Apache AGE Documentation](https://age.apache.org/)
- [openCypher Query Language](https://opencypher.org/)
- [AGENTS.md Specification](../AGENTS.md)

## Support

- **Issues**: [GitHub Issues](https://github.com/carverauto/guided/issues)
- **Discussions**: [GitHub Discussions](https://github.com/carverauto/guided/discussions)
- **Documentation**: [Development Guide](DEVELOPMENT.md)

---

**Last Updated**: 2025-01-26
**MCP Server Version**: 1.0.0
**Protocol Version**: 2024-11-05
