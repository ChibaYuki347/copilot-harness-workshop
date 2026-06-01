# レシピ集

複数のハーネスレイヤーを組み合わせた、エンドツーエンドの実践例です。各レシピは
現実の「どうすれば…できるか？」という問いに答え、[`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples) 配下の実行可能な成果物にリンクします。

## このセクションの内容

| レシピ | 対応ホスト | 組み合わせ | 目的 |
|---|---|---|---|
| [PR Review スキル](pr-review-skill.md) | 🟢 両ホスト[^host-legend] | スキル + カスタムエージェント | 1 つのコマンドで実行できる、レビュー可能で再利用しやすい PR レビューワークフローです。 |
| [GitHub MCP サーバー](github-mcp-server.md) | 🟦 CLI 主体 | MCP | GitHub MCP サーバー（またはプライベート MCP）を追加し、セッション内で使う方法です。 |
| [セッション終了時のシークレットスキャン](session-end-secret-scan.md) | 🟢 両ホスト | フック | セッションが終了するたびに実行される、自動シークレットスキャンです。 |
| [パス別インストラクション](path-specific-instructions.md) | 🟪 VS Code 主体 | カスタムインストラクション（`applyTo` glob） | フロントエンド用とバックエンド用でルールを分けつつ、設定の重複を避ける方法です。 |
| [マルチエージェントワークフロー](multi-agent-workflow.md) | 🟦 CLI 専用 | カスタムエージェント + フリートモード | 並列レビューの流れです: ラバーダック + code-review + security-reviewer。 |
| [ハーネスを社内で紹介する](presenting-the-harness.md) | 🟢 両ホスト | live demo 全部 | 5 / 15 / 45 分の presenter ラダー — このハーネスをチームにどう紹介するか |

[^host-legend]: **凡例** — 🟢 **両ホスト** = Copilot CLI と VS Code Copilot Chat の両方で、同じファイルがそのまま動きます。🟦 **CLI 主体 / 専用** = CLI 固有のスラッシュコマンド・フラグ・既定バンドル機能に依存します。VS Code には別の仕組みがあるか、相当機能がありません。🟪 **VS Code 主体** = VS Code 固有のスキーマ（例: `.instructions.md` の `applyTo` glob）に依存します。CLI もファイルは読みますが、ホスト固有のセマンティクスは尊重しません。詳細は [サポートマトリクス](../reference/vscode-vs-cli.md) を参照。

## レシピの読み方

各レシピページは、同じ構成で書かれています:

1. **課題。** どんな困りごとを解決するかを 1 段落で説明します。
2. **使うレイヤー。** どのカスタマイズを組み合わせているかを示します。
3. **ファイル。** そのままコピーできる実際の成果物と、そのパスです。
4. **動作の流れ。** レシピを呼び出したときにエージェントが何をするかを説明します。
5. **バリエーション。** チームの要件に合わせて調整する方法を紹介します。

## サンプルファイルの場所

すべてのサンプル成果物は、リポジトリ内の
[`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples) にあります:

```
examples/
├── instructions/      # copilot-instructions + path-specific examples
├── skills/            # SKILL.md examples
├── hooks/             # hooks.json + scripts
├── mcp/               # .mcp.json templates
├── agents/            # custom-agent Markdown files
└── prompts/           # *.prompt.md files
```

必要なフォルダーを、利用中のリポジトリの `.github/`（リポジトリスコープ）または
`~/.copilot/`（個人スコープ）にコピーします。
