---
description: "Refactor and strengthen the tests for a given file or module."
argument-hint: "Path to the file or module under test"
---

# /refactor-tests

The user will give you a path (e.g., `backend/app/services/payment.py` or
`frontend/src/components/Button.tsx`). Treat that as `$ARGUMENT`.

## Task

1. **Locate the test file** that corresponds to `$ARGUMENT`. If there isn't one, say
   so and stop; ask whether to create a new one before continuing.
2. **Read both** the source and the test file. Understand the public surface.
3. **Inventory** the existing tests. For each, note:
   - which public function/method/component it exercises
   - happy path or error path
   - is it actually asserting behavior, or just exercising the code path?
4. **Identify gaps**. For each public function, check:
   - happy-path covered?
   - error / edge cases covered?
   - boundary conditions (empty, max size, special chars, timezone, etc.)?
5. **Propose a plan** (do not edit yet): a bulleted list of test additions /
   refactors, grouped by function under test. Each item ≤ 1 line.
6. **Wait for confirmation.** Ask `ask_user` whether to proceed, with three options:
   - "Yes — apply all changes"
   - "Yes — apply only the additions, skip refactors"
   - "No — show me the plan only"
7. If approved, apply the changes. Run the test suite (`pnpm test --run <file>` /
   `pytest <file> -q`). Iterate until green.

## Constraints

- **Don't change the source under test.** This is a test refactor, not a behavior
  change.
- Use the project's existing test framework / style — don't introduce a new one.
- Keep test names descriptive (`it("rejects empty input", ...)`, `test_returns_404_on_unknown_user`).
- Prefer one assertion per test where reasonable. Stack assertions only when they
  describe one logical behavior together.
