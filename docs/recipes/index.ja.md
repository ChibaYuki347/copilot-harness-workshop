# レシピ集

複数のハーネスレイヤーを組み合わせた、エンドツーエンドの実践例です。各レシピは
現実の「どうすれば…できるか？」という問いに答え、[`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples) 配下の実行可能な成果物にリンクします。

## このセクションの内容

| レシピ | 組み合わせ | 目的 |
|---|---|---|
| [PR Review スキル](pr-review-skill.md) | スキル + カスタムエージェント | 1 つのコマンドで実行できる、レビュー可能で再利用しやすい PR レビューワークフローです。 |
| [GitHub MCP サーバー](github-mcp-server.md) | MCP | GitHub MCP サーバー（またはプライベート MCP）を追加し、セッション内で使う方法です。 |
| [セッション終了時のシークレットスキャン](session-end-secret-scan.md) | フック | セッションが終了するたびに実行される、自動シークレットスキャンです。 |
| [パス別インストラクション](path-specific-instructions.md) | カスタムインストラクション | フロントエンド用とバックエンド用でルールを分けつつ、設定の重複を避ける方法です。 |
| [マルチエージェントワークフロー](multi-agent-workflow.md) | カスタムエージェント + フリートモード | 並列レビューの流れです: ラバーダック + code-review + security-reviewer。 |

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
