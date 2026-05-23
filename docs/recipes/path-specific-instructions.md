# Recipe: Path-specific instructions

!!! info "Works on: 🟪 VS Code Copilot Chat primary"
    **`applyTo` glob targeting is a VS Code-specific feature.** The
    `.github/instructions/*.instructions.md` files with `applyTo: "frontend/**"`
    frontmatter only filter by path **inside VS Code Copilot Chat** — VS Code's
    `CustomInstructionsService` matches each open / edited file against the glob and
    injects only the matching instruction files.

    **In Copilot CLI**, the same files *are* discovered (via the VS Code interop
    reader), but the CLI **does not honor `applyTo` globs** — it merges every
    matching instruction file flatly into the system prompt regardless of which file
    you're working on. So the path-specific behavior described below is VS
    Code-only.

    **CLI-native equivalent: nested `AGENTS.md` files.** The CLI walks subdirectories
    looking for `AGENTS.md` — placing `frontend/AGENTS.md` and `backend/AGENTS.md`
    gives you the same "different rules in different directories" outcome without
    needing globs. See the *CLI equivalent* section at the end of this recipe.

**Tell Copilot one set of rules for the frontend and a different set for the backend
without duplicating the rest.**

## Problem

In a monorepo, your `frontend/` is TypeScript + React with strict ESLint, while
`backend/` is Python + FastAPI with Ruff. A single `copilot-instructions.md` either
becomes a long `if frontend then… else…` list, or ignores the distinction.

## Layers used

- **Custom Instructions** — repo-wide + path-specific (`applyTo` frontmatter).

## File layout

```
.github/
├── copilot-instructions.md            # team-wide baseline (small)
└── instructions/
    ├── frontend.instructions.md       # applyTo: frontend/**
    └── backend.instructions.md        # applyTo: backend/**
```

## Baseline — `.github/copilot-instructions.md`

Keep this short. Conventions that apply *everywhere* only.

```markdown
# Conventions — monorepo

- This is a monorepo with `frontend/` (React/TS) and `backend/` (Python/FastAPI).
- We use Conventional Commits (`feat:`, `fix:`, `chore:`…).
- Cross-language changes that touch both halves must update `CHANGELOG.md`.
- Never `git push --force` on `main`.
```

## Path-specific — `.github/instructions/frontend.instructions.md`

```markdown
---
applyTo: "frontend/**"
---

# Frontend conventions

- TypeScript strict mode; never use `any` — prefer `unknown` + a type guard.
- React 18+. Functional components only. Hooks rules apply.
- State: Zustand for global, `useReducer` for component-local complex state.
- Tests: Vitest + React Testing Library. Files `*.test.tsx` next to the component.
- Run `pnpm lint && pnpm test --run` before claiming done.
```

## Path-specific — `.github/instructions/backend.instructions.md`

```markdown
---
applyTo: "backend/**"
---

# Backend conventions

- Python 3.12. Type hints mandatory on public functions.
- Web framework: FastAPI. Routers live in `backend/app/routers/`.
- DB access through `backend/app/db.py` only — never `import asyncpg` directly.
- Tests: pytest + httpx.AsyncClient. Files in `backend/tests/`.
- Run `ruff check --fix && pytest -q` before claiming done.
```

## How it composes (in VS Code Copilot Chat)

When you ask Copilot to change `frontend/src/components/Button.tsx`:

- The **baseline** applies (Conventional Commits, no force-push…).
- The **frontend instruction** applies (TypeScript strict, Vitest, etc.).
- The **backend instruction does not** apply (path mismatch).

When the change touches both halves, **both** path-specific instructions apply
**plus** the baseline.[^combined]

[^combined]: From the GitHub docs: *"If the path you specify matches a file that
    Copilot is working on, and a repository-wide custom instructions file also exists,
    then the instructions from both files are used."* This composition is performed
    by VS Code's `CustomInstructionsService`; the Copilot CLI does **not** perform
    glob-based filtering on `.instructions.md` files — see the *CLI equivalent*
    section below.

## Verifying (VS Code)

In VS Code Copilot Chat, open the **Instructions** picker (or `Add Context → Instructions`)
to confirm which files are attached for the current context. The `applyTo` matches are
re-evaluated whenever the active file changes.

## CLI equivalent — nested `AGENTS.md` { #cli-equivalent }

The Copilot CLI **reads** `.github/instructions/*.instructions.md` (via its VS Code
interop reader), but it merges all matching files flatly into the system prompt
without honoring `applyTo` globs — every instruction is always in scope. To get
"different rules in different directories" in the CLI, use **nested `AGENTS.md`**
files instead:

```
.
├── AGENTS.md                # team-wide baseline (top-level)
├── frontend/
│   └── AGENTS.md            # frontend rules
└── backend/
    └── AGENTS.md            # backend rules
```

When you start a CLI session inside `frontend/` (or `cd` into it during a session),
the CLI walks up the tree, picks up the nearest `AGENTS.md` files, and merges them
into the prompt. The top-level `AGENTS.md` is always included; the subdirectory one
joins it.[^nested-agents]

[^nested-agents]: Per the Copilot CLI spec, `readNestedAgentsInstructions` discovers
    `AGENTS.md` files in subdirectories (excluding the repo root, which is read by a
    separate path). This is the CLI-native mechanism for path-specific instructions.

| Want | VS Code | Copilot CLI |
|---|---|---|
| Baseline rules for the whole repo | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` **or** root `AGENTS.md` |
| Different rules for `frontend/` | `.github/instructions/frontend.instructions.md` with `applyTo: "frontend/**"` | `frontend/AGENTS.md` |
| Different rules for `backend/` | `.github/instructions/backend.instructions.md` with `applyTo: "backend/**"` | `backend/AGENTS.md` |
| Personal overlay | User profile `.instructions.md` | `~/.copilot/copilot-instructions.md` |

If you want **one set of files that works in both hosts**, you can ship the
`.instructions.md` files (VS Code will use `applyTo`) *and* nested `AGENTS.md`
(CLI will use proximity). The duplication is the cost of cross-host parity until
the CLI honors `applyTo` natively.

### Verifying in the CLI

You can still confirm which instruction sources the CLI loaded:

```text
/env             # prints the merged list of instruction sources
```

The `.instructions.md` files will appear in the list — just remember the CLI
**doesn't** narrow them by `applyTo` glob.

## Variations

- **Multi-glob `applyTo`.** The `applyTo` field accepts both string and array values:

    ```markdown
    ---
    applyTo:
      - "backend/**/*.py"
      - "scripts/**/*.py"
    ---
    ```

- **Personal overlay.** A teammate who prefers tabs over spaces can keep that
  preference in `~/.copilot/copilot-instructions.md` without polluting the team file.
- **`AGENTS.md` per subtree.** Drop `AGENTS.md` inside `frontend/` and `backend/`.
  Copilot honors the nearest `AGENTS.md` in the directory tree from cwd.

## Pitfalls

!!! warning "Glob pitfalls"
    - **Unquoted glob patterns** used to cause issues in older CLI versions — `applyTo:
      **/*.ts` was misparsed.[^unquoted] Modern versions handle it correctly, but
      quoting (`applyTo: "**/*.ts"`) is still the safer style.
    - **Glob matches the path Copilot is operating on**, not the cwd. If you ask Copilot
      to "refactor frontend/src", but the glob is `frontend/src/**/*.ts`, only the
      `.ts` files actually get the instruction loaded.

[^unquoted]: From the changelog: *"Instruction files with unquoted glob patterns in
    applyTo frontmatter (e.g. applyTo: \*\*/\*.ts) are now applied correctly"*.

## Try it

A runnable example is in [`examples/instructions/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/instructions).
