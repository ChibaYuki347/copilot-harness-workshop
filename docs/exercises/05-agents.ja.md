# 5 · カスタムエージェント

🟡 **中級 · 約30分**

🟩 **トラック B — Copilot CLI が必要**（`/agent` ピッカーは CLI のみ。VS Code は `target: vscode` が必要 · [詳細](../reference/vscode-vs-cli.md)）

## 学習目標

この演習を終えると、次のことができるようになります:

- 焦点を絞ったシステムプロンプトを持つカスタムエージェントファイル（`.agent.md`）を書けるようになります。
- そのエージェントのツールセットを制限し、本当に **読み取り専用** にできるようになります。
- `/agent` と自然言語の両方で呼び出せるようになります。
- サブエージェントのツール制限が実際に強制されたことを確認できるようになります。

## 前提条件

- `main` に少なくとも 1 コミットあり、feature ブランチに 1 つ変更がある、スクラッチ用の git リポジトリ（エージェントにレビューさせる diff が必要です）。
- 約30分。

!!! warning "組織のカスタムエージェントポリシーを確認してください"
    Copilot Enterprise / Business の管理者はカスタムエージェントを無効化できます。手順 3 の後に `/agent` を実行して、ピッカーが空、または *"custom agents are not enabled for this enterprise"* と表示される場合は、[Copilot ポリシー設定](https://docs.github.com/copilot/managing-copilot/managing-policies-and-features-for-your-enterprise/managing-policies-for-github-copilot-in-your-enterprise) を確認してから先に進んでください。

## チェックポイントコミット

```bash
git checkout -b feature/auth
echo "function login(user, pw) { return user.password === pw; }" > auth.js
git add auth.js
git commit -m "feat: add login"
```

## シナリオ

専用の **security reviewer** サブエージェントが欲しい状況です。役割は「シークレット、インジェクション、壊れた認証を探す」といった狭い範囲に絞り、ファイルを **読む** ことしかできず（編集は不可）、結果は構造化された Markdown テーブルで返します。メインエージェントは、セキュリティ確認を依頼されたときだけこれに委譲します。

## 手順

### 1. エージェント用フォルダーを作成する

```bash
mkdir -p .github/agents
```

### 2. `.github/agents/security-reviewer.agent.md` を書く

接尾辞には **`.agent.md`** を使います（これが正式な形です。プレーンな `.md` も受け付けられますが、docs と ecosystem では `.agent.md` が標準です）:

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

重要なのは **`tools: ["read", "search"]`** の 1 行です。これでエージェントは読み取り専用ツールに制限されます。`edit` も `execute` も shell もありません。

**確認できる結果**: `cat .github/agents/security-reviewer.agent.md | head` でフロントマターが表示されます。

### 3. エージェントが登録されたことを確認する

```bash
copilot
```

セッション内で:

```text
/env
```

出力には `Custom agents` セクションがあり、そこに `security-reviewer` が表示されるはずです。次でも確認できます:

```text
/agent
```

…これでピッカーが開きます。

### 4. エージェントを呼び出す

ピッカーから選ぶか、自然言語で次のように依頼します:

```text
Run the security-reviewer agent on the current diff against origin/main.
```

メインエージェントは `security-reviewer` に処理を渡し、その結果としてテーブル形式のレポートが返ってくるはずです。チェックポイントでコミットした `auth.js` には、少なくとも 1 件は検出が出るはずです（平文パスワード比較と入力検証不足）。

### 5. ツール制限を確認する

サブエージェントが動いている間、**edit** の試行がないか見ます。あるべきではありません。はっきりした証拠が欲しければ、`--debug` 付きでセッションを起動して grep します:

```bash
copilot --debug 2>&1 | tee /tmp/copilot.log
# … run the prompt above …
grep -E 'agent=security-reviewer.*tool=(edit|write|execute)' /tmp/copilot.log
# should print nothing
```

## 完了条件 { #definition-of-done }

次の 4 つをすべて満たせば完了です:

- [ ] `.github/agents/security-reviewer.agent.md` が存在し、フロントマターに `tools: ["read", "search"]` がある。
- [ ] `/env` に `security-reviewer` がカスタムエージェントとして表示される。
- [ ] セキュリティレビューを依頼すると `security-reviewer` へ委譲される（エージェントの返答や `--debug` 出力で委譲を確認できます）。
- [ ] エージェント終了後、**作業ツリーのファイルが 1 つも変更されていない**（`git status` に自分で加えた変更以外の編集が出ない）。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    out-of-scope ルールと型付き severity legend を明示した、より整った版です:

    ```markdown
    --8<-- "examples/agents/security-reviewer.agent.md"
    ```

    エージェントのフロントマター（`tools`, `model`, `skills`, `mcp-servers`, `target`）や `.agent.md` と `.md` の違いについて詳しくは、[カスタマイズ → カスタムエージェント](../customizations/agents.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .github/agents
git checkout main && git branch -D feature/auth
rm -f auth.js
```

## トラブルシューティング

- **`/env` にエージェントが出ません。** ファイル名は `.github/agents/` 配下の `<name>.agent.md`（または `<name>.md`）でなければなりません。エージェント識別子は、ファイル名から接尾辞を除いたものです。
- **エージェントがファイルを編集してしまいます。** フロントマターを確認してください。`tools` をまったく書かなかった場合、そのエージェントは *すべて* のツールを継承します。この演習では `tools: ["read", "search"]` を明示することが前提です。
- **メインエージェントが自分で答えてしまい、委譲しません。** `description` を強めてください（例: "**Always** use this agent for security reviews"）。または `Use the security-reviewer agent to …` と明示的に依頼します。

## やってはいけないこと

- 「読み取り専用」と名付けたエージェントに `"*"` を指定したり、`tools` を省略したりしないでください。安全性の前提が崩れます。
- すべてのメッセージで反応するような `description`（例: "Use this for any code question"）を書かないでください。メインエージェントが過剰に委譲し、主スレッドを失います。
- プロジェクト固有のシークレットやホスト名をエージェントプロンプトに書かないでください。エージェントはコミットされ、リポジトリアクセスを持つ人には見えます。

## 発展課題

1. **MCP 制限を追加する。** [演習 4](04-mcp.md) を行っているなら、エージェントのフロントマターに `mcp-servers: []` を加え、このサブエージェントが `notes-fs` サーバーへ到達できないようにします。再実行して、`notes/` を一覧できないことを確認してください。
2. **スキルと組み合わせる。** フロントマターに `skills: [secrets-scanner]` を追加し、`.github/skills/` に小さな `secrets-scanner` スキルを作ります。スキルはエージェント起動時にコンテキストへ読み込まれます。`/env` で確認してください。
