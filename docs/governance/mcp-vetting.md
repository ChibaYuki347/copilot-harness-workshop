# Vetting an MCP server before you connect it

When you add a new entry to `.mcp.json` (CLI) or `.vscode/mcp.json` (VS Code),
you are extending the agent's tool surface. Once connected, the agent can call
those tools the same way it calls `bash`. If the server is malicious or buggy,
the blast radius is identical to whatever those tools can do.

This page is the checklist to run before that first connection.

## When to use this checklist

- New third-party MCP server you found in a registry / blog post / `awesome-*` list.
- Internal MCP server from another team, before adopting org-wide.
- Existing MCP server, before you upgrade across a major version.
- Before a regulated workload (PII, financial data, production secrets) gets
  near it.

You don't need to run this on first-party servers maintained by the same team
that maintains your repo, but you should still know the answers to most of the
questions.

## The five questions

### 1. What does it do, and does it write?

- What tools does the server expose? (`list_tools` in the MCP inspector, or
  `/mcp` in the CLI after connecting in a scratch sandbox.)
- For each tool: read-only, write-local, write-remote?
- If write-remote: to *which* system, with *whose* credentials, on *whose* behalf?
- Is there a tool that can delete or overwrite data without confirmation?

Pattern: prefer read-only servers for first contact. If the server bundles read
and write capabilities, see if there's a `--read-only` mode or if you can
restrict via `--allow-tool` / `--deny-tool`.

### 2. Where does it send data?

- Does the server keep all calls local, or proxy to a SaaS?
- If SaaS: what's the privacy policy, retention period, training opt-out?
- Does it phone home for telemetry on launch? (`strace -f -e trace=connect` is
  your friend for a 5-minute audit.)
- Does it embed model calls that hit a separate vendor (e.g., an "AI
  summarizer" tool that secretly calls OpenAI)?

Pattern: assume any input you pass becomes a server-side log entry unless
proven otherwise. Don't feed it secrets or PII on first try.

### 3. How does it authenticate?

- API key in environment, OAuth flow, mTLS, anonymous?
- Where is the credential stored after the OAuth dance? File? Keychain?
- Can you scope the credential narrowly? (e.g., a fine-grained GitHub PAT
  rather than a `repo`-scoped classic PAT)
- Does the credential expire? Can it be rotated?

Pattern: prefer narrow, expiring credentials. If the server only works with
broad credentials, that's a yellow flag.

### 4. What's its supply chain?

- Where do you install it from? (`npm`, `pip`, `cargo`, `uvx`, `npx` from a
  registry, or directly from a GitHub repo via `git+`.)
- Who publishes it? Is the publisher reputable, the repo well-maintained, the
  last commit recent?
- Does it pin its own dependencies, or pull `latest` at install time?
- Is the maintainer the same entity as the underlying service (e.g., a GitHub
  MCP server published by `github/`) or a third party wrapper?

Pattern: `npx @some-random-user/cool-mcp` is an unaudited code execution from
that author on every launch. Pin a version. Prefer first-party where it exists.

### 5. What does your org policy say?

- Enterprise Copilot policy can disable MCP entirely or restrict to an
  allow-list. Check `/usage` or the GitHub Copilot enterprise admin page.
- Internal data classification: does the server's destination satisfy the
  classification of the data you'll send to it?
- Procurement / vendor onboarding: is this server already approved? If not,
  what's the lightweight path?

Pattern: when in doubt, ask Security before connecting. The cost of asking is
much lower than the cost of an exfiltration incident.

## 5-minute first-contact procedure

For a server that passes the questions above:

1. **Sandbox.** Start a fresh scratch directory, `--network=none` if you can.
2. **Minimal config.** Add only this server to `.mcp.json`. Set credentials to
   a throwaway / read-only token.
3. **Tool listing.** Start `copilot`, run `/mcp` (or VS Code `Chat: List MCP
   tools`). Check the list matches the docs.
4. **Probe.** Ask the agent to call one read-only tool with non-sensitive input.
   Verify the response shape and that no extra outbound calls happened
   (`audit.log` + `netstat`).
5. **Stress one write path.** With a clearly throwaway target (a scratch repo,
   a dummy record), try one write tool. Confirm the write happened where you
   expected and only there.
6. **Decide.** Either promote the config to your real `.mcp.json`, or remove
   it.

## Per-server lockdown

Once the server is in, you can still restrict it:

```bash
copilot \
  --allow-tool 'github(get_issue:*)' \
  --allow-tool 'github(search_code:*)' \
  --deny-tool 'github(delete_repository)'
```

For VS Code, equivalent settings live under `chat.tools.autoApprove` and the
MCP server's own settings panel.

## Quick rubric

A green-light server typically has all of:

- First-party or well-known maintainer.
- Pinned-version install (`@1.2.3`, not `latest`).
- Read-only default; write tools opt-in.
- Narrow credentials (fine-grained PAT, scoped API key).
- Local-only, or SaaS with a clear privacy policy and opt-out.

A red-flag server typically has any of:

- `npx` from a personal account you don't know.
- Asks for broad credentials (`admin:org`, full AWS credentials, root API key).
- No documentation of what data it sends, where.
- Bundles tools far beyond its stated purpose.
- Publishes only minified or obfuscated code.

## See also

- [Customizations → MCP](../customizations/mcp.md)
- [Risk mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [Recipe → Foundry Tools MCP](../recipes/foundry-tools-mcp.md)
- [Recipe → GitHub MCP server](../recipes/github-mcp-server.md)
