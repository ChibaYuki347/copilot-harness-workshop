# Recipe: Session-end secret scan

**Catch leaked secrets the moment a Copilot session ends — before you push.**

## Problem

Copilot occasionally generates code that *looks like* a real config file. If it
inadvertently writes a credential into `.env.local` while solving an unrelated task,
you want to know **immediately**, not when a teammate flags it in review.

## Layers used

- **Hook** on `sessionEnd`.

## File layout

```
.github/hooks/secrets-scanner/
├── README.md
├── hooks.json
└── scan-secrets.sh
```

## `hooks.json`

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

This is the same pattern used by [`github/awesome-copilot/hooks/secrets-scanner`](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner) — adopt it directly, or use the trimmed version below.

## `scan-secrets.sh` (minimal)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCAN_MODE="${SCAN_MODE:-warn}"   # warn | block
SCAN_SCOPE="${SCAN_SCOPE:-diff}" # diff | all

if [[ "$SCAN_SCOPE" == "diff" ]]; then
  # Files modified during this session.
  FILES=$(git diff --name-only HEAD || true)
else
  FILES=$(git ls-files)
fi

[[ -z "$FILES" ]] && exit 0

# Patterns adapted from common secret-scan rules. Add your own.
PATTERN='(AKIA[0-9A-Z]{16})|(ghp_[A-Za-z0-9]{36})|(xox[abps]-[A-Za-z0-9-]{10,})|(-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)'

HITS=$(echo "$FILES" | xargs grep -EnH "$PATTERN" 2>/dev/null || true)

if [[ -z "$HITS" ]]; then
  echo "🔒 secrets-scanner: clean ($SCAN_SCOPE)" >&2
  exit 0
fi

echo "🚨 secrets-scanner: possible secrets detected:" >&2
echo "$HITS" >&2

if [[ "$SCAN_MODE" == "block" ]]; then
  echo "{\"response\": \"Possible secret detected. Review the files above before committing.\", \"stopProcessing\": true}"
  exit 0
fi

# warn mode: print only
exit 0
```

Make it executable:

```bash
chmod +x .github/hooks/secrets-scanner/scan-secrets.sh
```

## How it runs

1. You finish your work in Copilot CLI; you exit the session (`/exit`, `Ctrl+D`, or task complete).
2. The `sessionEnd` event fires.
3. `scan-secrets.sh` greps modified files for credential-shaped strings.
4. Findings are printed to your terminal.

## Variations

- **`block` mode.** With `SCAN_MODE=block`, the hook returns a JSON response that
  surfaces a clear warning in the CLI output. It can't actually "unwind" the session
  (that already ended), but it forces visibility.
- **`preToolUse` instead of `sessionEnd`.** Use `preToolUse` matching the `bash` tool
  with arguments containing `git commit` or `gh pr create` if you want to block before
  the secret can leave the local repo. The hook returns `{ "permissionDecision": "deny" }`.
- **External scanner.** Replace the inline grep with `trufflehog`, `gitleaks`, or your
  org's chosen tool. The shell of the recipe stays the same.
- **POST to SIEM.** Use the `http` hook type instead of `command` and post the diff
  metadata to your security stack.

## Pitfalls

!!! warning "Don't trust the warn-only mode for compliance"
    A warn-only hook is **advisory**. If you have a real compliance requirement, run
    the equivalent scan in CI (where you control the environment) and gate merges
    on it. Use the local hook to **shorten the feedback loop**, not as the only line
    of defense.

## Try it

The runnable starter is at [`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
(and the upstream [`hooks/secrets-scanner`](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner) is a richer reference).
