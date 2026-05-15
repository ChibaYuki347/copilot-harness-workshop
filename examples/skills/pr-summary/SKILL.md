---
name: pr-summary
description: |
  Use this skill when the user asks for a summary of an open pull request or of the
  current branch's diff. Trigger phrases: "summarize this PR", "PR summary",
  "what changed on this branch". Do not trigger for general code questions or one-line
  diff explanations.
license: MIT
---

# PR Summary

Produce a concise, structured summary of the current branch (or an open PR) suitable
for pasting into a PR description.

## Output Contract

When this skill finishes:

1. A file `.pr-summary.md` exists at the repo root.
2. Its sections are: **Title (Conventional Commits)**, **Why**, **What changed**,
   **Files touched**, **Testing**, **Risks**.
3. The final response is the file's contents, plus the path it was saved to.

## Workflow

### Phase 1 — Scope

1. Determine the base branch from the argument (default: `origin/main`).
2. Compute the diff range: `BASE...HEAD`.
3. Run `git log --oneline BASE..HEAD` and `git diff --stat BASE...HEAD` to get an
   overview.

### Phase 2 — Read

4. For each changed file (up to ~20), run `git diff BASE...HEAD -- <file>` and read
   the hunks.
5. Cluster files by purpose: feature code, tests, docs, config.

### Phase 3 — Synthesize

6. Draft the summary:
   - **Title**: Conventional Commits format. Pick `feat`, `fix`, `chore`, `refactor`,
     `docs`, `test`, `perf`, `build`, or `ci` based on the dominant change kind.
   - **Why**: one or two sentences. If unclear from the diff, mention that explicitly
     instead of inventing a reason.
   - **What changed**: bulleted by cluster.
   - **Files touched**: a short list, grouped.
   - **Testing**: what tests were added / modified. If none, say so.
   - **Risks**: ≤ 3 specific risks (perf, compat, security, data loss). If you don't
     see any, write "No notable risks identified from the diff."
7. Save to `.pr-summary.md`.

### Phase 4 — Present

8. Print the file contents.
9. Tell the user where it was saved and how to use it:
   ```text
   gh pr edit --body-file .pr-summary.md
   ```

## Notes

- If `gh` is not installed, skip the gh-related hint.
- If the branch has no diff against the base, say so and stop. Don't invent content.
- Don't speculate about why a change was made beyond what the diff supports.
