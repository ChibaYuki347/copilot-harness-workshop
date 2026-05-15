#!/usr/bin/env bash
#
# Log session end. Captures: duration (approx, from start log), files touched.

set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"

# Files modified during this session (best-effort: anything dirty in working tree).
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

cat >> "$LOG_DIR/sessions.log" <<EOF
[$TS] END   session=$SESSION_ID branch=$BRANCH head=$HEAD_SHA dirty_files=$DIRTY
EOF

exit 0
