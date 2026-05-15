# Customizations — Overview

The six layers of the Copilot harness, in roughly **the order you should adopt them**.

```mermaid
flowchart LR
    A[Custom Instructions<br/>📜] --> B[Prompt Files<br/>⌨️]
    B --> C[Skills<br/>🦾]
    C --> D[Hooks<br/>🪝]
    D --> E[MCP Servers<br/>🔌]
    E --> F[Custom Agents<br/>🤖]

    style A fill:#5e35b1,color:#fff
    style B fill:#3949ab,color:#fff
    style C fill:#1e88e5,color:#fff
    style D fill:#00897b,color:#fff
    style E fill:#43a047,color:#fff
    style F fill:#fb8c00,color:#fff
```

You don't have to adopt them all at once. In practice, **the first three give you 80 %
of the value** for a single project; the last three pay off when you have a team, multiple
repos, or an internal tool surface to expose.

## At a glance

| Layer | Lives in | Scope | When to reach for it |
|---|---|---|---|
| **[Custom Instructions](custom-instructions.md)** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md`, `~/.copilot/copilot-instructions.md` | Repo or personal | You're tired of saying "use 4-space indent" / "always run `pnpm`, not `npm`" every turn. |
| **[Prompt Files](prompt-files.md)** | `*.prompt.md` files / repo-level slash commands | Repo or personal | You have a 6-line prompt you paste twice a week. |
| **[Skills](skills.md)** | `.github/skills/<name>/SKILL.md` (repo), `~/.copilot/skills/<name>/SKILL.md` (personal), `~/.agents/skills/<name>/SKILL.md` | Repo or personal | The task has *steps*, scripts, or output contracts. |
| **[Hooks](hooks.md)** | `.github/hooks/<name>/hooks.json` (repo), `~/.copilot/hooks/<name>/hooks.json` (personal) | Repo or personal | You want something to happen automatically when the agent does X. |
| **[MCP Servers](mcp.md)** | `.mcp.json` (repo, at git root), user-level via `copilot mcp` | Repo or personal | The agent needs a tool that isn't a shell command — internal API, DB, SaaS. |
| **[Custom Agents](agents.md)** | `~/.copilot/agents/<name>.md`, repo-level agent dirs | Repo or personal | You want a focused sub-agent (e.g. "security reviewer") you can `/agent`-pick. |

## How they compose

A real workflow rarely uses just one. For example:

> **"Open a PR, then auto-summarize and label it."**
>
> 1. **Custom Instruction** tells the agent your PR template format.
> 2. **Skill** `/pr-summary` walks the agent through generating the summary.
> 3. **Hook** on `postToolUse` matching `gh pr create` triggers the labeler script.
> 4. **MCP server** exposes your internal "release-train" service to fill in metadata.

You'll see the full version of this in [Recipes →](../recipes/index.md).

## Discovery rules (where Copilot looks)

Custom instructions, MCP servers, skills, and agents are **discovered at every directory
level from your current working directory up to the git root** — so a monorepo with
per-package overrides works naturally.[^discovery]

[^discovery]: See `github/copilot-cli` changelog: *"Custom instructions, MCP servers,
    skills, and agents are now discovered at every directory level from the working
    directory up to the git root, enabling full monorepo support."*

Personal-scope files live under `~/.copilot/` (and, for skills only, also under
`~/.agents/skills/`). They apply across every project on your machine.

## Verifying what's loaded

Inside any session, run:

```
/env
```

This prints **exactly** which instructions, MCP servers, skills, agents, plugins, and
LSP servers are active. When something isn't behaving as expected, **always start here**.

## Next

Pick a layer to dive into, or skim them in order:

- [📜 Custom Instructions](custom-instructions.md)
- [⌨️ Prompt Files & Slash Commands](prompt-files.md)
- [🦾 Skills](skills.md)
- [🪝 Hooks](hooks.md)
- [🔌 MCP Servers](mcp.md)
- [🤖 Custom Agents](agents.md)
