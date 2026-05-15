# 2 · Prompt Files

🟢 **Beginner · ~25 min**

## Learning objectives

By the end of this exercise you can:

- Define a prompt file with YAML frontmatter and an argument hint.
- Invoke it as a slash command (`/pr-description`) from inside a session.
- Pass an argument and confirm it ends up in the prompt body.

## Prerequisites

- A scratch git repo with at least one commit on `main`.
- Copilot CLI authenticated.
- ~25 minutes.

## Checkpoint commit

```bash
git commit --allow-empty -m "checkpoint: before prompt-files exercise"
```

## Scenario

Every time someone opens a PR, they write the description from scratch and it
ends up structured slightly differently. You want one canonical template that
your whole team can invoke as `/pr-description` and have grounded in the actual
diff — not made up.

## Steps

### 1. Make sure there's a diff to summarize

Inside your lab repo, create a tiny change so the prompt has something real to
chew on:

```bash
echo "# Lab repo" > README.md
git add README.md
git commit -m "feat: add README"
echo "## New section" >> README.md   # leave this one uncommitted on purpose
```

Now `git diff` and `git log origin/main..HEAD` both have content.

### 2. Create the prompt file

```bash
mkdir -p .github/prompts
```

Create `.github/prompts/pr-description.prompt.md`:

```markdown
---
description: "Draft a PR description from the current branch's diff."
argument-hint: "Optional base branch (default: origin/main)"
---

# /pr-description

The user gave you `$ARGUMENT` as the base branch. If empty, use `origin/main`.
If `origin/main` doesn't exist, fall back to `HEAD~1`.

## Task

1. Run `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD`.
2. Read the diff hunks that look most interesting (≤ 10 files).
3. Produce a PR description with exactly these sections:
   - **Summary** (one sentence)
   - **What changed** (bulleted by area)
   - **Tests** (what's covered; "no test changes" if none)
   - **Risks** (≤ 3 specific risks, or "no notable risks identified")
4. Write the result to `.pr-description.md` and print its path.

## Constraints

- Don't invent reasons that aren't visible in the diff.
- If the diff is empty, say so and stop. Don't write a file.
```

**Verifiable outcome**: `ls .github/prompts/pr-description.prompt.md` succeeds.

### 3. Start a session and confirm the command is registered

```bash
copilot
```

Inside the session, type `/` and start typing `pr`. The autocomplete should show
`/pr-description` with the description from the frontmatter.

### 4. Invoke the prompt

```text
/pr-description
```

Watch the agent: it should run `git log` and `git diff`, then write
`.pr-description.md`.

### 5. Invoke with an argument

```text
/pr-description HEAD~1
```

This time the base is `HEAD~1`, so the diff is smaller. The resulting file
should reflect the smaller scope.

## Definition of done { #definition-of-done }

All four must be true:

- [ ] `.github/prompts/pr-description.prompt.md` exists with `description` and
      `argument-hint` in frontmatter.
- [ ] Inside a session, typing `/pr-` shows `/pr-description` in autocomplete.
- [ ] Invoking `/pr-description` creates `.pr-description.md` in the repo root.
- [ ] The file contains the four required sections (Summary / What changed /
      Tests / Risks) — even if some are short.

## Reference solution { #reference-solution }

??? success "Show reference solution"
    A polished prompt file from the docs site:

    ```markdown
    --8<-- "examples/prompts/refactor-tests.prompt.md"
    ```

    The `pr-description` prompt above follows the same shape: numbered task
    steps, explicit constraints, an output contract.

    For the full reference on prompt-file frontmatter and arguments, see
    [Customizations → Prompt Files](../customizations/prompt-files.md).

## Cleanup

```bash
rm -rf .github/prompts .pr-description.md
git restore README.md
```

## Troubleshooting

- **`/pr-description` doesn't appear in autocomplete.** The filename must end in
  `.prompt.md`. A filename like `pr-description.md` (no `.prompt`) will be
  ignored.
- **The prompt runs but doesn't see any diff.** Make sure your branch isn't
  `main`/`master` itself — there's no diff against the base. Check out a feature
  branch first: `git checkout -b feature/test`.

## What not to do

- Don't hardcode `origin/main` into the body — use `$ARGUMENT` so the prompt
  works in repos with different default branches (`master`, `develop`, …).
- Don't put `--yes` / non-interactive shell commands in the body that bypass
  user confirmation. Prompt files run with **your** permissions.

## Stretch goals

1. Add a second argument: `argument-hint: "<base> [--draft]"`. When `--draft` is
   passed, prepend `[DRAFT] ` to the summary.
2. Pipe the result straight into a GitHub PR with `gh`:
   ```text
   /pr-description origin/main && gh pr create --body-file .pr-description.md
   ```
   (Add this to the prompt body as a *suggestion* the agent prints — don't run
   it automatically.)
