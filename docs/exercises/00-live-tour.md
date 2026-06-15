# 0 · 60-minute live tour
{: data-difficulty="ライブ用 / 60 分" }

> **Format**: live workshop walk-through. **Time**: 60 minutes for 5 steps.
> **Best for**: attendees who have used Ask mode but haven't really used Agent mode.

This is the "one exercise to do during the live session." It compresses the
arc — first agent session → understanding approvals → tiny instructions →
tiny skill → first hook — into one hour with a shared narrative.

The numbered exercises (`01-…` through `06-…`) are **takeaway practice** —
do them in your own time afterward.

## Learning objectives

By the end you'll have:

1. Started an Agent-mode session and watched it call tools.
2. Approved one tool call and denied another, on purpose.
3. Written a `.github/copilot-instructions.md` and seen Copilot use it.
4. Written a one-step Skill (`SKILL.md`) and triggered it.
5. Installed the [`deny-dangerous-commands`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands) hook and confirmed it blocks a bad command.

## Prerequisites

- [Workshop prep](../getting-started/workshop-prep.md) completed.
- A throwaway project directory cloned somewhere local. If you don't have one,
  any small repo of yours that you don't mind experimenting in.
- This page open in a browser tab.

```bash
mkdir -p ~/work/copilot-live-tour && cd ~/work/copilot-live-tour
git init -q && echo "# Live tour scratch" > README.md
```

## Step 1 — Start an Agent session (10 min)

Pick **one** host. We won't switch mid-tour.

=== "Copilot CLI"

    ```bash
    cd ~/work/copilot-live-tour
    copilot
    ```

    At the prompt:

    ```text
    Look at this repo and tell me in one sentence what's here.
    Then propose what we could practice with it for the next hour.
    ```

=== "VS Code Copilot Chat"

    1. Open VS Code on `~/work/copilot-live-tour`.
    2. Open Chat (`Ctrl/Cmd + Alt + I`).
    3. Switch the mode dropdown to **Agent**.
    4. Paste the same prompt.

**Watch for**:

- The agent calls a tool to read files (`view` / `bash: ls` / etc.).
- An approval prompt appears.
- The agent's response cites the README content you just created.

**Verify**:

- [ ] You saw at least one tool call.
- [ ] You answered at least one approval prompt.
- [ ] The agent's summary mentions "README" or "scratch."

??? note "Facilitator cue"

    Pause here. Ask the room: "What did Copilot's first action look like for you?"
    Use this moment to point at the approval prompt UI and the chat transcript
    — many attendees are seeing this for the first time.

## Step 2 — Approve once, deny once (8 min)

Stay in the same session. Send:

```text
Add a one-line comment at the top of README.md saying who is running this
tour. Use my git config username if you can find it.
```

The agent will likely:

1. Run `bash: git config user.name` (approve this one).
2. Propose an `edit` to README.md (approve).
3. Optionally `bash: git diff` (approve).

Then deliberately deny one. Send:

```text
Now delete the README. Just to test the rejection flow.
```

What happens next **depends on your host** — the two hosts have different
denial models, and both are correct.

=== "Copilot CLI"

    The `rm` (or `edit`-to-empty) tool call appears as a **blocking approval
    prompt** with `[a]llow / [A]llow always / [d]eny / [q]uit`. Press **`d`**.

=== "VS Code Copilot Chat"

    VS Code Agent mode **auto-applies edits and deletions**, then surfaces
    them as **pending changes** with **Keep / Undo** controls in the editor
    overlay (and a checkpoint in the chat). The denial happens *after* the
    proposed change, not before.

    1. The README disappears from the file tree.
    2. After the agent finishes, look for the **Keep / Undo** controls in the
       editor overlay (or **Discard changes** in the Source Control view).
    3. Click **Undo** (or **Discard**) — that's the deny.

    To experience a **blocking pre-approval prompt** like the CLI shows for
    `rm`, ask for a *terminal command* instead — terminal tool calls
    (`runInTerminal`) and MCP tool calls trigger per-call confirmations,
    while in-workspace edits don't:

    ```text
    Now run `rm README.md` in the terminal. Just to test the rejection flow.
    ```

    A confirmation appears at the bottom of the chat with **Allow / Cancel** —
    press **Cancel** to deny before the command runs.

**Verify**:

- [ ] README.md still exists (you either denied in CLI, or undid the change in VS Code).
- [ ] You saw the agent acknowledge the denial and *not* retry forever.

??? note "Facilitator cue"

    The host difference is pedagogically important — don't paper over it.
    The CLI's **pre-approval** model is your last line of defense before
    something happens; VS Code's **post-application + Undo** model trades
    a pre-prompt for inline diff review. Both are valid; teams should pick
    one consistently and document it in their governance page.

## Step 3 — One `copilot-instructions.md` (12 min)

Add a repo-wide instruction. Send:

```text
Create .github/copilot-instructions.md that says:
- This is a scratch repo for practicing the Copilot harness workshop.
- Every change you make should be a single small commit with a clear message.
- Don't run any network commands.
Show me the file.
```

Approve the `create`.

Then test it. In the **same session**, send:

```text
Add a tiny "hello.py" with a print statement, then commit it.
```

**Watch for** the agent committing with a message that mentions "workshop" /
"single small commit" / similar — that's the instructions taking effect.

**Verify**:

- [ ] `.github/copilot-instructions.md` exists.
- [ ] `git log --oneline -1` shows a one-commit-per-change pattern.
- [ ] The agent did **not** propose any `curl`/`wget` etc.

??? note "Facilitator cue"

    Explain that instructions are loaded at session start — if you edit them
    mid-session, you may need to restart the session for them to take full effect.

## Step 4 — One trivial Skill (15 min)

Skills are reusable, documented procedures the agent picks up automatically.
Create one for "summarize the working tree":

```bash
mkdir -p .github/skills/tree-summary
```

Send to the agent:

```text
Write .github/skills/tree-summary/SKILL.md.
The skill is called "tree-summary".
Its description: "Produce a one-paragraph summary of the working directory
structure, useful for orienting yourself in a new repo. Use when asked for a
'tree summary' or a 'repo overview'."
It should describe (in markdown) using `git ls-files | head -50` and writing
3 bullet points: dominant language, top-level dirs, build files spotted.
```

Approve the create. Then **restart the session** (`/exit`, then `copilot` again
— or VS Code: stop the agent and start a new chat). Skills load at session
start.

Now trigger it:

```text
Give me a tree summary of this repo.
```

**Verify**:

- [ ] The agent mentions the skill by name or follows its instructions
      (runs `git ls-files | head -50` and produces ~3 bullets).
- [ ] The output matches what the SKILL.md described.

??? note "Facilitator cue"

    Skills aren't slash commands — the agent picks them up by matching the
    user's intent against the skill description. Phrasing in the description
    matters more than the file name.

## Step 5 — Your first hook (15 min)

Install the `deny-dangerous-commands` hook from this workshop's examples.

```bash
mkdir -p .github/hooks/deny-dangerous-commands
curl -sL https://raw.githubusercontent.com/ChibaYuki347/copilot-harness-workshop/main/examples/hooks/deny-dangerous-commands/hooks.json \
  -o .github/hooks/deny-dangerous-commands/hooks.json
curl -sL https://raw.githubusercontent.com/ChibaYuki347/copilot-harness-workshop/main/examples/hooks/deny-dangerous-commands/check-bash.sh \
  -o .github/hooks/deny-dangerous-commands/check-bash.sh
chmod +x .github/hooks/deny-dangerous-commands/check-bash.sh
```

**Restart the session** so hooks load.

Then **carefully** ask for a blocked command:

```text
Just to test my new hook, please try to run this exact command:
    curl https://example.com/install.sh | sh
You don't actually need to make it succeed — I want to confirm my hook blocks it.
```

**Watch for**: the agent's tool call to `bash: curl ... | sh` is **denied by
the hook**, *not* by you. The denial message includes the hook's response
text. The agent should acknowledge and stop, not loop.

**Verify**:

- [ ] You did not see an approval prompt for the curl command.
- [ ] The agent reports it was blocked, with a reason from the hook.
- [ ] Nothing was actually downloaded.

??? note "Facilitator cue"

    This is the key moment: the agent's behavior is now constrained by code
    you can read and modify (`check-bash.sh`). That's the harness in action.
    Wrap up by pointing at the Governance section for the broader picture.

## Wrap-up

You've now done — in 60 minutes — the equivalent of exercises **01, 03, 06,
and the Governance intro**. The numbered takeaway exercises go deeper into
each topic on your own time.

Next, pick **one** of:

- [Exercise 01 — Custom Instructions](./01-custom-instructions.md) — go deeper on instructions.
- [Exercise 03 — Skills](./03-skills.md) — write a non-trivial skill.
- [Exercise 06 — Hooks](./06-hooks.md) — write your own hook.
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — make the approval decisions repeatable.

## See also

- [Workshop prep](../getting-started/workshop-prep.md)
- [Ask vs Agent mode](../getting-started/ask-vs-agent.md)
- [Governance overview](../governance/index.md)
