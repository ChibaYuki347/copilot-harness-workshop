# Copilot Instructions — `copilot-harness-workshop`

This repository is a **MkDocs Material documentation site** that teaches users how to
customize the GitHub Copilot CLI. It is itself a worked example of those customizations.

## Stack at a glance

- **Static site generator:** [MkDocs](https://www.mkdocs.org/) + [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).
- **i18n:** `mkdocs-static-i18n` plugin in **suffix** mode. English (`*.md`) is the default;
  Japanese counterparts use the `*.ja.md` suffix. Missing translations fall back to English.
- **Deployment:** GitHub Actions builds with `mkdocs build --strict` and deploys via
  `actions/deploy-pages`. The published URL is
  `https://chibayuki347.github.io/copilot-harness-workshop/`.

## Conventions

1. **Always run `mkdocs build --strict` locally** before declaring a content change done.
   `--strict` turns warnings (broken links, missing nav entries, unknown anchors) into errors.
2. **Use admonitions intentionally.** Use `!!! note`, `!!! warning`, `!!! tip` to highlight,
   not for plain prose. Don't wrap every paragraph in one.
3. **Code examples must be runnable.** Hooks (`hooks.json`), Skills (`SKILL.md`), MCP configs
   (`.mcp.json`) should follow the [official spec](https://docs.github.com/copilot) and the
   patterns in [`github/awesome-copilot`](https://github.com/github/awesome-copilot).
4. **Don't invent config keys.** If you're unsure whether a key exists in `hooks.json` or
   `.mcp.json`, search the changelog (`github/copilot-cli` repo) or the awesome-copilot
   examples before writing it down.
5. **English is the canonical source.** When adding a Japanese page, create the English page
   first. Japanese pages are summaries / localizations — they don't need to mirror every
   sentence verbatim.

## Project map

```
docs/                  → site source (Markdown). Sections: getting-started, customizations,
                         recipes, case-studies, reference.
examples/              → copy-pasteable sample artifacts referenced from the docs.
mkdocs.yml             → site config (theme, nav, i18n, plugins).
.github/workflows/     → CI: build + deploy to Pages on push to main.
requirements.txt       → pinned MkDocs + plugin versions.
```

## When asked to add a new page

1. Place the English version under the right section directory.
2. Add a nav entry in `mkdocs.yml` so the page appears in the sidebar.
3. If the topic is featured on the home page or top-level customization page,
   add a Japanese counterpart with the `.ja.md` suffix. Translate the `nav_translations`
   entry as well.
4. Run `mkdocs build --strict` and fix every warning.

## When asked to add a new example

- Examples live under `examples/<category>/<name>/` with a `README.md` explaining what it
  does, when to use it, and how to install it.
- Reference the example from at least one docs page (recipe or customization page) so it
  doesn't become orphan content.

## Out of scope

- We don't ship runnable application code beyond the example artifacts.
- We don't write language-specific tutorials (e.g. "Copilot for Rust"); the focus is on
  the harness layer that works regardless of project language.
