# Recipe: Presenting the harness

!!! info "Works on: 🟢 Copilot CLI + VS Code Copilot Chat"
    The presenter ladder is host-neutral. Every "money shot" below lists what
    to type or click in each host. Pick one host before you go on screen — do
    not switch mid-talk.

**A 5 / 15 / 45-minute presenter ladder for showing the Copilot harness to
your team or a meetup audience, using this repo as the live demo.**

## Problem

The rest of this site has two paths in:

- **Learner path** — [Try this repo as a live demo](../getting-started/try-this-repo.md)
  and the [Exercises](../exercises/index.md) track. Both assume *you* are at
  the keyboard.
- **Workshop attendee path** — [Exercise 0: 60-minute live tour](../exercises/00-live-tour.md).
  Assumes someone *else* is at the keyboard for an hour.

There's nothing for the *presenter* — the engineer who has 5 minutes in a team
meeting, or 15 minutes at coffee, or a 45-minute brown bag, and wants the room
to leave with the harness concept (Skills + Hooks + MCP + Instructions + Agents)
*plus* enough pointers to keep going on their own.

This recipe is that script.

## Layers used

- The entire wired demo at the repo root — `.github/{skills,instructions,hooks,prompts,agents}/`, `.mcp.json`.
- The audit hook (`.github/hooks/audit-demo/log.sh`) for live visibility into what the agent is doing.
- The [devcontainer](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md) for zero-install demos on a borrowed laptop.

## Pick your bucket

| Bucket | When it fits | What lands |
|---|---|---|
| **5 min — lightning** | Stand-up, team meeting, hallway demo | "Copilot has a *harness* you can shape — not just a prompt box." Mental model + 1 money shot. |
| **15 min — coffee chat** | Coffee, brown bag intro, quick demo for a curious manager | Lightning + Skills + path-specific instructions + audit log. Audience leaves knowing the *vocabulary*. |
| **45 min — brown bag** | Internal brown bag, meetup talk, lunch & learn | Coffee chat + Hooks + MCP teaser + governance one-liner + handoff to exercises. Audience leaves able to *start*. |

The existing [Exercise 0 — 60-minute live tour](../exercises/00-live-tour.md) is
the 60-minute hands-on track for actual workshops where attendees code along.
Don't run it as a presenter; *facilitate* it.

## Setup once (before any bucket)

Do these in the order listed. They take 3–4 minutes if you've never done it
on this machine, ~30 seconds if you have.

### 1. Open the repo in Codespaces

```text
https://codespaces.new/ChibaYuki347/copilot-harness-workshop
```

The [devcontainer](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md)
preinstalls Python, Node, `gh`, `jq`, the Copilot CLI, and the docs site
dependencies. When `✅ copilot-harness-workshop devcontainer ready.` appears,
you're set. (If your team blocks Codespaces, do **Dev Containers: Reopen in
Container** locally — same flow.)

### 2. Lay out three panes

Whatever your terminal multiplexer is (VS Code split terminal, tmux, iTerm
splits), get three panes visible at once. The audience reads all three at
the same time and *that* is the whole demo:

```text
┌────────────────────────────┬────────────────────────────┐
│                            │                            │
│   PANE 1: copilot session  │   PANE 2: tail audit log   │
│   (you type here)          │   (don't touch — it scrolls│
│                            │    every time the agent    │
│                            │    calls a tool)           │
│                            │                            │
├────────────────────────────┴────────────────────────────┤
│                                                         │
│   PANE 3: VS Code editor on .github/ (for "here's what  │
│   was wired up" reveal at the end)                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

In pane 2:

```bash
tail -f ~/.copilot/copilot-harness-audit.log
```

### 3. Authenticate once

```bash
gh auth status || gh auth login --web
```

In Codespaces this almost always says you're already authenticated. Locally
you'll do the device-code flow. `copilot` reuses the same credentials, so
don't `/login` separately unless prompted.

### 4. Open the docs site in a browser tab

```text
https://chibayuki347.github.io/copilot-harness-workshop/
```

Worst-case fallback if the live demo wedges: you can talk through the same
content on the site without a single command.

## 5-minute lightning script

**Goal**: the room leaves saying "Copilot has a *harness*."

| Time | What you say | What's on screen |
|---|---|---|
| 0:00 — 0:30 | "Most people see Copilot as a chat box. There's a whole *harness* around it — files in your repo that change how it behaves. Five things: Instructions, Skills, Prompt Files, Hooks, MCP. I'll show you in 4 minutes." | Browser tab on [Mental model](../customizations/mental-model.md). The one diagram. |
| 0:30 — 1:00 | "This repo *is* the demo — everything you'll see lives in `.github/`." | Switch to pane 3 (editor on `.github/`). Scroll past `instructions/`, `skills/`, `hooks/`, `prompts/`, `agents/`. Do not open any file. |
| 1:00 — 3:30 | "Watch what the agent picks up at startup." Type the prompt below. | Pane 1: `copilot` then **the prompt below**. Pane 2 scrolls in real time. |
| 3:30 — 4:30 | "Every line in the right pane is one tool call the agent made — that's the *audit hook* logging it. The agent also read 7 instruction files automatically — those came from `.github/instructions/`. That's the harness." | Both panes still visible. |
| 4:30 — 5:00 | "If you want to try it: [chibayuki347.github.io/copilot-harness-workshop](https://chibayuki347.github.io/copilot-harness-workshop/) — there's a Codespaces button. Questions later." | Browser tab on the site home. |

The prompt to type in pane 1:

```text
Read .github/copilot-instructions.md and the files in .github/instructions/
then tell me in two sentences what conventions this repo enforces.
```

This is the lightning's money shot: the right pane scrolls, the left pane
answers correctly *because* it read the instructions, and you didn't write
a single line of code.

## 15-minute coffee chat script

The 5-minute script first. Then add these three beats.

### Beat 1 — "what else did it know?" (3 min)

In pane 1, after the lightning answer:

```text
/instructions
```

Then:

```text
/skills
```

Then:

```text
/agents
```

Narrate as the lists scroll: "These came from `.github/instructions/`,
`.github/skills/`, `.github/agents/` — all in the repo, all version-controlled,
all team-shared the moment you push."

### Beat 2 — "and it's *scoped*" (3 min)

```text
Show me what would change if I asked you to edit docs/recipes/foo.md
versus .github/workflows/ci.yml. Which conventions apply to each?
```

The answer cites the path-specific instructions
(`.github/instructions/markdown.instructions.md` with its `applyTo` glob)
for the first path and the repo-wide instructions for the second.

Money shot: instructions can be *conditional* on the file path. That's the
moment a curious manager goes "oh, so I could enforce different rules for
frontend vs. backend without forking the doc."

### Beat 3 — "and it's *auditable*" (2 min)

Stop the tail in pane 2 for one second, then:

```bash
wc -l ~/.copilot/copilot-harness-audit.log
head -5 ~/.copilot/copilot-harness-audit.log | jq -c '{tool: .toolName, repo: .repo}'
```

"Every tool call the agent made today, append-only, structured, with the
session ID. You can ship that to Splunk, or scan it nightly for `rm -rf`
patterns, or just keep it as evidence for your security team. The hook is
30 lines of bash in `.github/hooks/audit-demo/log.sh`. You can write your
own in an afternoon."

End on the [governance overview](../governance/index.md) tab in the browser
— don't open it, just point at it. "There's a whole section on this."

## 45-minute brown bag script

The coffee chat (≈ 15 min). Then add four beats.

### Beat 4 — write an instruction live (8 min)

```bash
mkdir -p /tmp/demo-repo && cd /tmp/demo-repo && git init -q
cat > .github/copilot-instructions.md <<'EOF'
# Project conventions
- Reply in bullet points, never prose.
- Always end with a single 🦆 emoji.
EOF
copilot
```

In the session:

```text
Tell me what this repo is about.
```

The answer comes back in bullets, ends with 🦆. "Two lines of instructions,
zero retraining, zero deployment, just `git add` and your team has it tomorrow."

Move back to the workshop repo before the next beat.

### Beat 5 — Skills > Prompt Files > Slash Commands (8 min)

Open `.github/skills/site-build-check/SKILL.md` in pane 3. Read the frontmatter
out loud — `name`, `description`. "Skills are reusable workflows the agent
discovers on its own based on the description. They're how you teach Copilot
your team's vocabulary."

In pane 1:

```text
/skills
```

Then pick `site-build-check`:

```text
Use site-build-check to verify the docs build.
```

The agent runs `mkdocs build --strict` and reports. Pane 2 logs every step.

"Same files work in VS Code Chat — they're under `.github/skills/`, same path,
same `SKILL.md`. The host doesn't matter."

### Beat 6 — Hooks block, MCP extends (8 min)

Open `.github/hooks/audit-demo/hooks.json` in pane 3. "This is the *observability*
hook — `postToolUse`, only reads. There's also a `preToolUse` flavor that can
*block* tool calls — `examples/hooks/deny-dangerous-commands/` ships a working
one that stops `rm -rf` before it runs. We're not loading it live because the
demo would be boring; the repo has it."

Open `.mcp.json` (root). "Zero servers wired by default — for safety. But this
is where you'd add the GitHub MCP server, or a private one your team runs.
There's a [recipe](github-mcp-server.md) walking through it."

In pane 1:

```text
/mcp
```

The empty list is the point. "Trust ratchets up, never down."

### Beat 7 — handoff to exercises (5 min)

Browser to [Exercises track](../exercises/index.md). Don't read; point at the
ladder: 1 → 2 → 3 → 4 → 5 → 6 → capstone. "If today landed for you, do
exercise 1 this week, exercise 3 next week, capstone whenever. Each one is
self-contained and runnable in this same Codespace."

Then [governance overview](../governance/index.md): "and if you're going to
roll any of this out to your team, this section is the half-hour read."

Last 1 minute: questions.

## Money shots — what to point the camera at

If the audience only remembers one frame from each bucket, make it these:

| Bucket | The frame |
|---|---|
| 5 min | Pane 2 (audit log) scrolling lines while pane 1 (agent) answers. *Live observability.* |
| 15 min | The agent's answer correctly distinguishing `docs/recipes/foo.md` vs `.github/workflows/ci.yml`. *Scoped instructions.* |
| 45 min | The 2-line `copilot-instructions.md` in `/tmp/demo-repo` making the agent answer in bullets ending with 🦆. *Tiny change, real behavior shift.* |

## Fallback plan — when something breaks live

| Failure | Fallback |
|---|---|
| Codespaces won't boot | Open [Try this repo as a live demo](../getting-started/try-this-repo.md) in the browser and read through it. The screenshots in this site are the same flow. |
| `copilot` won't authenticate | Run the 5-min script entirely from the docs site browser tab. The [Mental model](../customizations/mental-model.md) and [Customizations overview](../customizations/index.md) pages have the same story without a terminal. |
| Audit log too noisy | `export COPILOT_HARNESS_AUDIT=0` in the session and restart `copilot`. The hook is now a no-op; the rest of the demo still works. |
| `tail -f` shows nothing | The hook is gated on `bash` being on PATH and `jq` being installed. In the devcontainer both are guaranteed. On a local laptop, `which jq` to verify; if missing, `brew install jq` / `apt-get install jq`. |
| Network drops mid-demo | Skip to Beat 4 (write an instruction live). It needs no network beyond the agent's first response, and the *result* is the lesson — not the latency. |

## After the talk — what to send

A one-liner you can drop in chat / email after the session:

```text
What I showed today: https://chibayuki347.github.io/copilot-harness-workshop/
Five customization layers, all live in the repo: .github/{instructions,skills,prompts,hooks,agents}.
If you want to try it without installing anything: https://codespaces.new/ChibaYuki347/copilot-harness-workshop
Self-paced exercises: docs/exercises/ (start with 1, do 2 next week, capstone whenever).
```

## Variations

- **Internal champion track** — replace the demo repo URL with your fork. Pre-add one
  Skill that's specific to your team (e.g. "summarise this Jira ticket"), and demo
  *that* instead of `site-build-check` in Beat 5. The audience recognises the workflow
  and the harness lesson sticks harder.
- **Meetup speaker track** — keep this repo as the demo (no internal context risk),
  but add a slide before the 5-min script that says what *your* team uses Copilot for.
  Without that, audiences default to assuming you work at GitHub.
- **Skip the brown bag, run the workshop** — if you have an hour and want attendees
  to type along, drop this recipe and run [Exercise 0](../exercises/00-live-tour.md)
  with the facilitator cues. Don't try to present *and* facilitate at the same time.
