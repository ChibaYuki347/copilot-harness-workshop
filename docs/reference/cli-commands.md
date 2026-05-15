# CLI commands & slash commands

A practical, copy-paste reference for the `copilot` CLI and the in-session slash
commands. This is **not** a generated CLI dump — it's the set you'll actually use,
with the *why*.

!!! tip "Authoritative source"
    `copilot --help` and `/help` inside a session are the source of truth. Pin those
    in a terminal tab; treat this page as the **annotated** version.

## Launching `copilot`

```bash
copilot                       # interactive session in the current directory
copilot --resume              # resume the most recent session for this dir
copilot --resume <session-id> # resume a specific session
copilot --log-level debug     # verbose logs (in addition to the session log file)
copilot --version             # print version
```

### Headless / prompt mode

```bash
copilot -p "Summarize the last 5 commits"          # one-shot
copilot -p "$(cat my-prompt.md)" --allow-tool=shell
copilot -p "/pr-review"                            # run a slash command headless
```

Useful for CI, scripting, "pre-commit AI checks." In prompt mode, repo-level hooks
and workspace MCP servers are **gated** behind env vars (see
[reference: file layout](file-layout.md#prompt-mode-environment-toggles)).

### Common flags

| Flag | Effect |
|---|---|
| `-p, --prompt <text>` | Run one prompt and exit. |
| `--allow-tool <pattern>` | Allow a tool without prompting. Supports glob matching, e.g. `--allow-tool='shell(npm run test:*)'`. Repeat the flag for multiple patterns. |
| `--deny-tool <pattern>` | Block a tool entirely. Same syntax as `--allow-tool`. |
| `--allow-all` / `--yolo` | **Dangerous.** Skip every permission prompt. CI only. |
| `--allow-all-paths` | Auto-approve every directory access prompt in `-p` mode. |
| `--resume [id]` / `--continue` | Resume the latest or a specific session. |
| `--enable-all-github-mcp-tools` | Expose the entire GitHub MCP toolset. |
| `--add-github-mcp-toolset <name>` | Enable one MCP toolset (e.g., `issues`). |
| `--add-github-mcp-tool <name>` | Enable one MCP tool by name. |
| `--disable-mcp-server <name>` | Disable a configured MCP server for this run. |
| `--additional-mcp-config <json\|@file>` | Inject extra MCP config inline or from a file (can repeat; later overrides earlier). |
| `--model <name>` / `--reasoning-effort <level>` / `--effort <level>` | Pick the model and reasoning effort. |
| `--agent=<name>` | Run the session with a custom agent. |
| `--experimental` | Enable experimental features (autopilot, etc.). |
| `--list-env` | In `-p` mode, log loaded plugins / agents / skills / MCP servers (useful in CI). |

For the canonical, version-specific list:

```bash
copilot help            # all CLI flags
copilot help permissions
copilot help environment
copilot help config
copilot help logging
```

## In-session slash commands

These are surfaced by `/help` inside a running session. The high-traffic ones are
bolded; this is the practical subset — for the complete list press `?` or run
`/help` in your CLI.

### Session & conversation

| Command | What it does |
|---|---|
| **`/help`** | Show all slash commands. |
| **`/exit`** | End the session. |
| `/clear` | Abandon this session and start fresh. |
| `/new` | Start a new conversation in the same workspace. |
| `/compact` | Summarize older context to free up tokens. |
| `/context` | Visualize current token usage. |
| `/usage` | Session statistics (premium requests, duration, lines edited, per-model tokens). |
| `/share` | Share the session / research report as Markdown, HTML, or a gist. |
| `/copy` | Copy the last response to the clipboard. |
| `/rewind` / `/undo` | Rewind the last turn and revert file changes. |
| `/resume` | Switch to a different session (id / task id / name). |
| `/rename` | Rename the current session (auto-name from history if no arg). |

### Permissions

| Command | What it does |
|---|---|
| **`/allow-all`** (alias **`/yolo`**) | Enable all permissions for this session. Subcommands: `on`, `off`, `show`. |
| **`/reset-allowed-tools`** | Undo `/allow-all` and re-trigger the autopilot permission dialog. |
| `/add-dir <path>` | Add a directory to the allowed list for file access. |
| `/list-dirs` | Display all allowed directories. |
| `/cwd <path>` | Change working directory (alias: `/cd`). |

### Customizations

| Command | What it does |
|---|---|
| **`/instructions`** | View and toggle loaded custom instruction files. |
| **`/skills`** | List, enable/disable, reload skills. Subcommands: `list`, `info`, `add`, `reload`, `remove`. |
| **`/mcp`** | MCP server admin (see below). |
| **`/agent`** | Browse and select from available custom agents (singular — not `/agents`). |
| `/plugin` | Manage plugins and plugin marketplaces. |
| `/env` | Show loaded environment details (instructions, MCP servers, skills, agents, plugins, LSPs, extensions). |
| `/lsp` | Manage Language Server configuration. |
| `/init` | Initialize Copilot instructions for this repository. |

### Agents & sub-agents

| Command | What it does |
|---|---|
| `/fleet` | Enable fleet mode (parallel sub-agent execution). |
| `/tasks` | View and manage background tasks / sub-agents. |
| `/sidekicks` | View running sidekick agents. |
| `/model` | Pick a model for this session. |
| `/delegate` | Send this session to GitHub and let Copilot open a PR. |
| `/plan` | Create an implementation plan before coding. |
| `/research` | Run deep research using GitHub + web search. |
| `/review` | Run the code-review agent on the current changes. |
| `/diff` | Review changes in the current directory. |
| `/pr` | Operate on PRs for the current branch. |
| `/autopilot` | Toggle autopilot mode (experimental). |

### Help & meta

| Command | What it does |
|---|---|
| `/feedback` | Send feedback to the Copilot team. |
| `/changelog` | Display the CLI changelog (append `summarize` for an AI summary). |
| `/version` / `/update` | Show / update the CLI. |
| `/theme` / `/statusline` / `/footer` | UI tweaks. |
| `/experimental` | Enable / disable experimental features. |
| `/streamer-mode` | Hide preview model names and quota details (for screen recording). |

### `/mcp` subcommands

| Command | What it does |
|---|---|
| `/mcp` | Open the interactive MCP picker. |
| `/mcp add` | Add a new MCP server interactively. |
| `/mcp show` (or just `/mcp`) | List configured servers and their state. |

You can also disable servers from the CLI via `--disable-mcp-server <name>` at launch.

## Env vars to know

| Variable | Meaning |
|---|---|
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | Extra directories scanned for instruction files. |
| `COPILOT_AGENT_SESSION_ID` | Provided **to hook scripts**. Identifies the session. |
| `COPILOT_CLI` | Set to `1` in hook scripts. Lets shared scripts detect "I'm running under Copilot CLI." |
| `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS` | Set `=1` to allow repo hooks in prompt mode. |
| `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` | Set `=1` to allow workspace MCP in prompt mode. |
| `GITHUB_TOKEN` | Picked up by the GitHub MCP server. |

## Where logs live

```
~/.copilot/logs/
```

Sessions get one log file each. When debugging hooks or MCP startup, set
`--log-level debug` and tail the latest file.

## See also

- [Custom Instructions](../customizations/custom-instructions.md)
- [Hooks](../customizations/hooks.md)
- [MCP](../customizations/mcp.md)
