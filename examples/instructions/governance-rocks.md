# Governance ROCKS — a starter `copilot-instructions.md`

A template `.github/copilot-instructions.md` you can drop into any internal
repo as the **first** governance signal the agent sees. A single short page
that codifies the team's non-negotiables, named in a way the agent will
quote back to you.

> **ROCKS = Rules, Ownership, Code-of-care, Knowns, Stops.**
> Five sections, in this order, every time.

This is a starting point, not a finished policy. Adapt the bracketed
placeholders to your team. Keep the whole file **under 200 lines** — Copilot
loads it on every session and longer pages start to dilute attention.

---

## Copy-paste template

Save the block below as `.github/copilot-instructions.md` at your repo root.

````markdown
# Project conventions for Copilot — [PROJECT NAME]

This file is loaded automatically at the start of every Copilot session
(CLI: `copilot`; VS Code: Copilot Chat). Read it once; then follow it.

## R — Rules (must)

These are non-negotiable. If a user prompt asks you to violate one, refuse
and explain which rule it violates.

- **Never push to `main` directly.** All work goes via a branch and a PR.
- **Never run `git push --force*` on a shared branch.** Use `--force-with-lease`
  on personal branches only.
- **Never `rm -rf` outside the current repo's working tree.**
- **Never commit secrets.** If you generate one, write it to `.env.local`
  (gitignored) and reference via `${VAR}`.
- **Never disable a hook** (`.github/hooks/*`) to make a command go through.
- **Never `curl … | sh`.** Download, inspect, then run.

## O — Ownership

- This repo is owned by `[TEAM_NAME]`. PR reviewers are
  `[@user1 @user2 @user3]`.
- Production deploys are owned by `[ONCALL_TEAM]`. **You may not trigger a
  deploy** — only open a PR that, when merged, the deploy pipeline picks up.
- Customer data lives in `[REGION]`. Don't move it across regions without
  explicit instruction in the user prompt.

## C — Code-of-care (preferred)

These are strong defaults. You can deviate with a one-line justification in
the PR description.

- **One concern per commit.** Don't bundle a refactor with a feature.
- **Tests before push.** Run the local test command (`[npm test|pytest|go test ./...]`)
  and report the result. Don't push red.
- **Public APIs need a docstring.** Every new exported symbol gets one
  sentence describing its purpose and one example.
- **Error messages name the user-visible thing first.** Not "DB error", but
  "Couldn't load user profile (DB query failed)".

## K — Knowns

The "things that have bitten us before" list. Surface them when you see
something that looks like a re-occurrence.

- **The `legacy_users` table has soft deletes.** Always filter
  `WHERE deleted_at IS NULL` unless explicitly asked.
- **The `auth-v1` package returns `null` for missing fields, `auth-v2`
  returns `undefined`.** Don't `===` compare; use `== null`.
- **CI flakes on `e2e/checkout.spec.ts` step 4.** Rerun once before
  reporting a real failure.

## S — Stops

When to **stop and ask the user**, not proceed:

- The task touches **customer data** (any table starting with `cust_*`).
- The task involves **production credentials** (env vars starting with
  `PROD_*`).
- You're about to **make more than 5 file changes** in a single turn —
  pause and confirm the plan first.
- You can't find an obvious owner for a file you'd modify (no `CODEOWNERS`
  entry, no recent commits from a named team).
- The user prompt would require you to **delete data** (rows, files,
  branches, deployments).

## How to read this file

When asked "what are the rules for this repo?", quote the relevant section
(R / O / C / K / S) verbatim. Don't paraphrase.

When you propose a change that touches a rule, **name the rule** in your
explanation so the user can confirm or override.

When the user explicitly overrides a rule for a single task, log that override
in the PR description ("Per user override: skipped 'tests before push' because
…").
````

---

## How this differs from a plain `copilot-instructions.md`

Most repo-level instruction files mix tone-of-voice, conventions, and rules
into one bulleted list. The ROCKS structure makes governance content
**queryable by the agent** — when you ask "what's the rule on force-push?",
the agent finds it under `R` and quotes it. When you ask "should we delete
this table?", the agent finds it under `S` and stops.

The 5-letter buckets also give you a stable target for code reviewers
("you've added a `must`, that goes under R, not C").

## When to put a rule in R vs C

| Test | R (must) | C (preferred) |
|---|---|---|
| If the agent violated this, would Security file a ticket? | ✅ | ❌ |
| If the agent violated this, would the on-call get paged? | ✅ | ❌ |
| Can a teammate plausibly override this for a one-off task? | ❌ | ✅ |
| Does it require a follow-up cleanup commit if skipped? | ❌ (don't skip) | ✅ |

When in doubt, start in C and promote to R if you find the agent skipping it.

## When to add a `K` entry

Every time a Copilot-driven incident review finds "the agent didn't know X."
The Knowns section is the team's accumulated context that *isn't* in the code.

Keep it ≤ 10 bullets. Once you cross 10, ask whether each one is still true
— stale Knowns are worse than missing ones.

## Cross-references

- [Governance → Risk mental model](../../docs/governance/risk-mental-model.md)
- [Governance → Approval cheat sheet](../../docs/governance/approval-cheatsheet.md)
- [`examples/instructions/copilot-instructions.md`](../copilot-instructions.md)
  — the generic tone-of-voice example (use both together).
- [`examples/hooks/deny-dangerous-commands/`](../../hooks/deny-dangerous-commands/)
  — enforces the rules in `R` mechanically, so a typo can't bypass them.
