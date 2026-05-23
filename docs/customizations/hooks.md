# 🪝 Hooks

**Run a script (or call an HTTP endpoint) when the agent crosses a lifecycle event.**

!!! abstract "Where it works"
    🟢 **Copilot CLI** · 🟢 **VS Code (Preview)** — same `.github/hooks/*.json` JSON format (Claude Code-compatible) is read by both hosts. VS Code support is Preview as of 2026-05; see the [official VS Code Hooks docs](https://code.visualstudio.com/docs/copilot/customization/hooks). User-scope locations differ: CLI uses `~/.copilot/hooks/`; VS Code uses `~/.copilot/hooks` or `~/.claude/settings.json`. Your **organization's enterprise policy** may disable hooks in VS Code — check before relying on them. See [VS Code vs CLI](../reference/vscode-vs-cli.md).

Hooks are the *automation* layer. They let you observe and *gate* what the agent does
without changing how you prompt it.

## When to use them

- You want every session to **log** prompts and tool calls for audit.
- You want a **guardrail** that blocks dangerous commands (`rm -rf /`, `git push --force` on `main`).
- You want a **session-end** task: auto-commit, secret scan, dependency audit.
- You want to **inject context** into specific tool calls based on their arguments.
- You want to **POST events** to your internal SIEM / Slack / observability stack.

## Anatomy

A hook is a directory containing a `hooks.json` config plus any scripts it invokes.

```
.github/hooks/<hook-name>/
├── hooks.json
├── README.md
└── <your-script>.sh
```

The same shape works at user scope under `~/.copilot/hooks/<hook-name>/`.

## Minimal example — `sessionEnd` secret scan

`.github/hooks/secrets-scanner/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/secrets-scanner/scan-secrets.sh",
        "cwd": ".",
        "env": {
          "SCAN_MODE": "warn",
          "SCAN_SCOPE": "diff"
        },
        "timeoutSec": 30
      }
    ]
  }
}
```

This is the pattern used by [`github/awesome-copilot`'s secrets-scanner](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner).
When the session ends, `scan-secrets.sh` runs against the diff and prints any matches.

## Hook events

| Event | Fires when… |
|---|---|
| `sessionStart` | A new session begins (once per session). |
| `sessionEnd` | A session ends (once per session). |
| `userPromptSubmitted` | The user submits a prompt. **Can short-circuit** and return a response without invoking the model. |
| `preToolUse` | The agent is about to invoke a tool. Can `allow` / `ask` / `deny` it, or modify the args. |
| `postToolUse` | A tool succeeded. |
| `postToolUseFailure` | A tool failed. |
| `notification` | Async events: shell completion, permission prompt shown, elicitation dialog, agent done. |
| `permissionRequest` | A tool permission prompt is about to be shown. Can pre-approve / deny. |
| `preCompact` | Context compaction is about to run. |
| `subagentStart` | A sub-agent is being spawned. Can inject extra context. |
| `subagentStop` | A sub-agent has stopped. |
| `agentStop` | The agent stops (via `task_complete` or otherwise). |

For the full event reference and payload shapes see [Reference → Hook events](../reference/hook-events.md).

## Hook types

Three kinds of hook entries can appear in the `hooks` array:

=== "Command (local exec)"

    ```json
    {
      "type": "command",
      "bash": "./scripts/audit.sh",
      "cwd": ".",
      "env": { "AUDIT_LEVEL": "high" },
      "timeoutSec": 30
    }
    ```

    Use `command` cross-platform alias instead of `bash` if your script should run via
    `cmd` or PowerShell on Windows.

=== "HTTP (POST JSON)"

    ```json
    {
      "type": "http",
      "url": "https://hooks.example.com/copilot-events",
      "headers": { "Authorization": "Bearer ${SIEM_TOKEN}" },
      "timeoutSec": 5
    }
    ```

    The hook payload is POSTed as JSON. Useful for sending events to an external
    observability/security stack without shelling out.

=== "With matcher (preToolUse only)"

    ```json
    {
      "type": "command",
      "matcher": "^bash$",
      "bash": "./guard-bash.sh",
      "timeoutSec": 10
    }
    ```

    `matcher` is a regex against the tool name. The hook only fires for tools whose name
    fully matches.

## Hook return contract

A hook script's **stdout is interpreted as JSON** when the event supports rich
responses. For example, a `preToolUse` hook can return:

```json
{
  "permissionDecision": "deny",
  "response": "Force-push on protected branch refused by org policy.",
  "additionalContext": "Branch=main, user=alice"
}
```

…or for `userPromptSubmitted`, it can short-circuit and return a response directly:

```json
{
  "response": "I won't run that — the prompt contains a `--force-yes` flag in production scope.",
  "stopProcessing": true
}
```

`preToolUse` hooks can also rewrite the tool call before it runs, by returning
`modifiedArgs` or `updatedInput`[^modify]:

```json
{
  "modifiedArgs": { "command": "git push --dry-run" }
}
```

[^modify]: From the changelog: *"preToolUse hooks now respect modifiedArgs/updatedInput,
    and additionalContext fields."*

Hooks that don't need to return anything special can simply exit `0` and print
human-readable status to stderr (visible in `--verbose`).

## Where they live

| Path | Scope |
|---|---|
| `.github/hooks/<name>/hooks.json` | Repo (committed). |
| `~/.copilot/hooks/<name>/hooks.json` | Personal. |
| Plus settings-style configs in `settings.json`, `settings.local.json`, `config.json` | Less common. |

Repo hooks load only **after folder trust is confirmed** — Copilot won't run them on a
brand-new clone without your explicit consent.

## Environment variables hooks receive

- `COPILOT_AGENT_SESSION_ID` — unique ID for this session.
- `COPILOT_CLI=1` — useful in `git` hooks to detect "I'm being run by Copilot" and skip
  interactive prompts.
- Plus everything you specify in `env:` in `hooks.json`.

## Modes that affect hooks

- In **prompt mode (`-p`)**, repo hooks and workspace MCP servers are *opt-in* via env vars:
    - `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=1`
    - `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP=1`
- In **interactive mode**, both load after trust confirmation.

## Pitfalls

!!! warning "Hooks that misbehave"
    - **Slow hooks block the agent.** Set a tight `timeoutSec`. A `sessionStart` hook
      that takes 30 seconds will make every session feel laggy.
    - **Hooks aren't sandboxed.** A malicious hook can run anything. Review hooks like
      any other code you check into the repo.
    - **Hooks fire only after trust.** Don't put your "first impression" logic into a
      `sessionStart` hook — the agent has already been running for a moment by the time
      it fires on a fresh repo.

## VS Code variant (Preview) { #vs-code-variant }

VS Code Copilot Chat reads the same `.github/hooks/*.json` format. As of 2026-05,
hooks in VS Code are in **Preview**.

### Locations VS Code searches

| Scope | Default file location |
|---|---|
| Workspace | `.github/hooks/*.json` |
| Workspace (Claude format) | `.claude/settings.json`, `.claude/settings.local.json` |
| User | `~/.copilot/hooks`, `~/.claude/settings.json` |
| Per-agent | `hooks:` field inside a custom agent's `.agent.md` frontmatter (set `chat.useCustomAgentHooks: true`) |
| Plugin | `hooks.json` or `hooks/hooks.json` in the plugin (same as CLI) |

Workspace hooks take precedence over user hooks for the same event. Customize what
gets loaded via `chat.hookFilesLocations` in `settings.json`:

```jsonc
{
  "chat.hookFilesLocations": {
    ".github/hooks": true,
    ".claude/settings.local.json": true,
    ".claude/settings.json": true,
    "~/.claude/settings.json": true
  }
}
```

### Event-name casing differences

The site's examples use camelCase (`sessionStart`, `preToolUse`, …) — that's what
`awesome-copilot` uses and what the CLI accepts. The **official VS Code Hooks
docs** use **PascalCase** (`SessionStart`, `PreToolUse`, `Stop`, …) and don't list
a `sessionEnd` event — VS Code calls session end **`Stop`**. The CLI accepts both
casings (PascalCase aliases via `vsCodePreToolUseInputMapper`), so you can usually
write camelCase and have both hosts pick it up — but if you author for VS Code
first, prefer PascalCase + `Stop` over `sessionEnd`. See the
[official VS Code Hooks reference](https://code.visualstudio.com/docs/copilot/customization/hooks)
for the canonical event list.

### Verifying VS Code hooks fired

Open **View → Output** in VS Code and select the **GitHub Copilot Chat Hooks**
channel. Each hook execution logs its stdout/stderr there.

!!! warning "Enterprise policy gate"
    Organizations can disable VS Code hooks entirely. The official VS Code docs
    say: *"Your organization might have disabled the use of hooks in VS Code."*
    Confirm with your admin before relying on them for security-critical
    automation.

## Verification

```text
/env                # shows count of loaded hooks
copilot --verbose   # surfaces hook stdout/stderr inline
```

(VS Code users: see the *GitHub Copilot Chat Hooks* output channel.)

## Next

→ [🔌 MCP Servers](mcp.md) — when you want to expose **tools**, not just react to events.
→ Recipe: [session-end secret scan](../recipes/session-end-secret-scan.md).
