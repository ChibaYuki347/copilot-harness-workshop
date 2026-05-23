# 🧪 Exercises

**Hands-on homework you can do on your own machine after reading the rest of this
site.** Each exercise is small, self-contained, and ends with an *objective* signal
that tells you it worked — not "looks about right".

## How this track is structured

The exercises layer on top of each other. If you do them in order, the artifacts
you build in one exercise can be reused in the next — and the **Capstone** combines
four of them into a single working pipeline.

The track is split into **two**, so you can stop at the right place for your tooling:

### 🟪 Track A — Anyone with Copilot (VS Code *or* CLI)

These exercises produce artifacts that work in **both** the VS Code Copilot
extension and Copilot CLI. Same files, same configuration, both hosts pick them up.

| # | Exercise | Layer | Difficulty | Time |
|---|---|---|---|---|
| 1 | [Custom Instructions](01-custom-instructions.md) | Always-on context | 🟢 Beginner | ~20 min |
| 2 | [Prompt Files](02-prompt-files.md) | Reusable prompt | 🟢 Beginner | ~25 min |
| 4 | [MCP Servers](04-mcp.md) | External tools | 🟡 Intermediate | ~30 min |

!!! tip "MCP setup differs between hosts"
    The MCP exercise targets the **CLI's `.mcp.json`** as the canonical
    config, but Step 2.5 of that exercise shows the equivalent VS Code config
    (`.vscode/mcp.json`) so VS Code users can do it too.

### 🟩 Track B — CLI-primary (also works in VS Code, with caveats)

These exercises use **the same file formats** as Track A — but the lab steps lean
on the **CLI's slash-command UX** (`/agent`, `/skills`, hook logging) and on
features that are GA on CLI but **Preview in VS Code** (hooks). VS Code users can
follow along by translating commands to the Agent Customizations editor and the
GitHub Copilot Chat output channels.

| # | Exercise | Layer | Difficulty | Time | VS Code note |
|---|---|---|---|---|---|
| 3 | [Skills](03-skills.md) | Reusable workflow + scripts | 🟡 Intermediate | ~45 min | Workspace `.github/skills/` works in VS Code too — the lab uses CLI conventions for testing |
| 5 | [Custom Agents](05-agents.md) | Delegated specialist | 🟡 Intermediate | ~30 min | Same `.agent.md` works in both; `/agent` picker is CLI, VS Code uses the agent picker |
| 6 | [Hooks](06-hooks.md) | Lifecycle automation | 🟡 Intermediate | ~30 min | VS Code support is **Preview** + can be disabled by org policy — check before running |
| ✨ | [Capstone — release-notes pipeline](capstone.md) | Composes all | 🟡 Intermediate | ~45 min | Composes Track B layers; the slash-command steps are CLI-flavored |

→ See [VS Code vs Copilot CLI](../reference/vscode-vs-cli.md) for the full
support matrix before you start.

## Before you start

!!! warning "Work in a scratch repo"
    Don't do these exercises in a repo you care about. Spin up a fresh one:

    ```bash
    mkdir ~/copilot-harness-lab && cd "$_"
    git init && git commit --allow-empty -m "init"
    ```

    Every exercise assumes you're in a git repo where you can safely create files.

You'll need:

- **Copilot CLI** installed and authenticated — see
  [Getting Started → Installation](../getting-started/installation.md).
- **`git`** and a recent shell. The hooks exercise uses `bash`; macOS/Linux/WSL all
  work.
- **`gh` CLI** (optional) — only needed for the *stretch goals* on the prompt-files
  and capstone exercises.

## How each page is shaped

Every exercise page follows the same template, so you can skim it the same way
every time:

1. **Learning objectives** — what you'll be able to do at the end.
2. **Time & difficulty** — what you're signing up for.
3. **Prerequisites** — files, accounts, tools.
4. **Checkpoint commit** — `git commit -am "before-exercise"` so you can `git
   reset --hard` if you want to start over.
5. **Scenario** — one paragraph framing the problem.
6. **Steps** — numbered, each with a verifiable outcome.
7. **Definition of done** — an objective checklist (commands, files, exit codes).
8. **Reference solution** — collapsible, prefers snippets from
   [`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples)
   so you can copy-paste real files.
9. **Cleanup** — how to remove what you added.
10. **Troubleshooting** — the two or three failure modes you're most likely to hit.
11. **What not to do** — gotchas that bite later.
12. **Stretch goals** — 1–3 ideas to take it further.

## A note on verification

Most exercises verify with **commands**, not with "does Copilot's reply *seem*
right". Useful built-in checks you'll see repeatedly:

| Command | Tells you |
|---|---|
| `/env` | Which instructions / skills / agents / hooks / MCP servers loaded for this session. |
| `/instructions` | Specifically the instruction files in scope. |
| `/skills` | Loaded skills. |
| `/mcp show` | Connected MCP servers and their tools. |
| `/agent` | The custom-agent picker, showing what's available. |
| `copilot --debug …` | Stream of tool calls, hook firings, MCP traffic. |

If the right file is loaded, it shows up in `/env`. If it doesn't, the problem is
**discovery**, not the model.

## Cleaning up

At the end of every exercise there's a **Cleanup** block. If you stop midway, the
shortest reset is:

```bash
git restore --staged . && git checkout -- . && git clean -fd
```

…inside your scratch repo. That undoes every file the exercise had you create.

---

Ready? Start with **[1 · Custom Instructions](01-custom-instructions.md)**.
