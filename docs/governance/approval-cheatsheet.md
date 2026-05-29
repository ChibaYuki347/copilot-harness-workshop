# Approval cheat sheet

The single highest-leverage decision you make in agent mode is **what you
auto-approve, what you always ask about, and what you flat-out forbid**.
This page is the cheat sheet.

!!! tip "Default mental rule"
    **"If the agent's action is reversible *and* I'd notice it failing — auto-approve.
    Otherwise, force the prompt."**

## Always ask { #always-ask }

Configure your harness to **always require a human prompt** for these, no matter
what:

| Operation | Why | How to enforce |
|---|---|---|
| `rm` of anything outside the current repo / scratch dir | Hard to undo across system. | preToolUse hook (regex on `command`). |
| `git push --force`, `git push -f`, `git push --force-with-lease` against `main` / a release branch | Rewrites shared history. | Same hook. Optionally pair with a CODEOWNERS rule on the remote side. |
| `git reset --hard`, `git clean -fd` | Loses uncommitted work. | Same hook. |
| `sudo …` (any) | Privilege escalation. | Same hook + don't run Copilot as root. |
| `gh repo delete`, `gh secret set`, `gh api -X DELETE …` | Destructive / secret-writing GitHub ops. | Same hook. |
| `terraform apply`, `terraform destroy`, `kubectl delete ns …`, `docker system prune` | Infra blast radius. | Same hook + restrict env / role-bound credentials. |
| Anything touching `~/.ssh`, `~/.aws`, `~/.kube`, `.env*` files | Credential / cred-equivalent files. | Hook on `edit` / `create` tools (matcher), or filesystem permissions (chmod 600 + immutable). |
| Network calls to non-allowlisted hosts | Data-exfil risk. | Network-level — see [Blast-radius → network](./blast-radius.md#network). |

The starter `examples/hooks/deny-dangerous-commands/` ships with most of these.
Tune the regex to your team.

## Safe to auto-approve { #safe-to-auto-approve }

For most of a normal session, these are usually fine to auto-approve — they're
read-only or scoped to scratch space, and the worst case is "wasted seconds":

- `ls`, `cat`, `head`, `tail`, `grep`, `rg`, `fd`, `find` (search/read).
- `git status`, `git log --oneline`, `git diff`, `git branch --show-current`.
- `npm test`, `pnpm test`, `pytest`, `go test`, `cargo test`, `mvn test` (test
  runners — usually idempotent).
- `npm run lint`, `eslint`, `ruff check`, `mypy`, `tsc --noEmit`.
- Edits to files inside the current repo's working tree (Copilot already shows
  you a diff before applying).

### Copilot CLI flags

```bash
copilot \
  --allow-tool 'bash(npm test:*)' \
  --allow-tool 'bash(pytest:*)' \
  --allow-tool 'bash(git status:*)' \
  --allow-tool 'bash(git diff:*)' \
  --allow-tool 'view' \
  --deny-tool  'bash(rm -*:*)' \
  --deny-tool  'bash(sudo *:*)'
```

`bash(<prefix>:*)` matches a bash command starting with `<prefix>`. Combine
allow + deny so that the deny wins on overlap (it does, in current builds).

You can persist these as repo defaults by storing them in
`.copilot/config.json` or by using a `sessionStart` hook that prints `--allow-tool`
suggestions for the user.

### VS Code Copilot Chat

Settings → search **"Chat Tools"**. The relevant keys:

```jsonc
// .vscode/settings.json or User settings
{
  // Tools the agent is allowed to call without asking each time.
  "chat.tools.autoApprove": false,                      // master switch (default: false)
  "chat.agent.allowList": ["fetch", "search"],          // tool-id allow-list
  "chat.agent.denyList":  ["github.copilot.terminal.execute:rm*"]  // example pattern
}
```

Exact keys vary by VS Code Copilot Chat version — verify in **Settings →
Features → Chat** before relying on the names here. The risk model is the same
regardless of UI.

## Never auto-approve when unattended { #never-auto-approve-unattended }

A blanket rule that overrides everything else:

> **If you are not actively watching the chat panel, no auto-approval should
> be active.** Period.

Concretely:

- Don't leave `copilot -p '<long task>'` running unattended with `--allow-tool`
  expanded.
- Before stepping away, run `/exit` or close the tab. Sessions hold credentials.
- If you delegate to the cloud agent (`/delegate`), prefer scoped tokens
  (fine-grained PAT, short-lived) over your default credentials.
- Prompt-injection (category 5 in the [risk model](./risk-mental-model.md))
  is the reason: the agent can read text that *changes what it tries to do*.
  If you can't see the tool call, you can't catch the change.

## Team defaults { #team-defaults }

A reasonable, copy-pasteable starter policy for a small team:

| Auto-approve | Ask every time | Deny always |
|---|---|---|
| `view`, `grep`, `ls`, `cat`, `git status`, `git diff` | `edit`, `create` (let the user see each diff once) | `rm -rf /`, `rm -rf ~`, `curl … \| sh`, `mkfs`, fork bomb |
| Test runners, linters | `bash(git push …)`, `bash(git reset --hard …)` | `bash(sudo …)` outside containers |
| `bash(npm test:*)`, `bash(pytest:*)` | All MCP tools that write (until vetted per [MCP vetting](./mcp-vetting.md)) | `bash(gh secret set …)` |

Drop this into a team-wide `.github/copilot-instructions.md` so even new
contributors with default settings get the same baseline:

```markdown
## Approval policy

Always require my approval before:
- Any `rm`, `mv`, or `cp` that targets a path starting with `/`, `~`, or `$HOME`.
- Any `git push --force*`, `git reset --hard`, `git clean -fd`.
- Any `sudo`, `chmod 777`, `chown`.
- Any `gh secret`, `gh repo delete`, `gh api -X DELETE`.
- Any `terraform apply`/`destroy`, `kubectl delete`, `docker system prune`.
- Any file edit inside `.github/`, `.env*`, `~/.ssh/`, `~/.aws/`, `~/.kube/`.

You may run read-only inspection (`ls`, `cat`, `grep`, `git status`, `git log`,
`git diff`) and project test/lint commands without asking.
```

A Custom Instruction like this is **a hint, not enforcement** — pair it with
the `deny-dangerous-commands` hook for the actual block.

## Common mistakes

- **"I'll allow `bash` and just watch."** — `bash` is too broad. The model can
  paste any command. Allow specific prefixes (`bash(npm test:*)`), not the
  whole tool.
- **"It's just a scratch repo, I'll auto-approve everything."** — Until the
  agent reads a README that links to a script. Allow read-only by default and
  expand from there.
- **"Approval prompts are noise."** — They're cheap insurance. Only suppress
  them for actions whose worst case you've already accepted.

## See also

- [Risk mental model](./risk-mental-model.md) — why these rules exist.
- [Blast-radius limiting](./blast-radius.md) — enforcement beyond hooks.
- [`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands)
- [`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls)
