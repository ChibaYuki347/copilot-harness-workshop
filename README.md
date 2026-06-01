# copilot-harness-workshop

> **Harnessing GitHub Copilot CLI** — a practical guide to customizing the agent for your real-world workflow with **Custom Instructions, Prompt Files, Skills, Hooks, MCP servers, and Custom Agents**.

📖 **Live site:** <https://chibayuki347.github.io/copilot-harness-workshop/>

🚀 **Try it in one click:** [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ChibaYuki347/copilot-harness-workshop) — opens a fully-provisioned devcontainer with MkDocs, Node, `gh`, `jq`, and the Copilot CLI preinstalled. See [`.devcontainer/README.md`](./.devcontainer/README.md).

🇯🇵 **日本語版は同じサイト内の言語スイッチャーから切り替えられます。**

---

## What's in this repo

This repo plays two roles at once:

1. It **publishes the docs site** that explains how to customize Copilot.
2. It **is itself a live demo** of every customization layer the docs cover —
   clone it, run `copilot`, and the Skills / Hooks / Prompt / Agent / MCP /
   path-specific Instructions are all wired up.

| Path | Purpose |
|---|---|
| `docs/` | MkDocs Material source for the GitHub Pages site (English + Japanese subset). |
| `examples/` | Copy-pasteable sample artifacts referenced from the docs — `SKILL.md`, `hooks.json`, `.mcp.json`, custom instructions, prompt files, and a custom agent. |
| `mkdocs.yml` | Site configuration (theme, navigation, i18n, plugins). |
| `.github/workflows/deploy-pages.yml` | CI that builds and deploys the site to GitHub Pages on every push to `main`. |
| `.github/copilot-instructions.md` | Repo-wide Copilot instructions. |
| `.github/instructions/markdown.instructions.md` | **Live demo** — path-specific instructions that activate when editing `docs/**/*.md`. |
| `.github/prompts/new-recipe.prompt.md` | **Live demo** — adds a `/new-recipe` slash command. |
| `.github/skills/{site-build-check,translate-page}/` | **Live demo** — two repo-relevant Skills. |
| `.github/hooks/audit-demo/` | **Live demo** — safe-by-default `postToolUse` hook that appends a JSONL line per tool call to `~/.copilot/copilot-harness-audit.log`. |
| `.github/agents/docs-reviewer.agent.md` | **Live demo** — a docs-PR reviewer sub-agent. |
| `.mcp.json` | **Live demo** — MCP config template (zero servers by default, no side effects). |
| `.devcontainer/` | Reproducible workspace: Python 3.12 + Node LTS + `gh` + `jq` + MkDocs + Copilot CLI preinstalled. Open in [GitHub Codespaces](https://codespaces.new/ChibaYuki347/copilot-harness-workshop) or with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers). |

→ See [Try this repo as a live demo](https://chibayuki347.github.io/copilot-harness-workshop/getting-started/try-this-repo/)
for the 5-minute walkthrough and the opt-out switches for every layer above.

## Why "harness"?

GitHub Copilot CLI ships as a general-purpose agent, but its real value emerges when you **shape its behavior to your codebase, team, and threat model**. The customization surface is large:

- 📜 **Custom Instructions** teach Copilot your conventions.
- 🧩 **Prompt Files / Slash Commands** turn repeated tasks into one-shot commands.
- 🦾 **Skills** package reusable, multi-step agent procedures with their own scripts and templates.
- 🪝 **Hooks** wire automation into agent lifecycle events (`sessionStart`, `preToolUse`, …).
- 🔌 **MCP servers** extend the agent with new tools from your internal systems.
- 🤖 **Custom Agents / Sub-agents** delegate specialized work in parallel.

This workshop walks through each layer with worked examples and case studies.

## Quick start (local preview)

```bash
git clone https://github.com/ChibaYuki347/copilot-harness-workshop.git
cd copilot-harness-workshop

python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt

mkdocs serve
# open http://127.0.0.1:8000/copilot-harness-workshop/
```

## Audience

Developers and platform/DevEx teams who already use GitHub Copilot CLI and want to make it **fit their organization** instead of just using the defaults.

## Contributing

PRs welcome — see the docs site for the conventions this repo follows. Examples should be runnable and grounded in the [official spec](https://docs.github.com/copilot/concepts/agents/about-copilot-cli) or [github/awesome-copilot](https://github.com/github/awesome-copilot).

## License

[MIT](./LICENSE). Examples are provided as-is; review and adapt before applying to your own systems.
