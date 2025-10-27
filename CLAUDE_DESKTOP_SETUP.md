# Quick Start: Connect Claude Desktop to guided.dev

Get AI-powered secure coding guidance in your Claude Desktop conversations.

## Prerequisites

- ✅ Claude Desktop installed ([download](https://claude.ai/download))
- ✅ Node.js installed ([download](https://nodejs.org))
- ✅ guided.dev server running

## 1. Start the guided.dev Server

```bash
cd /path/to/guided
mix phx.server
```

Verify it's running:
```bash
curl http://localhost:4000/mcp
```

## 2. Configure Claude Desktop

**Find your config file:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

**Add guided.dev to the config:**

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

**If you have other MCP servers, just add guided.dev to the list:**

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
    "your-other-server": {
      "command": "...",
      "args": ["..."]
    }
  }
}
```

## 3. Restart Claude Desktop

Close and reopen Claude Desktop completely.

## 4. Test It!

In a new Claude conversation:

```
You: Do you have access to guided.dev?
```

Claude should confirm it has access to three tools:
- `tech_stack_recommendation`
- `secure_coding_pattern`
- `deployment_guidance`

## Example Usage

### Get Tech Stack Recommendations

```
You: I want to build a dashboard to track my team's metrics
```

Claude will use `tech_stack_recommendation` and provide secure recommendations with security advisories.

### Get Secure Coding Patterns

```
You: How do I safely query a SQLite database in Python?
```

Claude will use `secure_coding_pattern` and show you secure code examples.

### Get Deployment Guidance

```
You: Where should I deploy my Streamlit app?
```

Claude will use `deployment_guidance` and recommend deployment platforms.

## Troubleshooting

### "I don't have access to guided.dev"

1. **Check server is running:**
   ```bash
   curl http://localhost:4000/mcp
   ```

2. **Verify npx is available:**
   ```bash
   npx --version
   ```

3. **Check Claude Desktop logs:**
   - macOS: `~/Library/Logs/Claude/`
   - Windows: `%APPDATA%\Claude\logs\`
   - Linux: `~/.config/Claude/logs/`

4. **Restart both:**
   - Stop and restart guided.dev server
   - Completely quit and reopen Claude Desktop

### "Connection refused"

Make sure Phoenix is running on port 4000:
```bash
lsof -i :4000
```

Should show something like:
```
COMMAND   PID   USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
beam.smp  1234  user   45u  IPv4  0x...      0t0  TCP *:4000 (LISTEN)
```

### "npx: command not found"

Install Node.js from [nodejs.org](https://nodejs.org), then try again.

## What You Get

When Claude uses guided.dev, it provides:

✅ **Security-First Recommendations** - All tech stacks come with OWASP Top 10 security advisories
✅ **Secure Code Examples** - Real code snippets using best practices
✅ **Deployment Guidance** - Recommendations based on your stack and requirements
✅ **Up-to-Date Knowledge** - Curated from the guided.dev knowledge graph

## Need More Help?

- **Full Documentation**: [docs/MCP_SERVER.md](guided/docs/MCP_SERVER.md)
- **AGENTS.md Protocol**: [AGENTS.md](AGENTS.md)
- **GitHub Issues**: [github.com/carverauto/guided/issues](https://github.com/carverauto/guided/issues)

---

**Ready to build secure software with AI?** 🚀

Start a conversation with Claude and ask for development guidance!
