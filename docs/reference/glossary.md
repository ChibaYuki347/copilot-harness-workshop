# Glossary

Terms used throughout this site, with one-paragraph definitions and a pointer to
where each is used.

## Agent

A persona Copilot CLI can run as. The "main" agent is the one you talk to in your
session. **Sub-agents** are spawned by the main agent (via the `task` tool) to handle
a scoped piece of work in their own context window. **Custom agents** are Markdown
files in `.github/agents/` (repo) or `~/.copilot/agents/` (personal) that define a new
agent identifier with its own system prompt and tool allowlist.

→ See [Custom Agents](../customizations/agents.md).

## `AGENTS.md`

A repo-root Markdown file that conveys conventions to multiple agentic tools, not
just Copilot CLI. A community convention. Functionally similar to
`.github/copilot-instructions.md`, but portable across tools (Cursor, Codex, OpenCode,
…). Files named `CLAUDE.md` and `GEMINI.md` are likewise honored.

## Built-in agents

Sub-agents that ship with Copilot CLI. The most useful are **`rubber-duck`** (design
critique), **`code-review`** (focused review of unstaged / branch diff), **`explore`**
(parallel codebase research). You invoke them with the `task` tool.

## Custom instructions

Plain-Markdown rules the agent loads automatically. Repo-scoped (`.github/copilot-instructions.md`,
`AGENTS.md`, `.github/instructions/*.instructions.md`), personal (`~/.copilot/copilot-instructions.md`),
or env-driven (`COPILOT_CUSTOM_INSTRUCTIONS_DIRS`).

→ See [Custom Instructions](../customizations/custom-instructions.md).

## Fleet mode

In-session mode (toggled with `/fleet`) optimized for running multiple sub-agents in
parallel. Different from "run one sub-agent" — fleet mode adjusts the main agent's
behavior to dispatch and reconcile.

## Hooks

Event-driven shell or HTTP callouts defined in `hooks.json`. Fire on `sessionStart`,
`sessionEnd`, `preToolUse`, `postToolUse`, `userPromptSubmitted`, etc. Can be
**advisory** (just log) or **blocking** (return `permissionDecision: "deny"`).

→ See [Hooks](../customizations/hooks.md), [Hook events reference](hook-events.md).

## MCP (Model Context Protocol)

Open protocol for exposing tools and data to AI agents in a typed, transport-agnostic
way. Copilot CLI supports MCP servers configured in `.mcp.json` (repo) or
`~/.copilot/mcp.json` (personal). Transports: `stdio`, `http`, `sse`.

→ See [MCP](../customizations/mcp.md).

## Prompt file

A `*.prompt.md` file under `.github/prompts/` (or personal equivalents). Becomes a
slash command: `release.prompt.md` → `/release`. Think "saved prompt", not "skill" —
no workflow phases, no required output contract.

→ See [Prompt Files](../customizations/prompt-files.md).

## Prompt mode

Headless mode (`copilot -p '...'`) — one prompt in, response out, exit. Used for CI
and scripting. Workspace-trusted features (repo hooks, workspace MCP) are gated by
env vars to prevent untrusted code from auto-running.

## Permission

A grant for the agent to call a tool (with given arguments). Granted interactively at
the permission prompt or pre-approved via `--allow-tool`, `.copilot/config.json`, or
hooks. Use `/allow-all` (alias `/yolo`) to skip all prompts in the current session
(dangerous) and `/reset-allowed-tools` to undo. Hooks can short-circuit individual
permission requests via the `permissionDecision` field.

## Ask mode

The chat-only host mode: you ask, the model answers and may propose diffs, but
**takes no actions on its own**. Default in VS Code Copilot Chat sidebar, on
GitHub.com, on mobile. The bridge between Ask and Agent is in
[Ask mode vs Agent mode](../getting-started/ask-vs-agent.md).

## Agent mode

The mode where Copilot **takes actions** on your behalf: reads files, edits
files, runs `bash`, calls MCP tools, retries on failure. Default in Copilot CLI;
opt-in via mode dropdown in VS Code Copilot Chat (Preview). Every action goes
through an approval prompt unless pre-allowed.

## Plan mode

A CLI sub-mode (`Shift+Tab` to cycle) where Copilot **doesn't take actions** —
it asks clarifying questions and proposes a structured plan for you to
approve. Useful before letting it loose on a multi-file change.

## Edit mode

A CLI sub-mode (`Shift+Tab` to cycle) optimized for **mechanical edits in a
known set of files** — fewer "let me think about this" loops, more direct
file writes. Less common day-to-day than Plan and the default.

## Auto-approve

The state where a tool's permission decision is granted in advance — either
session-wide (`A`llways allow at the prompt, `--allow-tool '<tool>(<args>:*)'`
at launch, `chat.tools.autoApprove` in VS Code) or by a hook returning
`permissionDecision: "allow"`. The opposite is **always-ask**, which forces
a prompt even when the tool is on the allow-list.

## MCP client

The side that **calls** the MCP tools — in our setting, Copilot itself. The CLI
includes a built-in MCP client; VS Code Chat includes one in Preview.

## MCP server

The side that **provides** the MCP tools — a separate process (stdio) or
endpoint (http) that exposes a typed tool list and handles each tool call. The
GitHub MCP server ships bundled with Copilot CLI; custom servers go in
`.mcp.json` (CLI) or `.vscode/mcp.json` (VS Code).

## Tool vs Skill vs Agent vs Instruction

A frequent point of confusion. Quick disambiguation:

| Concept | What it is | When the agent uses it | Who writes it |
|---|---|---|---|
| **Instruction** | Always-loaded prose (`.github/copilot-instructions.md`) | Every session, every turn | Repo / personal |
| **Skill** | On-demand documented procedure (`SKILL.md`) | When user intent matches `description` | Repo / personal |
| **Tool** | Atomic capability the agent can invoke (`bash`, `view`, MCP-provided) | When the model decides | Built-in or MCP server |
| **Agent** | A persona with its own system prompt + tool allowlist (`.agent.md`) | When delegated to via `task` or `/agent` | Repo / personal / built-in |

→ Instructions and Skills don't compete with Tools or Agents — they shape *how*
the agent uses them.

## Sidekick

A long-running auxiliary agent that runs alongside your main session (`/sidekicks`
to inspect). Use cases: keep a watcher agent fixing test failures in the background
while you work on features in the foreground.

## Skill

A reusable, model-readable procedure defined in `SKILL.md` (with YAML frontmatter)
under `.github/skills/<name>/`. Loaded **on demand** based on the skill's
`description`. Useful for multi-phase workflows with a defined output contract.

→ See [Skills](../customizations/skills.md).

## Sub-agent

An agent invoked from another agent's session. The `task` tool launches one. Each
sub-agent runs in its own context window. Sub-agents can be built-in
(`rubber-duck`, `code-review`, `explore`) or custom (files under `.github/agents/`).

## Tool

A capability Copilot CLI can invoke: `view`, `edit`, `create`, `grep`, `glob`,
`bash`, `task`, MCP-server-provided tools, etc. Every tool call may require a
permission decision; that's where `preToolUse` hooks plug in.

## Workspace trust

The CLI's notion of "this workspace's customizations are safe to load." On first run
in a clone, you may be prompted to trust it. Affects when repo `.mcp.json` and
`.github/hooks/` are honored, especially in prompt mode.

## See also

- [File layout reference](file-layout.md) — *where* each of these lives.
- [CLI commands reference](cli-commands.md) — *how* to interact with them.
