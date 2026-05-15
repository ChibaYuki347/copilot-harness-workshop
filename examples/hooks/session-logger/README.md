# Hook: session-logger

Append a one-line log entry whenever a Copilot CLI session starts or ends in this
repo. Lightweight; meant as a *starter* pattern for richer telemetry.

## Install

```
.github/hooks/session-logger/
├── hooks.json
├── log-session-start.sh
├── log-session-end.sh
└── README.md
```

```bash
chmod +x .github/hooks/session-logger/*.sh
```

Add `.copilot-logs/` to `.gitignore`.

## What gets logged

`.copilot-logs/sessions.log` accumulates lines like:

```
[2025-01-20T13:42:11Z] START session=abc-123 user=ada branch=feature/login head=2c4f
[2025-01-20T14:08:35Z] END   session=abc-123 branch=feature/login head=4a91 dirty_files=3
```

## Extending

- **Per-session file.** Replace `>> sessions.log` with `> sessions/$SESSION_ID.start.json`
  to keep each session in its own file.
- **Structured JSON.** Emit JSON lines for easy parsing with `jq` later.
- **Ship to telemetry.** Wrap the cat with `curl -X POST https://telemetry.example/api -d @-`.
- **Compute deltas.** Pair START/END entries to compute session duration; emit to a
  metrics dashboard.

## Caveats

- `sessionEnd` runs **after** the conversation ends. It cannot retroactively block
  anything. Use it for observability, not enforcement.
- Hooks have a `timeoutSec` cap; long network calls will be killed. Either keep it
  fast or fire-and-forget (`&`).
