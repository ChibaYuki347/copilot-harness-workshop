# Try this repo as a live demo

You don't need to scaffold a sample project to feel how the harness layers
fit together — **`copilot-harness-workshop` is wired up as its own demo**.
Clone it, open a session in the repo root, and every customization layer
covered in this site will be live.

> **Read-only by default.** The wiring ships *safe* — no `preToolUse` hook
> can block or modify a tool call, the bundled MCP config has zero servers
> enabled, and the audit hook writes to a log file outside the repo. You can
> opt out of any layer in one step (see [Opting out](#opting-out)).

## What's wired at the repo root

| Layer | Path | What you'll see | Verify with |
|---|---|---|---|
| Custom Instructions (repo-wide) | `.github/copilot-instructions.md` | Site conventions load on every session start. | `/instructions` |
| Custom Instructions (path-specific) | `.github/instructions/markdown.instructions.md` | Extra rules apply only when editing `docs/**/*.md`. | `/instructions` then ask Copilot to edit any file under `docs/`. |
| Prompt Files | `.github/prompts/new-recipe.prompt.md` | A `/new-recipe` slash command appears. | `/help` then `/new-recipe my-slug` |
| Skills | `.github/skills/site-build-check/`, `.github/skills/translate-page/` | Two repo-relevant Skills are discoverable. | `/skills` |
| Hooks | `.github/hooks/audit-demo/` | Each successful tool call gets one metadata-only JSONL line in your audit log. | `tail -f ~/.copilot/copilot-harness-audit.log` |
| MCP servers | `.mcp.json` (root) | Copilot loads the config — zero servers are configured by default. | `/mcp` |
| Custom Agents | `.github/agents/docs-reviewer.agent.md` | A `docs-reviewer` sub-agent is registered. | `/agents` |

Everything is mirrored as a copy-pasteable template under
[`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples) —
that directory is the canonical reference the docs link to. The `.github/`
copies above are the **same patterns wired up live in this repo**.

## Five-minute walkthrough

### 1. Clone and open a session

```bash
git clone https://github.com/ChibaYuki347/copilot-harness-workshop.git
cd copilot-harness-workshop
copilot
```

Trust the workspace at the prompt. Copilot will read `.github/copilot-instructions.md`
on startup — you can see this in your first prompt response, which will know
this is a MkDocs site.

!!! tip "Zero-install fast path"
    If you don't want to install Python / Node / `gh` / `jq` / the Copilot CLI
    on your host, this repo ships a **devcontainer** that preinstalls all of
    them. Click **Code → Codespaces → Create codespace** on the GitHub repo
    page, or use **Dev Containers: Reopen in Container** locally. See
    [the devcontainer README](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md)
    for details.

### 2. List every customization the agent picked up

In the session, run these in turn:

```text
/instructions
/skills
/agents
/mcp
```

You should see:

- **`/instructions`** lists `.github/copilot-instructions.md` plus the path-specific
  `markdown.instructions.md` (only active when editing matching files).
- **`/skills`** lists `site-build-check` and `translate-page`.
- **`/agents`** lists `docs-reviewer`.
- **`/mcp`** loads the config — the server map is empty by default.

If any of these come up empty, see [Troubleshooting](#troubleshooting).

### 3. Trigger a Skill

```text
Verify the docs build is clean.
```

The `site-build-check` Skill runs `mkdocs build --strict`, parses the output,
and reports either a clean build or a table of warnings. It is **diagnostic
only** — it does not edit files.

### 4. Watch a hook fire

In a separate terminal:

```bash
mkdir -p ~/.copilot && touch ~/.copilot/copilot-harness-audit.log
tail -f ~/.copilot/copilot-harness-audit.log
```

> **Requires `bash`.** The hook script is Bash. macOS / Linux / WSL / Git
> Bash are fine; on Windows-native the Copilot CLI hook runner will skip
> it silently and the log won't grow.

Now ask Copilot to do something concrete:

```text
List the recipe pages we have today.
```

Each **successful** tool call appends one metadata-only JSON-Lines record
to the log:

```json
{"ts":"2026-06-01T12:00:01Z","repo":"copilot-harness-workshop","branch":"main","source":"copilot-harness-workshop","mode":"metadata","toolName":"bash","sessionId":"abc-123"}
```

Note what is **not** logged in default mode: the command Copilot ran,
file paths it touched, file contents, stdout, stderr. To capture full
payloads for your own debugging, opt in:

```bash
export COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1
copilot
```

In full-payload mode the log will contain whatever Copilot saw — treat
it as confidential.

### 5. Try the path-specific instructions

```text
Add a new H2 section to docs/getting-started/installation.md titled "Updating".
```

Because the file matches `docs/**/*.md`, the path-specific instructions in
`.github/instructions/markdown.instructions.md` are layered on top of the
repo-wide ones — you'll see Copilot use the `##` heading depth, an English
canonical voice, and a `bash` / `text` code-fence language even for trivial
output. Don't commit the change; this is just a feel-check. `/undo` to roll back.

### 6. Delegate to the custom agent

```text
Run the docs-reviewer agent on the current diff.
```

With no diff, the agent will return an **OK verdict** ("No issues found").
With a real diff (e.g., after `git checkout -b experiment` and a small
edit), it will flag any conventions issues, broken links, or strict-build
warnings.

## Following the first-session tour in this repo

[Your first session](first-session.md) walks through 6 generic steps —
launch agent → ground → plan → approve tools → inspect diff → commit. You
can do every step in **this** repo:

| First-session step | Try it here |
|---|---|
| Pick a project | `cd copilot-harness-workshop` |
| Ground the agent | `Take a look at this repo and tell me what it's for, the build command, and the riskiest file.` (it'll cite `mkdocs.yml` and `.github/workflows/deploy-pages.yml`) |
| Plan mode | `Shift+Tab` then `Add a "Updating" section to the Installation page. Plan it.` |
| Approve tools | Approve `mkdocs build` and `git diff` per session; never auto-approve `git push`. |
| Inspect diff | `Show me the diff for the installation page.` |
| Commit | Skip commit — discard with `/undo` so you don't leave a sample edit on your branch. |

## Opting out

Each wired layer can be disabled without forking the repo. The audit hook
also has a per-machine environment variable so you can leave the tree
clean.

| Layer | Opt-out (per-machine, no repo edit) | Opt-out (modifies your working tree) |
|---|---|---|
| Audit hook | `export COPILOT_HARNESS_AUDIT=0` before launching `copilot` | `rm -rf .github/hooks/audit-demo` or set `"postToolUse": []` in `hooks.json` |
| Skills | Override via user-scoped `~/.copilot/skills/<name>/` | `rm -rf .github/skills/<name>` |
| Prompt file | — | `rm .github/prompts/new-recipe.prompt.md` |
| Path-specific instructions | — | `rm .github/instructions/markdown.instructions.md` |
| Custom agent | Override via user-scoped `~/.copilot/agents/` | `rm .github/agents/docs-reviewer.agent.md` |
| MCP config | — | `rm .mcp.json` (the file already configures zero servers, so removing it just makes `/mcp` empty) |

User-scoped overrides under `~/.copilot/` always load alongside the
workspace-scoped wiring above. For the audit hook specifically,
`COPILOT_HARNESS_AUDIT=0` is the cleanest opt-out — anything that
modifies tracked files in `.github/` will show up in your `git status`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `/skills` shows nothing | You're on an older Copilot CLI without workspace skills discovery, or you `cd`'d into a subdirectory. | Update to the latest Copilot CLI; run `copilot` from the repo root. |
| `/mcp` errors instead of an empty server map | The empty-object `.mcp.json` is being read by a CLI version that requires at least one entry. | Add a dummy entry per [Customizations → MCP](../customizations/mcp.md) or delete `.mcp.json`. |
| Audit log file never appears (Linux / macOS) | The hook isn't firing because `.github/hooks/audit-demo/log.sh` isn't executable. | `chmod +x .github/hooks/audit-demo/log.sh`. |
| Audit log file never appears (Windows-native) | The hook runner skips Bash hooks when `bash` isn't on PATH. | Install Git Bash or WSL, or accept that the hook is a no-op on this platform. |
| Audit log lines say `"jq not installed"` | The shaper falls back to a minimal line. | Install `jq` (`brew install jq` / `apt install jq`). |
| Path-specific instructions don't activate | The file you're editing doesn't match the `applyTo` glob. | Check `.github/instructions/markdown.instructions.md` — only files under `docs/**/*.md` and `examples/**/README.md` trigger it. |

## See also

- [Workshop prep](workshop-prep.md) — install Copilot CLI / VS Code Copilot Chat before the walkthrough above.
- [Customizations overview](../customizations/index.md) — concept-level pages
  for each layer the wiring demonstrates.
- [Exercises track](../exercises/index.md) — when you're ready to build the
  same layers in your own project, work through exercises 1 → 6.
- [Reference → File layout](../reference/file-layout.md) — exactly where each
  customization file lives and what discovers it.
