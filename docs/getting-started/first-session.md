# Your first session

A 10-minute tour of the agentic loop, ending with you having actually changed a file.

## Step 1 — Pick a project

Use any repo you don't mind experimenting on. For this tour we'll assume a small
Python/Node/Go project. If you don't have one, `git clone` a public repo you know well.

```bash
cd ~/code/my-project
copilot
```

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

→ [Slash commands tour](slash-commands.md)
→ Or skip ahead to [Customizations](../customizations/index.md) and start shaping
the harness.
