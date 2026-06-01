# Hook: audit-all-tool-calls

Append a structured **JSON Lines** record to `~/.copilot/audit.log` for every
tool call Copilot makes — `preToolUse`, `postToolUse`, and
`postToolUseFailure`. Pure observability; never blocks.

Pairs with [`deny-dangerous-commands`](../deny-dangerous-commands/README.md):
that hook decides; this hook records.

## Why you want this

The "**don't blindly approve**" rule only works if you can review *afterwards*
what the agent actually did. Without an audit log you're trusting the chat
transcript, which:

- doesn't survive `/clear`,
- doesn't survive `/exit`,
- doesn't show MCP-tool calls in their raw form, and
- mixes user messages with tool calls so a `grep` is hard.

This hook gives you one append-only file you can `tail -f`, `grep`, or ship to a
SIEM.

## Install (Copilot CLI)

```bash
mkdir -p .github/hooks/audit-all-tool-calls
cp examples/hooks/audit-all-tool-calls/* .github/hooks/audit-all-tool-calls/
chmod +x .github/hooks/audit-all-tool-calls/log.sh
```

## Install (VS Code Copilot Chat — Preview)

Same files, same path. VS Code reads `.github/hooks/*.json`. If your workspace
hasn't picked them up:

```jsonc
// .vscode/settings.json
{
  "chat.hookFilesLocations": {
    ".github/hooks": true
  }
}
```

## Log format

`~/.copilot/audit.log`, one JSON object per line:

```json
{"ts":"2024-09-14T12:00:01Z","phase":"pre","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolInput":{"command":"npm test"},"sessionId":"abc-123"}}
{"ts":"2024-09-14T12:00:14Z","phase":"post","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolResult":{"exitCode":0,"stdout":"..."}}}
```

| Field | Meaning |
|---|---|
| `ts` | UTC timestamp, ISO 8601. |
| `phase` | `pre` (before tool runs), `post` (success), `fail` (non-zero exit). |
| `user` / `host` | Who and where (helpful for shared dev boxes / Codespaces). |
| `repo` / `branch` | git context at the time of the call. |
| `payload` | Raw hook payload from Copilot. Includes `toolName`, `toolInput`, and (for `post*`) `toolResult`. |

## Useful queries (with `jq`)

```bash
# All bash commands the agent ran today
jq -c 'select(.phase=="pre" and .payload.toolName=="bash") | {ts, cmd: .payload.toolInput.command}' ~/.copilot/audit.log

# Anything that failed
jq -c 'select(.phase=="fail")' ~/.copilot/audit.log

# Time-series count per tool, last 24h
jq -r 'select(.phase=="pre") | .payload.toolName' ~/.copilot/audit.log | sort | uniq -c | sort -rn

# Files Copilot edited / created in this repo
jq -c 'select(.phase=="post" and (.payload.toolName=="edit" or .payload.toolName=="create")) | .payload.toolInput.path' ~/.copilot/audit.log
```

## Caveats

- **The log can grow fast.** Rotate it (`logrotate`, `~/.copilot/audit.log.*`) or
  archive weekly. A 1-hour agentic session can easily produce 1–5 MB.
- **The payload contains anything the agent saw, including code snippets.**
  Treat it as sensitive; don't ship it raw to a public bucket.
- `postToolUse` does **not** fire if the tool was denied — that's
  `preToolUseFailure`-shaped; configure if you also want denial records.
- Hooks have a `timeoutSec` cap (5s here). Keep `log.sh` cheap; if you ship to a
  remote SIEM, fire-and-forget (`curl … &`) so a slow network doesn't stall the
  agent.
- The hook runs **synchronously before/after every tool call** — a broken script
  here is felt immediately. Test with `bash log.sh pre < some-payload.json`
  before enabling.

## See also

- [Governance → Auditing what the agent did](../../../docs/governance/auditing.md)
- [Governance → Approval cheat sheet](../../../docs/governance/approval-cheatsheet.md)
- [Hook events reference](../../../docs/reference/hook-events.md)
