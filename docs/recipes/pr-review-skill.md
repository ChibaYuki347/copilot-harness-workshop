# Recipe: PR Review Skill

**A reusable, multi-phase PR review you can invoke with one slash command.**

## Problem

Every team has a PR-review checklist, but in practice it lives in someone's head,
or in a `CONTRIBUTING.md` no one re-reads. We want a Skill that runs the checklist
deterministically: same questions, same output format, evidence-based answers.

## Layers used

- **Skill** for the structured workflow.
- **Custom agent** (`code-review`, built-in) for the heavy lifting.
- Optional: a **`postToolUse` hook** that auto-comments the result on the PR.

## File layout

```
.github/skills/pr-review/
├── SKILL.md
└── references/
    └── checklist.md
```

## `SKILL.md`

```markdown
---
name: pr-review
description: |
  Use this skill when the user asks to review a pull request or the current branch's
  diff. Trigger phrases include "review this PR", "review the diff", "do a PR review".
  Do not trigger for one-line code suggestions or for general code-quality questions.
license: MIT
compatibility: "Cross-platform. Requires git and the gh CLI."
argument-hint: "Optional: base branch to diff against (default: origin/main)"
---

# PR Review Skill

## Output Contract

By the end:

1. A file `.pr-review/REVIEW.md` exists at the repo root.
2. Each section of the checklist (see `references/checklist.md`) is filled in or
   explicitly marked **N/A** with a one-line reason.
3. Every finding cites at least one `file:line` reference.
4. The final response includes a one-paragraph executive summary and a verdict:
   **Approve / Approve-with-comments / Request-changes**.

## Workflow

### Phase 1 — Ground

1. Determine the base branch from the argument (default: `origin/main`).
2. Run `git diff --stat <base>...HEAD` and capture the changed files.
3. Load `references/checklist.md`.

### Phase 2 — Investigate

Delegate to the built-in `code-review` agent: pass the diff and the checklist, ask
for a structured review. The agent should return findings as a JSON array
`[{ severity, file, line, what, why, fix }, ...]`.

### Phase 3 — Synthesize

1. Create `.pr-review/REVIEW.md` by filling in the checklist + the findings.
2. For each finding, verify the `file:line` actually exists in the diff before
   including it.
3. Compute the verdict:
   - any `Critical` → **Request-changes**
   - else any `High` → **Approve-with-comments**
   - else → **Approve**

### Phase 4 — Present

Print the executive summary and the verdict, and tell the user where the full review
is saved.
```

## `references/checklist.md` (excerpt)

```markdown
# Review checklist

- **Correctness** — Does the change do what its description claims?
- **Tests** — Are tests added/updated? Are they meaningful (not assert-true)?
- **Error handling** — Are failure modes considered?
- **Security** — Any secret-leak, SSRF, injection risk introduced?
- **Performance** — Any obviously hot paths added without bounds?
- **Backwards compat** — Are public types / endpoints stable?
- **Docs** — Is `CHANGELOG.md` updated for user-visible changes?
```

## How it runs

```text
/pr-review
/pr-review develop
```

1. The skill scopes the diff.
2. The `code-review` sub-agent analyzes it against the checklist.
3. A structured `REVIEW.md` lands at the repo root.
4. The CLI prints the verdict.

## Optional: auto-comment on the PR

Add a hook that watches for `gh pr` tool use and posts the review as a comment:

```json
{
  "version": 1,
  "hooks": {
    "postToolUse": [
      {
        "type": "command",
        "matcher": "^bash$",
        "bash": ".github/hooks/pr-comment/comment.sh",
        "timeoutSec": 15
      }
    ]
  }
}
```

`comment.sh` checks whether `.pr-review/REVIEW.md` exists and, if so, posts it via
`gh pr comment -F .pr-review/REVIEW.md`.

## Variations

- **Stricter verdict policy.** Require human approval for any verdict that isn't
  `Approve`, by returning `permissionDecision: "ask"` from a `preToolUse` hook on
  `gh pr merge`.
- **Domain-specific checklist.** Subclass the skill per team: `.github/skills/pr-review-backend/`,
  `.../pr-review-frontend/`. Each ships its own `checklist.md`.
- **Trigger from CI.** Run the skill on every PR with two repeated allow-tool flags:

  ```bash
  copilot -p '/pr-review' \
    --allow-tool='shell(git:*)' \
    --allow-tool='shell(gh:*)'
  ```

  `--allow-tool` takes one glob pattern per flag; you cannot pass a comma-list. The
  `:*` glob is the convention for "any subcommand of this binary".

## Try it

The runnable starter is at [`examples/skills/pr-summary/SKILL.md`](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/examples/skills/pr-summary/SKILL.md).
Copy it to `.github/skills/pr-summary/` in your repo, restart your session, and run
`/pr-summary`.
