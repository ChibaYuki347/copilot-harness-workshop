# Devcontainer for `copilot-harness-workshop`

Open this repo in a container — locally with the **Dev Containers** VS Code
extension, or in the cloud with **GitHub Codespaces** — and everything the
site teaches is preinstalled and wired up. No need to install MkDocs, Node,
jq, or the Copilot CLI on your host.

## What's provisioned

| Tool / extension | Why |
|---|---|
| Python 3.12 (base image) | Runs `mkdocs build --strict` and `mkdocs serve`. |
| Node.js LTS (feature) | Used by `npm install -g @github/copilot`. |
| GitHub CLI (feature) | `gh auth login` for Copilot CLI + scripted PR / issue flows. |
| `jq` (postCreate) | Required by the `audit-demo` hook for the rich metadata format. |
| MkDocs + Material + i18n + pymdown-extensions (postCreate) | Pinned via `requirements.txt`. |
| `@github/copilot` CLI (postCreate) | The agentic CLI the harness wires up against. |
| VS Code extension: `GitHub.copilot` | Inline completions. |
| VS Code extension: `GitHub.copilot-chat` | Chat + Ask/Agent/Plan modes. |
| VS Code extensions: `ms-python.python`, markdownlint, markdown-all-in-one | Docs authoring quality of life. |

## How to open it

### GitHub Codespaces (zero local install)

1. Click **Code → Codespaces → Create codespace on `main`** on the GitHub repo page.
2. Wait for the postCreate hook to finish (you'll see `✅ copilot-harness-workshop devcontainer ready.` in the terminal).
3. Codespaces usually starts with GitHub auth already wired. Verify with `gh auth status`; if it says you're logged out, run `gh auth login --web`.
4. Start the live demo: `copilot`.

### VS Code Dev Containers (local Docker)

Prereqs: Docker Desktop / Colima / Rancher Desktop, plus the
[Dev Containers VS Code extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

1. `git clone https://github.com/ChibaYuki347/copilot-harness-workshop.git`
2. `code copilot-harness-workshop`
3. When VS Code prompts, click **Reopen in Container**. (Or use the command palette: **Dev Containers: Reopen in Container**.)
4. Wait for postCreate to finish.
5. Local containers always need a fresh device-code login: `gh auth login --web`.
6. `copilot` (it'll reuse the `gh` credentials; on first launch it may also prompt with `/login`).

## Verify the live demo

Inside the container terminal:

```bash
copilot
# Then in the session:
/instructions   # should list .github/copilot-instructions.md + path-specific markdown rules
/skills         # should list site-build-check + translate-page
/agents         # should list docs-reviewer
/mcp            # config loaded, server map empty (by design)
```

In a second terminal:

```bash
tail -f ~/.copilot/copilot-harness-audit.log
```

You should see one metadata-only JSONL line per successful tool call, e.g.:

```json
{"ts":"2026-06-02T00:00:00Z","repo":"copilot-harness-workshop","branch":"main","source":"copilot-harness-workshop","mode":"metadata","toolName":"bash","sessionId":"abc-123"}
```

## Previewing the docs site

```bash
mkdocs serve
# Then open the forwarded port 8000 (VS Code will offer to open it automatically).
```

For the strict build CI runs:

```bash
mkdocs build --strict
```

## Persistence

- `~/.copilot/` (audit log, auth tokens, sessions) lives **inside the container**.
  In Codespaces it persists across restarts of the same codespace. Locally, it
  resets when you rebuild the container — re-run `gh auth login --web` if so.
- The repo working tree is bind-mounted, so edits in the container are edits
  to your local checkout.
- **No host mount is configured for `~/.copilot/` by design** — persisting
  Copilot / GitHub auth tokens onto a shared or reused dev host is a security
  risk we'd rather not opt every attendee into. If you want that trade-off on
  a single-user machine, add a `mounts` entry to `devcontainer.json` yourself.

## Opting out of the audit hook

Per-shell, no repo edit:

```bash
export COPILOT_HARNESS_AUDIT=0
```

See [`.github/hooks/audit-demo/README.md`](../.github/hooks/audit-demo/README.md)
for the full opt-out matrix and the verbose (`COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1`)
mode.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `copilot: command not found` after build | postCreate didn't finish or failed mid-way. | Re-run `bash .devcontainer/postCreate.sh`. |
| `mkdocs build --strict` says a plugin is missing | The Python deps weren't installed for the active interpreter. | `pip install --user -r requirements.txt`. |
| Audit log lines say `"jq not installed"` | apt step failed for some reason. | `sudo apt-get install -y jq`. |
| `gh auth login` browser flow doesn't open | You're in a remote codespace / SSH. | Use `gh auth login --web` and copy the device code into your local browser. |
| `gh auth status` says you're already logged in (Codespaces) | Codespaces injects a Copilot-scoped token. | Nothing to do — `copilot` will reuse it. |
| Port 8000 isn't forwarded | The forward didn't auto-trigger. | VS Code → **Ports** panel → **Forward a Port** → `8000`. |
