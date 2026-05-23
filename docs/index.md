---
hide:
  - navigation
  - toc
---

# Copilot Harness Workshop

> **Make GitHub Copilot yours — in the terminal *and* in your editor.** A practical
> guide to customizing both **Copilot CLI** and **VS Code Copilot Chat** with the
> same set of files: Custom Instructions, Prompt Files, Skills, Hooks, MCP servers,
> and Custom Agents.

[Get started :material-rocket-launch:](getting-started/what-is-copilot-cli.md){ .md-button .md-button--primary }
[Jump to customizations :material-cog:](customizations/index.md){ .md-button }
[CLI vs VS Code matrix :material-table:](reference/vscode-vs-cli.md){ .md-button }

!!! tip "Two surfaces, one harness"
    Everything on this site is built around the idea that **the harness files travel
    across hosts**. Most files (`.github/copilot-instructions.md`, `*.prompt.md`,
    `SKILL.md`, `.agent.md`, `.github/hooks/*.json`, MCP configs) work in both
    Copilot CLI and VS Code Copilot Chat with the same syntax. Where there's a real
    difference — e.g. `applyTo` globs are a VS Code-only filter, `/fleet` is a
    CLI-only orchestrator — every page calls it out explicitly with a 🟦 / 🟪 / 🟢
    badge. The full breakdown lives in the
    [VS Code vs CLI support matrix](reference/vscode-vs-cli.md).

---

## Why "harness"?

GitHub Copilot is powerful out of the box, but its real value emerges when you
**shape it to your codebase, team, and risk model**. The harness — the set of files
and conventions that sit *around* the agent — is where that shaping happens, and
it's the same shape whether you're driving Copilot from the terminal (Copilot CLI)
or the editor (VS Code Copilot Chat).

This site is opinionated, example-driven, and grounded in the [official Copilot
docs](https://docs.github.com/copilot/concepts/agents/about-copilot-cli), the
[VS Code Copilot Chat customization docs](https://code.visualstudio.com/docs/copilot/customization/overview),
and the patterns in [github/awesome-copilot](https://github.com/github/awesome-copilot).

## The six layers of the harness

<div class="feature-grid" markdown>

<div class="feature-card" markdown>
### 📜 Custom Instructions
Teach Copilot your conventions once, apply them everywhere — repo-wide, path-specific, or personal.

[Learn more →](customizations/custom-instructions.md)
</div>

<div class="feature-card" markdown>
### ⌨️ Prompt Files & Slash Commands
Turn repeated prompts into one-shot, parameterized `/commands` your whole team can invoke.

[Learn more →](customizations/prompt-files.md)
</div>

<div class="feature-card" markdown>
### 🦾 Skills
Package multi-step agent procedures — with scripts, templates, and rubrics — into a single `SKILL.md`.

[Learn more →](customizations/skills.md)
</div>

<div class="feature-card" markdown>
### 🪝 Hooks
React to agent lifecycle events (`sessionStart` / `preToolUse` / `postToolUse` / `sessionEnd` in the CLI, `SessionStart` / `PreToolUse` / `PostToolUse` / `Stop` in VS Code Preview).

[Learn more →](customizations/hooks.md)
</div>

<div class="feature-card" markdown>
### 🔌 MCP Servers
Plug your internal APIs, databases, and SaaS tools into the agent via the Model Context Protocol.

[Learn more →](customizations/mcp.md)
</div>

<div class="feature-card" markdown>
### 🤖 Custom Agents
Delegate specialized work — research, code review, rubber-ducking — to focused sub-agents.

[Learn more →](customizations/agents.md)
</div>

</div>

## How to read this site

| You are… | Start here |
|---|---|
| New to Copilot (CLI or VS Code) | [What is Copilot CLI?](getting-started/what-is-copilot-cli.md) |
| Wondering which features work where | [VS Code vs CLI matrix](reference/vscode-vs-cli.md) |
| Ready to customize | [Customizations overview](customizations/index.md) |
| Looking for copy-paste examples | [Recipes](recipes/index.md) |
| Planning a team rollout | [Case study: team rollout](case-studies/team-rollout.md) |
| Looking up a specific config key | [Reference](reference/cli-commands.md) |
| Want hands-on homework | [Exercises](exercises/index.md) — 6 graded labs + a capstone (CLI + VS Code tracks) |

## A note on accuracy

Both Copilot CLI and VS Code Copilot Chat ship rapid updates. Every page on this
site cites the relevant [`github/copilot-cli`](https://github.com/github/copilot-cli)
changelog entries, [official CLI docs](https://docs.github.com/copilot), and
[VS Code Copilot Chat docs](https://code.visualstudio.com/docs/copilot) when
describing config formats. If you spot a drift, open an issue or a PR — links at
the top of every page.
