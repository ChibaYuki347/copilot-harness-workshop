#!/usr/bin/env bash
# Post-create provisioning for copilot-harness-workshop.
#
# Runs once after the devcontainer is built. Installs the OS deps the hook
# needs (jq), the Python deps the docs site needs (mkdocs + plugins), and
# the Copilot CLI itself. Then prints a short "next steps" banner.
#
# Idempotent: safe to re-run.

set -euo pipefail

echo "==> apt: installing jq (required by .github/hooks/audit-demo)"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends -qq jq
sudo rm -rf /var/lib/apt/lists/*

echo "==> pip: installing requirements.txt (user-site)"
python -m pip install --user --upgrade --quiet pip
python -m pip install --user --quiet -r requirements.txt
# Make sure ~/.local/bin (where pip --user puts mkdocs) is on PATH for
# every subsequent shell — devcontainer.json also exports it, but appending
# here covers existing shells started before postCreate finishes.
if ! grep -qs 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"
echo "    mkdocs at: $(command -v mkdocs || echo 'NOT FOUND')"
mkdocs --version 2>&1 | head -1 || true

echo "==> chmod: making the audit hook executable (best-effort)"
# Non-fatal: on Windows bind-mounts chmod can be a no-op or fail. The hook's
# `bash` runner key in hooks.json invokes the script via `bash log.sh`, so
# the executable bit isn't strictly required either way.
chmod +x .github/hooks/audit-demo/log.sh \
  || echo "    warning: chmod failed (likely a Windows bind-mount); hook will still run via 'bash log.sh'"

echo "==> npm: installing GitHub Copilot CLI (@github/copilot)"
if ! command -v copilot >/dev/null 2>&1; then
  # Try as the current user first; if the npm global prefix isn't writeable,
  # fall back to sudo. Either way we verify the binary is reachable.
  npm install -g @github/copilot >/dev/null 2>&1 \
    || sudo npm install -g @github/copilot >/dev/null
fi
echo "    copilot at: $(command -v copilot || echo 'NOT FOUND')"
copilot --version 2>&1 | head -1 || true

# Pre-create the audit log so `tail -f` works on first run with no surprise.
mkdir -p "$HOME/.copilot"
touch "$HOME/.copilot/copilot-harness-audit.log"

cat <<'BANNER'

✅ copilot-harness-workshop devcontainer ready.

Next steps:
  1. Authenticate         gh auth status || gh auth login --web
                          (Codespaces is usually pre-authenticated; local containers
                           need this. `copilot` will reuse the same credentials.)
  2. Preview the docs     mkdocs serve            (browse http://localhost:8000/)
  3. Try the live demo    copilot                 (then /skills, /agents, /instructions, /mcp)
  4. Watch the hook fire  tail -f ~/.copilot/copilot-harness-audit.log

Walkthrough: docs/getting-started/try-this-repo.md
Opt-out the audit hook for this shell: export COPILOT_HARNESS_AUDIT=0

BANNER
