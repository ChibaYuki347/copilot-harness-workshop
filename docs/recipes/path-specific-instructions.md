# Recipe: Path-specific instructions

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

## How it composes

When you ask Copilot to change `frontend/src/components/Button.tsx`:

- The **baseline** applies (Conventional Commits, no force-push…).
- The **frontend instruction** applies (TypeScript strict, Vitest, etc.).
- The **backend instruction does not** apply (path mismatch).

When the change touches both halves, **both** path-specific instructions apply
**plus** the baseline.[^combined]

[^combined]: From the GitHub docs: *"If the path you specify matches a file that
    Copilot is working on, and a repository-wide custom instructions file also exists,
    then the instructions from both files are used."*

## Verifying

```text
/instructions   # see each instruction file and toggle them
/env            # confirms what's loaded for the current context
```

When you mention a file, the picker will tell you which path-specific rules attach.

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
