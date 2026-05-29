# 6 · Hooks

🟡 **Intermediate · ~30 min**

🟩 **Track B — CLI-primary** (also runs in **VS Code Preview** with the same `.github/hooks/*.json` — check enterprise policy · [details](../reference/vscode-vs-cli.md))

## Learning objectives

By the end of this exercise you can:

- Wire `sessionStart` and `sessionEnd` hooks via `hooks.json`.
- Write a hook script that records useful diagnostic info to a log file.
- Confirm the hooks fire on a clean `/exit` and inspect their output.
- Reason about which session-termination paths fire `sessionEnd` (and which
  don't).

## Prerequisites

- A scratch git repo.
- `bash` available.
- ~30 minutes.

## Checkpoint commit

```bash
git commit --allow-empty -m "checkpoint: before hooks exercise"
```

## Scenario

You want a small audit trail: every time a Copilot session starts and ends in
this repo, append one line to `.copilot-logs/sessions.log` with the timestamp,
branch, HEAD sha, and how many files are dirty. Not for compliance — for
yourself, so you can `tail` it and remember what you were up to last week.

!!! warning "`sessionEnd` only fires on clean exits"
    `sessionEnd` runs on `/exit`, on EOF, and on a clean process exit. It
    does **not** fire if you `kill -9` the process, close the terminal
    without `/exit`, or crash. Don't rely on it for compliance-grade
    auditing — that's what enterprise policies are for. Use it for
    your-own-laptop nice-to-haves.

## Steps

### 1. Make the log directory gitignored

```bash
mkdir -p .copilot-logs
echo ".copilot-logs/" >> .gitignore
git add .gitignore && git commit -m "chore: ignore .copilot-logs"
```

We don't want the log itself making the working tree dirty.

### 2. Create the hook scripts

```bash
mkdir -p .github/hooks/session-logger
```

`.github/hooks/session-logger/log-session-start.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

echo "[$TS] START session=$SESSION_ID branch=$BRANCH head=$HEAD_SHA dirty_files=$DIRTY" \
  >> "$LOG_DIR/sessions.log"
```

`.github/hooks/session-logger/log-session-end.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

echo "[$TS] END   session=$SESSION_ID branch=$BRANCH head=$HEAD_SHA dirty_files=$DIRTY" \
  >> "$LOG_DIR/sessions.log"
```

Make both executable:

```bash
chmod +x .github/hooks/session-logger/*.sh
```

### 3. Wire the hooks

`.github/hooks/session-logger/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": ".github/hooks/session-logger/log-session-start.sh",
        "cwd": ".",
        "env": { "LOG_DIR": ".copilot-logs" },
        "timeoutSec": 10
      }
    ],
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/session-logger/log-session-end.sh",
        "cwd": ".",
        "env": { "LOG_DIR": ".copilot-logs" },
        "timeoutSec": 10
      }
    ]
  }
}
```

### 4. Run a session and exit cleanly

```bash
copilot
```

Accept folder trust if prompted (repo hooks load **only** in trusted dirs). Run
`/env` inside the session — you should see a "Hooks loaded: 2" line (one for
`sessionStart`, one for `sessionEnd`).

Type something trivial, then **exit cleanly**:

```text
/exit
```

### 5. Inspect the log

```bash
cat .copilot-logs/sessions.log
```

You should see two lines for the session you just ran:

```text
[2024-09-14T12:34:56Z] START session=abc-123 branch=main head=44bec3d dirty_files=0
[2024-09-14T12:35:42Z] END   session=abc-123 branch=main head=44bec3d dirty_files=0
```

## Definition of done { #definition-of-done }

All four must be true:

- [ ] `.github/hooks/session-logger/hooks.json` exists with both
      `sessionStart` and `sessionEnd` entries.
- [ ] Both shell scripts are executable.
- [ ] `/env` inside a session shows hooks loaded.
- [ ] After one clean `/exit`, `.copilot-logs/sessions.log` contains **one
      START line and one END line** with the same `session=` value.

## Reference solution { #reference-solution }

??? success "Show reference solution"
    The full session-logger from the docs site (identical structure):

    `hooks.json`:

    ```json
    --8<-- "examples/hooks/session-logger/hooks.json"
    ```

    `log-session-end.sh`:

    ```bash
    --8<-- "examples/hooks/session-logger/log-session-end.sh"
    ```

    For the full list of hook events (`sessionStart`, `sessionEnd`,
    `preToolUse`, `postToolUse`, `userPromptSubmit`, …) and which env vars
    each one exposes, see [Reference → Hook events](../reference/hook-events.md).

## Cleanup

```bash
rm -rf .github/hooks .copilot-logs
git restore --staged .gitignore && git checkout -- .gitignore
# (or just delete the ".copilot-logs/" line you added)
```

## Troubleshooting

- **No log lines appear.** Did you accept folder trust on session start? Did
  `/env` say hooks were loaded? If yes, run the scripts manually:
  `./.github/hooks/session-logger/log-session-end.sh` — they should append a
  line. If *that* fails, it's a shebang / permission / GNU-vs-BSD issue.
- **Only START fires, never END.** You probably closed the terminal instead of
  `/exit`-ing. `sessionEnd` requires a clean exit. Try again with `/exit`.
- **Hooks fire but the script error-exits.** Hooks are subject to a
  `timeoutSec` cap and a non-zero exit can block the session lifecycle in
  some configurations. Add `set -x` to the script and tail the log; or just
  remove `set -e` while debugging.

## What not to do

- **Don't write the log inside the working tree without gitignoring it.** Your
  repo will be permanently dirty.
- **Don't put network calls in a `sessionStart` hook.** It runs *before* your
  prompt and can delay every session start by seconds.
- **Don't run `sudo` or anything destructive from a hook.** Repo hooks are
  trusted on `cwd` acceptance — a malicious `hooks.json` in a stranger's repo
  shouldn't be able to do real damage to you.

## Stretch goals

1. **Add a `preToolUse` guard** that denies the `edit` tool on files matching
   `**/secrets/**`. Use the `block` action in the hook output. Test by
   trying to edit such a file inside a session.
2. **Aggregate logs across sessions.** Add a `postToolUse` hook that records
   one line per *tool call* (truncated). Compute a session-summary later
   with `awk` / `jq`.
