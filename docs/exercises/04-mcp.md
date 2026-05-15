# 4 · MCP Servers

🟡 **Intermediate · ~30 min**

## Learning objectives

By the end of this exercise you can:

- Add a workspace-scoped MCP server via `.mcp.json`.
- Verify it's connected with `/mcp show` and see its tools.
- Use a tool from the new server inside a session.
- Restrict the same session to **only** that server (and nothing else).

## Prerequisites

- A scratch git repo.
- **Node.js** on `$PATH` (so `npx` works). Check: `node --version` should be
  ≥ 18.
- ~30 minutes.

!!! tip "No GitHub auth needed for this exercise"
    We're using the **filesystem** reference server from
    `@modelcontextprotocol/server-filesystem`, which is npm-published and needs
    no API token. It just exposes read/write tools scoped to a directory you
    pick. Perfect for a sandbox.

## Checkpoint commit

```bash
git commit --allow-empty -m "checkpoint: before mcp exercise"
```

## Scenario

You want Copilot to be able to list and read files from a specific
directory — not your whole repo, not your `$HOME` — using a tool you control.
You'll add the filesystem MCP server scoped to a `notes/` folder inside your
lab repo.

## Steps

### 1. Create the directory the MCP server will see

```bash
mkdir -p notes
echo "# Meeting Tue" > notes/2026-05-12.md
echo "# Meeting Wed" > notes/2026-05-13.md
```

### 2. Add `.mcp.json`

At the repo root, create `.mcp.json`:

```json
{
  "mcpServers": {
    "notes-fs": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${PWD}/notes"]
    }
  }
}
```

**Verifiable outcome**: `cat .mcp.json | jq .mcpServers.notes-fs.type` prints
`"stdio"`.

### 3. Start a session and check the connection

```bash
copilot
```

Approve folder trust if prompted (workspace MCP servers only load in trusted
directories). Then:

```text
/mcp show
```

You should see a line like:

```text
notes-fs              connected     tools: read_file, list_directory, …
```

If the server doesn't appear, see Troubleshooting below.

### 4. Use a tool from the new server

```text
List the files in the notes/ directory and show me what's in the most recent one.
```

The agent should:

1. Call `notes-fs/list_directory` (you'll see a permission prompt the first time).
2. Call `notes-fs/read_file` on `2026-05-13.md`.
3. Print the contents.

### 5. Lock the session down to just this server (stretch verification)

Exit the session, then start a new one with **only** `notes-fs` enabled:

```bash
copilot --allow-tool 'notes-fs/*' --deny-tool '*'
```

Now the same prompt as in step 4 should succeed, but `Read .github/copilot-instructions.md`
should be denied (because the built-in `read` tool isn't in the allow-list).

## Definition of done { #definition-of-done }

All four must be true:

- [ ] `.mcp.json` at repo root contains a `notes-fs` entry with `type: "stdio"`.
- [ ] `/mcp show` lists `notes-fs` as **connected**.
- [ ] Asking the agent to list `notes/` calls `notes-fs/list_directory`.
      (You'll see the tool name in the permission prompt or in `--debug`.)
- [ ] Asking it to read a file in `notes/` returns the actual file contents.

## Reference solution { #reference-solution }

??? success "Show reference solution"
    A `.mcp.json` showing **three** servers (stdio, http, and a no-auth
    filesystem one):

    ```json
    --8<-- "examples/mcp/.mcp.json"
    ```

    For the full reference on MCP server types, env-var interpolation, and the
    built-in GitHub MCP server (which is enabled by default — no `.mcp.json`
    needed), see [Customizations → MCP servers](../customizations/mcp.md).

## Cleanup

```bash
rm -rf .mcp.json notes/
```

## Troubleshooting

- **`/mcp show` says `notes-fs` is `failed` or never shows up.**
    - Did you accept folder trust on session start? Workspace MCP servers
      don't load in untrusted dirs.
    - Try the command manually: `npx -y @modelcontextprotocol/server-filesystem
      $PWD/notes`. If that fails, it's a Node/npm setup issue, not a Copilot
      one.
- **Tool calls hang.** Some npm proxies block first-time `npx` downloads. Run
  the npx command once in a separate terminal to warm the cache, then retry.

## What not to do

- **Don't put secrets directly in `.mcp.json`.** Use `${ENV_VAR}` interpolation
  (see the reference solution's `kb-search` example). The file is committed.
- **Don't point the filesystem server at `$HOME` or `/`** "just to see what
  happens". You'll give the agent read access to everything.
- **Don't add an HTTP MCP server that you don't trust.** It runs with your
  session's tool permissions; a malicious one can ask to call dangerous
  built-in tools.

## Stretch goals

1. **Disable the built-in GitHub MCP** for this session by adding it to
   `.mcp.json` with `"disabled": true`. Confirm with `/mcp show` that it's no
   longer listed.
2. **Write a 20-line MCP server** in Python (`mcp` package) that exposes a
   single tool `now()` returning the current ISO timestamp. Wire it via
   `.mcp.json` `type: "stdio"`. Call it from a session: "what time is it,
   according to my custom MCP server?"
