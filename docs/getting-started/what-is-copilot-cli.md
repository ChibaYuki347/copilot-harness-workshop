# What is Copilot CLI?

GitHub Copilot CLI is an **agentic command-line interface** that brings Copilot —
the same one you know from GitHub.com and your IDE — into your terminal. It runs the
same harness as the GitHub Copilot coding agent that creates pull requests on the web.

```
$ copilot
```

That's the entire UX. From there you converse in natural language, point at files
with `@`, reference issues and PRs with `#`, and shell out with `!`.

## What it can do

The CLI is a fully agentic loop: it reads files, runs commands (with your approval),
edits code, talks to GitHub.com, and iterates until the task you described is done.

| Capability | Example |
|---|---|
| Edit code in place | "Fix the off-by-one bug in `@src/pagination.ts`" |
| Run shell commands | "Run the tests and tell me what's failing" |
| Operate on GitHub | "Summarize the open issues labeled `bug`" |
| Plan before coding | `Shift+Tab` to enter **plan mode** |
| Background work | `/delegate` hands the task to Copilot in the cloud |

## How it relates to Copilot in your IDE

| | IDE Copilot | Copilot CLI |
|---|---|---|
| Surface | Editor, completions, Chat | Terminal, agentic loop |
| Tool use | Limited to editor APIs | Shell, MCP, Skills, Hooks |
| Authentication | IDE plugin login | Same GitHub account / PAT |
| Customization | `.github/copilot-instructions.md` | Same + Skills + Hooks + MCP |

**All the customization files you put under `.github/` work for both**, which is part
of what makes the harness valuable: customize once, benefit everywhere.

## Key concepts you'll see throughout this site

- **Session.** One run of `copilot` is a *session*. Hooks fire at session boundaries.
- **Turn.** Within a session, every prompt → response pair is a *turn*.
- **Tool.** Anything the agent can invoke: shell commands, MCP tools, built-in tools.
- **Skill.** A bundled, callable procedure with its own instructions and assets.
- **Hook.** A script (or HTTP endpoint) that fires on a lifecycle event.
- **MCP server.** A long-running process exposing tools via the Model Context Protocol.
- **Custom agent / sub-agent.** A scoped, delegated worker spawned by the main agent.

## When to use the CLI vs other Copilot surfaces

!!! tip "Rule of thumb"
    Use the **IDE** for inline suggestions and quick edits.
    Use the **CLI** for multi-file changes, repo-wide refactors, build/test loops,
    and anything that benefits from running shell commands.
    Use the **cloud coding agent** (`/delegate`) when you want a PR opened
    asynchronously while you do something else.

## Next

→ [Install the CLI](installation.md)
→ Or jump straight to [first session](first-session.md) if you already have it installed.
