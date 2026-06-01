# Hook: audit-demo (live demo)

This hook is wired at the **repo root** as a **live demonstration** of the
`postToolUse` hook surface. Anyone who clones this repo and runs `copilot`
(or opens VS Code Copilot Chat in this workspace, where hooks are still
Preview) will have it firing automatically.

> **Read-only and metadata-only by default.** This hook does not block,
> modify, or re-route any tool call. It does not log tool input/output
> content by default — only the tool name, timestamp, repo basename, and
> branch. Full-payload mode is opt-in via an environment variable.

## Requirements

- `bash` on `PATH`. On Windows-native (no Git Bash / WSL) the Copilot CLI
  hook runner skips Bash hooks; the audit log simply won't grow.
- Optional: `jq` for richer JSON shaping. Without `jq`, the hook still
  writes a minimal line per call.

## What you should see (default = metadata only)

Run a session, then:

```bash
tail -f ~/.copilot/copilot-harness-audit.log
```

Each line looks like:

```json
{"ts":"2026-06-01T12:00:01Z","repo":"copilot-harness-workshop","branch":"main","source":"copilot-harness-workshop","mode":"metadata","toolName":"bash","sessionId":"abc-123"}
```

Note what is **not** logged in default mode: command strings, file paths,
file contents, stdout, stderr, model output. If the agent reads a secret
or runs a sensitive command, the log captures only that `bash` ran — not
what it did.

## Verbose mode (opt-in, your machine only)

If you want to inspect full payloads for your own debugging:

```bash
export COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1
copilot
```

In this mode each line contains the entire Copilot hook payload —
`toolName`, `toolInput`, `toolResult` — which **may include code,
command output, file paths, and any sensitive material the agent
saw**. Treat the log as confidential and rotate it.

## Opt out without editing the repo

Set this per-machine; no need to delete tracked files:

```bash
export COPILOT_HARNESS_AUDIT=0
```

The hook still runs but exits early with no log write.

## Opt out by editing the repo (modifies your working tree)

| Method | Effect |
|---|---|
| `rm -rf .github/hooks/audit-demo` | Removes the hook entirely. Will appear as a deletion in `git status`. |
| Set `"postToolUse": []` in `hooks.json` | Keeps the directory but disables the event. Same caveat — local change shows up in `git status`. |
| Override with `~/.copilot/hooks/...` | User-scoped hooks load alongside workspace-scoped ones. Useful for adding behaviour, less reliable for blanket-disabling — prefer `COPILOT_HARNESS_AUDIT=0` for that. |

## Why this is safe-by-default

| Property | Why it matters |
|---|---|
| `postToolUse` only — no `preToolUse` | Cannot block or alter a tool call. |
| Metadata-only by default | The log contains no code, no command output, no file content. |
| Writes to `$HOME` outside the repo | Log will never be committed by accident. |
| 5-second timeout | A hung script can't stall the agent indefinitely. |
| Exits `0` even on failure | A broken log write never breaks the agent loop. |
| No outbound network calls | Nothing leaves your machine. |
| `COPILOT_HARNESS_AUDIT=0` per-machine switch | Disable without dirtying the working tree. |

## See also

- [Customizations → Hooks](../../../docs/customizations/hooks.md) — the full
  concept page.
- [`examples/hooks/audit-all-tool-calls/`](../../../examples/hooks/audit-all-tool-calls/)
  — a more complete template (covers `pre`, `post`, and `fail`, full payload
  by default).
- [`docs/getting-started/try-this-repo.md`](../../../docs/getting-started/try-this-repo.md)
  — the walkthrough that exercises every harness layer wired into this repo.
