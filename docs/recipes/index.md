# Recipes

End-to-end worked examples that compose multiple harness layers. Each recipe answers
a real "how do I…" question and links to runnable artifacts under [`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples).

## In this section

| Recipe | Combines | Goal |
|---|---|---|
| [PR Review Skill](pr-review-skill.md) | Skill + custom agent | Reviewable, repeatable PR-review workflow you can run with one command. |
| [GitHub MCP server](github-mcp-server.md) | MCP | Adding the GitHub MCP server (or a private MCP) and using it inside a session. |
| [Session-end secret scan](session-end-secret-scan.md) | Hook | Automatic secret scan whenever a session ends. |
| [Path-specific instructions](path-specific-instructions.md) | Custom instructions | Different rules for frontend vs. backend without two copies of everything. |
| [Multi-agent workflow](multi-agent-workflow.md) | Custom agents + fleet mode | Parallel review pass: rubber-duck + code-review + security-reviewer. |

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
