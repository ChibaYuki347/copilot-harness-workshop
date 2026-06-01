#!/usr/bin/env bash
# preToolUse hook for the `bash` tool.
# Reads the tool-call payload from stdin and emits a JSON permissionDecision.
# - "deny"  -> Copilot will refuse the call and show the reason to the agent.
# - "ask"   -> Copilot will prompt the user, regardless of any auto-approve rules.
# - (omit)  -> normal permission flow.
#
# Tune DENY_PATTERNS to your team's policy. Keep ASK_PATTERNS for things that are
# legitimate but should never be auto-approved.

set -euo pipefail

PAYLOAD="$(cat)"

# Extract the command string. The bash tool's input shape is
# { "command": "<shell string>", ... }.
# Fall back to scanning the whole payload if jq is missing.
if command -v jq >/dev/null 2>&1; then
  CMD="$(printf '%s' "$PAYLOAD" | jq -r '.toolInput.command // .toolInput.bash // empty')"
else
  CMD="$PAYLOAD"
fi

deny() {
  printf '{"permissionDecision":"deny","response":%s}\n' \
    "$(printf '%s' "$1" | jq -Rs '.' 2>/dev/null || printf '"%s"' "$1")"
  exit 0
}

ask() {
  printf '{"permissionDecision":"ask","response":%s}\n' \
    "$(printf '%s' "$1" | jq -Rs '.' 2>/dev/null || printf '"%s"' "$1")"
  exit 0
}

# --- DENY patterns: hard block, agent must change approach. -------------------
DENY_PATTERNS=(
  'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF][[:space:]]+/($|[[:space:]])'   # rm -rf /
  'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF][[:space:]]+~($|[[:space:]/])'  # rm -rf ~
  'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[fF][[:space:]]+\$HOME'              # rm -rf $HOME
  'curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh'                       # curl ... | (sudo) sh
  'wget[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh'                       # wget ... | sh
  ':\(\)\{[[:space:]]*:\|:[[:space:]]*&[[:space:]]*\}[[:space:]]*;'         # fork bomb
  'mkfs(\.|[[:space:]])'                                                     # mkfs anything
  'dd[[:space:]]+if=.*of=/dev/(sd|nvme|hd)'                                  # dd to a real disk
  '>[[:space:]]*/dev/sda'
  'chmod[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?(-)?(0|)777[[:space:]]+/'
  'chown[[:space:]]+(-[a-zA-Z]+[[:space:]]+)?[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+[[:space:]]+/'
)

# --- ASK patterns: legitimate, but a human should confirm every time. --------
ASK_PATTERNS=(
  'git[[:space:]]+push[[:space:]]+.*--force'        # force push
  'git[[:space:]]+push[[:space:]]+.*-f($|[[:space:]])'
  'git[[:space:]]+reset[[:space:]]+--hard'
  'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*[df]'
  '^sudo[[:space:]]'                                # any sudo
  'gh[[:space:]]+repo[[:space:]]+delete'
  'gh[[:space:]]+secret[[:space:]]+set'             # writing secrets
  'docker[[:space:]]+system[[:space:]]+prune'
  'kubectl[[:space:]]+delete[[:space:]]+(ns|namespace)'
  'terraform[[:space:]]+(apply|destroy)([[:space:]]|$)'
)

for pat in "${DENY_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $pat ]]; then
    deny "Blocked by deny-dangerous-commands hook: command matches '$pat'. Pick a safer alternative or run this manually outside Copilot."
  fi
done

for pat in "${ASK_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $pat ]]; then
    ask "deny-dangerous-commands: '$pat' is high-impact. Re-confirm before approving."
  fi
done

# Default: stay silent; Copilot uses its normal permission flow.
exit 0
