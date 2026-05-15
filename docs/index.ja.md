---
hide:
  - navigation
  - toc
---

# Copilot Harness Workshop

> **GitHub Copilot CLI を自分仕様にする。** Custom Instructions・Prompt Files・Skills・
> Hooks・MCP・Custom Agents を使って Copilot エージェントをチームと現場に最適化するための
> 実践ガイドです。

[はじめる :material-rocket-launch:](getting-started/what-is-copilot-cli.md){ .md-button .md-button--primary }
[カスタマイズ一覧 :material-cog:](customizations/index.md){ .md-button }

---

## なぜ「Harness（ハーネス）」なのか

GitHub Copilot CLI は素のままでも強力ですが、その真価は **コードベース・チーム・リスク
モデルに合わせて形を整えたとき** に発揮されます。エージェントの周りに置く設定ファイル群
や運用慣習 — それが本サイトで言う「ハーネス」です。

本サイトはオピニオン強めで、例ベース。すべての記述は [公式 Copilot ドキュメント](https://docs.github.com/copilot/concepts/agents/about-copilot-cli)
と [github/awesome-copilot](https://github.com/github/awesome-copilot) のパターンに準拠
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
`sessionStart` / `preToolUse` / `postToolUse` / `sessionEnd` などのライフサイクル
イベントに自動処理を仕込みます。

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
| Copilot CLI 初心者 | [Copilot CLI とは](getting-started/what-is-copilot-cli.md) |
| カスタマイズに着手したい | [カスタマイズ概要](customizations/index.md) |
| コピペできる例が欲しい | [レシピ集](recipes/index.md) |
| チーム導入を計画中 | [ケーススタディ: チーム導入](case-studies/team-rollout.md) |
| 設定キーをピンポイントで調べたい | [リファレンス](reference/cli-commands.md) |
| 手を動かして練習したい | [演習](exercises/index.md) — 段階的に進む 6 つのラボ＋キャップストーン |

## 正確性について

Copilot CLI のアップデートは速いです。本サイトの各ページでは、設定フォーマットの記述に
[`github/copilot-cli`](https://github.com/github/copilot-cli) の changelog エントリや
[公式ドキュメント](https://docs.github.com/copilot) を引用します。ずれを見つけたら
ぜひ Issue / PR をお願いします（リンクは各ページ上部）。
