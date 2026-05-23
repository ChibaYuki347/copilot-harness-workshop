# 🤖 Custom Agents

**Delegate specialized work to focused sub-agents that the main agent can call.**

!!! abstract "Where it works"
    🟢 **Copilot CLI** · 🟢 **VS Code** — same `.github/agents/<name>.agent.md` file format works in both hosts. The `.agent.md` schema (frontmatter + body) is interoperable across CLI and VS Code per upstream `microsoft/vscode-copilot-chat` design notes. Differences are at the UX level: CLI uses `/agent`; VS Code uses the agent picker in Chat. *Tool reference names* differ slightly (CLI exposes `task`; VS Code uses `agent` and an aliased toolset). See [VS Code vs CLI](../reference/vscode-vs-cli.md).

Copilot CLI ships with a powerful built-in `task` tool that spawns *sub-agents* — each
running in its own context window with its own prompt, tools, and (optionally) model.
You can also define **custom agents** that surface as named, pickable workers.

## When to use a custom agent

- You want a **specialist** the main agent can hand off to — a "security reviewer",
  a "test designer", a "research agent".
- You want the specialist to have a **constrained toolset** (read-only, no shell).
- You want to run **N independent investigations in parallel** without polluting your
  main session's context.
- You want a different **model** for a sub-task (cheap model for grunt work, premium
  model for the synthesis).

## Built-in agents you already have

| Agent | What it's for | Tools |
|---|---|---|
| `explore` | Fast, low-cost codebase exploration with a Haiku-class model | grep/glob/view/shell |
| `task` | Run verbose CLI commands (tests, builds, linters) and summarize | All CLI tools, Haiku |
| `general-purpose` | Complex multi-step tasks needing the full toolset | All CLI tools, Sonnet |
| `rubber-duck` | Independent critique of plans / implementations | Read-only investigation |
| `code-review` | Reviews diffs with a high-signal-to-noise filter | Read-only investigation |
| `research` | Deep research across GitHub + the web | Search / fetch |

These are invoked via the `task` tool — Copilot picks them automatically based on the
work, or you can request one explicitly: *"Use the `rubber-duck` agent to critique my plan."*

## Anatomy of a custom agent

A custom agent is a Markdown file with YAML frontmatter, conventionally named
`<name>.agent.md` (plain `.md` is also accepted for legacy / VS Code-style files):

```markdown
---
name: security-reviewer
description: |
  Reviews a diff for security issues — credential leaks, SSRF, command injection,
  insecure crypto, auth bypass. Read-only; never edits files. Use when the user asks
  for a security review or pre-merge security check.
tools: ["read", "search"]
model: claude-sonnet-4.5
skills: [secrets-scanner, dependency-audit]
---

# Security Reviewer

You are a security reviewer. Your output is a structured report, not a chat.

## Workflow

1. Diff the working branch against `origin/main` (or whatever the user specifies).
2. For each file changed:
   - Check for hardcoded secrets, tokens, keys.
   - Check for input handling without validation.
   - Check for shell-out / SQL / template patterns that could be injected.
   - Check for auth/authz checks added or removed.
3. Cross-reference with the project's `SECURITY.md` if present.

## Report format

For each issue, emit:

- **Severity** (Critical / High / Medium / Low / Info)
- **File:line**
- **What** (one sentence)
- **Why it matters** (one sentence)
- **Fix sketch** (one or two lines of code or a directive)

If you find no issues, say so explicitly. Do not pad.
```

!!! info "`tools` is a list of tool **names / aliases**, not permission patterns"
    Valid values include built-in aliases (`read`, `edit`, `search`, `execute`),
    fully-qualified MCP tool names (e.g. `github-mcp-server/issue_read`), and `*` for
    "everything". You cannot encode permission patterns like `bash(git diff)` here —
    use the agent prompt to constrain behavior and `--allow-tool` / hooks to enforce
    it.[^agent-tools] Omit `tools` entirely to inherit all available tools.

[^agent-tools]: From the GitHub docs: *"`tools` is a list of tool names or aliases,
    including tools from MCP servers configured in the repository settings or the
    agent profile (for example, `tools: [\"read\", \"edit\", \"search\", \"some-mcp-server/tool-1\"]`).
    If you omit this property, the agent will have access to all available tools."*

## Where custom agents live

Custom agents are discovered alongside your other customizations — at every directory
level from cwd up to the git root, plus your personal scope.[^agents-loc]

[^agents-loc]: From the changelog: *"Custom instructions, MCP servers, skills, and
    agents are now discovered at every directory level from the working directory up to
    the git root, enabling full monorepo support."*

| Path | Scope |
|---|---|
| `.github/agents/<name>.agent.md` | Repo (committed). |
| `~/.copilot/agents/<name>.agent.md` | Personal. |
| `agents/<name>.agent.md` in a `.github-private` org/enterprise repo | Organization / enterprise (admin-managed). |

The `.agent.md` suffix is the canonical extension (plain `.md` is also accepted for
legacy / VS Code-style files). The agent identifier is the filename minus the suffix
— `security-reviewer.agent.md` becomes the agent `security-reviewer`.

## Frontmatter reference

| Key | Purpose |
|---|---|
| `name` | Unique identifier; appears in `/agent` picker. Defaults to the filename. |
| `description` | When to invoke (used by the main agent to pick). |
| `tools` | List of tool names / aliases the agent may call. Omit to inherit all. |
| `model` | Override the default model for this agent. |
| `skills` | List of skill names to load eagerly into this agent's context.[^skills-field] |
| `mcp-servers` | Restrict the agent to a subset of configured MCP servers. |
| `target` | **Optional** filter — `vscode` or `github-copilot` (or omitted for both). Omitting it lets the agent surface in both hosts; setting it restricts the agent to one. Same file format works in both hosts by default.[^target-field] |

[^skills-field]: From the changelog: *"Custom agents can now declare a `skills` field to
    eagerly load skill content into agent context at startup."*

[^target-field]: `target` is an **optional filter**, not a host switch. The
    `.agent.md` schema is interoperable between Copilot CLI and VS Code Chat per
    upstream `microsoft/vscode-copilot-chat` design notes — set `target` only
    when you want to *hide* the agent from one host.

## Invoking a custom agent

```text
/agent                      # interactive picker
"Run the security-reviewer agent on the diff."
```

You can also have the main agent compose work *across* agents in a single response —
this is what **fleet mode** is for.

## Fleet mode — parallel sub-agents

```text
/fleet
```

Enables parallel sub-agent execution. With fleet mode on, the main agent can dispatch
N independent investigations at once. Useful when:

- You need to analyze multiple services or modules independently.
- You have a research question with several unrelated threads.
- You want to validate a plan from multiple angles (code reviewer + rubber duck) in parallel.

Monitor running fleets with `/tasks` and `/sidekicks`.

## Pitfalls

!!! warning "Anti-patterns"
    - **Building a one-shot agent for a one-time task.** That's what prompt files are
      for. Reserve agents for recurring specialist roles.
    - **Overly broad tool allowlist.** A "research agent" with `bash(rm)` is just the
      main agent with extra steps.
    - **No clear hand-back contract.** Specify what the agent must return to the main
      agent so its work can be acted on (e.g. *"Return a JSON object with `findings: [...]`"*).

## Composition example

A typical "ship it safely" flow:

1. **Main agent** plans the feature (plan mode).
2. **`rubber-duck`** critiques the plan.
3. Main agent implements.
4. **`code-review`** reviews the diff.
5. **`security-reviewer`** (custom) runs the security pass.
6. Main agent reconciles findings and asks the user to approve.

See the worked version in [Recipes → multi-agent workflow](../recipes/multi-agent-workflow.md).

## Next

→ [Recipes](../recipes/index.md) for end-to-end workflows.
→ [Reference → File layout](../reference/file-layout.md) to see all the customization
files in one map.
