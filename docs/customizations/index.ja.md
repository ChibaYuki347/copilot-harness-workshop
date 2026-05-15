# カスタマイズ — 概要

Copilot ハーネスの 6 つのレイヤーを、おおよそ **導入を進める順番** に沿って紹介します。

```mermaid
flowchart LR
    A[Custom Instructions<br/>📜] --> B[Prompt Files<br/>⌨️]
    B --> C[Skills<br/>🦾]
    C --> D[Hooks<br/>🪝]
    D --> E[MCP Servers<br/>🔌]
    E --> F[Custom Agents<br/>🤖]

    style A fill:#5e35b1,color:#fff
    style B fill:#3949ab,color:#fff
    style C fill:#1e88e5,color:#fff
    style D fill:#00897b,color:#fff
    style E fill:#43a047,color:#fff
    style F fill:#fb8c00,color:#fff
```

すべてを一度に導入する必要はありません。実際には、単一のプロジェクトであれば **最初の
3 つで価値の 80 % を得られます**。後半の 3 つは、チーム運用・複数リポジトリ・社内向け
ツール群を公開したい場合に効果を発揮します。

## ひと目でわかる概要

| レイヤー | 配置場所 | スコープ | 使いどき |
|---|---|---|---|
| **[カスタムインストラクション](custom-instructions.md)** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md`, `~/.copilot/copilot-instructions.md` | リポジトリまたは個人 | 毎ターン「4 スペースインデントにする」「`pnpm` を使い、`npm` は使わない」と伝えるのに疲れている。 |
| **[プロンプトファイル](prompt-files.md)** | `*.prompt.md` ファイル / リポジトリレベルのスラッシュコマンド | リポジトリまたは個人 | 6 行程度のプロンプトを週に 2 回は貼り付けている。 |
| **[スキル](skills.md)** | `.github/skills/<name>/SKILL.md`（リポジトリ）, `~/.copilot/skills/<name>/SKILL.md`（個人）, `~/.agents/skills/<name>/SKILL.md` | リポジトリまたは個人 | その作業には *手順*、スクリプト、または出力契約がある。 |
| **[フック](hooks.md)** | `.github/hooks/<name>/hooks.json`（リポジトリ）, `~/.copilot/hooks/<name>/hooks.json`（個人） | リポジトリまたは個人 | エージェントが X をしたときに、何かを自動で実行したい。 |
| **[MCP サーバー](mcp.md)** | git ルートの `.mcp.json`、または `copilot mcp` による個人設定 | リポジトリまたは個人 | エージェントにシェルコマンドではないツールが必要 — 社内 API、DB、SaaS など。 |
| **[カスタムエージェント](agents.md)** | `~/.copilot/agents/<name>.md`、またはリポジトリレベルのエージェントディレクトリ | リポジトリまたは個人 | 特化したサブエージェント（例: 「セキュリティレビュー担当」）を用意し、`/agent` から選べるようにしたい。 |

## どう組み合わせるか

実際のワークフローでは、1 つだけ使うことはほとんどありません。たとえば次のような構成です。

> **「PR を作成して、その後で自動要約とラベル付けを行う。」**
>
> 1. **カスタムインストラクション** で PR テンプレートの形式をエージェントに伝える。
> 2. **スキル** `/pr-summary` で要約生成の手順をたどらせる。
> 3. `postToolUse` の **フック** で `gh pr create` に一致したときにラベラー用スクリプトを起動する。
> 4. **MCP サーバー** で社内の "release-train" サービスを公開し、メタデータを埋める。

完全版は [レシピ →](../recipes/index.md) で確認できます。

## 検出ルール（Copilot が探す場所）

カスタムインストラクション、MCP サーバー、スキル、エージェントは、**現在の作業
ディレクトリから git ルートまでの各ディレクトリ階層で検出されます**。そのため、
パッケージ単位で上書きするモノレポも自然に扱えます。[^discovery]

[^discovery]: `github/copilot-cli` changelog より: *「カスタムインストラクション、MCP サーバー、
    スキル、エージェントは、作業ディレクトリから git ルートまでの各階層で検出される
    ようになり、モノレポを完全にサポートできるようになりました。」*

個人スコープのファイルは `~/.copilot/` 配下に置きます（スキルのみ `~/.agents/skills/`
も使用します）。これらは、このマシン上のすべてのプロジェクトに適用されます。

## 何が読み込まれているかを確認する

どのセッションでも、次を実行します。

```
/env
```

これにより、有効になっているインストラクション、MCP サーバー、スキル、エージェント、
プラグイン、LSP サーバーが **正確に** 表示されます。期待どおりに動かないときは、
**まずここを確認します**。

## 次へ

深掘りしたいレイヤーから読んでも、順番にざっと見てもかまいません。

- [📜 カスタムインストラクション](custom-instructions.md)
- [⌨️ プロンプトファイルとスラッシュコマンド](prompt-files.md)
- [🦾 スキル](skills.md)
- [🪝 フック](hooks.md)
- [🔌 MCP サーバー](mcp.md)
- [🤖 カスタムエージェント](agents.md)
