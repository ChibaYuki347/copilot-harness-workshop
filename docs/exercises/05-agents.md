# 5 · Custom Agents

🟡 **Intermediate · ~30 min**

🟩 **Track B — CLI-primary** (same `.agent.md` works in VS Code, but the lab uses `/agent` slash commands · [details](../reference/vscode-vs-cli.md))

## Learning objectives

By the end of this exercise you can:

- Author a custom agent file (`.agent.md`) with a focused system prompt.
- Restrict that agent's toolset so it's truly **read-only**.
- Invoke it via `/agent` and via natural language.
- Confirm the sub-agent's tool restrictions were enforced.

## Prerequisites

- A scratch git repo with at least one commit on `main` and one change on a
  feature branch (we need a diff for the agent to review).
- ~30 minutes.

!!! warning "Check your organization's custom-agents policy"
    Copilot Enterprise / Business administrators can disable custom agents.
    Run `/agent` after Step 3 — if the picker is empty or you see *"custom
    agents are not enabled for this enterprise"*, check the admin
    [Copilot policy settings](https://docs.github.com/copilot/managing-copilot/managing-policies-and-features-for-your-enterprise/managing-policies-for-github-copilot-in-your-enterprise)
    before continuing.

## Checkpoint commit

```bash
git checkout -b feature/auth
echo "function login(user, pw) { return user.password === pw; }" > auth.js
git add auth.js
git commit -m "feat: add login"
```

## Scenario

You want a dedicated **security reviewer** sub-agent — one that has a tightly
focused prompt ("look for secrets, injection, broken auth"), can only **read**
files (never edit), and reports findings in a structured Markdown table. The
main agent delegates to it whenever you ask for a security pass.

## Steps

### 1. Create the agents folder

```bash
mkdir -p .github/agents
```

### 2. Write `.github/agents/security-reviewer.agent.md`

Use **`.agent.md`** as the suffix (this is the canonical form — plain `.md` is
also tolerated but `.agent.md` is what the docs and ecosystem standardize on):

```markdown
---
name: security-reviewer
description: |
  Reviews a diff for security issues — credential leaks, injection, broken
  auth, insecure crypto. Read-only; never edits files. Trigger when the user
  asks for a security review, a security pass, or a pre-merge security check.
  Do not trigger for general code reviews.
tools: ["read", "search"]
---

# Security Reviewer

You are a focused security reviewer. Output a **structured report**, not a chat.
You never edit files.

## Workflow

1. Run `git diff origin/main...HEAD` (or the base the user specified).
2. For every hunk, check:
   - Hardcoded secrets, tokens, keys.
   - Auth checks added or *removed* on endpoints.
   - SQL / shell / template injection via string interpolation.
   - Insecure crypto: weak algos, hardcoded keys, missing IVs.
3. Cross-reference `SECURITY.md` if present.

## Output

A Markdown table sorted by severity desc:

| Severity | File:line | What | Why | Fix sketch |
|---|---|---|---|---|

Then a one-line verdict:

- **Critical** present → `BLOCK`
- **High** present, no Critical → `REVIEW`
- Otherwise → `OK`

If there are no issues, say so explicitly. Don't pad.

## Rules

- Cite **file:line** for every finding. Never invent locations.
- Smallest correct fix only — no large refactors.
- Don't propose disabling a security control to silence a finding.
```

The key line is **`tools: ["read", "search"]`** — this restricts the agent to
read-only tools. No `edit`, no `execute`, no shell.

**Verifiable outcome**: `cat .github/agents/security-reviewer.agent.md | head`
prints the frontmatter.

### 3. Confirm the agent registers

```bash
copilot
```

In the session:

```text
/env
```

The output should include a `Custom agents` section listing
`security-reviewer`. You can also browse with:

```text
/agent
```

…which opens the picker.

### 4. Invoke the agent

Pick the agent through the picker, or use natural language:

```text
Run the security-reviewer agent on the current diff against origin/main.
```

The main agent should hand off to `security-reviewer`, which then produces a
table-shaped report. The sample `auth.js` you committed in the checkpoint
should fire at least one finding (the plaintext password comparison and the
missing input validation).

### 5. Confirm the tool restriction

While the sub-agent is running, watch for any **edit** attempts. There shouldn't
be any. If you want hard evidence, run the session with `--debug` and grep:

```bash
copilot --debug 2>&1 | tee /tmp/copilot.log
# … run the prompt above …
grep -E 'agent=security-reviewer.*tool=(edit|write|execute)' /tmp/copilot.log
# should print nothing
```

## Definition of done { #definition-of-done }

All four must be true:

- [ ] `.github/agents/security-reviewer.agent.md` exists with `tools: ["read",
      "search"]` in frontmatter.
- [ ] `/env` lists `security-reviewer` under custom agents.
- [ ] Asking for a security review delegates to `security-reviewer` (you can
      see the hand-off in the agent's reply or in `--debug` output).
- [ ] After the agent finishes, **no files in the working tree have been
      modified** (`git status` shows no edits beyond what you made yourself).

## Reference solution { #reference-solution }

??? success "Show reference solution"
    A more polished version with explicit out-of-scope rules and a typed
    severity legend:

    ```markdown
    --8<-- "examples/agents/security-reviewer.agent.md"
    ```

    For the full reference on agent frontmatter (`tools`, `model`, `skills`,
    `mcp-servers`, `target`) and on the `.agent.md` vs `.md` distinction, see
    [Customizations → Custom Agents](../customizations/agents.md).

## Cleanup

```bash
rm -rf .github/agents
git checkout main && git branch -D feature/auth
rm -f auth.js
```

## Troubleshooting

- **`/env` doesn't list the agent.** Filename must be exactly
  `<name>.agent.md` (or `<name>.md`) inside `.github/agents/`. The agent
  identifier is the filename minus the suffix.
- **The agent edits files anyway.** Check the frontmatter — if you left
  `tools` out entirely, the agent inherits *all* tools. The exercise depends on
  the explicit `tools: ["read", "search"]` list.
- **The main agent answers itself instead of delegating.** Strengthen the
  `description` ("**Always** use this agent for security reviews"), or
  request the agent explicitly: `Use the security-reviewer agent to …`.

## What not to do

- Don't list `"*"` (or omit `tools`) on an agent you've named "read-only" — it
  defeats the entire safety story.
- Don't write a `description` that triggers on every message ("Use this for any
  code question"). The main agent will hand off too eagerly and you'll lose
  the main thread.
- Don't put project-specific secrets or hostnames in the agent prompt — agents
  are committed and visible to anyone with repo access.

## Stretch goals

1. **Add an MCP restriction.** If you did the [MCP exercise](04-mcp.md), add
   `mcp-servers: []` to the agent frontmatter so this sub-agent can't reach the
   `notes-fs` server. Re-run the agent and confirm it can't list `notes/`.
2. **Pair it with a Skill.** Add `skills: [secrets-scanner]` to the frontmatter
   (and create a tiny `secrets-scanner` skill in `.github/skills/`). The skill
   loads into the agent's context at startup. Confirm with `/env`.
