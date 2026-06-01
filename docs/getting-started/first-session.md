# Your first session

A 10-minute tour of the agentic loop, ending with you having actually changed a file.

!!! abstract "Choose your track"
    === "🟦 Already use Ask mode — fast lane"

        You already use **Copilot Ask mode** (chat sidebar). You want to feel
        the difference when Copilot is allowed to **edit files and run commands
        on its own**. Do these in order:

        1. Read the first 2 sections below — **Pick a project** + **Ask Copilot
           to ground itself** — they're the same in both tracks.
        2. **Skip "Step 3 — Plan a change (Plan Mode)" details** and just press
           `Shift+Tab` once to feel what plan mode does, then exit back.
        3. Focus on **Step 4 — Approve the right tools** and **Step 5 — Inspect
           the diff before committing**. This is the actual mental model shift
           from Ask mode.
        4. Then jump to [Ask vs Agent mode](ask-vs-agent.md) for the side-by-side
           reference, and [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md)
           for what to allow vs deny in real work.

    === "🟢 Full newcomer — guided tour"

        New to Copilot agents entirely (or only used Ask mode briefly). Just go
        through every step below in order. Plan on 15–20 minutes. Don't worry
        about getting "the perfect first prompt" — the goal is just to feel the
        agentic loop once: prompt → tool call → approval → result.

        - If anything feels confusing, the [Ask vs Agent mode](ask-vs-agent.md)
          primer gives the mental model in 5 minutes — read it then come back.
        - After this page, the [customizations overview](../customizations/index.md)
          shows how to start shaping Copilot to your team.

---

## Step 1 — Pick a project

Use any repo you don't mind experimenting on. For this tour we'll assume a small
Python/Node/Go project. If you don't have one, `git clone` a public repo you know well.

```bash
cd ~/code/my-project
copilot
```

!!! tip "Want to follow along inside this very repo?"
    `copilot-harness-workshop` itself ships every harness layer wired up —
    Custom Instructions, Skills, Hooks, a Prompt File, an MCP config, and a
    Custom Agent. If you cloned this repo to do the workshop, you can run
    the same 6 steps below in **this** repo and see real wiring activate:
    see [Try this repo as a live demo](try-this-repo.md).

You'll see the splash, the trust prompt, and then an empty input box.

## Step 2 — Ask Copilot to ground itself

Don't dive into changes yet. Get the agent to *understand* the project first:

```text
Take a look at this repo and tell me:
1. What is it for, in one sentence?
2. What's the build/test command?
3. What's the riskiest file or function I should know about before changing things?
```

Copilot will read files (you may be asked to approve), poke around the directory
structure, run `git log`, etc. The output gives you confidence that the agent has a
roughly accurate mental model.

!!! tip "Use `@` for precision"
    If you already know the file, mention it directly: `@src/server.ts` pulls the file
    into the prompt context immediately. This is faster than letting the agent search.

## Step 3 — Plan a change (Plan Mode)

Press **`Shift+Tab`** to cycle into **Plan Mode**. In plan mode Copilot won't write
code — it asks clarifying questions and proposes a structured plan.

```text
Add a /healthz endpoint that returns {"status":"ok"} as JSON. Plan it.
```

Review the plan. Push back if you disagree. When ready, exit plan mode with `Shift+Tab`
again and tell Copilot to implement.

## Step 4 — Approve the right tools

When Copilot wants to run a tool (`bash`, `npm`, `pytest`, …), you get a prompt:

```
Allow npm test?
  1. Yes
  2. Yes, and approve npm for the rest of this session
  3. No, and tell Copilot what to do differently
```

Pick **(2)** for safe, frequently-used tools (`npm`, `pytest`, `git status`). Pick **(1)**
for anything destructive (`rm`, `git push`, `gh pr merge`). Always read the args before
approving — if Copilot proposes `rm -rf node_modules`, that's probably fine; if it
proposes `rm -rf ~/`, **deny** and feed back.

!!! warning "`--allow-all-tools` is a footgun"
    The `-p` / `--prompt` programmatic mode supports `--allow-all-tools`. Use it in CI
    where Copilot has minimal blast radius (containerized, scratch checkout). Never use
    it on your dev machine.

## Step 5 — Verify before accepting

After Copilot finishes, run:

```text
Show me the diff and explain what changed in each hunk.
```

Then run the tests yourself or have Copilot do it:

```text
Run the tests and report failures only.
```

## Step 6 — Wrap up

If you're happy:

```text
Commit the changes with a conventional commit message and push.
```

If you're not:

```text
Revert your changes; let's redo the implementation differently.
```

`/undo` rewinds the previous turn including file edits.

## Cheat sheet from this tour

| Action | How |
|---|---|
| Mention a file | `@path/to/file` |
| Mention an issue / PR | `#123` |
| Run a shell command verbatim | `!ls -la` |
| Switch to plan mode | `Shift+Tab` |
| Cancel the current turn | `Esc` |
| Rewind the previous turn | `/undo` |
| Save context window space | `/compact` |
| Show what's loaded into context | `/env` |

## VS Code Copilot Chat — same loop, different UI { #vscode-agent-mode }

The 6 steps above are written for **Copilot CLI** in a terminal. If you're
doing this tour in **VS Code Copilot Chat** instead, the *concept* is
identical — instructions load, plan mode plans, approval prompts appear,
diffs render, hooks fire — but the surface is different. Here's how to
follow the same loop in VS Code:

| Tour step | What to do in VS Code |
|---|---|
| **Open a session** | Open the workspace, then **View → Chat** (or `Ctrl/Cmd+Alt+I`). |
| **Switch to Agent mode** | In the Chat header, switch the mode dropdown from **Ask** (default) → **Agent**. The first time you do this, VS Code shows a one-time "Agent mode lets Copilot edit files and run commands" notice — read it. |
| **Step 2 (ground itself)** | Same prompt — type it into Chat. Use **`#file:src/server.ts`** instead of `@src/server.ts`. |
| **Step 3 (Plan mode)** | Switch the mode dropdown to **Plan** instead of pressing `Shift+Tab`. Same idea: model proposes a plan without writing code. |
| **Step 4 (approve tools)** | Approval prompts render as **inline buttons** in the Chat panel (Allow once / Allow always / Deny) rather than as a numbered list. Same options, just clickable. |
| **Step 5 (verify diff)** | VS Code opens **a diff editor automatically** for every file the agent edits. You can keep or reject hunks individually. |
| **Step 6 (commit)** | Use the **Source Control** panel (Ctrl/Cmd+Shift+G) — Copilot can author the commit message via the **✨ Generate Commit Message** button. |
| **`/undo`** | Use standard **VS Code Undo** (Ctrl/Cmd+Z) in each modified file. There's no transactional rewind across files; the diff editor lets you reject hunks before they're saved. |

!!! tip "What's different and what isn't"
    The **mental model** is identical — Custom Instructions still load at
    startup, hooks still fire on every tool call, approval still gates risky
    commands. The shape of the UI is different, and a few CLI-only features
    (`/fleet`, `/sidekicks`, `/share` to gist) don't have direct VS Code
    equivalents yet. The [slash commands page](slash-commands.md#vscode-equivalents)
    has the full CLI ↔ VS Code mapping.

→ [Slash commands tour](slash-commands.md)
→ Or skip ahead to [Customizations](../customizations/index.md) and start shaping
the harness.
