# What is Copilot CLI?

GitHub Copilot CLI is an **agentic command-line interface** that brings Copilot —
the same one you know from GitHub.com and your IDE — into your terminal. It runs the
same harness as the GitHub Copilot coding agent that creates pull requests on the web.

!!! note "Using VS Code Copilot Chat instead? Keep reading."
    This page introduces the **CLI surface** specifically, but the harness this site
    teaches (Custom Instructions, Skills, Hooks, MCP, Custom Agents) **also applies
    to VS Code Copilot Chat in agent mode**. Almost every customization file you'll
    write under `.github/` works in both. The
    [VS Code vs CLI matrix](../reference/vscode-vs-cli.md) is the canonical "which
    feature works where" reference; the per-feature pages mark host-specific bits
    with 🟦 (CLI-only / -primary), 🟪 (VS Code-only / -primary), or 🟢 (both).

```
$ copilot
```

That's the entire UX. From there you converse in natural language, point at files
with `@`, reference issues and PRs with `#`, and shell out with `!`.

## What it can do

The CLI is a fully agentic loop: it reads files, runs commands (with your approval),
edits code, talks to GitHub.com, and iterates until the task you described is done.

| Capability | Example |
|---|---|
| Edit code in place | "Fix the off-by-one bug in `@src/pagination.ts`" |
| Run shell commands | "Run the tests and tell me what's failing" |
| Operate on GitHub | "Summarize the open issues labeled `bug`" |
| Plan before coding | `Shift+Tab` to enter **plan mode** |
| Background work | `/delegate` hands the task to Copilot in the cloud |

## How it relates to VS Code Copilot Chat

Both surfaces are now agentic and share most of the harness vocabulary. The
differences are about *where* you invoke Copilot and *which* slash commands /
orchestration features each host exposes.

| | VS Code Copilot Chat (agent mode) | Copilot CLI |
|---|---|---|
| Surface | Editor side panel + inline chat | Terminal, agentic REPL |
| Tool use | Editor APIs + Shell + MCP + Skills + Hooks + Custom Agents | Shell + MCP + Skills + Hooks + Custom Agents |
| Authentication | VS Code Copilot extension login | Same GitHub account / PAT, via `gh auth` |
| Customization files | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` (with `applyTo` glob), `.github/prompts/*.prompt.md`, `.github/skills/`, `.github/agents/`, `.github/hooks/` (Preview), `.vscode/mcp.json` | `.github/copilot-instructions.md` + `AGENTS.md` (incl. nested), `.github/prompts/`, `.github/skills/`, `.github/agents/`, `.github/hooks/`, `.mcp.json` or `.github/mcp.json` |
| Orchestration unique to this host | Inline edits, applied to active editor; Chat modes / Plan mode | `/fleet` parallel sub-agents, `/delegate` to cloud agent, headless `copilot -p '…'` |

**Most files under `.github/` work in both** — that's part of what makes the harness
valuable: customize once, benefit everywhere. The few exceptions (e.g. `applyTo`
globs are a VS Code-only filter, `/fleet` is a CLI-only orchestrator) are flagged
on each page with a 🟦 / 🟪 / 🟢 host badge.

## Key concepts you'll see throughout this site

- **Session.** One run of `copilot` is a *session*. Hooks fire at session boundaries.
- **Turn.** Within a session, every prompt → response pair is a *turn*.
- **Tool.** Anything the agent can invoke: shell commands, MCP tools, built-in tools.
- **Skill.** A bundled, callable procedure with its own instructions and assets.
- **Hook.** A script (or HTTP endpoint) that fires on a lifecycle event.
- **MCP server.** A long-running process exposing tools via the Model Context Protocol.
- **Custom agent / sub-agent.** A scoped, delegated worker spawned by the main agent.

## When to use the CLI vs other Copilot surfaces

!!! tip "Rule of thumb"
    Use the **IDE** for inline suggestions and quick edits.
    Use the **CLI** for multi-file changes, repo-wide refactors, build/test loops,
    and anything that benefits from running shell commands.
    Use the **cloud coding agent** (`/delegate`) when you want a PR opened
    asynchronously while you do something else.

## Next

→ [Install the CLI](installation.md)
→ Or jump straight to [first session](first-session.md) if you already have it installed.
