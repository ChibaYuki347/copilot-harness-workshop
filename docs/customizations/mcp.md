# 🔌 MCP Servers

**Plug your own tools into the agent via the Model Context Protocol.**

!!! abstract "Where it works"
    🟢 **Copilot CLI** (project: `.github/mcp.json` or `.mcp.json`; user: `~/.copilot/mcp-config.json`) · 🟢 **VS Code** (Preview — `.vscode/mcp.json` workspace + `settings.json` `mcp.servers` user scope). **Same MCP protocol**, but the file location and top-level JSON key differ — CLI uses `"mcpServers"`, VS Code uses `"servers"`. Ship both files for mixed teams. See [VS Code vs CLI](../reference/vscode-vs-cli.md).

MCP — Model Context Protocol — is the open standard that lets a model talk to external
tools. Copilot CLI ships with **GitHub's MCP server enabled by default** (so the agent
can list issues, comment on PRs, etc.) and supports adding your own.

## Why this exists

The agent is locked to a fixed tool set (bash, view, edit, …). MCP is how you
**extend that set** with anything that has an API: ticket systems, internal
search, vendor SaaS, Azure Foundry, a private knowledge base. Instead of the
agent guessing `curl` invocations, it gets typed tools with schemas and a
single permission category to approve.

## Alternatives — when *not* to reach for MCP

- The action is **a one-off shell command** → just let the agent call `bash`.
  MCP is overkill for "run my linter once."
- The action is **a procedure with multiple shell steps** → write a [Skill](skills.md)
  whose body is the procedure; cheaper than running an MCP server.
- The action is **internal-only and never reused by other tools** → consider an
  in-repo script the agent runs via `bash`. MCP shines when the same tool is
  also useful from Cursor / Claude Desktop / your own agent.

## When to use MCP

- The agent needs to read or write to a system that isn't a shell command — e.g. your
  internal CRM, ticketing tool, feature flag service, or SaaS dashboard.
- You want to expose a *typed* API (with schemas) rather than freeform CLI arguments.
- You want to share the tool with other MCP-capable hosts (Claude Desktop, Cursor, etc.).

## Where MCP configuration lives

| Scope | File |
|---|---|
| **Repo (preferred)** | `.mcp.json` at the **git root**. Committed. |
| **Repo (alt)** | `.github/mcp.json` — the CLI also accepts this path; useful if you keep all bot config under `.github/`. |
| **Personal** | `~/.copilot/mcp-config.json` (managed via `/mcp add` or by editing the file directly). The location follows `$COPILOT_HOME` if set. |
| **Env var** | `GITHUB_COPILOT_MCP_JSON` — pass a JSON string directly. Highest precedence. Useful for CI / one-off overrides. |

!!! warning "Migration note (CLI)"
    `.vscode/mcp.json` and `.devcontainer/devcontainer.json` are **no longer read** as
    MCP server config sources by the CLI. The CLI now only reads `.mcp.json` or
    `.github/mcp.json` at the git root (plus user-scope `~/.copilot/mcp-config.json`).
    The CLI surfaces a migration hint if it finds `.vscode/mcp.json` without one of
    those files.[^migration] **VS Code still uses `.vscode/mcp.json`** — mixed teams
    should ship both, see the [VS Code variant section](#vs-code-equivalent) below.

[^migration]: From the `github/copilot-cli` changelog: *"Remove `.vscode/mcp.json` and
    `.devcontainer/devcontainer.json` as MCP server config sources; CLI now only reads
    `.mcp.json`. A migration hint appears when `.vscode/mcp.json` is detected without
    `.mcp.json`."*

## VS Code equivalent { #vs-code-equivalent }

VS Code Copilot Chat also speaks MCP (Preview as of 2026-05). It reads a
different file with a slightly different shape — same servers, different
top-level key and env-var syntax.

| Aspect | Copilot CLI | VS Code |
|---|---|---|
| Workspace config | `.mcp.json` *or* `.github/mcp.json` | `.vscode/mcp.json` |
| User config | `~/.copilot/mcp-config.json` | VS Code Settings → `mcp.servers` |
| Top-level JSON key | `"mcpServers"` | `"servers"` |
| Env-var reference | `${VAR}` | `${env:VAR}` |
| Server lifecycle | CLI spawns / IPC | VS Code Workbench manages via `vscode.lm.startMcpGateway()` |
| Tool naming | `mcp__<server>__<tool>` | `<server>/<tool>` (after virtual grouping) |
| Auth storage | OS keychain via `keytar`, file fallback at `~/.copilot/config/mcp-oauth-config/` | VS Code Secret Storage / Authentication API |

The **same MCP server binary works in both hosts** — only the config file changes.

```jsonc
// .vscode/mcp.json (VS Code) — mirrors the .mcp.json above
{
  "servers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": { "LINEAR_API_KEY": "${env:LINEAR_API_KEY}" }
    }
  }
}
```

For mixed teams, **commit both** `.mcp.json` and `.vscode/mcp.json` with the same
server list during the rollout window. A small `npm run sync-mcp` script that
generates one from the other keeps them in lockstep. Official VS Code docs:
[Use MCP servers in VS Code (Preview)](https://code.visualstudio.com/docs/copilot/chat/mcp-servers).

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
