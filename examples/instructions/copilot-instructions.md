# Example: copilot-instructions.md

> Drop this file at `.github/copilot-instructions.md` in your repo. Replace the
> placeholders with your team's reality.

## About this repo

This is **<project name>**, a <one-line description: "Next.js web app", "FastAPI
service", "monorepo with frontend + backend">. Default branch: `main`.

## Stack

- **Languages:** <e.g., TypeScript 5.x, Python 3.12>
- **Frameworks:** <e.g., Next.js 14, FastAPI 0.110>
- **Tests:** <e.g., Vitest, pytest>
- **Lint / format:** <e.g., ESLint + Prettier, ruff>

## Conventions

- Use **TypeScript strict mode**. Never `any` — prefer `unknown` + type guards.
- **Conventional Commits** (`feat:`, `fix:`, `chore:`…). One change per commit when
  possible.
- New public functions get **JSDoc / docstrings**.
- New endpoints / public types update `CHANGELOG.md` under `## [Unreleased]`.
- Don't introduce a **new runtime dependency** without asking first.
- Tests live next to the code: `foo.ts` ↔ `foo.test.ts`.

## Workflow

When working on a task:

1. State a one-line plan before editing files.
2. Make the change; keep diffs minimal.
3. Run **`pnpm lint && pnpm test --run`** (or `ruff check --fix && pytest -q` for
   Python). Don't claim done until both pass.
4. Don't `git push --force` on `main` or release branches.

## Useful project commands

```bash
pnpm install              # install deps
pnpm dev                  # local dev server
pnpm test                 # run all tests
pnpm lint                 # lint
```

## What to ask the user

Use the `ask_user` tool when:

- An ambiguous business decision arises (which of two valid behaviors is "right").
- You'd otherwise have to invent a name, URL, or config value.

Don't ask trivia questions the project answers itself (look in the README first).

## What not to do

- Don't generate code with **placeholder** values like `XXX`, `your-token-here` and
  silently leave them. Either ask, or fail loudly.
- Don't commit secrets or `.env` files.
- Don't delete migrations.
- Don't refactor things outside the scope of the current task.
