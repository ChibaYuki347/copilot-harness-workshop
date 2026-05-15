# Hook: pre-commit-format

Auto-formats files that Copilot CLI wrote via the `edit` or `create` tools.

## Install

```
.github/hooks/pre-commit-format/
├── hooks.json
├── format.sh
└── README.md
```

```bash
chmod +x .github/hooks/pre-commit-format/format.sh
```

Restart your session (or `/hooks reload`) and check `/hooks` lists the hook.

## How it works

- Registered as a `postToolUse` hook with matcher `^(edit|create)$`.
- Reads the tool input JSON from stdin, pulls out the file path, runs the right
  formatter:
  - `prettier` for JS/TS/JSON/Markdown/CSS/HTML.
  - `ruff format && ruff check --fix` for Python.
  - `gofmt` for Go, `rustfmt` for Rust.
- Quiet on success; prints a one-line status to stderr.

## Customize

- **Different formatters.** Edit `format.sh` to call your project's specific tool
  (e.g., `biome` instead of `prettier`, `black` instead of `ruff format`).
- **Skip large files.** Add a size check at the top of `format_one`.
- **Allowlist directories.** Wrap the body with `[[ "$file" == frontend/* ]] || return 0`.

## Caveats

- The formatter runs *after* the tool, so the agent sees the **pre-format** content
  in its working memory. If a follow-up edit fails because line numbers shifted, ask
  the agent to re-read the file.
- `jq` is required to parse the tool input. If you don't have it, replace the parser
  with `python3 -c 'import json,sys; print(json.load(sys.stdin)["toolInput"]["path"])'`.
