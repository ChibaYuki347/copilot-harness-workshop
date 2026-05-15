# 🦾 Skills

**Bundle a multi-step procedure — with scripts, templates, and rubrics — that the
agent can pick up and execute as a single named capability.**

A Skill is the heaviest-weight customization on this page, and the most powerful.
Where a prompt file is "a parameterized prompt", a Skill is **a folder containing a
`SKILL.md` plus any helper scripts, reference docs, and output templates it needs**.

## When to use a Skill (vs. a prompt file)

| Pick a **prompt file** when… | Pick a **Skill** when… |
|---|---|
| The task fits in one Markdown body. | The task has phases, validation, or its own data files. |
| You don't need helper scripts. | You want a `scan.py` or `validate.sh` shipped alongside the prompt. |
| The output is conversational. | The output is structured (files in a specific layout, a rubric, a checklist). |

## Anatomy of a Skill

```
.github/skills/<skill-name>/
├── SKILL.md                       # the entry point — YAML frontmatter + body
├── scripts/                       # optional helper scripts
│   └── scan.py
├── assets/                        # optional templates the agent fills in
│   └── templates/
│       └── REPORT.md
└── references/                    # optional reference docs the agent loads on demand
    └── checklist.md
```

The `SKILL.md` looks like this:

```markdown
---
name: pr-summary
description: |
  Use this skill when the user asks to summarize the current branch's PR or to draft a
  PR description. Trigger on prompts like "summarize my PR", "draft PR description",
  "what changed in this branch".
license: MIT
compatibility: "Cross-platform. Requires git and the gh CLI."
argument-hint: "Optional: target branch to diff against (default: origin/main)"
---

# PR Summary Skill

Generates a PR description following our team template, grounded in the actual diff.

## Output Contract

Before finishing, all of the following must be true:

1. A file `PR_BODY.md` exists in the repo root with the populated template.
2. Every section in the template is filled in or explicitly marked `N/A`.
3. The summary references only changes that appear in the diff.

## Workflow

### Phase 1 — Gather

1. Determine the base branch (default `origin/main`, override from argument).
2. Run `git diff --stat <base>...HEAD` and `git log <base>..HEAD --oneline`.
3. Identify the highest-risk file in the diff (largest churn or sensitive path).

### Phase 2 — Draft

Copy `assets/templates/PR_BODY.md` into the repo root and fill in:

- **Summary** — one paragraph.
- **Motivation** — link to the issue if found in commit messages.
- **What changed** — bullet list grouped by area.
- **Risk** — the high-risk file from Phase 1, plus mitigations.
- **Validation** — tests run, commands executed.

### Phase 3 — Validate

1. Re-read `PR_BODY.md`. Check every section is filled.
2. Confirm every bullet in "What changed" maps to a hunk in the diff.
3. If any check fails, fix and re-run.
```

## How Copilot picks a Skill up

When the user's prompt **matches a skill's `description`** (semantically — the
description is fed to the model), Copilot offers to invoke it. You can also force
invocation by typing the slash command:

```text
/pr-summary
/pr-summary develop
```

## Where Skills live

Skills are discovered at every directory level from cwd up to the git root, plus a few
well-known personal directories.[^skills-loc]

[^skills-loc]: See `github/copilot-cli` changelog entries: *"Add `~/.agents/skills/` as a
    personal skill discovery directory"* and *"Custom instructions, MCP servers, skills,
    and agents are now discovered at every directory level from the working directory up
    to the git root, enabling full monorepo support"*.

| Location | Scope |
|---|---|
| `.github/skills/<name>/SKILL.md` | Repo (committed). |
| `~/.copilot/skills/<name>/SKILL.md` | Personal. |
| `~/.agents/skills/<name>/SKILL.md` | Personal (cross-tool, also used by VS Code GHCP). |
| Any subdirectory of the above with `SKILL.md` directly inside | Recursively discovered. |

## Managing skills inside the CLI

```text
/skills            # list discovered skills, enable/disable
/skills add <dir>  # add a directory of skills
/env               # confirm which skills are active
```

Disabled skills are remembered across sessions.

## Frontmatter reference

| Key | Required | Purpose |
|---|---|---|
| `name` | Yes | Identifier — becomes the slash command (`/<name>`). Lowercase, hyphen-separated. |
| `description` | Yes | What the skill does **and when to trigger**. The model uses this to decide whether to invoke. |
| `license` | No | SPDX identifier for the skill's own license. |
| `allowed-tools` | No | Pre-approve specific tools (e.g. `shell`, `bash`, MCP tool names) so Copilot doesn't ask each time. **Use sparingly — see the warning below.** |
| `disable-model-invocation` | No | If `true`, the skill only runs when invoked explicitly via `/<name>`; the model can't decide to invoke it. |
| `compatibility` | No | Free-form runtime / OS requirements (informational). |
| `argument-hint` | No | Inline help for the slash command picker. |

!!! danger "`allowed-tools: shell` removes a security gate"
    Only pre-approve `shell` / `bash` for skills whose source you have **personally
    reviewed and trust**. Pre-approving terminal commands lets a malicious skill (or
    a prompt-injection into a benign skill) run arbitrary code without confirmation.
    The GitHub docs are explicit about this: *"When in doubt, omit `shell` and
    `bash` from `allowed-tools` so that Copilot must ask for your explicit
    confirmation before running terminal commands."*

## Writing a great `description`

The description is **the most important field**. It's how the model decides whether to
trigger your skill. Be explicit about the user phrasings you want to match, *and the
ones you don't*:

> **Good:** *"Use this skill when the user explicitly asks to summarize a pull request
> or draft a PR description. Trigger for phrases like 'summarize my PR', 'draft PR
> description', 'what changed in this branch'. Do not trigger for plain `git diff`
> requests or general code review."*

> **Bad:** *"PR summary."*

## Pitfalls

!!! warning "Common gotchas"
    - **Skills that exceed the token limit** are still discoverable and invocable, but
      their body content is loaded lazily. Keep `SKILL.md` itself focused; push detail
      into `references/*.md` that the skill body tells the agent to load on demand.
    - **No `BOM`.** Save `SKILL.md` as plain UTF-8 (no Byte Order Mark) — older versions
      of the CLI failed to parse BOM-prefixed frontmatter. Modern versions handle it,
      but it's a portability hazard.
    - **Don't hardcode absolute paths.** Use `$SKILL_ROOT` for the skill's own folder.

## Next

→ [🪝 Hooks](hooks.md) — the event-driven counterpart to Skills.
→ Or jump to the worked example: [Recipe: PR review skill](../recipes/pr-review-skill.md).
