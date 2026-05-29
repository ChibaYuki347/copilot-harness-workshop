# Recipe: Microsoft Foundry Tools MCP

!!! info "Works on: 🟢 Both"
    Foundry Tools exposes Azure AI Foundry capabilities as a **remote MCP server**.
    Both Copilot CLI (`.mcp.json` with `"type": "http"`) and VS Code Copilot Chat
    (`.vscode/mcp.json` with `"servers"`) speak the same protocol and connect to
    the same endpoint. The only differences are the top-level JSON key and the
    env-var syntax — see [MCP → VS Code variant](../customizations/mcp.md#vs-code-equivalent).

**Wire your Copilot session into Azure AI Foundry's Content Understanding,
Document Intelligence, PII masking, translation, and speech tools — without
writing any of the SDK glue.**

## When you'd reach for this

You're already in an agentic session, and you need one of:

- "Pull the structured fields out of this scanned PDF" → Content Understanding
- "Mask PII before I paste this log into a ticket" → PII detection + masking
- "Translate the German specs section into Japanese for the offshore team" →
  Translator
- "Transcribe this voice memo into Markdown" → Speech-to-text

You *could* shell out to `az cognitiveservices …` for each, but then the
agent has to know your subscription, region, key handling, and result shape.
Foundry Tools wraps all of that as MCP tools the agent picks up automatically.

## Why MCP, not bash

| With bash + Azure CLI | With Foundry Tools MCP |
|---|---|
| Agent guesses the right `az` subcommand | Agent gets a typed tool list at session start |
| Auth handled per-call (env vars in shell) | Auth handled once at MCP server start |
| Output parsing is ad-hoc text | Output is structured JSON the model can consume |
| Each call is a `bash` approval prompt | One approval per tool category, then auto-allow |

This is the **MCP value prop in two columns**. Use it as the pitch when
introducing MCP to the team.

## Layers used

- **MCP** (`http` transport — remote endpoint, no local process).
- Optionally: a **Custom Instruction** that tells the agent when to reach for
  Foundry vs. just answering from context.

## Part 1 — Get Foundry credentials

You need an Azure AI Foundry project. The MCP server authenticates using one of:

- **API key** (simplest, single-tenant)
- **Entra ID OAuth** (recommended for org rollout, supports SSO)
- **Managed identity** (when Copilot runs in an Azure VM / Codespace with one)

For a first pass, generate an API key from the Azure AI Foundry portal under
your project's **Keys and Endpoint** blade and stash it:

```bash
# Add to ~/.bashrc / ~/.zshrc / ~/.profile, not committed
export FOUNDRY_ENDPOINT='https://<your-project>.cognitiveservices.azure.com'
export FOUNDRY_API_KEY='<paste-here>'
```

## Part 2 — Copilot CLI: `.mcp.json`

Workspace-scope: drop this into the repo at `.mcp.json` (or
`.github/mcp.json`):

```json
{
  "mcpServers": {
    "foundry-tools": {
      "type": "http",
      "url": "https://foundry-tools-mcp.azurewebsites.net/mcp",
      "headers": {
        "x-foundry-endpoint": "${FOUNDRY_ENDPOINT}",
        "Authorization": "Bearer ${FOUNDRY_API_KEY}"
      }
    }
  }
}
```

> The exact public URL of the Foundry Tools remote MCP server is in the
> [Foundry MCP catalog entry](https://learn.microsoft.com/azure/ai-foundry/concepts/mcp).
> Substitute the value from the portal — it changes per cloud region.

Verify it loaded:

```text
/mcp show
```

You should see `foundry-tools` listed with its tool count (5–15 depending on
which Foundry features your project has enabled).

## Part 3 — VS Code: `.vscode/mcp.json`

Same server, slightly different shape:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "foundry-tools": {
      "type": "http",
      "url": "https://foundry-tools-mcp.azurewebsites.net/mcp",
      "headers": {
        "x-foundry-endpoint": "${env:FOUNDRY_ENDPOINT}",
        "Authorization": "Bearer ${env:FOUNDRY_API_KEY}"
      }
    }
  }
}
```

Note the env-var syntax: `${env:VAR}` (VS Code) vs. `${VAR}` (CLI).

Verify in VS Code: open Chat panel → tools dropdown → confirm `foundry-tools/*`
tools appear.

For mixed teams during a rollout, commit **both** files. (A 10-line
`scripts/sync-mcp.mjs` that translates one into the other keeps drift away.)

## Part 4 — Try it

Restart your Copilot session. Then:

=== "Content Understanding"

    ```text
    Use the foundry-tools content-understanding tool to extract structured
    fields from ./samples/invoice-2026-04.pdf. I want vendor, total, line items.
    ```

    The agent should call `foundry-tools/content_understanding_analyze` (or
    similar — the exact tool name comes from `/mcp show`), pass the file URL or
    bytes, and return a JSON object you can paste straight into a table.

=== "PII masking"

    ```text
    I want to share this log snippet in a Slack thread. Use foundry-tools to
    mask any PII first, then show me the masked version. Don't include the
    original in your reply.

    ---
    [paste log here]
    ```

    The agent calls `foundry-tools/pii_detect` then `pii_mask`, returns only
    the masked output. Useful as a habit before pasting customer data anywhere.

=== "Translation"

    ```text
    Translate sections "Build" and "Test" of README.md into Japanese using
    foundry-tools translator. Put the result in README.ja.md.
    ```

    Cleaner than shelling out — the agent reads the file, calls the tool,
    writes the result, all in one approval per tool category.

## Approval pattern

The first call to each Foundry tool prompts:

```text
Copilot wants to call:

    foundry-tools/pii_detect
    input: { text: "..." }

[a]llow once  [A]lways allow this tool  [d]eny  [q]uit
```

Recommendation:

- **`A`llow always** for read-only tools (translation, PII *detection*,
  language *identification*).
- **`a`llow once** for tools that send data to a service for the first time
  on a given input (PII *masking* — confirm the data is OK to ship).
- Connect via a [vetted](../governance/mcp-vetting.md) endpoint only.

## Optional — A Custom Instruction that nudges the agent

Add to `.github/copilot-instructions.md`:

```markdown
## Foundry Tools MCP usage

When asked to **extract structured fields from a document**, **mask PII**, or
**translate**, prefer calling the `foundry-tools/*` tools over writing custom
parsers or guessing. If `foundry-tools` is not loaded (e.g., session started
outside this workspace), say so and stop instead of falling back to your own
parsing.
```

Two effects:

1. The agent reaches for the right tool without prompting.
2. The agent fails *loudly* when running in a workspace where Foundry isn't
   configured — no silent low-quality fallback.

## Cost & quota

Foundry Tools calls bill against your Azure AI Foundry project. To keep
visibility:

- Set a Foundry quota / budget alert in the Azure portal.
- Add a [`postToolUse` audit hook](../governance/auditing.md#hook-based-audit-log)
  filtered on `foundry-tools/*` — counts calls per session.

For workshops, give attendees a low-cap throwaway key (or a sandbox project
with a daily quota of a few dollars).

## Bridging from an Azure AI Foundry walkthrough

If your team has done a hands-on Azure AI Foundry walkthrough recently,
this recipe is the "now use it from Copilot" sequel. The Foundry capabilities
typically demoed (Content Understanding, PII, translator) are the same APIs
— Copilot just gets typed access to them via MCP, instead of you running
curl examples.

## Variations

- **Lock to a specific Foundry deployment.** Add `x-foundry-deployment:
  <name>` to the headers if your project has multiple deployments.
- **Run behind a private endpoint.** Replace the public URL with your private
  endpoint FQDN. Authentication via managed identity removes the API key.
- **Pair with the GitHub MCP server.** Agent reads a GitHub issue with a PDF
  attachment, hands the PDF to Foundry Content Understanding, posts the
  extracted fields back as a comment — all in one turn.

## See also

- [Customizations → MCP](../customizations/mcp.md) — full schema reference.
- [Recipe → GitHub MCP server](github-mcp-server.md) — composes well with this one.
- [Governance → MCP vetting](../governance/mcp-vetting.md) — checklist before
  connecting any new MCP server.
- [Governance → Auditing](../governance/auditing.md) — log Foundry calls for
  cost / data-residency visibility.
- [Azure AI Foundry docs → MCP](https://learn.microsoft.com/azure/ai-foundry/concepts/mcp)
  (canonical endpoint + tool list).
