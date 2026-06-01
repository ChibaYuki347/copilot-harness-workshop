---
name: site-build-check
description: |
  Use this skill before declaring a docs change done. Runs `mkdocs build --strict`,
  parses the output, and either confirms a clean build or reports each warning
  with the file/line that needs fixing. Trigger phrases: "verify the docs build",
  "is the site clean?", "run strict build". Do not trigger for unrelated tasks.
license: MIT
---

# Site Build Check

You confirm `mkdocs build --strict` is clean — the same check our CI runs on
every push to `main`.

This skill is a **live demo** of the *Skills* customization — see
[Customizations → Skills](../../../docs/customizations/skills.md) for the concept.

## Output Contract

When this skill finishes:

1. You have run `mkdocs build --strict` from the repo root.
2. The final response states either:
   - **`Build clean (M seconds)`** — extracted from the `Documentation built in N.NN seconds` line, or
   - **`Build failed with K warnings:`** followed by a markdown table with
     columns `File | Line | Warning` (one row per warning).
3. You do **not** edit any file. Diagnostics only.

## Workflow

### Phase 1 — Environment

1. Check the virtualenv. If `.venv/` doesn't exist or `mkdocs` is not on PATH,
   tell the user: `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`.
   Then stop. Don't auto-create the venv unless the user explicitly asks.
2. Otherwise proceed.

### Phase 2 — Run

3. Run `mkdocs build --strict 2>&1`. Capture stdout+stderr.
4. The build is **clean** if exit code 0 and the output contains no `WARNING` /
   `ERROR` lines. Extract the timing from the
   `INFO    -  Documentation built in N.NN seconds` line.

### Phase 3 — Report

5. If clean: emit `Build clean (M seconds)`. Done.
6. If warnings or non-zero exit: extract every `WARNING - ` line. Parse the file
   path and line number when present (format: `docs/<path>.md, line N: <msg>` or
   `Doc file '<path>' contains a link <...>` without line numbers). Emit the
   markdown table.

## Rules

- Don't try to fix the warnings yourself. The output is diagnostic only.
- Don't run any other command (no `git`, no `pip install`). Just the build.
- If `mkdocs` itself crashes (Python traceback in stderr), surface the traceback
  verbatim instead of trying to parse it.
- If the user passes a `--clean` or `--no-strict` flag, refuse and explain that
  the skill enforces strict mode (CI parity).
