#!/usr/bin/env bash
#
# Log session start. Captures: when, where, who, on what branch.

set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
USER_NAME="$(whoami 2>/dev/null || echo unknown)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"

cat >> "$LOG_DIR/sessions.log" <<EOF
[$TS] START session=$SESSION_ID user=$USER_NAME branch=$BRANCH head=$HEAD_SHA
EOF

exit 0
