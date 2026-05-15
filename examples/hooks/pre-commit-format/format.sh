#!/usr/bin/env bash
#
# Auto-format files the agent just wrote with edit/create.
#
# Triggered as a postToolUse hook. Reads the tool input from stdin (JSON) and runs
# the appropriate formatter for each changed file.

set -euo pipefail

INPUT="$(cat || true)"

# Extract the file path(s) the tool acted on. Both edit and create tools include a
# "path" or "file_path" field in toolInput.
PATHS=$(echo "$INPUT" | jq -r '
  .toolInput.path // .toolInput.file_path // .toolInput.target // empty
' 2>/dev/null || true)

if [[ -z "$PATHS" ]]; then
  exit 0
fi

format_one() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.md|*.css|*.html)
      command -v prettier >/dev/null && prettier --write "$file" >/dev/null 2>&1 || true
      ;;
    *.py)
      command -v ruff >/dev/null && ruff format "$file" >/dev/null 2>&1 || true
      command -v ruff >/dev/null && ruff check --fix --quiet "$file" >/dev/null 2>&1 || true
      ;;
    *.go)
      command -v gofmt >/dev/null && gofmt -w "$file" || true
      ;;
    *.rs)
      command -v rustfmt >/dev/null && rustfmt "$file" 2>/dev/null || true
      ;;
  esac
}

while IFS= read -r p; do
  [[ -n "$p" ]] && format_one "$p"
done <<< "$PATHS"

echo "🧹 formatted touched files" >&2
exit 0
