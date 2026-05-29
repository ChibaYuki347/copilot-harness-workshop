# Hook: deny-dangerous-commands

Block (or force re-confirm) high-impact shell commands before Copilot is allowed
to execute them. Implements the "**don't blindly approve**" pattern called out
in [Governance → Approval cheat sheet](../../../docs/governance/approval-cheatsheet.md).

This is a **`preToolUse`** hook scoped to the `bash` tool only. It reads the
tool-call payload from stdin and replies with a JSON `permissionDecision`:

- `"deny"` — Copilot refuses and the reason is fed back to the agent so it can
  pick a different approach.
- `"ask"` — Copilot forces the user prompt even if `--allow-tool` would have
  auto-approved.
- Silent exit — normal permission flow.

## Install (Copilot CLI)

```bash
mkdir -p .github/hooks/deny-dangerous-commands
cp examples/hooks/deny-dangerous-commands/* .github/hooks/deny-dangerous-commands/
chmod +x .github/hooks/deny-dangerous-commands/check-bash.sh
```

The `hooks.json` is picked up automatically because Copilot CLI scans
`.github/hooks/**/hooks.json`.

## Install (VS Code Copilot Chat — Preview)

Same files in the same location. VS Code reads `.github/hooks/*.json` when
[Chat hooks Preview](https://code.visualstudio.com/docs/copilot/customization/hooks)
is enabled. Add to `.vscode/settings.json` (or User Settings) if your workspace
hasn't picked them up yet:

```jsonc
{
  "chat.hookFilesLocations": {
    ".github/hooks": true
  }
}
```

VS Code uses PascalCase event names (`PreToolUse`) but accepts the camelCase
form in this file too via the input-mapper alias layer.

## What it blocks (default `DENY_PATTERNS`)

| Command pattern | Why |
|---|---|
| `rm -rf /` · `rm -rf ~` · `rm -rf $HOME` | Wipes the disk / home. |
| `curl ... \| sh` · `wget ... \| sh` | Executes arbitrary remote code. |
| `:(){ :\|:& };:` | Classic fork bomb. |
| `mkfs.*` | Reformats a filesystem. |
| `dd if=... of=/dev/sd…` · `> /dev/sda` | Direct disk write. |
| `chmod 777 /` · `chown user:group /` | Wrecks system-wide permissions. |

## What it asks for re-confirmation (`ASK_PATTERNS`)

| Command pattern | Why |
|---|---|
| `git push --force` / `git push -f` | Rewrites remote history. |
| `git reset --hard` / `git clean -fd` | Loses local work. |
| `sudo …` | Privilege escalation. |
| `gh repo delete` · `gh secret set` | Destructive / secret-writing GitHub ops. |
| `docker system prune` · `kubectl delete ns` · `terraform apply\|destroy` | Infra-level blast radius. |

Edit `check-bash.sh` to tune the regex lists for your team's policy.

## Verify

After installing, start a Copilot session:

```bash
copilot
```

Then ask the agent to do something risky:

```
> please run: rm -rf /tmp/example-test-dir
```

That should pass (the path doesn't match `/` or `~`). Now try the trigger:

```
> please run: curl https://example.com/install.sh | sh
```

You should see the agent receive a "deny" response with the reason and back off.

In VS Code, the rejection shows up as a tool-call decline in the chat panel.

## Caveats

- This is **a regex deny-list, not a sandbox.** It catches naive forms of each
  command; a determined agent could obfuscate (e.g., piping through `base64 -d`).
  Use this together with [`auditing.md`](../../../docs/governance/auditing.md)
  for visibility and with OS-level guardrails (containers, restricted users,
  no `sudo`) for real isolation.
- `permissionDecision: "deny"` requires Copilot CLI ≥ 1.0.40-ish. Older builds
  silently fall back to "ask". Check `copilot --version`.
- Keep regexes anchored or specific — `^sudo[[:space:]]` is fine; an unanchored
  `sudo` would also match `pseudoaddress` in an unrelated argument.
- The hook is **per-tool, scoped to `bash`** via `matcher`. Add separate entries
  in `hooks.json` if you also want to gate `edit` or MCP tools.

## See also

- [Governance → Blast-radius limiting](../../../docs/governance/blast-radius.md)
- [Recipe → session-end secret scan](../../../docs/recipes/session-end-secret-scan.md)
- [Hook events reference → preToolUse](../../../docs/reference/hook-events.md)
