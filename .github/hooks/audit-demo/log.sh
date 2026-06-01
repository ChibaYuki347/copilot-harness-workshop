#!/usr/bin/env bash
# Live-demo audit hook for copilot-harness-workshop.
#
# Appends a single JSONL line per successful tool call to
# $AUDIT_LOG (default ~/.copilot/copilot-harness-audit.log).
#
# Properties (intentional, do not change without updating the docs):
#   - postToolUse only -> never blocks or modifies a tool call
#   - default = METADATA-ONLY (toolName, ts, repo, branch). Full payload (which
#     may include code, command output, file paths, accidental secrets) is
#     opt-in via COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1
#   - opt-out per-machine via COPILOT_HARNESS_AUDIT=0 (no need to delete files
#     tracked in the repo)
#   - reads payload from stdin, never reaches out to the network
#   - writes outside the repo working tree (under $HOME) so the log is never
#     accidentally committed
#   - degrades gracefully when jq is missing
#   - exits 0 even on partial failure so the hook never stalls the agent
#
# Requires: bash. On Windows-native (no Git Bash / WSL) this hook will be
# skipped by the Copilot CLI hook runner.
#
# Inspect:  tail -f ~/.copilot/copilot-harness-audit.log
# Disable:  export COPILOT_HARNESS_AUDIT=0   (per-machine, no repo edit)
# Verbose:  export COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1

set -uo pipefail

# Per-machine kill switch — does not require editing tracked repo files.
if [ "${COPILOT_HARNESS_AUDIT:-1}" = "0" ]; then
  cat >/dev/null 2>&1 || true
  exit 0
fi

LOG_FILE="${AUDIT_LOG:-$HOME/.copilot/copilot-harness-audit.log}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || exit 0

PAYLOAD="$(cat 2>/dev/null || echo '')"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
FULL="${COPILOT_HARNESS_AUDIT_FULL_PAYLOAD:-0}"

if command -v jq >/dev/null 2>&1; then
  if [ "$FULL" = "1" ]; then
    # Verbose mode: keep the entire payload (may include code, secrets, output).
    jq -cn \
      --arg ts "$TS" \
      --arg repo "$REPO" \
      --arg branch "$BRANCH" \
      --argjson payload "${PAYLOAD:-null}" \
      '{ts:$ts, repo:$repo, branch:$branch, source:"copilot-harness-workshop", mode:"full", payload:$payload}' \
      >> "$LOG_FILE" 2>/dev/null || true
  else
    # Default mode: metadata only (toolName + a few non-sensitive fields).
    jq -cn \
      --arg ts "$TS" \
      --arg repo "$REPO" \
      --arg branch "$BRANCH" \
      --argjson payload "${PAYLOAD:-null}" \
      '{ts:$ts, repo:$repo, branch:$branch, source:"copilot-harness-workshop", mode:"metadata", toolName:($payload.toolName // null), sessionId:($payload.sessionId // null)}' \
      >> "$LOG_FILE" 2>/dev/null || true
  fi
else
  # No jq: emit minimal metadata only. Refuse to dump base64 payloads silently
  # — that would be an undocumented sidecar of the verbose mode.
  printf '{"ts":"%s","repo":"%s","branch":"%s","source":"copilot-harness-workshop","mode":"metadata","note":"jq not installed; install jq for richer metadata"}\n' \
    "$TS" "$REPO" "$BRANCH" >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
