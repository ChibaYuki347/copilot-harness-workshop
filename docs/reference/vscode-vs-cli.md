# VS Code vs Copilot CLI — what works where

This site is **about the harness**, not the host. Almost every customization on
this page **works in both** the VS Code GitHub Copilot extension *and* the
Copilot CLI. The two hosts even **share the same file formats** for most layers
(`.agent.md`, `*.instructions.md`, `*.prompt.md`, `SKILL.md`, `hooks.json`). The
real differences are *where* the host looks for each file, what UX surfaces it
through, and which features are Preview vs GA.

!!! info "Why this page exists"
    A common question from teams piloting Copilot is: *"If half the team uses VS
    Code and the other half uses the CLI, which customizations can we share?"* The
    short answer is **almost all of them**. The long answer is the table below.

## At-a-glance matrix

| Customization | VS Code (Copilot Chat / Agent mode) | Copilot CLI | Shared config file? |
|---|---|---|---|
| [Custom Instructions](../customizations/custom-instructions.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/copilot-instructions.md` |
| [Path-specific instructions (`applyTo`)](../customizations/custom-instructions.md#path-specific) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/instructions/*.instructions.md` |
| [Prompt Files](../customizations/prompt-files.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/prompts/*.prompt.md` |
| [Skills](../customizations/skills.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/skills/<name>/SKILL.md` (+ `.agents/skills/`, `.claude/skills/`) |
| [MCP servers](../customizations/mcp.md) | 🟢 Yes (Preview) | 🟢 Yes | ⚠️ Different file, **same protocol** — ship both during migration |
| [Custom Agents](../customizations/agents.md) | 🟢 Yes | 🟢 Yes | ✅ Same `.github/agents/<name>.agent.md` — schema is interoperable[^agent-compat] |
| [Hooks](../customizations/hooks.md) | 🟢 Yes (Preview)[^hooks-preview] | 🟢 Yes | ✅ Same `.github/hooks/*.json` format (Claude Code-compatible) |

Legend: 🟢 fully supported · 🟡 supported with caveat · ❌ not supported.

[^agent-compat]: Per the upstream `microsoft/vscode-copilot-chat` design notes,
    `.agent.md` files written for the CLI "should mostly work" when opened in VS
    Code — only the *tool reference names* differ (CLI exposes a built-in
    `task` tool; VS Code exposes `agent` as an alias and resolves named
    subagents through its picker).
[^hooks-preview]: Per the official
    [VS Code Hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks)
    (Preview as of 2026-05). The same JSON schema and event names that CLI
    accepts are loaded by VS Code. Your organization may disable hooks via
    enterprise policy; check `chat.hookFilesLocations` settings and your admin's
    Copilot policy before relying on them.

## Config file locations side by side

Where each tool **reads** the same kind of configuration:

| What you're configuring | VS Code extension | Copilot CLI |
|---|---|---|
| Repo-wide instructions | `.github/copilot-instructions.md` (or `AGENTS.md`) | `.github/copilot-instructions.md` (also reads `AGENTS.md`, `CLAUDE.md`) |
| Path-specific instructions | `.github/instructions/<name>.instructions.md` | `.github/instructions/<name>.instructions.md`[^cli-vscode-instr] |
| Prompt files | `.github/prompts/<name>.prompt.md` | `.github/prompts/<name>.prompt.md` |
| Personal skills | `<user profile>/skills/` (Settings Sync), `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | `~/.copilot/skills/`, `~/.agents/skills/`, `~/.claude/skills/` |
| Repo skills | `.github/skills/<name>/SKILL.md` (also reads `.agents/skills/`, `.claude/skills/`) | `.github/skills/<name>/SKILL.md` (same alts) |
| MCP servers (workspace) | `.vscode/mcp.json` (uses `"servers"` key) | `.github/mcp.json` *or* `.mcp.json` (uses `"mcpServers"` key) |
| MCP servers (personal) | VS Code settings `mcp.servers` (user scope) | `~/.copilot/mcp-config.json` |
| Custom agents | `.github/agents/<name>.agent.md` (workspace) or `<user profile>/agents/` | `.github/agents/<name>.agent.md` (workspace) or `~/.copilot/agents/` |
| Hooks | `.github/hooks/*.json` (workspace), `~/.copilot/hooks` or `~/.claude/settings.json` (user) | `.github/hooks/*.json` (workspace), `~/.copilot/hooks/` (user); plugin hooks too |

[^cli-vscode-instr]: The CLI also reads `.vscode/copilot.instructions.json` for
    cross-tool compatibility — so a VS Code-authored instructions setup is
    portable to the CLI without renaming. Source: upstream `copilot-agent-runtime`
    `readVSCodeInstructions` / `readVSCodeInstructionFiles`.

!!! note "MCP: same protocol, two config files"
    Both hosts speak MCP. The **payload semantics are identical**, but the file
    they read and the JSON key they expect differ:

    | Host | File | Top-level key | Env-var syntax |
    |---|---|---|---|
    | Copilot CLI | `.github/mcp.json` *or* `.mcp.json` (project) | `"mcpServers"` | `${ENV_VAR}` |
    | VS Code | `.vscode/mcp.json` (workspace) | `"servers"` | `${env:ENV_VAR}` |

    For a mixed team, ship **both** files during the rollout window (or generate
    one from the other in a small script). See the
    [MCP customization page](../customizations/mcp.md) for full examples.

## Slash-command map

The CLI uses slash commands (`/instructions`, `/skills`, …) that surface what's
loaded for the current session. VS Code uses its own command palette and the Chat
view. Rough equivalents:

| You want to… | Copilot CLI | VS Code |
|---|---|---|
| See what custom instructions are active | `/instructions` | Chat → `@workspace /instructions` (or open the file) |
| See discovered skills | `/skills` | **Chat: Open Customizations** (Command Palette) → Agent Customizations editor |
| See discovered MCP servers + tools | `/mcp show` | MCP servers panel in the Chat view |
| Pick a custom agent | `/agent` | Agent picker at the bottom of the Chat view |
| See everything loaded | `/env` | Agent Customizations editor (Preview) |
| Run a prompt file | `/<name-of-prompt-file>` | Chat → `/<name-of-prompt-file>` (same syntax) |
| Inspect hook executions | `/hooks show` (and `~/.copilot/logs/`) | **GitHub Copilot Chat Hooks** output channel |

## Practical guidance

- **Almost everything is universal.** Custom Instructions, Prompt Files, Skills,
  Custom Agents, and Hooks all use the same files in both hosts. The harness you
  build for one tool benefits the other.
- **MCP is universal but the config file differs.** Same protocol; ship both
  `.vscode/mcp.json` (VS Code, `servers`) and `.mcp.json` (CLI, `mcpServers`)
  during a migration window. The CLI also accepts `.github/mcp.json`.
- **Hooks are now cross-host (VS Code is in Preview).** The CLI is still the
  more mature surface — richer event coverage and template variables — but a
  VS Code user with the same `.github/hooks/*.json` will get the same hooks
  firing.
- **Slash-command UX is CLI-specific.** Discovery commands (`/skills`,
  `/instructions`, `/mcp show`) exist as VS Code panels and the Agent
  Customizations editor (Preview) instead.

## When to introduce each layer to a mixed team

A rollout that works for "half VS Code, half CLI":

1. **Custom Instructions** — week 1. Universal, same file.
2. **Prompt Files** — week 1. Universal, same file.
3. **MCP** — week 2. Pick one server (GitHub MCP or filesystem). Ship both
   config files (`.vscode/mcp.json` + `.mcp.json`).
4. **Skills (workspace)** — week 3. Drop `SKILL.md` under `.github/skills/<name>/`
   — both hosts pick it up.
5. **Custom Agents** — week 4. Drop `.agent.md` under `.github/agents/` — same
   file format for both. CLI exposes them via `/agent`; VS Code via the agent
   picker.
6. **Hooks** — week 5+. VS Code support is in Preview; if your org allows it via
   enterprise policy, ship `.github/hooks/*.json` for both. Otherwise scope
   hooks to the CLI half of the team.

## See also

- [Customizations overview](../customizations/index.md) — every layer in detail.
- [Exercises](../exercises/index.md) — labs split into **Track A** (universal,
  same files in both hosts) and **Track B** (CLI-primary — same files work in
  VS Code, but the lab uses CLI-specific UX).
- [File layout](file-layout.md) — every customization file in one diagram.
