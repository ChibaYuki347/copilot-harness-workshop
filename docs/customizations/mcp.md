# 🔌 MCP Servers

**Plug your own tools into the agent via the Model Context Protocol.**

MCP — Model Context Protocol — is the open standard that lets a model talk to external
tools. Copilot CLI ships with **GitHub's MCP server enabled by default** (so the agent
can list issues, comment on PRs, etc.) and supports adding your own.

## When to use MCP

- The agent needs to read or write to a system that isn't a shell command — e.g. your
  internal CRM, ticketing tool, feature flag service, or SaaS dashboard.
- You want to expose a *typed* API (with schemas) rather than freeform CLI arguments.
- You want to share the tool with other MCP-capable hosts (Claude Desktop, Cursor, etc.).

## Where MCP configuration lives

| Scope | File |
|---|---|
| **Repo** | `.mcp.json` at the **git root**. Committed. |
| **Personal** | `~/.copilot/mcp-config.json` (managed via `/mcp add` or by editing the file directly). The location follows `$COPILOT_HOME` if set. |

!!! warning "Migration note"
    `.vscode/mcp.json` and `.devcontainer/devcontainer.json` are **no longer read** as
    MCP server config sources by the CLI. Only `.mcp.json` at the git root. The CLI
    surfaces a migration hint if it finds `.vscode/mcp.json` without `.mcp.json`.[^migration]

[^migration]: From the `github/copilot-cli` changelog: *"Remove `.vscode/mcp.json` and
    `.devcontainer/devcontainer.json` as MCP server config sources; CLI now only reads
    `.mcp.json`. A migration hint appears when `.vscode/mcp.json` is detected without
    `.mcp.json`."*

## Minimal example — `.mcp.json`

```json
{
  "mcpServers": {
    "linear": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    },
    "internal-search": {
      "type": "http",
      "url": "https://mcp.internal.example.com/search",
      "headers": {
        "Authorization": "Bearer ${INTERNAL_MCP_TOKEN}"
      }
    }
  }
}
```

Two transports are common:

| Transport | When to use |
|---|---|
| `stdio` | Local processes (`npx`, `uvx`, a binary). The CLI spawns the process and pipes JSON-RPC over stdio. |
| `http` (or `sse`) | Remote services. The CLI hits an HTTP endpoint per JSON-RPC call. |

`${VARNAME}` references in `command`, `args`, `env`, `cwd`, or `headers` are
**automatically resolved from your environment**.[^envref]

[^envref]: From the changelog: *"MCP server env vars referenced in command, args, or cwd
    fields are automatically included in the server environment."*

## Managing MCP servers from the CLI

```text
/mcp                  # interactive picker
/mcp add              # add a new MCP server interactively
```

Disable servers per launch:

```bash
copilot --disable-mcp-server <name>     # turn off one configured server
copilot --disable-builtin-mcps          # turn off bundled servers (e.g., the GitHub MCP)
```

Adjust config inline at launch:

```bash
copilot --additional-mcp-config '{"mcpServers":{"my-tool":{"type":"stdio","command":"./tool"}}}'
copilot --additional-mcp-config @./overrides.mcp.json
```


From the shell, the `copilot mcp` subcommand manages servers programmatically.

## Authentication patterns

- **API key in env var.** Simplest. Reference via `${VAR}` in `env:`.
- **OAuth (interactive).** Copilot opens a browser; for headless environments it falls
  back to **device code (RFC 8628)**.[^devicecode]
- **OAuth (`client_credentials`).** Supported for fully headless / CI use.
- **Microsoft Entra ID.** Supported, including avoiding the consent screen on every login.

[^devicecode]: From the changelog: *"Add device code flow (RFC 8628) as a fallback for
    MCP OAuth in headless and CI environments."*

## Security & policy

- Organizations can **allowlist** which MCP servers are usable. The CLI shows a warning
  when a server is blocked by policy and hides it from `/mcp show`.
- A server can request **LLM sampling** (i.e. ask Copilot's model to run inference on
  its behalf). The user is prompted to approve via a review prompt.

## Trying it out

The default `github-mcp-server` is the easiest one to play with. Inside a session:

```text
/mcp show
```

You'll see `github-mcp-server` listed. Then try:

```text
List the 5 most recent open issues in this repo and group them by label.
```

The agent will call the GitHub MCP server's tools to satisfy the request.

## Discovery & the MCP registry

Copilot CLI can **install MCP servers from a registry** with guided configuration. From
inside a session, run `/mcp` and follow the picker. This is the gentle on-ramp before
hand-authoring `.mcp.json`.

## Pitfalls

!!! warning "Common MCP missteps"
    - **Spawning a server for every session is slow.** Long-startup servers (Python
      packages with heavy deps) drag every Copilot launch. Consider an `http` MCP server
      that runs as a long-lived service.
    - **Schema sloppiness.** MCP tools with non-standard JSON Schema were a source of
      compatibility issues. Validate your tool schemas.
    - **Secrets in `.mcp.json`.** **Never** embed a token literal. Use `${VAR}` and
      document the env vars in your README.
    - **Trust before load.** Workspace MCP servers from `.mcp.json` load only after
      folder trust is confirmed.

## Verification

```text
/env       # shows loaded MCP servers and their status
/mcp show  # detailed view including reconnection state
```

## Next

→ [🤖 Custom Agents](agents.md) — when you want a *whole agent* dedicated to a task,
not just a tool the agent can call.
→ Recipe: [GitHub MCP server](../recipes/github-mcp-server.md) — the worked example.
