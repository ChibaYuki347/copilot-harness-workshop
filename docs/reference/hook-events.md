# Hook events reference

Every event Copilot CLI fires that you can attach a hook to, with: when it fires,
what payload your script sees on stdin, and what response shape (if any) the CLI
respects in return.

!!! note
    Hook event names are written in **camelCase** here (the canonical form in
    `hooks.json`). PascalCase variants (`SessionStart`) are also accepted for
    compatibility with VS Code's Chat hooks; prefer camelCase in new files.

## Lifecycle events

### `sessionStart`

| | |
|---|---|
| Fires when | A new Copilot CLI session is created (a fresh `copilot` run, not a `/clear`). |
| Payload (stdin) | JSON: `{ "sessionId": "...", "cwd": "...", "modelId": "...", "instructions": [...] }` |
| Response respected | None (informational). |
| Common uses | Log session start, pre-warm caches, write a session header to a log file. |

### `sessionEnd`

| | |
|---|---|
| Fires when | The session ends (`/exit`, EOF, or process exits cleanly). |
| Payload | JSON with session summary fields. |
| Response | Mostly informational. A `response` field is surfaced as a final message; `stopProcessing` is ignored (session is over). |
| Common uses | Secret scan, git status summary, post to a notification channel. |

### `preCompact`

| | |
|---|---|
| Fires when | Just before `/compact` runs (manual or automatic context compaction). |
| Payload | JSON with the current conversation size & threshold. |
| Response | None enforced. |
| Common uses | Snapshot the full transcript before it gets summarized. |

## Tool events

### `preToolUse`

| | |
|---|---|
| Fires when | Just before the agent invokes a tool (e.g., `bash`, `edit`, `view`, an MCP tool). |
| Payload | JSON: `{ "toolName": "bash", "toolInput": {...}, "sessionId": "..." }` |
| Response respected | **Yes — this hook can block.** |
| Common uses | Permission gating, deny-list dangerous commands, redirect a tool call. |

#### Response shape

```json
{
  "permissionDecision": "allow" | "deny" | "ask",
  "response": "Reason shown to the agent and the user.",
  "stopProcessing": false
}
```

- `permissionDecision: "deny"` — the tool call is rejected. The `response` is shown
  to the agent (so it can adapt).
- `permissionDecision: "ask"` — Copilot prompts the user before running, regardless
  of stored permissions.
- `permissionDecision: "allow"` — explicit allow (skip the prompt).
- Omitting the field uses the normal permission flow.

#### Matcher

```json
{
  "type": "command",
  "matcher": "^bash$",
  "bash": "./check.sh"
}
```

`matcher` is a regex against the tool name. Use it to scope hooks (e.g., only
`bash`, only `edit`).

### `postToolUse`

| | |
|---|---|
| Fires when | After a tool call has succeeded. |
| Payload | JSON: `{ "toolName", "toolInput", "toolResult", "sessionId" }` |
| Response respected | Informational `response`; cannot retroactively block. |
| Common uses | Auto-format files written by `edit`/`create`, log file changes, send a notification when long jobs finish. |

### `postToolUseFailure`

| | |
|---|---|
| Fires when | After a tool call has failed (non-zero exit, exception). |
| Payload | JSON with the failure detail. |
| Response | Informational. |
| Common uses | Capture failed `bash` invocations to a log for debugging. |

## Prompt events

### `userPromptSubmitted`

| | |
|---|---|
| Fires when | Just after the user submits a prompt, before the agent reasons over it. |
| Payload | JSON: `{ "prompt": "...", "sessionId": "..." }` |
| Response | `response` is **prepended to the agent's context**, so you can inject
   dynamic facts ("current sprint is XYZ"). `stopProcessing: true` aborts the prompt. |
| Common uses | Inject "now()" / branch name / current ticket; redact obvious secrets
   before they reach the model. |

### `notification`

| | |
|---|---|
| Fires when | The CLI is about to show a desktop / inline notification (e.g., long task complete). |
| Payload | Notification text and metadata. |
| Response | Informational. |
| Common uses | Mirror notifications to Slack, suppress noisy ones. |

### `permissionRequest`

| | |
|---|---|
| Fires when | The CLI is about to prompt the user for a permission decision. |
| Payload | The proposed action. |
| Response | Can short-circuit the prompt with a `permissionDecision`. |
| Common uses | Centralized policy ("anything touching `prod/` always asks"). |

## Sub-agent events

### `subagentStart`

| | |
|---|---|
| Fires when | A sub-agent (built-in or custom) starts. |
| Payload | `{ "agent": "...", "prompt": "...", "sessionId": "..." }` |
| Response | A returned `additionalContext` is injected into the sub-agent's prompt. |
| Common uses | Log fan-out, mirror sub-agent runs to telemetry, inject parent-session context. |

### `subagentStop`

| | |
|---|---|
| Fires when | A sub-agent has stopped (succeeded, failed, or was cancelled). |
| Payload | Stop reason and the sub-agent identifier. |
| Response | Informational. |
| Common uses | Capture sub-agent results, log durations per agent type. |

### `agentStop`

| | |
|---|---|
| Fires when | The main agent stops (via `task_complete`, error, or user cancel). |
| Payload | Stop reason. |
| Response | Informational. |
| Common uses | Cleanup, log total duration. |

## Hook script env vars

Every hook script (`type: "command"`) is invoked with:

| Variable | Set by | Meaning |
|---|---|---|
| `COPILOT_AGENT_SESSION_ID` | CLI | Stable session identifier; correlates events. |
| `COPILOT_CLI` | CLI | Always `1`. Lets shared scripts know "I'm under Copilot CLI." |
| Variables under `env: {...}` in `hooks.json` | you | Anything you set in the hook config. `${VAR}` is resolved from the parent env. |

## Response JSON: full schema

```jsonc
{
  // Shown to the user and (for prompt / preToolUse hooks) added to model context.
  "response": "Some message",

  // Additional structured context the agent should see (preToolUse, subagentStart,
  // sessionStart).
  "additionalContext": "Extra grounding info",

  // For preToolUse: "allow" | "deny" | "ask". Other events: ignored.
  "permissionDecision": "deny",

  // For preToolUse: rewrite the tool's arguments before it runs.
  "modifiedArgs": { "command": "..." },
  "updatedInput": { /* alternative name accepted */ },

  // Abort whatever was about to happen. Honored on userPromptSubmitted, preToolUse;
  // ignored on terminal events like sessionEnd.
  "stopProcessing": true
}
```

If your script writes **plain text** to stdout, it's treated as `response`. Use JSON
when you need any other field.

## See also

- [Hooks customization](../customizations/hooks.md)
- [Session-end secret-scan recipe](../recipes/session-end-secret-scan.md)
