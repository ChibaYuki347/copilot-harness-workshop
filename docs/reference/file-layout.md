# File layout reference

All the locations Copilot CLI reads from, on one page. Scope = "repo" means
discovered inside the workspace; "personal" = your home directory; "env" =
controlled by an environment variable.

## Custom Instructions

| Path | Scope | Format |
|---|---|---|
| `.github/copilot-instructions.md` | repo (one per repo) | Markdown |
| `.github/instructions/**/*.instructions.md` | repo (recursive) | Markdown + YAML frontmatter with `applyTo` |
| `AGENTS.md` | repo (also `CLAUDE.md`, `GEMINI.md` if present, in git root and cwd) | Markdown |
| `~/.copilot/copilot-instructions.md` | personal | Markdown |
| dirs listed in `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | env | Scanned for `AGENTS.md` and `.github/instructions/**/*.instructions.md` |

Discovery: walks from cwd up to the git root, reading any of the repo-scope files
it finds. Personal + env-driven files always apply.

## Prompt files (slash commands)

| Path | Scope |
|---|---|
| `.github/prompts/*.prompt.md` | repo |
| `~/.copilot/prompts/*.prompt.md` | personal |
| `~/.agents/prompts/*.prompt.md` | personal cross-tool |

A file named `release.prompt.md` is invoked as `/release`.

## Skills

| Path | Scope |
|---|---|
| `.github/skills/<name>/SKILL.md` | repo |
| `~/.copilot/skills/<name>/SKILL.md` | personal |
| `~/.agents/skills/<name>/SKILL.md` | personal cross-tool |

A skill folder can contain anything alongside `SKILL.md` — `references/`,
`templates/`, helper scripts. The model reads `SKILL.md` first; the rest is loaded
only when the skill says so.

## Hooks

| Path | Scope |
|---|---|
| `.github/hooks/<name>/hooks.json` | repo (multiple folders allowed) |
| `~/.copilot/hooks/<name>/hooks.json` | personal |

A single `hooks.json` can declare multiple events; multiple hooks folders compose
(they all run).

## MCP

| Path | Scope |
|---|---|
| `.mcp.json` (at git root) | repo |
| `~/.copilot/mcp-config.json` | personal (location follows `$COPILOT_HOME` if set) |

`.vscode/mcp.json` and `.devcontainer/devcontainer.json` are **no longer** read as
MCP config sources by current Copilot CLI versions[^vscode]. Workspace MCP servers
live in `.mcp.json` at the git root; user-level MCP servers live in
`~/.copilot/mcp-config.json` (not `mcp.json`).

[^vscode]: From the CLI changelog: *"Remove `.vscode/mcp.json` and
    `.devcontainer/devcontainer.json` as MCP server config sources; CLI now only
    reads `.mcp.json`. A migration hint appears when `.vscode/mcp.json` is detected
    without `.mcp.json`."*

## Custom agents

| Path | Scope |
|---|---|
| `.github/agents/<name>.agent.md` | repo |
| `~/.copilot/agents/<name>.agent.md` | personal |
| `agents/<name>.agent.md` in a `.github-private` org/enterprise repo | org / enterprise |

The `.agent.md` suffix is the canonical extension (also accepted as plain `.md` for
legacy/VS Code compatibility[^agent-ext]). A file named `security-reviewer.agent.md`
becomes the agent identifier `security-reviewer`.

[^agent-ext]: From the CLI changelog: *"Improved parsing of VS Code-formatted custom
    agents with the `.agent.md` suffix."* The GitHub docs note that the name defaults
    to "the filename (without the `.md` or `.agent.md` suffix)".

## Prompt-mode environment toggles

When you run Copilot in headless / prompt mode (`copilot -p ...`), workspace-trusted
features are **gated** by environment variables:

| Variable | Default | Effect when `=1` |
|---|---|---|
| `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS` | unset | Repo-level hooks in `.github/hooks/` are honored. |
| `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` | unset | Workspace `.mcp.json` is loaded. |

This prevents a malicious `git clone` from running arbitrary code via hooks the
first time you `copilot -p` it from a script.

## Cross-tool conventions (`~/.agents/`)

The `~/.agents/` tree is a community convention used by several agentic tools.
Copilot CLI reads from it as a **personal** source, so:

- Drop reusable skills / prompts / agents under `~/.agents/`.
- They'll be available in Copilot CLI **and** other tools that honor the convention
  (Cursor, Codex, OpenCode, etc.).

This is the cleanest place for *truly* tool-agnostic content.

## Logs

```
~/.copilot/logs/
```

One file per session. Useful when debugging hooks or MCP servers — set
`--log-level debug` to make them verbose.

## At-a-glance directory map

```
.
├── .github/
│   ├── copilot-instructions.md         # team baseline
│   ├── instructions/                   # path-specific (recursive)
│   │   └── **/*.instructions.md
│   ├── prompts/
│   │   └── *.prompt.md
│   ├── skills/
│   │   └── <name>/SKILL.md
│   ├── hooks/
│   │   └── <name>/hooks.json
│   └── agents/
│       └── *.agent.md
├── AGENTS.md                           # alternative to copilot-instructions.md
├── .mcp.json                           # MCP at git root
└── ...
~/
├── .copilot/
│   ├── copilot-instructions.md         # personal baseline
│   ├── prompts/, skills/, hooks/, agents/
│   ├── mcp-config.json                 # personal MCP servers
│   └── logs/
└── .agents/                            # cross-tool shared
    ├── prompts/, skills/, agents/
```
