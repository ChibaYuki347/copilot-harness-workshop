# 🤖 カスタムエージェント

**メインエージェントから呼び出せる、専用のサブエージェントに専門作業を委譲します。**

!!! abstract "対応ホスト"
    🟢 **Copilot CLI**（既定） · 🟡 **VS Code**（エージェントの frontmatter に `target: vscode` を追加）。ファイル形式は `.github/agents/<name>.agent.md` で共通。`target` フィールドでホストを切り替えます。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

Copilot CLI には、*サブエージェント* を起動する強力な組み込み `task` ツールがあります。
各サブエージェントは、独自のプロンプト・ツール・（必要に応じて）モデルを持つ専用
コンテキストで動作します。さらに、名前付きで選択できる **カスタムエージェント** も
定義できます。

## カスタムエージェントを使う場面

- メインエージェントが委譲できる **専門家** が欲しい。たとえば「セキュリティレビュー担当」、
  「テスト設計担当」、「リサーチ担当」など。
- その専門家に **制約付きのツールセット**（読み取り専用、shell なし）を与えたい。
- メインセッションのコンテキストを汚さずに、**N 個の独立した調査を並列実行** したい。
- サブタスクごとに別の **モデル** を使いたい（単純作業には安価なモデル、総合判断には
  高性能モデルなど）。

## すでに使える組み込みエージェント

| エージェント | 用途 | ツール |
|---|---|---|
| `explore` | Haiku クラスのモデルによる高速・低コストなコードベース探索 | grep/glob/view/shell |
| `task` | 詳細出力の CLI コマンド（テスト、ビルド、リンター）を実行して要約 | すべての CLI ツール、Haiku |
| `general-purpose` | フルツールセットが必要な複雑な多段タスク | すべての CLI ツール、Sonnet |
| `rubber-duck` | 計画 / 実装を独立視点で批評 | 読み取り専用の調査 |
| `code-review` | ノイズの少ない diff レビュー | 読み取り専用の調査 |
| `research` | GitHub と Web を横断する深い調査 | 検索 / 取得 |

これらは `task` ツール経由で呼び出されます。Copilot が作業内容に応じて自動選択する
こともできますし、*"計画の批評に `rubber-duck` エージェントを使う"* のように明示的に
依頼することもできます。

## カスタムエージェントの構成

カスタムエージェントは YAML フロントマターを持つ Markdown ファイルで、慣例的に
`<name>.agent.md` という名前を付けます（レガシー / VS Code 形式のファイルでは通常の
`.md` も受け付けます）。

```markdown
---
name: security-reviewer
description: |
  Reviews a diff for security issues — credential leaks, SSRF, command injection,
  insecure crypto, auth bypass. Read-only; never edits files. Use when the user asks
  for a security review or pre-merge security check.
tools: ["read", "search"]
model: claude-sonnet-4.5
skills: [secrets-scanner, dependency-audit]
---

# Security Reviewer

You are a security reviewer. Your output is a structured report, not a chat.

## Workflow

1. Diff the working branch against `origin/main` (or whatever the user specifies).
2. For each file changed:
   - Check for hardcoded secrets, tokens, keys.
   - Check for input handling without validation.
   - Check for shell-out / SQL / template patterns that could be injected.
   - Check for auth/authz checks added or removed.
3. Cross-reference with the project's `SECURITY.md` if present.

## Report format

For each issue, emit:

- **Severity** (Critical / High / Medium / Low / Info)
- **File:line**
- **What** (one sentence)
- **Why it matters** (one sentence)
- **Fix sketch** (one or two lines of code or a directive)

If you find no issues, say so explicitly. Do not pad.
```

!!! info "`tools` はパーミッションパターンではなく、ツールの **名前 / エイリアス** の一覧です"
    有効な値には、組み込みエイリアス（`read`、`edit`、`search`、`execute`）、完全修飾の
    MCP ツール名（例: `github-mcp-server/issue_read`）、そして「すべて」を意味する `*`
    が含まれます。ここに `bash(git diff)` のようなパーミッションパターンは書けません。
    挙動の制約はエージェントのプロンプトで表現し、実際の強制には `--allow-tool` /
    フックを使います。[^agent-tools] `tools` を完全に省略すると、利用可能なすべての
    ツールを継承します。

[^agent-tools]: GitHub ドキュメントより: *「`tools` はツール名またはエイリアスの一覧で、
    リポジトリ設定やエージェントプロファイルで構成された MCP サーバーのツールも含められます
    （例: `tools: [\"read\", \"edit\", \"search\", \"some-mcp-server/tool-1\"]`）。このプロパティを
    省略した場合、エージェントは利用可能なすべてのツールにアクセスできます。」*

## カスタムエージェントの配置場所

カスタムエージェントは、ほかのカスタマイズと同様に検出されます。cwd から git ルート
までの各ディレクトリ階層と、個人スコープが対象です。[^agents-loc]

[^agents-loc]: changelog より: *「カスタムインストラクション、MCP サーバー、スキル、
    エージェントは、作業ディレクトリから git ルートまでの各階層で検出されるようになり、
    モノレポを完全にサポートできるようになりました。」*

| パス | スコープ |
|---|---|
| `.github/agents/<name>.agent.md` | リポジトリ（コミットされる）。 |
| `~/.copilot/agents/<name>.agent.md` | 個人。 |
| `agents/<name>.agent.md` を `.github-private` の org/enterprise リポジトリに置く | 組織 / エンタープライズ（管理者が管理）。 |

`.agent.md` 接尾辞が正式な拡張子です（レガシー / VS Code 形式では通常の `.md` も
受け付けます）。エージェント識別子はファイル名から接尾辞を除いたもので、
`security-reviewer.agent.md` ならエージェント `security-reviewer` になります。

## フロントマターのリファレンス

| キー | 用途 |
|---|---|
| `name` | 一意の識別子。`/agent` ピッカーに表示されます。既定ではファイル名が使われます。 |
| `description` | 呼び出す場面の説明（メインエージェントが選択に使います）。 |
| `tools` | エージェントが呼び出せるツール名 / エイリアスの一覧。省略するとすべて継承します。 |
| `model` | このエージェントの既定モデルを上書きします。 |
| `skills` | 起動時にこのエージェントのコンテキストへ先行読み込みするスキル名の一覧。[^skills-field] |
| `mcp-servers` | エージェントが使える MCP サーバーを、設定済みの一部に制限します。 |
| `target` | `vscode` または `github-copilot`。どのツールで有効化するかを絞り込みます。 |

[^skills-field]: changelog より: *「カスタムエージェントは `skills` フィールドを宣言して、
    起動時にスキル内容をエージェントのコンテキストへ先行読み込みできるようになりました。」*

## カスタムエージェントの呼び出し

```text
/agent                      # interactive picker
"Run the security-reviewer agent on the diff."
```

メインエージェントに、複数エージェントをまたいで 1 回の応答内で作業を組み立てさせる
こともできます。これが **フリートモード（fleet mode）** の用途です。

## フリートモード（fleet mode）— 並列サブエージェント

```text
/fleet
```

並列サブエージェント実行を有効にします。フリートモードをオンにすると、メインエージェントは
N 個の独立した調査を同時に振り分けられます。次のような場面で有効です。

- 複数のサービスやモジュールを独立して分析したい。
- 無関係な複数の論点を持つ調査課題がある。
- 計画を複数の観点（コードレビュー + ラバーダック）から並列に検証したい。

実行中の fleet は `/tasks` と `/sidekicks` で確認できます。

## 落とし穴

!!! warning "アンチパターン"
    - **一度きりの作業のために使い捨てエージェントを作る。** その用途はプロンプト
      ファイル向きです。エージェントは繰り返し使う専門役割に限定します。
    - **広すぎるツール許可リスト。** `bash(rm)` を持つ「リサーチ担当」は、
      回りくどいだけのメインエージェントです。
    - **引き継ぎ契約が曖昧。** メインエージェントが結果を利用できるよう、何を返すべきか
      を明示します（例: *"`findings: [...]` を含む JSON オブジェクトを返す"*）。

## 組み合わせ例

典型的な「安全に出荷する」フロー:

1. **メインエージェント** が機能を計画する（プランモード）。
2. **`rubber-duck`** が計画を批評する。
3. メインエージェントが実装する。
4. **`code-review`** が diff をレビューする。
5. **`security-reviewer`**（カスタム）がセキュリティレビューを行う。
6. メインエージェントが指摘を整理し、ユーザーに承認を求める。

詳細版は [レシピ → マルチエージェントワークフロー](../recipes/multi-agent-workflow.md) を参照してください。

## 次へ

→ [レシピ](../recipes/index.md) でエンドツーエンドのワークフローを確認できます。
→ [リファレンス → ファイルレイアウト](../reference/file-layout.md) では、すべての
カスタマイズファイルを 1 枚で把握できます。
