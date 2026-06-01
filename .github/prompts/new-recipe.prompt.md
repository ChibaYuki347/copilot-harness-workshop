---
description: "Scaffold a new docs/recipes/<slug>.md page with the conventional structure."
argument-hint: "Short slug for the recipe (e.g., github-issues-mcp)"
---

# /new-recipe

The user will give you a short slug (e.g., `github-issues-mcp`). Treat that as
`$ARGUMENT`. If it isn't given, ask for it via `ask_user` before continuing.

This prompt is a **live demo** of the *prompt files* customization — see
[Customizations → Prompt Files](../../docs/customizations/prompt-files.md) for
the concept and full schema.

## Task

1. Verify the slug is kebab-case, lowercase ASCII, and does not collide with an
   existing file under `docs/recipes/`.
2. Create `docs/recipes/$ARGUMENT.md` with the following structure (English
   canonical). Use the same section headings as the existing recipes so the
   page feels consistent:

   ```markdown
   # Recipe: <human-readable title>

   > **What you'll build:** one sentence describing the artifact.

   ## When to use this

   - Bullet list of 2–4 concrete trigger situations.

   ## Prerequisites

   - Copilot CLI ≥ 1.0.x (or VS Code Copilot Chat) authenticated.
   - Any external dependencies (e.g., `gh`, an MCP server binary).

   ## Steps

   ### 1. <imperative step>

   <prose + code block>

   ### 2. <imperative step>

   ...

   ## Verify it works

   <commands the reader can run to confirm the recipe is wired up>

   ## Troubleshooting

   | Symptom | Likely cause | Fix |
   |---|---|---|
   | … | … | … |

   ## See also

   - Cross-link to the relevant `docs/customizations/*.md`.
   - Cross-link to the relevant `examples/*/` sample.
   ```

3. Add the new page to `mkdocs.yml` under the `Recipes:` nav block, in
   alphabetical order by slug.
4. Add the page's English title to `plugins.i18n.languages[ja].nav_translations`
   with a working Japanese translation (use the same prefix convention as
   existing entries: `"Recipe: <title>": "レシピ — <title>"`).
5. **Do not** create a `.ja.md` counterpart automatically — ask the user
   whether they want one. Some recipes ship in English only and rely on the
   i18n fallback.
6. Run `mkdocs build --strict`. Fix any warning before declaring done.

## Constraints

- Don't invent config keys for hooks / skills / MCP. If unsure, search the
  existing examples under `examples/` or the
  [`github/awesome-copilot`](https://github.com/github/awesome-copilot) catalog.
- Don't link to internal-only URLs or named individuals. Public artifact only.
- If the recipe references a runnable artifact, add a stub under
  `examples/<category>/<name>/` with a README — never leave the docs page
  pointing at a non-existent example path.
