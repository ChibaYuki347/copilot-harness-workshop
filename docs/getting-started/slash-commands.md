# Slash commands tour

Slash commands are the operating handles of Copilot CLI. They're invoked by typing
`/command` at the start of an input.

Run `/help` inside any session for the full list. Below is a curated tour of the ones
you'll use most when **customizing** the agent.

## Environment & state

| Command | What it does |
|---|---|
| `/env` | Show all loaded instructions, MCP servers, skills, agents, plugins, LSP servers. **First thing to run when debugging "why isn't my customization applied?".** |
| `/context` | Visualize token usage of the context window. |
| `/compact` | Summarize history to free context budget. |
| `/init` | Generate a starter `.github/copilot-instructions.md` for the current repo. |
| `/instructions` | View and toggle individual instruction files. |

## Customization management

| Command | What it does |
|---|---|
| `/skills` | List skills, enable/disable, `add` new ones. |
| `/mcp` | Manage MCP servers (`show`, `enable`, `disable`, `auth`, `reload`). |
| `/agent` | Browse and pick a custom agent for the next turn. |
| `/plugin` | Manage plugin marketplaces. |
| `/lsp` | View / configure LSP servers. |

## Code workflow

| Command | What it does |
|---|---|
| `/plan` | Build an implementation plan before coding (also `Shift+Tab`). |
| `/diff` | Review the changes the agent made this session. |
| `/review` | Run the built-in code-review agent on the diff. |
| `/pr` | Operate on the PR for the current branch. |
| `/delegate` | Hand the task to Copilot in the cloud — opens a PR async. |
| `/undo` | Rewind the previous turn (including file edits). |
| `/rewind` | Same as `/undo`. |

## Multi-agent / parallelism

| Command | What it does |
|---|---|
| `/fleet` | Enable **fleet mode** for parallel sub-agent execution. |
| `/tasks` | View and manage background tasks (sub-agents and shell commands). |
| `/sidekicks` | View running sidekick agents. |

## Sessions

| Command | What it does |
|---|---|
| `/resume` | Switch to a different session (by ID, task ID, or name). |
| `/share` | Export the session to Markdown, HTML, or a GitHub gist. |
| `/chronicle` | Session history insights. |
| `/remote` | Toggle remote control from GitHub web/mobile. |

## Permissions

| Command | What it does |
|---|---|
| `/allow-all` | Enable all permissions (tools, paths, URLs) for this session. **Risky** — read [the security note](#permissions). |
| `/add-dir` | Add a directory to the allowed list for file access. |
| `/reset-allowed-tools` | Reset session tool allowlist. |

## Inline modifiers (not slash commands but useful here)

| Token | Effect |
|---|---|
| `@path` | Include file contents in the prompt. |
| `#123` | Reference an issue or PR. |
| `!cmd` | Run `cmd` in the shell and use the output. |

## Permissions

Copilot is **deny-by-default for shell tools**: every command requires approval unless
you've allowed it for the session. The approval prompt shows:

1. The exact command line that would run.
2. The cwd it would run in.
3. Two yes-options ("yes once" vs "yes for this session") and a no-option that lets
   you steer.

Treat `/allow-all` like `sudo`: only use it when you're confident in the blast radius.

## Programmatic mode

For CI or scripting, use the **headless mode**:

```bash
copilot -p "Summarize the diff between main and HEAD" --allow-tool='shell(git)'
```

See `copilot --help` for `--allow-tool` syntax and the full list of flags.

→ [Customizations overview](../customizations/index.md)
