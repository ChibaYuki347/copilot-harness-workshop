# Recipes

End-to-end worked examples that compose multiple harness layers. Each recipe answers
a real "how do I…" question and links to runnable artifacts under [`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples).

## In this section

| Recipe | Host | Combines | Goal |
|---|---|---|---|
| [PR Review Skill](pr-review-skill.md) | 🟢 Both[^host-legend] | Skill + custom agent | Reviewable, repeatable PR-review workflow you can run with one command. |
| [GitHub MCP server](github-mcp-server.md) | 🟦 CLI-primary | MCP | Adding the GitHub MCP server (or a private MCP) and using it inside a session. |
| [Session-end secret scan](session-end-secret-scan.md) | 🟢 Both | Hook | Automatic secret scan whenever a session ends. |
| [Path-specific instructions](path-specific-instructions.md) | 🟪 VS Code-primary | Custom instructions (`applyTo` glob) | Different rules for frontend vs. backend without two copies of everything. |
| [Multi-agent workflow](multi-agent-workflow.md) | 🟦 CLI-only | Custom agents + fleet mode | Parallel review pass: rubber-duck + code-review + security-reviewer. |

[^host-legend]: **Host legend** — 🟢 **Both** = works in Copilot CLI and VS Code Copilot Chat with the same files. 🟦 **CLI-primary / CLI-only** = relies on a CLI-specific slash command, flag, or bundled feature; VS Code may have a different mechanism or none. 🟪 **VS Code-primary** = relies on a VS Code-specific config schema (e.g. `applyTo` globs in `.instructions.md`); the CLI may read the files but won't honor host-specific semantics. See [the support matrix](../reference/vscode-vs-cli.md) for the full picture.

## How to read a recipe

Every recipe page follows the same shape:

1. **Problem.** The pain point in one paragraph.
2. **Layers used.** Which customizations this recipe stitches together.
3. **Files.** The actual artifacts you copy in, with their paths.
4. **How it runs.** What the agent does when you invoke the recipe.
5. **Variations.** Ways to adapt for your team's needs.

## Where to find the example files

All example artifacts live in [`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples)
in the repo:

```
examples/
├── instructions/      # copilot-instructions + path-specific examples
├── skills/            # SKILL.md examples
├── hooks/             # hooks.json + scripts
├── mcp/               # .mcp.json templates
├── agents/            # custom-agent Markdown files
└── prompts/           # *.prompt.md files
```

Copy the folder you need into your own repo's `.github/` (for repo scope) or
`~/.copilot/` (for personal scope).
