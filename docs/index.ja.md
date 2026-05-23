---
hide:
  - navigation
  - toc
---

# Copilot Harness Workshop

> **GitHub Copilot を自分仕様にする — ターミナルでも、エディタでも。** Custom
> Instructions・Prompt Files・Skills・Hooks・MCP・Custom Agents という同じ
> ファイル群で、**Copilot CLI** と **VS Code Copilot Chat** の両方をカスタマイズ
> するための実践ガイドです。

[はじめる :material-rocket-launch:](getting-started/what-is-copilot-cli.md){ .md-button .md-button--primary }
[カスタマイズ一覧 :material-cog:](customizations/index.md){ .md-button }
[CLI vs VS Code マトリクス :material-table:](reference/vscode-vs-cli.md){ .md-button }

!!! tip "2 つのサーフェス、1 つのハーネス"
    本サイトの大前提は「**ハーネスを構成するファイルはホスト間で持ち運べる**」という
    考え方です。ほとんどのファイル（`.github/copilot-instructions.md`、`*.prompt.md`、
    `SKILL.md`、`.agent.md`、`.github/hooks/*.json`、MCP 設定など）は、Copilot CLI と
    VS Code Copilot Chat の両方で同じ構文のまま動きます。実際に違いがある所 — たとえば
    `applyTo` glob は VS Code 専用フィルタ、`/fleet` は CLI 専用オーケストレーター
    — は 🟦 / 🟪 / 🟢 のバッジで明示しています。全体像は
    [VS Code vs CLI サポートマトリクス](reference/vscode-vs-cli.md) を参照してください。

---

## なぜ「Harness（ハーネス）」なのか

GitHub Copilot は素のままでも強力ですが、その真価は **コードベース・チーム・リスク
モデルに合わせて形を整えたとき** に発揮されます。エージェントの周りに置く設定ファイル群
や運用慣習 — それが本サイトで言う「ハーネス」です。そしてこの「形」は、Copilot を
ターミナル（Copilot CLI）から呼んでも、エディタ（VS Code Copilot Chat）から呼んでも、
同じ形のままです。

本サイトはオピニオン強めで、例ベース。すべての記述は [公式 Copilot ドキュメント](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)、
[VS Code Copilot Chat カスタマイズドキュメント](https://code.visualstudio.com/docs/copilot/customization/overview)、
[github/awesome-copilot](https://github.com/github/awesome-copilot) のパターンに準拠
しています。

## Harness を構成する 6 つのレイヤー

<div class="feature-grid" markdown>

<div class="feature-card" markdown>
### 📜 Custom Instructions
Copilot にコーディング規約を一度だけ教えれば、どこでも従ってくれます。リポジトリ全体・
パス指定・個人用と粒度を選べます。

[詳しく見る →](customizations/custom-instructions.md)
</div>

<div class="feature-card" markdown>
### ⌨️ Prompt Files / Slash Commands
繰り返すプロンプトを `/command` 一発で呼べる、パラメータ付きテンプレートに変えます。

[詳しく見る →](customizations/prompt-files.md)
</div>

<div class="feature-card" markdown>
### 🦾 Skills
スクリプト・テンプレート・評価基準を含む複数ステップの作業手順を、1 つの `SKILL.md` に
パッケージ化します。

[詳しく見る →](customizations/skills.md)
</div>

<div class="feature-card" markdown>
### 🪝 Hooks
エージェントのライフサイクルイベントに自動処理を仕込みます（CLI では `sessionStart` / `preToolUse` / `postToolUse` / `sessionEnd`、VS Code Preview では `SessionStart` / `PreToolUse` / `PostToolUse` / `Stop`）。

[詳しく見る →](customizations/hooks.md)
</div>

<div class="feature-card" markdown>
### 🔌 MCP サーバー
社内 API・DB・SaaS を Model Context Protocol 経由でエージェントの「使えるツール」に
追加します。

[詳しく見る →](customizations/mcp.md)
</div>

<div class="feature-card" markdown>
### 🤖 Custom Agents
リサーチ・コードレビュー・ラバーダックなど、専門ジョブをサブエージェントに委譲して
並列に走らせます。

[詳しく見る →](customizations/agents.md)
</div>

</div>

## 読み方ガイド

| あなたの状況 | おすすめスタート地点 |
|---|---|
| Copilot（CLI / VS Code）初心者 | [Copilot CLI とは](getting-started/what-is-copilot-cli.md) |
| どの機能がどちらで使えるか整理したい | [VS Code vs CLI マトリクス](reference/vscode-vs-cli.md) |
| カスタマイズに着手したい | [カスタマイズ概要](customizations/index.md) |
| コピペできる例が欲しい | [レシピ集](recipes/index.md) |
| チーム導入を計画中 | [ケーススタディ: チーム導入](case-studies/team-rollout.md) |
| 設定キーをピンポイントで調べたい | [リファレンス](reference/cli-commands.md) |
| 手を動かして練習したい | [演習](exercises/index.md) — 段階的に進む 6 つのラボ＋キャップストーン（CLI / VS Code 両トラック） |

## 正確性について

Copilot CLI も VS Code Copilot Chat も、アップデートは速いです。本サイトの各ページ
では、設定フォーマットの記述に [`github/copilot-cli`](https://github.com/github/copilot-cli) の
changelog エントリ、[公式 CLI ドキュメント](https://docs.github.com/copilot)、
[VS Code Copilot Chat ドキュメント](https://code.visualstudio.com/docs/copilot) を
引用します。ずれを見つけたらぜひ Issue / PR をお願いします（リンクは各ページ上部）。
