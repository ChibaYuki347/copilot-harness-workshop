# Safety & Governance

So far this site has shown you **how to make Copilot do more**. This section is
the opposite: how to **keep it from doing the wrong thing**, especially in
agent mode where the model can edit files, run shell commands, and call MCP
tools that reach the rest of your environment.

!!! warning "Why this section exists"
    In agent mode the question is no longer "did Copilot give me good code?"
    It's "**did I just approve something I shouldn't have?**" The patterns here
    are how the rest of this site's harness — Custom Instructions, Hooks, MCP
    — get used as **guardrails** instead of just productivity boosters.

## Read in this order

| Page | One-liner |
|---|---|
| [Risk mental model](./risk-mental-model.md) | What changed when you went from Ask mode to Agent mode, and which categories of risk you now own. |
| [Approval cheat sheet](./approval-cheatsheet.md) | When to hit `y`, when to hit `n`, and how to configure auto-approval so the obvious things stop interrupting you without losing oversight on the risky ones. |
| [Blast-radius limiting](./blast-radius.md) | Sandboxes, allow-listed shells, deny-list hooks, network restrictions. How to bound what Copilot *can* do in the worst case. |
| [Auditing what happened](./auditing.md) | Hook-based logs, session transcripts, `~/.copilot/audit.log`. How to look back and verify. |
| [MCP server vetting](./mcp-vetting.md) | Checklist before pointing Copilot at a third-party tool server, and what to ask about your own. |

## TL;DR for the impatient

If you only do three things this week:

1. **Install a deny-dangerous-commands hook.** Start with
   [`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands)
   and tune the regex list to your team. See
   [Blast-radius limiting](./blast-radius.md#deny-list-hook).
2. **Install an audit hook.** Even a one-line append to `~/.copilot/audit.log`
   is enough to look back at every tool call later. See
   [Auditing](./auditing.md#hook-based-audit-log).
3. **Decide your team's approval defaults.**
   See the [Approval cheat sheet](./approval-cheatsheet.md#team-defaults) —
   "always ask for `rm`, `sudo`, anything that writes to `main`" is a sensible
   starting point.

!!! tip "The fourth hook to install"
    Once the three above are in place, the next governance hook to add is the
    **session-end secret scan** — it runs `gitleaks` (or your scanner of choice)
    at `stop` so leaked credentials get caught before you walk away from the
    terminal. See [Recipe: session-end secret scan](../recipes/session-end-secret-scan.md).

## A note on hosts

Everything here applies to both **Copilot CLI** and **VS Code Copilot Chat
agent mode**. Hook files (`.github/hooks/*.json`) work in both
([Hooks page](../customizations/hooks.md#vs-code-variant)); approval prompts
exist in both UIs, just look different; MCP server config files differ in
schema but the risk model is identical.

## Why now

This site was originally written for users who already wanted to push Copilot
further. The audience for the **2026-06-02 lecture** is the opposite: most
attendees use Copilot Chat in **Ask mode** every day but have **never invoked
agent mode**. The single most common reason for that is risk uncertainty —
"what if it does something I can't undo?". This section is the answer.
