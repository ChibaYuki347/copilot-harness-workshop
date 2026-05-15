# 1 · Custom Instructions

🟢 **Beginner · ~20 min**

## Learning objectives

By the end of this exercise you can:

- Write a repo-wide `.github/copilot-instructions.md` that survives every session.
- Add a **path-specific** instruction file that only applies to one part of the
  repo.
- Verify in-session that both files were discovered, using `/instructions`.

## Prerequisites

- A scratch git repo (`mkdir lab-01 && cd lab-01 && git init`).
- Copilot CLI authenticated.
- ~20 minutes.

## Checkpoint commit

```bash
git commit --allow-empty -m "checkpoint: before custom-instructions exercise"
```

## Scenario

You're a tech lead. Your team has three rules every PR should follow, plus one
extra rule that only applies to Python files. Right now, those rules live in
Slack pins that nobody reads. You want Copilot to follow them automatically
without anyone copy-pasting context into the chat.

## Steps

### 1. Create the repo-wide instructions

Create `.github/copilot-instructions.md` with at least **three concrete rules**
your team would care about. Use the file from
[`examples/instructions/copilot-instructions.md`](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/examples/instructions/copilot-instructions.md)
as a template.

A minimal version (you can use this verbatim to get unblocked):

```markdown
# Lab repo conventions

## Stack
- Language: Python 3.12
- Tests: pytest

## Conventions
- Use **Conventional Commits** (`feat:`, `fix:`, etc.).
- Every new public function gets a docstring with one example.
- Tests live next to the code: `foo.py` ↔ `test_foo.py`.

## What not to do
- Don't introduce a new runtime dependency without asking.
```

**Verifiable outcome**: `cat .github/copilot-instructions.md` prints the file.

### 2. Add a path-specific instruction

Create `.github/instructions/python.instructions.md` with frontmatter that scopes
it to `**/*.py`:

```markdown
---
applyTo: "**/*.py"
---

# Python-specific rules

- Prefer `pathlib.Path` over `os.path`.
- Type hints are required on public function signatures.
- No `print()` for logging — use the `logging` module.
```

**Verifiable outcome**: the file exists at the exact path above with `applyTo` in
the frontmatter.

### 3. Start a session and inspect what loaded

```bash
copilot
```

In the session, run:

```text
/instructions
```

You should see **both files** in the list, with the second one marked as scoped
to `**/*.py`.

### 4. Ask Copilot to write Python that exercises the rules

In the session, prompt:

```text
Add a small module fizzbuzz.py with one public function and a test file.
```

Inspect the result:

- Is there a docstring? (rule from `copilot-instructions.md`)
- Does it use `pathlib` if any path appears? (rule from `python.instructions.md`)
- Is the test file named `test_fizzbuzz.py`? (rule from `copilot-instructions.md`)

## Definition of done { #definition-of-done }

All four must be true:

- [ ] `.github/copilot-instructions.md` exists with ≥ 3 rules.
- [ ] `.github/instructions/python.instructions.md` exists with `applyTo:
      "**/*.py"`.
- [ ] `/instructions` inside a fresh session lists **both** files.
- [ ] When you ask for Python code, the generated code respects at least one
      visible rule from each file (e.g. has a docstring **and** uses type hints).

## Reference solution { #reference-solution }

??? success "Show reference solution"
    The exact files used in the docs site are in `examples/`:

    `.github/copilot-instructions.md`:

    ```markdown
    --8<-- "examples/instructions/copilot-instructions.md"
    ```

    `.github/instructions/python.instructions.md`:

    ```markdown
    --8<-- "examples/instructions/instructions/python.instructions.md"
    ```

    For more on the discovery order, see
    [Reference → File layout](../reference/file-layout.md).

## Cleanup

```bash
rm -rf .github/copilot-instructions.md .github/instructions
```

## Troubleshooting

- **`/instructions` doesn't show my file.** It's almost always a path or filename
  typo. The repo-wide file must be exactly `.github/copilot-instructions.md`
  (singular, hyphenated), and path-specific files must end in
  `.instructions.md` inside `.github/instructions/`.
- **Copilot ignores a rule.** Instructions are *guidance*, not enforcement. If a
  rule is critical, restate it as a stronger constraint ("**Never** use
  `print()` for logging") and put it under a `## What not to do` heading.

## What not to do

- Don't put secrets, internal hostnames, or private project names in
  `copilot-instructions.md`. The file is committed and public.
- Don't use `applyTo: "**"` on path-specific files — that's just a duplicate
  of the repo-wide file, with more places to forget to update.

## Stretch goals

1. Add **a second path-specific file** for tests
   (`.github/instructions/tests.instructions.md` with `applyTo: "**/test_*.py"`)
   that forbids `unittest.mock` and prefers `pytest` fixtures.
2. Set the environment variable `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` to point at
   `~/.copilot/lab-overrides/` and put a personal preference there (e.g.
   "always show the diff before committing"). Confirm with `/env` that it
   loaded.
