# 3 · Skills

🟡 **Intermediate · ~45 min**

## Learning objectives

By the end of this exercise you can:

- Lay out a Skill directory (`SKILL.md` + scripts + references).
- Write `SKILL.md` frontmatter that the agent uses to decide when to invoke.
- Bundle a small **helper script** that the skill calls.
- Verify the skill is discoverable (`/skills`) and produces the contracted output.

## Prerequisites

- Lab repo from the earlier exercises (or a fresh one with one commit).
- `bash` available on `$PATH`.
- ~45 minutes.

## Checkpoint commit

```bash
git commit --allow-empty -m "checkpoint: before skills exercise"
```

## Scenario

Half your team writes commits like `feat(api): add login` and half writes `fix
stuff`. You want a `/commit-hygiene` skill that drafts a Conventional Commits
message from the staged diff, **and** validates the result with a tiny lint
script so the output is consistent regardless of who runs it.

## Steps

### 1. Lay out the skill folder

```bash
mkdir -p .github/skills/commit-hygiene/{scripts,references}
```

You should end up with:

```text
.github/skills/commit-hygiene/
├── SKILL.md
├── scripts/
│   └── lint-message.sh
└── references/
    └── conventional-commits.md
```

### 2. Write the lint script

`.github/skills/commit-hygiene/scripts/lint-message.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?usage: lint-message.sh <file>}"
FIRST="$(head -n1 "$FILE")"

if [[ ! "$FIRST" =~ ^(feat|fix|docs|test|refactor|chore|perf|build|ci)(\(.+\))?:[[:space:]].+$ ]]; then
  echo "FAIL: first line must match Conventional Commits."
  echo "  got: $FIRST"
  exit 1
fi

if (( ${#FIRST} > 72 )); then
  echo "FAIL: first line exceeds 72 chars (${#FIRST})."
  exit 1
fi

echo "OK: $FIRST"
exit 0
```

Make it executable:

```bash
chmod +x .github/skills/commit-hygiene/scripts/lint-message.sh
```

**Verifiable outcome**:

```bash
echo "feat: hello world" > /tmp/m && \
  .github/skills/commit-hygiene/scripts/lint-message.sh /tmp/m
# OK: feat: hello world
```

### 3. Write the reference

`.github/skills/commit-hygiene/references/conventional-commits.md`:

```markdown
# Conventional Commits cheat-sheet

Type prefixes we use:

- **feat** — a user-visible new capability
- **fix** — a user-visible bug fix
- **docs** — docs only
- **test** — tests only
- **refactor** — no behavior change
- **chore** — tooling, deps
- **perf** — performance only
- **build / ci** — build/CI plumbing

Format: `type(scope): subject` — subject in imperative mood, no trailing period,
72-char first-line limit.
```

### 4. Write `SKILL.md`

`.github/skills/commit-hygiene/SKILL.md`:

```markdown
---
name: commit-hygiene
description: |
  Use this skill when the user asks to draft, write, or fix a commit message,
  or asks about commit style. Triggers: "commit message", "commit msg", "draft
  a commit", "/commit-hygiene". Do not trigger for general PR/branch summaries.
license: MIT
---

# commit-hygiene

Draft a Conventional Commits message from the staged diff, then validate it
with the bundled lint script.

## Output Contract

When this skill finishes:

1. A file `.commit-message.txt` exists at the repo root.
2. `scripts/lint-message.sh .commit-message.txt` exits 0.
3. The final response is the message contents.

## Workflow

1. Read `references/conventional-commits.md` for the type list.
2. Run `git diff --staged --stat` and `git diff --staged` (truncate at ~400 lines).
3. Pick **one** type that best matches the dominant change kind. If multiple
   apply, prefer `feat` > `fix` > `refactor` > everything else.
4. Pick a scope only if the staged files are confined to one obvious directory.
5. Write a subject in the imperative ("add login", not "added login").
6. Save to `.commit-message.txt`:
   ```text
   type(scope): subject
   ```
7. Run `scripts/lint-message.sh .commit-message.txt`. If it fails, fix and retry.
8. Print the final message and the path.

## Rules

- One commit message. No alternatives, no "or maybe…".
- If the staged diff is empty, say so and stop. Don't invent.
- Never include explanations in the file itself — only the message lines.
```

**Verifiable outcome**: all four files exist and the lint script is executable.

### 5. Stage a change and invoke the skill

```bash
echo "// hello" > hello.js && git add hello.js
copilot
```

In the session, invoke the skill explicitly:

```text
/commit-hygiene
```

…or implicitly:

```text
Draft me a commit message for the staged changes.
```

### 6. Verify the contract

```bash
.github/skills/commit-hygiene/scripts/lint-message.sh .commit-message.txt
# OK: feat: ...
```

## Definition of done { #definition-of-done }

All five must be true:

- [ ] `.github/skills/commit-hygiene/SKILL.md` exists with `name` and
      `description` in frontmatter.
- [ ] `scripts/lint-message.sh` is executable (`ls -l` shows `x`) and exits 0
      on a valid sample.
- [ ] `/skills` inside a session lists `commit-hygiene`.
- [ ] After invocation, `.commit-message.txt` exists in the repo root.
- [ ] `lint-message.sh .commit-message.txt` exits 0.

## Reference solution { #reference-solution }

??? success "Show reference solution"
    The full `SKILL.md` shape (from the `pr-summary` example shipped with the
    docs site):

    ```markdown
    --8<-- "examples/skills/pr-summary/SKILL.md"
    ```

    For the discovery order (cwd up to git root, plus `~/.copilot/skills/`),
    see [Customizations → Skills](../customizations/skills.md).

## Cleanup

```bash
rm -rf .github/skills .commit-message.txt
git restore --staged hello.js && rm -f hello.js
```

## Troubleshooting

- **`/skills` doesn't show `commit-hygiene`.** Confirm the folder is exactly
  `.github/skills/commit-hygiene/SKILL.md` (case matters on Linux). The
  identifier comes from the folder name, not from `name:` in the frontmatter.
- **The skill runs but doesn't call the lint script.** Skills don't enforce
  tool calls — the `Workflow` section is guidance for the model. Tighten the
  language: "**You must** run `scripts/lint-message.sh` and only finish when it
  exits 0."

## What not to do

- Don't write shell scripts that assume GNU options on macOS (`sed -i ''` vs
  `sed -i`). Either use portable flags or note the requirement in the skill.
- Don't make the lint script fail on warnings as well as errors — exit codes
  should mean "did we satisfy the contract". Use stdout for warnings.

## Stretch goals

1. Add a body validation rule: if the staged diff touches > 5 files, the commit
   message **must** have a body paragraph explaining the grouping. Extend
   `lint-message.sh` and the `Workflow` section together.
2. Add a `references/scope-map.md` listing the directory → scope mapping for
   your real repo (e.g. `src/api/ → api`, `web/ → web`). Have the skill read it
   in step 4.
