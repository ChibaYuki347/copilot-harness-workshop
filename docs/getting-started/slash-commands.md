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

## VS Code Copilot Chat — equivalents { #vscode-equivalents }

The tables above are **Copilot CLI** commands. VS Code Copilot Chat exposes the same
capabilities but through different surfaces: some are settings in `settings.json`,
some are buttons in the Chat panel, some are dedicated VS Code commands (run via
**Command Palette → `Chat: ...`**).

| CLI slash command | VS Code equivalent | Notes |
|---|---|---|
| `/help` | **Chat: View Help** command, or `?` button in Chat header | |
| `/env` | **Chat: Show Configuration** + the Chat **"View tools"** dropdown | Shows which instructions / agents / MCP servers / tools are loaded for the current session. |
| `/context` | Token usage badge on the Chat input | Hover for breakdown. |
| `/compact` | **Chat: Start New Chat** (with carry-over disabled) | VS Code doesn't summarize history in-place; you start a fresh chat. |
| `/init` | **GitHub Copilot: Generate Instructions** command | Creates `.github/copilot-instructions.md`. |
| `/instructions` | Settings → `github.copilot.chat.codeGeneration.useInstructionFiles` (toggle) + the **"Instructions"** picker in the Chat input | Per-file enable/disable lives in the picker. |
| `/skills` | **Chat: Manage Skills** command | Skills loaded from `.github/skills/` show automatically; this command lets you enable/disable. |
| `/mcp` | `.vscode/mcp.json` (project) + Settings → `mcp.servers` (user) + **MCP: List Servers** command | VS Code uses different config files; the runtime behavior is the same. See [MCP](../customizations/mcp.md#config-locations). |
| `/agent` | The **agent picker** in the Chat header (dropdown next to mode) | Custom agents from `.github/agents/*.agent.md` appear automatically. |
| `/plan` (Plan mode) | **Plan mode** toggle in Chat header (next to "Ask" / "Edit" / "Agent") | Same concept, different UI. See [Ask vs Agent](./ask-vs-agent.md). |
| `/diff` | The **diff view** that opens automatically when Agent mode edits files | No explicit command needed; every edit opens a diff. |
| `/review` | **GitHub Copilot: Review Selection / Review Changes** command | Powered by the same code-review agent. |
| `/pr` | The **GitHub Pull Requests** extension's panel (separate extension) | Not a Copilot Chat command; Copilot Chat *uses* the extension's commands. |
| `/undo` / `/rewind` | Standard **VS Code Undo** (Ctrl/Cmd+Z) in each affected file | Chat doesn't have a transactional rewind; you undo per file. |
| `/fleet`, `/tasks`, `/sidekicks` | **No direct equivalent in VS Code yet** | Parallel sub-agent fan-out is CLI-only as of now. |
| `/resume` | **Chat: Open Chat...** picker (recent chats) | |
| `/share` | **Chat: Export...** command (Markdown / clipboard) | |
| `/allow-all` | Settings → `chat.tools.autoApprove` (boolean) | Same risk profile; same advice — pair with deny-list hooks. |
| `/add-dir` | Workspace trust dialog (one-time per folder) | VS Code's workspace-trust prompt covers this. |
| `/reset-allowed-tools` | **Chat: Reset Trusted Tools** command | |
| `@path` | **`#file:path/to/file`** in the Chat input | Different prefix character; same effect. |
| `#123` | **`#issue:123`** or **`#pr:123`** in Chat | Disambiguated by prefix. |
| `!cmd` | Not directly supported in Chat input | Use Agent mode and let it run the command. |

!!! tip "When in doubt — Command Palette"
    Almost every Copilot Chat capability is a Command Palette entry under
    **Chat: ...**, **GitHub Copilot: ...**, or **MCP: ...**. If a CLI slash
    command isn't listed above, search the palette for keywords — most have
    an equivalent that's just discoverable by a different name.

## Programmatic mode

For CI or scripting, use the **headless mode**:

```bash
copilot -p "Summarize the diff between main and HEAD" --allow-tool='shell(git)'
```

See `copilot --help` for `--allow-tool` syntax and the full list of flags.

→ [Customizations overview](../customizations/index.md)
