#!/usr/bin/env bash
# Append a JSON Lines audit record for every Copilot tool call.
# Phase: pre | post | fail (passed as $1 from hooks.json).
# Reads the raw hook payload from stdin and never blocks.
#
# Output: $AUDIT_LOG (default ~/.copilot/audit.log), one JSON object per line.

set -euo pipefail

PHASE="${1:-unknown}"
LOG_FILE="${AUDIT_LOG:-$HOME/.copilot/audit.log}"
mkdir -p "$(dirname "$LOG_FILE")"

PAYLOAD="$(cat)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
USER_NAME="${USER:-$(whoami 2>/dev/null || echo unknown)}"
HOST_NAME="$(hostname 2>/dev/null || echo unknown)"
REPO="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

if command -v jq >/dev/null 2>&1; then
  jq -cn \
    --arg ts "$TS" \
    --arg phase "$PHASE" \
    --arg user "$USER_NAME" \
    --arg host "$HOST_NAME" \
    --arg repo "$REPO" \
    --arg branch "$BRANCH" \
    --argjson payload "${PAYLOAD:-null}" \
    '{ts:$ts, phase:$phase, user:$user, host:$host, repo:$repo, branch:$branch, payload:$payload}' \
    >> "$LOG_FILE" 2>/dev/null \
  || printf '{"ts":"%s","phase":"%s","raw":%s}\n' \
       "$TS" "$PHASE" "$(printf '%s' "$PAYLOAD" | jq -Rs '.')" >> "$LOG_FILE"
else
  # Fallback: no jq -> store a base64-encoded payload to keep the line parseable.
  ENCODED="$(printf '%s' "$PAYLOAD" | base64 | tr -d '\n')"
  printf '{"ts":"%s","phase":"%s","user":"%s","host":"%s","repo":"%s","branch":"%s","payload_b64":"%s"}\n' \
    "$TS" "$PHASE" "$USER_NAME" "$HOST_NAME" "$REPO" "$BRANCH" "$ENCODED" >> "$LOG_FILE"
fi

exit 0
