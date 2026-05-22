# VS Code vs Copilot CLI — what works where

This site is **about the harness**, not the host. Most of the customizations on this
site work in **both** the VS Code GitHub Copilot extension *and* the Copilot CLI. A
few are CLI-only. This page is the one-screen cheat sheet so you can decide what to
roll out before you read the rest.

!!! info "Why this page exists"
    A common question from teams piloting Copilot is: *"If half the team uses VS
    Code and the other half uses the CLI, which customizations can we share?"* The
    short answer is **most of them**. The long answer is the table below.

## At-a-glance matrix

| Customization | VS Code (Copilot extension / Chat / Agent mode) | Copilot CLI | Shared config file? |
|---|---|---|---|
| [Custom Instructions](../customizations/custom-instructions.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/copilot-instructions.md` |
| [Path-specific instructions (`applyTo`)](../customizations/custom-instructions.md#path-specific) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/instructions/*.instructions.md` |
| [Prompt Files](../customizations/prompt-files.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/prompts/*.prompt.md` |
| [Skills](../customizations/skills.md) | 🟡 Personal scope only (`~/.agents/skills/`) | 🟢 Full (repo + personal) | ⚠️ Repo-scoped `.github/skills/` is **CLI-primary** |
| [MCP servers](../customizations/mcp.md) | 🟢 Yes (different file) | 🟢 Yes | ⚠️ Different — see below |
| [Custom Agents](../customizations/agents.md) | 🟡 Yes (with `target: vscode` frontmatter) | 🟢 Yes | ⚠️ Same file format, `target` field switches host |
| [Hooks](../customizations/hooks.md) | ❌ No | 🟢 Yes | 🟩 CLI-only |

Legend: 🟢 fully supported · 🟡 supported with caveat · ❌ not supported.

## Config file locations side by side

Where each tool **reads** the same kind of configuration:

| What you're configuring | VS Code extension | Copilot CLI |
|---|---|---|
| Repo-wide instructions | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Path-specific instructions | `.github/instructions/<name>.instructions.md` | `.github/instructions/<name>.instructions.md` |
| Prompt files | `.github/prompts/<name>.prompt.md` | `.github/prompts/<name>.prompt.md` |
| Personal skills | `~/.agents/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` (or `~/.copilot/skills/...`) |
| Repo skills | n/a (use personal scope) | `.github/skills/<name>/SKILL.md` |
| MCP servers (workspace) | `.vscode/mcp.json` *or* `"mcp.servers"` in `settings.json` | `.mcp.json` at repo root |
| MCP servers (personal) | User-scoped `settings.json` | `~/.copilot/mcp-config.json` |
| Custom agents | `.github/agents/<name>.agent.md` with `target: vscode` | `.github/agents/<name>.agent.md` (no target, or `target: github-copilot`) |
| Hooks | n/a | `.github/hooks/<name>/hooks.json` (+ scripts) |

!!! warning "MCP config files are **not** shared"
    The CLI **no longer reads** `.vscode/mcp.json`. As of the late-2026 changelog,
    it only reads `.mcp.json` at the repo root and emits a migration hint if it
    sees `.vscode/mcp.json` but no `.mcp.json`. If your team is mixed, ship
    **both** files with the same server definitions — see the
    [MCP customization page](../customizations/mcp.md) for the exact mapping.

## Slash-command map

The CLI uses slash commands (`/instructions`, `/skills`, …) that surface what's
loaded for the current session. VS Code uses its own command palette and the Chat
view. Rough equivalents:

| You want to… | Copilot CLI | VS Code |
|---|---|---|
| See what custom instructions are active | `/instructions` | Chat → `@workspace /instructions` (or open the file) |
| See discovered skills | `/skills` | Personal skills only — visible via the picker in Chat |
| See discovered MCP servers + tools | `/mcp show` | Open MCP panel (Chat side panel) |
| Pick a custom agent | `/agent` | Chat → mention the agent or use the picker |
| See everything loaded | `/env` | n/a — no direct equivalent |
| Run a prompt file | `/<name-of-prompt-file>` | Chat → `/<name-of-prompt-file>` |
| Run a hook | n/a (fires on lifecycle events) | n/a |

## Practical guidance

- **Custom Instructions + Prompt Files are universal.** Start here if your team is
  mixed; the same files Just Work in both environments.
- **MCP is universal but the config differs.** Ship both `.vscode/mcp.json` *and*
  `.mcp.json` with the same server list during a migration window.
- **Hooks are CLI-only.** If you need a `sessionEnd` audit log in VS Code, you'll
  have to do it outside Copilot (e.g. a Git post-commit hook, a wrapper script,
  or your IDE's task runner).
- **Skills and Custom Agents work in both**, but the repo-scoped patterns this
  site teaches (`.github/skills/`, custom `target`-less agents) assume the CLI as
  the primary surface. Personal-scope versions (`~/.agents/skills/`,
  `target: vscode`) are how to bring them to a VS Code user.

## When to introduce each layer to a mixed team

A rollout that works for "half VS Code, half CLI":

1. **Custom Instructions** — week 1. Universal.
2. **Prompt Files** — week 1. Universal.
3. **MCP** — week 2. Pick one server (filesystem or GitHub MCP). Ship both
   config files.
4. **Skills (personal)** — week 3, for CLI users; VS Code users get the same
   skill via `~/.agents/skills/`.
5. **Custom Agents** — week 4. CLI users by default; offer `target: vscode`
   versions for the others.
6. **Hooks** — week 5+, **CLI users only**. Use them for org-wide audit, not for
   anything user-facing that VS Code users would miss.

## See also

- [Customizations overview](../customizations/index.md) — every layer in detail.
- [Exercises](../exercises/index.md) — labs split into **Track A** (any Copilot
  user) and **Track B** (CLI required).
- [File layout](file-layout.md) — every customization file in one diagram.
