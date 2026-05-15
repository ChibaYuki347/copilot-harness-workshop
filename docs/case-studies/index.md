# Case Studies

How real people / teams actually compose the harness. Each case study presents:

- The **starting situation** (problem, constraints, team shape).
- The **layers chosen** and **why**.
- The **rollout path** — what they added first, second, third.
- The **outcome** and **what they'd do differently**.

## In this section

- [**Solo developer**](solo-developer.md) — one person, multiple side projects, mixed languages.
- [**Team rollout**](team-rollout.md) — 12-person product team adopting Copilot CLI across a monorepo.

## What you should take away

The point of these is not to copy them. It's to see the **sequencing**: which
customizations pay off first, when to add the next one, and which ones are easy to
defer.

A useful heuristic from both case studies:

> **Start with custom instructions. Add one skill. Then decide whether you need
> hooks or MCP — usually you don't yet.**

Most of the harness exists to handle scale (team coordination, automation). For a
solo dev with one repo, three text files cover 80% of the value.
