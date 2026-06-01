# Installation

This page covers installing the **GitHub Copilot CLI** (`copilot`). For full options and
platform-specific details, see the [official install guide](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli).

!!! info "Already using Copilot Ask mode in VS Code?"
    If you only need to install **both** VS Code Copilot Chat and Copilot CLI quickly
    in a single sitting, use the consolidated [Workshop prep](workshop-prep.md) page
    — it has both installers in one flow plus a smoke-test step for each.

## Prerequisites

- An **active GitHub Copilot subscription** (individual, Business, or Enterprise).
- macOS, Linux, or Windows (PowerShell 6+ or WSL).
- On Windows: PowerShell 6 or later.

## Install

=== "macOS / Linux (script)"

    ```bash
    curl -fsSL https://gh.io/copilot-install | bash
    ```

    Pass `| sudo bash` to install system-wide to `/usr/local/bin`. Otherwise it
    installs into `$HOME/.local/bin` — make sure that's on your `PATH`.

=== "Homebrew"

    ```bash
    brew install copilot-cli
    ```

    For prereleases (faster cadence, more bugs):

    ```bash
    brew install copilot-cli@prerelease
    ```

=== "npm (cross-platform)"

    ```bash
    npm install -g @github/copilot
    ```

=== "Windows (winget)"

    ```powershell
    winget install GitHub.Copilot
    ```

## Verify

```bash
copilot --version
```

You should see something like `copilot 1.0.x`.

## First launch

```bash
copilot
```

The first time you start a session in a directory, Copilot asks **whether to trust it**.
Trust is per-folder. If you say "yes and remember", the choice is persisted; otherwise
you'll be asked again next time.

If you're not logged in, run `/login` and follow the device-code flow.

!!! tip "Headless auth"
    For CI or scripted use, set `GH_TOKEN` (or `GITHUB_TOKEN`) to a fine-grained PAT
    with the **Copilot Requests** permission enabled. See
    [the PAT setup docs](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli)
    for the exact scope.

## Recommended companions

- A **terminal that supports multi-line input** (any modern terminal does;
  inside Copilot CLI, run `/terminal-setup` to wire up `Shift+Enter`).
- A working **`git`** binary (Copilot uses it constantly).
- For LSP-powered code intelligence, install a language server for your stack
  (e.g. `npm install -g typescript-language-server`). See [`/lsp`](../reference/cli-commands.md).

## Updating

```bash
copilot /update
```

…or from the shell, use your installer's normal upgrade path (`brew upgrade copilot-cli`,
`npm i -g @github/copilot@latest`, etc.).

## Uninstalling

- **Script install:** delete the `copilot` binary from `$HOME/.local/bin` (or `/usr/local/bin`).
- **Homebrew:** `brew uninstall copilot-cli`.
- **npm:** `npm uninstall -g @github/copilot`.

To purge your local state (sessions, cached MCP tokens, personal hooks/skills):

```bash
rm -rf ~/.copilot
```

→ [Run your first session](first-session.md)
