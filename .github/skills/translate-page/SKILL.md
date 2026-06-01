---
name: translate-page
description: |
  Use this skill when the user asks to add or update the Japanese counterpart of
  an English docs page. Trigger phrases: "translate <page> to Japanese", "add a
  Japanese version of <page>", "sync the JA page for <page>". Do not trigger for
  general translation requests outside docs/.
license: MIT
---

# Translate Page

You create or refresh the Japanese counterpart of an English docs page,
following the conventions used by `mkdocs-static-i18n` in suffix mode.

This skill is a **live demo** of the *Skills* customization — see
[Customizations → Skills](../../../docs/customizations/skills.md).

## Output Contract

When this skill finishes:

1. A file at the same path as the English source, but with the `.ja.md` suffix,
   exists (or has been updated).
2. If a new nav entry is required, `mkdocs.yml` is updated under
   `plugins.i18n.languages[ja].nav_translations` with a working translation.
3. `mkdocs build --strict` is clean.
4. The final response lists: the file written, whether nav was updated, and
   the build result.

## Workflow

### Phase 1 — Locate

1. Resolve the English source. If the user passes a path like
   `docs/getting-started/first-session.md`, use it. If they pass a friendly name
   like "the slash commands page", search `docs/**/*.md` for a matching H1 and
   confirm with `ask_user` before proceeding.
2. If the `.ja.md` peer already exists, read it. If not, you'll create one.

### Phase 2 — Translate

3. Translate the English page into Japanese. **Summaries are allowed** —
   Japanese pages do not have to mirror every sentence verbatim, but they must
   preserve:
   - All headings (translate the heading text, keep the structure)
   - All code blocks (do NOT translate inside fenced code)
   - All admonition types (`!!! note` stays English; the body translates)
   - All link targets (translate the link text, not the target path)
   - All Mermaid diagrams (translate node labels only, not the syntax)
4. Keep technical terms recognisable: "Custom Instructions" → "カスタムインストラクション",
   "Plan Mode" → "プランモード", "tool call" → "ツール呼び出し". Match terminology with
   existing JA pages (grep `docs/**/*.ja.md` for prior translations of the same
   term and reuse them).

### Phase 3 — Wire

5. If the page is referenced in `mkdocs.yml`'s nav under an English title
   without a JA translation, add a `nav_translations` entry. Use existing
   translations as templates for naming conventions (e.g., recipes prefix
   `"Recipe: …": "レシピ — …"`).

### Phase 4 — Verify

6. Run `mkdocs build --strict`. If it fails, fix the issue (most often a broken
   link or a heading anchor that changed). Repeat until clean.
7. Report the file path, nav update status, and build result.

## Rules

- Don't translate inside fenced code blocks. Comments inside code blocks are
  also kept in English unless the original is already in Japanese.
- Don't translate file paths, command names, env vars, or hook event names.
- Don't add new content that isn't in the English source. If the English page
  is missing something, surface it as a separate finding and let the user
  decide whether to update the English source first.
- Tone: polite-plain (です・ます) matching the surrounding JA pages.
