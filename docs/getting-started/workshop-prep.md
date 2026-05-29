# Workshop prep — 5 minutes, paste-able

This is a single-page checklist for in-house workshops where attendees show up
with mixed setups. Send this URL (or paste this content) ahead of the session.
Aim for everyone to arrive with both **VS Code Copilot Chat** and **Copilot CLI**
working — we'll choose which to use on the day.

> Time budget: **5–10 minutes** if you already have VS Code installed.

## Prereqs

- [ ] A GitHub account with a Copilot subscription (Free / Pro / Business / Enterprise).
- [ ] Admin rights on your laptop, or the ability to install Node.js and a VS Code extension.
- [ ] A terminal you're comfortable with (Terminal.app, Windows Terminal, iTerm2, etc.).

If your Copilot subscription is via your employer's Enterprise tenant, check
that **agent mode and MCP are not disabled by policy** before the session.
Run `copilot /usage` after installing — if MCP shows as "policy disabled",
flag it to your admin.

## Track 1 — VS Code Copilot Chat

1. **Install VS Code** if you don't have it: <https://code.visualstudio.com/>
2. **Install the GitHub Copilot extension** (it bundles Chat):
   - Open VS Code → Extensions panel (`Ctrl/Cmd + Shift + X`).
   - Search **GitHub Copilot**, click **Install** on the entry by GitHub.
   - The "GitHub Copilot Chat" extension installs as a dependency.
3. **Sign in.** A toast appears in the bottom right: "Sign in to GitHub" →
   browser → authorize.
4. **Smoke test.**
   - Open the Chat view (`Ctrl/Cmd + Alt + I`).
   - Type: `Hello, are you ready?` — you should get a reply.
   - In the mode dropdown at the bottom of the chat, switch to **Agent**.
     If "Agent" is missing, update the Copilot Chat extension to the latest
     version.

✅ Done with VS Code track when you can switch to Agent mode and get a reply.

## Track 2 — Copilot CLI

1. **Install Node.js 22+** if you don't have it.
   - macOS: `brew install node@22`
   - Windows: <https://nodejs.org/> (LTS installer) or `winget install OpenJS.NodeJS.LTS`
   - Linux: use [nodesource](https://github.com/nodesource/distributions) or your distro.
   - Verify: `node --version` shows `v22.x` or higher.
2. **Install Copilot CLI globally:**

   ```bash
   npm install -g @github/copilot
   ```

3. **Sign in.**

   ```bash
   copilot
   ```

   The first run launches a device-code OAuth flow — open the URL, paste the
   code, authorize.

4. **Smoke test.**

   ```bash
   copilot --version       # prints a version like 1.0.x
   ```

   Then start an interactive session:

   ```bash
   mkdir -p ~/copilot-warmup && cd ~/copilot-warmup
   copilot
   ```

   At the prompt, type `Hello, are you ready?` — you should get a reply.
   Type `/exit` to quit.

✅ Done with CLI track when `copilot --version` works **and** you've seen one
reply in an interactive session.

## Quick troubleshooting

| Symptom | Fix |
|---|---|
| `copilot: command not found` after `npm install -g` | npm global bin not on PATH. `npm config get prefix` → ensure `<prefix>/bin` is on `PATH`. |
| `copilot` opens but says "not signed in" repeatedly | Delete `~/.copilot/auth.json` and re-run `copilot`. |
| VS Code Chat dropdown has no "Agent" option | Update Copilot Chat extension. Reload window. |
| Corporate proxy / TLS error | Set `HTTPS_PROXY`. For TLS, set `NODE_EXTRA_CA_CERTS=/path/to/cert.pem`. |
| Permission denied on `npm install -g` | Use nvm, or `mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global && export PATH=$HOME/.npm-global/bin:$PATH` |

## During-session expectations

You'll only need **one** of the two hosts during the live session — pick the
one you're more comfortable with. We're installing both so you can compare.

For the live session you'll also want:

- A small repo you don't mind experimenting on (cloned and `cd`'d into).
- Ability to take a screenshot (we'll share screens of the approval prompts).

## See also

- [Installation](./installation.md) — deeper install reference if you hit issues.
- [Ask mode vs Agent mode](./ask-vs-agent.md) — what the mode switch actually means.
- [First session](./first-session.md) — what the first 10 minutes of agent work looks like.
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — bookmark for the live session.
