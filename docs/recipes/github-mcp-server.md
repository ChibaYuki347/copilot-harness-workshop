# Recipe: GitHub MCP server

**Use the default GitHub MCP server, then add a private one.**

## Problem

You want the agent to read issues, comment on PRs, query org metadata — without
shelling out to `gh` for every operation, and with **typed** tool calls (so the model
gets schema-validated arguments).

## Layers used

- **MCP** (the built-in `github-mcp-server` + an added custom server).

## Part 1 — The built-in GitHub MCP server

Good news: it's already there. Verify:

```text
/mcp show
```

You'll see `github-mcp-server` listed. From the `github/copilot-cli` README:

> "MCP-powered extensibility: Take advantage of the fact that the coding agent ships
> with GitHub's MCP server by default and supports custom MCP servers."

The default scope is your authenticated GitHub account — same auth as the CLI itself.

### What it gives you

The GitHub MCP server exposes tools for:

- Issues: list, read, comment, label.
- Pull requests: list, read, diff, review, merge.
- Repositories: search, get file contents, list commits.
- Actions: list workflows, get runs, fetch logs.
- Copilot Spaces & Copilot Extensions surfaces (where available).

You don't have to memorize these — Copilot will pick them automatically. Just say:

```text
List the 5 most recently updated issues labeled "bug" and group them by the file
mentioned most often in their bodies.
```

### Toolset controls

You can narrow the tools exposed at startup via flags:

```bash
copilot --enable-all-github-mcp-tools     # widest surface
copilot --add-github-mcp-toolset issues   # subset
copilot --add-github-mcp-tool issue_read  # single tool
```

(See the CLI changelog notes for the canonical flag names — they're stable across
recent versions.)

## Part 2 — Add a private MCP server

Suppose you have an internal "deploys" service with a Node-based MCP server. Add it
to `.mcp.json` at the **git root**:

```json
{
  "mcpServers": {
    "deploys": {
      "type": "stdio",
      "command": "node",
      "args": ["./tools/deploys-mcp/server.js"],
      "env": {
        "DEPLOYS_API_TOKEN": "${DEPLOYS_API_TOKEN}"
      }
    }
  }
}
```

Restart your session (or run `/mcp reload`) and check:

```text
/mcp show
```

`deploys` should appear with status `connected`. From now on, the agent can call
its tools by name: *"Use the `deploys` server to list pending deploys for `payments-api`."*

## Part 3 — A remote HTTP MCP server

For a remote service you control:

```json
{
  "mcpServers": {
    "kb-search": {
      "type": "http",
      "url": "https://kb.internal.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${KB_TOKEN}"
      }
    }
  }
}
```

Remote HTTP MCP servers are **automatically retried on transient network failures**[^retry],
so flaky networks won't ruin your session.

[^retry]: From the changelog: *"MCP remote server connections automatically retry on
    transient network failures."*

## OAuth-protected servers

If your MCP server requires OAuth:

```text
/mcp auth <name>
```

Copilot will open the browser, or fall back to **device code flow** in headless
contexts (so it works in WSL, SSH, devcontainers).

## Disabling without removing

You don't have to delete a server from `.mcp.json` to silence it:

```text
/mcp disable kb-search
```

The choice persists across sessions until you `/mcp enable kb-search`.

## Pitfalls

- **Don't put secrets inline.** Use `${VAR}` and document the required env vars in
  your `README.md`.
- **Long startup = slow sessions.** A server that takes 5 s to initialize delays every
  session start. Prefer HTTP servers for heavy dependencies, or pre-warm.
- **Workspace MCP load order.** Workspace servers from `.mcp.json` load **only after
  folder trust is confirmed**. Don't expect them to be available on the very first
  prompt of a brand-new clone.
