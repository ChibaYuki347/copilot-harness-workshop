# Copilot CLI とは

GitHub Copilot CLI は、GitHub.com や IDE で使い慣れた Copilot を
ターミナルに持ち込む **エージェント型コマンドラインインターフェース** です。Web 上で
pull request を作成する GitHub Copilot coding agent と同じハーネスで動作します。

!!! note "VS Code Copilot Chat ユーザーの方も読み進めてください"
    このページでは **CLI サーフェス** の入り口を中心に説明しますが、本サイトで扱う
    ハーネス（Custom Instructions・Skills・Hooks・MCP・Custom Agents）は
    **VS Code Copilot Chat の agent mode にもそのまま適用できます**。`.github/`
    配下に書くカスタマイズファイルはほとんどが両ホストで共通です。
    [VS Code vs CLI マトリクス](../reference/vscode-vs-cli.md) が「どの機能がどちらで
    動くか」の正典で、各機能ページではホスト固有の差分を 🟦（CLI 専用 / 主体）・
    🟪（VS Code 専用 / 主体）・🟢（両ホスト）のバッジで明示しています。

```
$ copilot
```

これが操作のすべてです。ここからは自然言語で対話し、`@` でファイルを
指定し、`#` で Issue や PR を参照し、`!` でシェルコマンドを実行できます。

## できること

CLI は完全なエージェントループです。ファイルを読み、コマンドを実行し（承認付き）、
コードを編集し、GitHub.com とやり取りし、説明したタスクが終わるまで反復します。

| 機能 | 例 |
|---|---|
| その場でコードを編集 | "`@src/pagination.ts` の off-by-one バグを修正して" |
| シェルコマンドを実行 | "テストを実行して、何が失敗しているか教えて" |
| GitHub 上の情報を扱う | "`bug` ラベルが付いた未解決の Issue を要約して" |
| コーディング前に計画する | `Shift+Tab` で **プランモード** に入る |
| バックグラウンドで作業する | `/delegate` でタスクをクラウド上の Copilot に渡す |

## VS Code Copilot Chat との関係

両サーフェスとも今はエージェント型で、ハーネスの語彙のほとんどを共有しています。
違いは「どこから Copilot を呼ぶか」と「どのスラッシュコマンド / 並列実行機能を
ホストが露出させているか」です。

| | VS Code Copilot Chat（agent mode） | Copilot CLI |
|---|---|---|
| 利用画面 | エディタのサイドパネル + インラインチャット | ターミナル、エージェント REPL |
| ツール利用 | エディタ API + シェル + MCP + Skills + Hooks + Custom Agents | シェル + MCP + Skills + Hooks + Custom Agents |
| 認証 | VS Code Copilot 拡張機能でログイン | 同じ GitHub アカウント / PAT（`gh auth`） |
| カスタマイズファイル | `.github/copilot-instructions.md`、`.github/instructions/*.instructions.md`（`applyTo` glob 付き）、`.github/prompts/*.prompt.md`、`.github/skills/`、`.github/agents/`、`.github/hooks/`（Preview）、`.vscode/mcp.json` | `.github/copilot-instructions.md` + `AGENTS.md`（入れ子可）、`.github/prompts/`、`.github/skills/`、`.github/agents/`、`.github/hooks/`、`.mcp.json` または `.github/mcp.json` |
| ホスト固有の操作 | アクティブエディタへのインライン編集、Chat モード / Plan モード | `/fleet` による並列サブエージェント、`/delegate` でクラウドエージェントに委譲、headless `copilot -p '…'` |

**`.github/` 配下のファイルはほとんどが両ホストで動きます** — これがハーネスの価値の
一つです。1 度カスタマイズすれば、どこでも効果があります。例外（たとえば `applyTo`
glob は VS Code 専用フィルタ、`/fleet` は CLI 専用オーケストレーター）は各ページで
🟦 / 🟪 / 🟢 のホストバッジで明示しています。

## このサイトで繰り返し登場する主要概念

- **セッション。** `copilot` を 1 回実行した単位が *セッション* です。フックはセッションの区切りで起動します。
- **ターン。** セッション内でのプロンプト → 応答の 1 組が *ターン* です。
- **ツール。** エージェントが呼び出せるものすべてです。シェルコマンド、MCP ツール、組み込みツールなどが含まれます。
- **スキル。** 手順とアセットをまとめた、呼び出し可能な作業手順です。
- **フック。** ライフサイクルイベントで起動するスクリプト（または HTTP エンドポイント）です。
- **MCP サーバー。** Model Context Protocol 経由でツールを公開する長時間稼働プロセスです。
- **カスタムエージェント / サブエージェント。** メインエージェントからスコープを絞って委譲されるワーカーです。

## CLI と他の Copilot 画面の使い分け

!!! tip "目安"
    インライン補完や小さな編集には **IDE** を使います。
    複数ファイルの変更、リポジトリ全体のリファクタリング、ビルド / テストのループ、
    シェルコマンドの実行が有効な作業には **CLI** が向いています。
    別の作業をしている間に非同期で PR を開きたい場合は
    **クラウドのコーディングエージェント**（`/delegate`）を使います。

## 次へ

→ [CLI をインストールする](installation.md)
→ すでにインストール済みであれば、[最初のセッション](first-session.md) から始められます。
