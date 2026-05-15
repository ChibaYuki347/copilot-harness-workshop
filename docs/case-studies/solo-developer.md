# Case Study: Solo developer

A composite based on common solo-dev usage patterns: one person, two or three side
projects, mixed languages (TypeScript, Python, occasional Rust), no team to coordinate
with.

## Starting situation

- **Repos:** three independent ones — a Next.js site, a FastAPI side service, a
  Tauri desktop app.
- **Constraint:** time. Anything that adds *another tool to maintain* is a no.
- **Goal:** stop typing the same setup instructions to Copilot every session.

## Layers chosen

| Layer | Used? | Why / why not |
|---|---|---|
| Custom instructions | ✅ | Free win. One file per repo. |
| Prompt files | ✅ | Saves typing for repetitive flows. |
| Skills | ✅ | One: a "release" skill that bumps versions + drafts release notes. |
| Hooks | ❌ | The CI already does formatting + tests. A local hook would be redundant. |
| MCP | ✅ | Just the built-in `github-mcp-server`. No custom servers — the marginal value didn't justify the maintenance. |
| Custom agents | ❌ | Built-in `rubber-duck` and `code-review` cover the need. |

## Rollout (in order)

### Day 1 — `AGENTS.md` per repo (15 minutes)

```markdown
# AGENTS.md

This is a Next.js 14 app router project. Use TypeScript strict mode. Prefer server
components when possible. Tailwind for styling. Tests with Vitest. Don't introduce
new dependencies without asking. Run `pnpm lint && pnpm test --run` before claiming
done.
```

Result: every new session starts with shared context. Saves ~5 minutes of explanation
per session.

### Week 1 — A `release` skill

```
.github/skills/release/SKILL.md
```

Workflow: bump version, update `CHANGELOG.md` from `git log`, create a git tag, draft
GitHub release notes via the GitHub MCP server. Invoked as `/release patch` or
`/release minor`.

This replaced a tedious 4-step manual process with one command.

### Month 1 — Personal `~/.copilot/copilot-instructions.md`

Cross-repo conventions: "Use Conventional Commits. Don't introduce a new dependency
unless asked. When you write tests, write at least one negative test."

This applies even when working on someone else's repo (e.g., contributing to an
open-source project).

### Month 2 — A few prompt files

`~/.copilot/prompts/refactor-tests.prompt.md` and `weekly-cleanup.prompt.md`. Niche
but high value when they fire.

## Outcome

- Sessions start productive immediately instead of after a 5-minute setup prompt.
- The release skill saves ~10 minutes per release. With ~2 releases per week, that's
  ~17 hours per year.
- Total maintenance cost: re-reading `AGENTS.md` once a quarter and trimming what's
  no longer true.

## What I'd do differently

- **Start with `AGENTS.md`, not `.github/copilot-instructions.md`.** They're
  near-equivalent, but `AGENTS.md` is a community convention used by multiple
  agentic tools (Cursor, Codex, etc.). Cross-tool portable.
- **Skip MCP custom servers until a real pain point emerges.** I bounced off building
  one for a personal note-taking tool because the upkeep > the value.
- **Don't write hooks for things CI already does.** I tried a pre-commit format hook,
  then realized my CI already rejected unformatted code. The hook was just duplicating
  the loop with less reliability.

## Templates

The exact files used by this case study live in
[`examples/instructions/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/instructions)
and [`examples/prompts/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/prompts).
