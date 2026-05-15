# 📜 Custom Instructions

**Teach Copilot your conventions once, apply them everywhere.**

Custom instructions are the simplest and highest-leverage customization. They're plain
Markdown files Copilot loads into its system prompt — no scripts, no JSON, no DSL.

## When to use them

- You catch yourself saying the same thing to Copilot every session.
- You have project-specific conventions (build commands, formatter, test runner).
- Different parts of the codebase have different rules (frontend vs. backend).
- You want personal preferences (style, verbosity) to follow you across projects.

## Where they live

Copilot CLI discovers instruction files at every directory level from your `cwd` up to
the git root, plus your home directory.[^locations]

[^locations]: From the `/help` output: *"Copilot respects instructions from these locations:
    CLAUDE.md, GEMINI.md, AGENTS.md (in git root & cwd), .github/instructions/\*\*/\*.instructions.md
    (in git root & cwd), .github/copilot-instructions.md, $HOME/.copilot/copilot-instructions.md,
    COPILOT_CUSTOM_INSTRUCTIONS_DIRS (additional directories via env var)"*

| Type | Path | Applies to |
|---|---|---|
| **Repo-wide** | `.github/copilot-instructions.md` | Every prompt in this repo. |
| **Path-specific** | `.github/instructions/**/*.instructions.md` | Files matching the `applyTo` glob. Recursive — sub-folders work too. |
| **Agent-style** | `AGENTS.md` (git root or cwd, also `CLAUDE.md` / `GEMINI.md`) | Whatever directory `AGENTS.md` lives under. |
| **Personal** | `~/.copilot/copilot-instructions.md` | Every project on this machine. |
| **Custom dirs** | Any path in `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | Each listed directory is scanned for `AGENTS.md` and `.github/instructions/**/*.instructions.md`. Useful for sharing curated instructions across repos. |

## Minimal example — repo-wide

`.github/copilot-instructions.md`:

```markdown
# Conventions — payments-service

- This is a TypeScript project. **Always** target Node 20 features.
- Use `pnpm`, never `npm` or `yarn`.
- Tests live in `*.test.ts` next to the file under test, not in a `__tests__` folder.
- We use `zod` for runtime validation — prefer `z.object({...}).parse()` over manual checks.
- Database access goes through `@/db/client.ts`. Never `import postgres` directly.
- When changing public types in `src/types/`, update `CHANGELOG.md` under "Unreleased".
```

That file is committed to the repo, so every contributor's Copilot session has the
same baseline.

## Minimal example — path-specific

`.github/instructions/python.instructions.md`:

```markdown
---
applyTo: "**/*.py"
---

# Python conventions

- Python 3.12+. Use `match` statements where they improve clarity.
- Type hints are mandatory for public functions.
- We use `ruff` for both linting and formatting. Run `ruff check --fix` before declaring done.
- Prefer `pathlib.Path` over `os.path`.
```

Path-specific files use the `applyTo` frontmatter to scope when they apply. They are
**combined** with the repo-wide file — both apply when the matched files are touched.[^combined]

[^combined]: Per the official docs: *"If the path you specify matches a file that Copilot
    is working on, and a repository-wide custom instructions file also exists, then the
    instructions from both files are used."*

## Minimal example — personal

`~/.copilot/copilot-instructions.md`:

```markdown
- Be terse. I read fast.
- Always show me the diff in unified format before committing.
- Default to `gh` CLI for GitHub operations.
- Never run `git push --force` without asking explicitly.
```

## How to write good ones

!!! tip "Heuristics that work"
    1. **Short beats long.** Anything you add costs tokens every turn. Cut prose.
    2. **Imperative voice.** *"Use `pnpm`."* not *"It is generally preferred that…"*.
    3. **State the why for non-obvious rules.** *"Use `pnpm` — workspace symlinks rely on it."*
    4. **Don't restate Copilot's defaults.** "Write good code" is noise.
    5. **Update them.** When a convention dies, delete the rule. Stale instructions are
       worse than missing ones.

!!! warning "Anti-patterns"
    - **Wall of text.** A 400-line instructions file is a 400-line system prompt overhead.
    - **Restating language docs.** Copilot already knows Python syntax.
    - **Personal preferences in the repo file.** Use `~/.copilot/...` for personal taste.

## Verification

```text
/instructions       # toggle individual files
/env                # see everything that's loaded
```

A correctly-loaded path-specific file shows up in `/instructions` and is mentioned in
`/env` under "Instructions".

## The `AGENTS.md` flavor

`AGENTS.md` is the [agent-instructions convention](https://github.com/agentsmd/agents.md)
shared by multiple AI tools. Copilot CLI honors the nearest `AGENTS.md` in the directory
tree from cwd up. Use it when you want your instructions to be portable across Claude
Code, Codex, Gemini CLI, etc.

`CLAUDE.md` and `GEMINI.md` at repo root are also honored, primarily for cross-tool
compatibility.

## Next

→ [⌨️ Prompt Files & Slash Commands](prompt-files.md) — the next-step abstraction when an
instruction is more of a *task template* than a always-on rule.
