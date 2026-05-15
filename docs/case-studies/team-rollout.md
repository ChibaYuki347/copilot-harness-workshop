# Case Study: Team rollout

A composite based on a 12-person product team adopting Copilot CLI across a
TypeScript/Python monorepo over ~3 months. Names changed; the *shape* of the
rollout is real.

## Starting situation

- **Team:** 12 engineers (8 backend Python, 3 frontend TS, 1 SRE).
- **Repos:** one monorepo, ~250k LOC, multiple services.
- **Existing AI usage:** ad-hoc copilot suggestions; no shared conventions.
- **Pain:** every engineer was writing their own context-priming prompt. Reviews were
  occasionally catching "AI-shaped" anti-patterns (over-abstracted, untested, copies of
  similar code elsewhere).
- **Goal:** make the AI-assisted workflow a *team* asset, not 12 individual workflows.

## Layers chosen

| Layer | Used? | Why |
|---|---|---|
| Custom instructions | ✅ | Mandatory baseline. Establishes house style. |
| Path-specific instructions | ✅ | Frontend ≠ backend. |
| Prompt files | ✅ | Shared `/new-service` and `/migration` flows. |
| Skills | ✅ | A `pr-review` skill enforcing the review checklist. |
| Hooks | ✅ | Two: secret scan on session end; format-on-edit. |
| MCP | ✅ | Built-in GitHub MCP + a private "internal docs" MCP. |
| Custom agents | ✅ | One `security-reviewer` agent. |

## Rollout (in order)

### Week 1 — Baseline conventions

Two people drafted `.github/copilot-instructions.md` in ~3 hours. The hard part wasn't
writing it — it was deciding the conventions. Existing `CONTRIBUTING.md` content was
mostly portable.

> **Lesson:** the AI conventions doc is a forcing function for *team* conventions you
> never wrote down. Budget time for the team conversation, not just the writing.

### Week 2 — Path-specific instructions

```
.github/instructions/
├── frontend.instructions.md   # applyTo: frontend/**
├── backend.instructions.md    # applyTo: backend/**
└── sre.instructions.md        # applyTo: ops/**, .github/workflows/**
```

Each subteam wrote their own. Approved by PR review. Now in version control alongside
the code.

### Week 3 — PR review skill

A `pr-review` skill (see [the recipe](../recipes/pr-review-skill.md)) wrapping the
team's review checklist. Bonus: it caught checklist-items that *people* were
skipping ("did we update CHANGELOG?").

The skill's `references/checklist.md` is the **single source of truth** for the
team's review standard — versioned, reviewable, no longer a Confluence page that
drifts.

### Month 2 — Hooks

Two hooks added:

- **`sessionEnd` → secret scan.** Same as the [recipe](../recipes/session-end-secret-scan.md).
  Warn-only; CI is still the enforcement.
- **`postToolUse` → auto-format.** Runs `pnpm prettier --write` or `ruff format` on
  files written by the edit/create tool. Keeps diffs small.

### Month 2 — Private MCP server

The team built a tiny MCP server exposing their internal docs (Confluence-like) as a
search tool. Now agents can answer "how do we usually structure new services?" by
querying the docs instead of guessing.

This required real engineering — about a week. The team only built it because they
*already* had the harness in place and could see exactly what was missing.

### Month 3 — `security-reviewer` agent

A custom agent (see [examples/agents/security-reviewer.agent.md](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/examples/agents/security-reviewer.agent.md))
that runs as a parallel sub-agent during the PR review skill. It looks specifically at
authentication, secret handling, and SQL/string-interpolation patterns.

The team's previous "manual security pass" stage now runs on every PR rather than
"when someone remembers."

## Outcome (qualitative)

- **Onboarding:** new hires productive in days, not weeks — the conventions are
  *executable*, not buried in a wiki.
- **PR quality:** fewer late-stage "could you rewrite this with X" comments, because
  the AI already knows X is the house style.
- **Less drift:** when a convention changes, the team updates the instruction file
  in one PR. Everyone picks it up the next session.
- **Cost:** ~1 engineer-week of upfront work spread over 3 months, then ~1 hour/month
  of maintenance.

## What we'd do differently

- **Path-specific instructions before week 1 is too early.** Start with a single
  baseline; let path-specific files emerge when the friction is real.
- **Don't build the MCP server first.** Tempting "look how cool we are" project. We
  only knew what tools we *actually* wanted after using the basic harness for a
  month.
- **Pin the harness in CI.** Use `copilot -p '/pr-review'` in a GitHub Action so
  individual machines aren't the only place the harness runs.
- **Trim regularly.** After 3 months, our custom instructions had ballooned. Quarterly
  review to delete stuff that became default behavior or got encoded elsewhere.

## Anti-patterns we hit

- **Instructions used as a TODO list.** "We should think about adding X." → No: the
  instruction file is what *is*, not what *might be*.
- **Skills that overlap.** `pr-review` and `code-quality-check` ended up doing 80%
  the same thing. We merged them.
- **A hook that did too much.** Our first `sessionEnd` hook scanned secrets,
  computed metrics, and posted to Slack. It got brittle. We split it into one
  hook per job.

## Templates

The exact files used by this case study live in
[`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples).
