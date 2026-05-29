# ⌨️ Prompt Files & Slash Commands

**Turn a repeated prompt into a one-shot, parameterized command.**

!!! abstract "Where it works"
    🟢 **Copilot CLI** · 🟢 **VS Code** (Copilot extension) — same `.github/prompts/*.prompt.md` files. Both surfaces type `/<name>` to invoke. See [VS Code vs CLI](../reference/vscode-vs-cli.md).

Custom instructions are *always-on*. Prompt files (a.k.a. custom slash commands) are
*on-demand* — you invoke them by typing `/command-name`.

## Why this exists

Some prompts are too **niche** for instructions (they don't apply to every turn)
but too **structured** to retype each time. A prompt file is the middle layer:
a versioned, parameterized template the team can share and the agent treats as
a first-class command.

## Alternatives — when *not* to reach for a prompt file

- The prompt has **steps with validation, output files, or scripts** → a
  [Skill](skills.md) is the right shape. Prompt files are flat Markdown bodies.
- The prompt is **invoked on a lifecycle event**, not by a human → a
  [hook](hooks.md) fires automatically; prompt files require typing `/foo`.
- The prompt is the same for **everyone, every turn** → that's an
  [instruction](custom-instructions.md), not a prompt file.

## When to use them

- You have a 6-line prompt you paste at least once a week.
- The task is repeatable but **not** something you want loaded into every turn.
- You want to share the recipe with the team via Git.
- You want parameters (file path, ticket number, …) injected into the prompt template.

## How a prompt file works

A prompt file is a Markdown file whose **body becomes the prompt** when the command is
invoked. Frontmatter declares the command name, description, and optional arguments.

The file lives where Copilot CLI discovers commands — alongside your other
customizations, at every directory level from cwd up to the git root, plus
`~/.copilot/`.

!!! info "Skills vs. prompt files"
    A **skill** is a richer structure (its own folder with scripts and templates).
    A **prompt file** is a lightweight, single-file template. If your "command" needs
    helper scripts or a multi-phase workflow, reach for a [Skill](skills.md) instead.

## Minimal example

`.github/prompts/refactor-tests.prompt.md`:

```markdown
---
description: "Refactor stale tests in the given file to current conventions"
argument-hint: "<path-to-test-file>"
---

You are refactoring the test file at: $ARGUMENTS

Apply these rules in order:

1. Replace any `expect(x).to.equal(y)` (chai) with `expect(x).toBe(y)` (vitest).
2. Convert callback-style tests to `async/await`.
3. Co-locate `beforeEach` set-up next to the `describe` it applies to.
4. Remove tests that only assert that the test file itself loads (`expect(true).toBe(true)`).
5. Run the file with `pnpm vitest run $ARGUMENTS` and report any failures verbatim.
```

Invoke it inside Copilot CLI:

```text
/refactor-tests src/services/payments.test.ts
```

The `$ARGUMENTS` token is replaced with what you passed.

## Composition with other features

Prompt files compose well with everything else:

- A prompt file can **reference a skill** in its body: *"Use the `/code-review` skill to
  review the diff before committing."*
- A prompt file can **call an MCP tool** by name: *"Use the `linear:get-issue` tool to
  fetch ticket details for $ARGUMENTS."*
- A prompt file can be **chained** via plan mode: ask the agent to plan first, run the
  prompt file as one step.

## Discovery & invocation

```text
/help     # lists all available commands, including prompt files
/env      # confirms which prompt files were picked up
```

Once discovered, the command appears in the slash-command autocomplete picker.

## Anti-patterns

!!! warning "Avoid these"
    - **Encoding a task that has steps you can't observe.** If the agent needs to choose
      between multiple paths based on file contents, a Skill with phase markers serves you better.
    - **Embedding secrets.** Prompt files are committed. Use environment variables or
      `gh secret`-injected env, not literal tokens.
    - **One huge "do everything" command.** If `/do-the-thing` actually means six
      different tasks, you've reinvented `copilot` itself.

## Worked patterns

| Pattern | Example body sketch |
|---|---|
| **Issue triage** | "Fetch issue #$ARGUMENTS, summarize, propose labels, propose milestone, propose assignee." |
| **PR summary** | "Read the diff of the current branch against `origin/main`. Produce a PR description in our template." |
| **Migration step** | "Search for usages of `oldFn(...)` and replace with `newFn(...)` per ADR-042. Skip files matching `legacy/**`." |
| **Dependency audit** | "Run `pnpm audit --json`. Group by severity. For each high/critical, propose a remediation." |

## Next

→ [🦾 Skills](skills.md) — when a prompt file is too small to hold the workflow.
