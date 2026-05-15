# copilot-harness-workshop

> **Harnessing GitHub Copilot CLI** — a practical guide to customizing the agent for your real-world workflow with **Custom Instructions, Prompt Files, Skills, Hooks, MCP servers, and Custom Agents**.

📖 **Live site:** <https://chibayuki347.github.io/copilot-harness-workshop/>

🇯🇵 **日本語版は同じサイト内の言語スイッチャーから切り替えられます。**

---

## What's in this repo

| Path | Purpose |
|---|---|
| `docs/` | MkDocs Material source for the GitHub Pages site (English + Japanese subset). |
| `examples/` | Copy-pasteable sample artifacts — `SKILL.md`, `hooks.json`, `.mcp.json`, custom instructions, prompt files, and a custom agent. |
| `mkdocs.yml` | Site configuration (theme, navigation, i18n, plugins). |
| `.github/workflows/deploy-pages.yml` | CI that builds and deploys the site to GitHub Pages on every push to `main`. |
| `.github/copilot-instructions.md` | The repo's own Copilot instructions — yes, it eats its own dog food. |

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
