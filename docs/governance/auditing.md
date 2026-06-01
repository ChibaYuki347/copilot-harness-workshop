# Auditing what happened

Approval prompts are how you *prevent* the wrong thing. Audit logs are how you
*find out* after the fact. You want both.

This page is about the audit-log half: structured, append-only, queryable
records of every tool call Copilot made. Pure observability, no enforcement.

## What you get out of the box

Not much, by default. The chat transcript shows you the *agent's narration* of
what it did, but:

- It doesn't survive `/clear` or `/exit`.
- MCP-tool calls are abbreviated in the UI; full inputs aren't visible.
- It mixes user messages, agent reasoning, and tool calls into one timeline,
  so post-hoc `grep` for "everything that wrote to disk" is awkward.
- VS Code Chat has a copy-conversation button but the result is still prose.

So we build our own.

## Hook-based audit log { #hook-based-audit-log }

The smallest useful audit is one append-only file with one JSON object per
tool call. Drop in [`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls):

```bash
mkdir -p .github/hooks/audit-all-tool-calls
cp examples/hooks/audit-all-tool-calls/* .github/hooks/audit-all-tool-calls/
chmod +x .github/hooks/audit-all-tool-calls/log.sh
```

It hooks `preToolUse`, `postToolUse`, and `postToolUseFailure`, writing JSON
Lines to `~/.copilot/audit.log`:

```json
{"ts":"2024-09-14T12:00:01Z","phase":"pre","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolInput":{"command":"npm test"},"sessionId":"abc-123"}}
{"ts":"2024-09-14T12:00:14Z","phase":"post","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolResult":{"exitCode":0,"stdout":"..."}}}
```

It works in both Copilot CLI and VS Code Chat (the hook spec is the same).

## Useful queries

Once the log exists, `jq` gives you a real query language:

```bash
# Every bash command the agent has tried to run, ever
jq -c 'select(.phase=="pre" and .payload.toolName=="bash")
       | {ts, cmd: .payload.toolInput.command}' \
  ~/.copilot/audit.log

# Anything that failed, with the error
jq -c 'select(.phase=="fail")
       | {ts, tool: .payload.toolName, err: .payload.toolResult.error}' \
  ~/.copilot/audit.log

# Tool-call counts in the last 24h
jq -r 'select(.phase=="pre") | .payload.toolName' ~/.copilot/audit.log \
  | sort | uniq -c | sort -rn

# Files Copilot edited in the current repo
jq -c --arg repo "$(git rev-parse --show-toplevel)" \
  'select(.phase=="post"
          and .repo==$repo
          and (.payload.toolName=="edit" or .payload.toolName=="create"))
   | .payload.toolInput.path' \
  ~/.copilot/audit.log

# Anything that looks like a network call
jq -c 'select(.phase=="pre"
              and .payload.toolName=="bash"
              and (.payload.toolInput.command | test("curl|wget|http")))
       | {ts, cmd: .payload.toolInput.command}' \
  ~/.copilot/audit.log
```

Bookmark these in your shell history. The mental shift is from "I'll trust
the chat transcript" to "I have a SQL-ish log."

## Live tailing during a session

For high-stakes sessions, keep a second pane open:

```bash
tail -F ~/.copilot/audit.log | jq -c 'select(.phase=="pre") | {ts, tool: .payload.toolName, cmd: .payload.toolInput.command // .payload.toolInput.path // .payload.toolInput}'
```

This is the "watch what's being attempted, in real time" feed. Useful when you
have auto-approval expanded — you can see denials still being attempted, and
notice if the agent is iterating on something you don't want.

## Session-level summary at the end

The `sessionEnd` hook is the place for a final summary. A 5-line shell script
can collect:

- Number of tool calls of each type
- Files touched (with `git diff --stat HEAD`)
- Whether the working tree is dirty
- A pointer to today's audit log slice for this session

See [`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
for the start/end logger pattern. Extend it with a `jq` query that filters the
audit log by `sessionId`.

## Forwarding to a SIEM / central log

Two patterns:

- **Fire-and-forget in the hook**: append `| curl -X POST https://siem/api/log -d @- &`
  to `log.sh` so the line is shipped after being appended locally. Keep `&` to
  avoid stalling the agent if the network is slow.
- **Tail-and-ship sidecar**: leave `log.sh` purely local; run a separate
  process (`vector`, `fluent-bit`, `promtail`) that tails `~/.copilot/audit.log`
  and ships. Cleaner separation, recommended for org-wide rollout.

For org rollout, the Microsoft Foundry Tools PII-masking endpoint (covered as
a recipe in a forthcoming PR) can scrub user identifiers and code snippets
before the log leaves the laptop.

## Don't lose `/delegate` traces

When you `/delegate` to the cloud agent, the local audit log won't see the
remote actions. The cloud agent leaves its trace on GitHub (in the resulting
PR description and check runs). For full visibility:

- Always `/delegate` with **fine-grained PATs** (so the GitHub audit log shows
  the bot identity and the token scopes).
- Cross-reference the cloud agent PR with your local audit log's `delegate`
  call (`jq 'select(.payload.toolName | startswith("delegate"))'`).

## What this gives you, in incident terms

- "Did Copilot delete my `~/work/foo`?" → grep the log for `rm` between
  timestamps.
- "Did the agent ever read `.env`?" → grep for `toolName == view` and
  `toolInput.path == ".env"`.
- "Why did `git push` fail last Thursday?" → search for `phase == "fail"`
  records with `toolName == bash` and the relevant date range.
- "Was this MCP tool ever called?" → filter by `payload.toolName`.

## Caveats

- **The log grows fast.** Rotate it (e.g., `logrotate` daily). A typical
  agentic session is 1–5 MB.
- **The payload contains code snippets.** Treat the log as sensitive (no
  public buckets, no Slack uploads).
- **Hook failures are silent unless you check.** Test with
  `jq -e . ~/.copilot/audit.log >/dev/null && echo OK` periodically.
- **VS Code Chat hook Preview** is currently a preview feature; enterprise
  policy can disable hooks entirely. If you rely on this for audit, document
  the policy dependency.

## See also

- [Risk mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [Blast-radius limiting](./blast-radius.md)
- [`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls)
- [`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
- [Recipe → session-end secret scan](../recipes/session-end-secret-scan.md)
