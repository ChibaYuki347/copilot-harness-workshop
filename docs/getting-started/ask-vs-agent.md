# Ask mode vs Agent mode

Most people who have used Copilot have only used **Ask mode** — the chat sidebar
that answers questions and proposes diffs. **Agent mode** is the second mode,
where Copilot takes actions on your behalf: edits files, runs commands,
calls tools, makes decisions inside a single user turn.

If you've used Copilot Chat to answer "how do I X?" you've used Ask mode.
If you've never watched Copilot edit your repo and run `npm test` on its own,
you haven't really used Agent mode yet.

This page is the bridge.

## Side by side

| | **Ask mode** | **Agent mode** |
|---|---|---|
| Where it lives | VS Code Chat panel (default), Copilot Chat web, GitHub.com mobile | Copilot CLI, VS Code Chat agent (Preview), GitHub.com Copilot Workspace |
| What it does | Answers, generates code, proposes diffs | Reads files, edits files, runs `bash`, calls MCP tools, retries on failure |
| Who decides each step | You — you copy the suggestion or click "Apply" | Copilot, with you approving each tool call |
| How many turns per task | Often many ("ask, copy, paste, ask again") | Often one ("here's the goal", agent loops until done) |
| Mental model | Pair-programmer over your shoulder | Junior teammate at the keyboard |
| Failure mode | Stale context, wrong suggestion | Wrong action taken with confidence |

## When to use which

- **Ask mode**: small, well-scoped questions; explaining unfamiliar code; quick
  refactors you'll review by eye; anything where you don't want side-effects.
- **Agent mode**: multi-step tasks ("add a `/healthz` endpoint, wire it through
  the router, add a test, run the test suite"); refactors that touch many
  files; spike work where you'd rather iterate than spec.

A good rule: start in Ask, switch to Agent the moment the answer involves
"now go do that in 5 files."

## Starting Agent mode

### Copilot CLI

```bash
cd ~/work/my-project
copilot
```

The default mode is agent-like — type a goal, and the agent will start
reading files and proposing actions. You'll be asked to approve each tool call
unless you've configured allow-lists.

### VS Code Chat (Preview)

1. Open the Chat view (View → Chat or `Ctrl/Cmd + Alt + I`).
2. In the dropdown at the bottom, switch from **Ask** to **Agent**.
3. The chat input gains a "tools" picker — that's the tools the agent can use.
4. Send your prompt; tool calls appear inline with `Approve` / `Deny` buttons.

If you don't see "Agent" in the dropdown, your Copilot Chat extension is
older than the agent rollout — update and reload the window.

## What "approval" looks like

In Agent mode, the agent's first instinct on a new prompt is to gather
context. That means tool calls — and you'll see prompts like:

**CLI**:

```text
Copilot wants to run:

    bash: npm test

[a]llow once  [A]lways allow  [d]eny  [q]uit
```

**VS Code**:

The chat panel pauses, shows the tool name, the exact arguments (file path,
shell command, MCP tool input), and gives you `Approve` / `Deny`. The
"Approve" button has a dropdown for "Approve and don't ask again for this tool."

Two things to remember the first time:

1. **The arguments are shown in full.** The agent is asking permission for a
   specific command, not a category. If the command looks wrong, deny.
2. **"Always allow" applies for the rest of the session** (and possibly
   future sessions if you choose "for this workspace"). Use it for things you
   want the agent to do repeatedly without friction (`npm test`, `pytest`),
   not for `bash`-as-a-category.

## Reading the screen — CLI

When the agent is thinking, you see:

- A streaming response (the model's words).
- "Tool call" blocks that show the tool name and a summary.
- Sometimes nested tool calls (the agent ran something, read the output, decided
  to run something else).
- A final answer or "I've changed these files: …" summary.

Keys to know:

- `Ctrl+C` once — interrupt this turn (the agent stops, you can revise your
  prompt).
- `Ctrl+C` twice — exit.
- `Shift+Tab` — cycle modes (Plan / Edit / Default).
- `/help` — see slash commands.
- `/usage` — see token + cost spend.

## Reading the screen — VS Code

When the agent is working, you see:

- The chat bubble streaming.
- Tool call cards (collapsed by default — click to see full input).
- File diffs that appear in your editor with the standard accept/reject ribbon.
- Status indicator at the bottom of the chat panel: "Working…" / "Waiting for
  approval" / "Done."

If the bottom says "Waiting for approval" and you don't see a button, the
approval prompt is in a different tool call card higher up — scroll back.

## Same skills, different host

The customizations you'll learn next — Instructions, Skills, Hooks, MCP —
work in both hosts. Pick the one you already use day-to-day for the live
session. You can switch later without losing your customization files.

## See also

- [Workshop prep](./workshop-prep.md) — install both hosts for the live session.
- [First session](./first-session.md) — walk through a real Agent session step by step.
- [Reference → VS Code vs Copilot CLI](../reference/vscode-vs-cli.md) — which features work where.
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — what to allow vs deny.
