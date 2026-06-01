---
applyTo:
  - "docs/**/*.md"
  - "examples/**/README.md"
---

# Markdown conventions for this site

These rules apply to **every Markdown file under `docs/`** plus every
`examples/**/README.md`. They are a **live demo** of the *path-specific
instructions* customization — see
[Custom Instructions → path-specific](../../docs/customizations/custom-instructions.md)
for the concept.

## Voice and structure

- Use second person ("you") and present tense.
- Lead each page with one sentence that answers "what is this page for?"
- Use H2 (`##`) for top-level sections; reserve H1 (`#`) for the page title.

## Admonitions — use them intentionally

Use `!!! note`, `!!! warning`, `!!! tip`, `!!! abstract`, `!!! example` to
**highlight** information, not to wrap every paragraph. If a paragraph would
read the same with or without the admonition, remove the admonition.

## Code blocks

- Always specify a language: ` ```bash `, ` ```text `, ` ```jsonc `, ` ```yaml `.
- Use `text` for terminal interaction (prompt + output) where syntax highlighting
  would mislead.
- Keep examples runnable. If a placeholder is needed, mark it: `<your-org>` /
  `${YOUR_TOKEN}`.

## Links

- Cross-link **inside** the site with relative paths (`../customizations/hooks.md`).
- Use `https://` absolute URLs only for external resources.
- Prefer canonical sources: `docs.github.com`, `code.visualstudio.com/docs`,
  `github/awesome-copilot`.

## Bilingual pages

- **English is canonical.** Add the `.md` version first; the `.ja.md` counterpart
  may summarise rather than translate word-for-word.
- Every page in the nav that exists in `.md` should have a `.ja.md` peer (the
  i18n plugin falls back to English when missing, but the language switcher
  surfaces the gap).
- When adding a nav entry in `mkdocs.yml`, also translate it under
  `plugins.i18n.languages[ja].nav_translations`.

## Before claiming done

- Run `mkdocs build --strict` — it must be warning-free.
- For any page in `docs/exercises/`, also run a manual `grep -n '^    ```' docs/exercises/<file>.md`
  check: nested fenced blocks inside admonitions need explicit blank lines or
  the renderer drops the syntax highlighting.
