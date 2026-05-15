# ケーススタディ: 個人開発者

よくある個人開発の利用パターンをもとにした合成事例です。1 人で 2〜3 個のサイド
プロジェクトを持ち、言語は TypeScript・Python・ときどき Rust。連携するチームは
ありません。

## 出発点の状況

- **リポジトリ:** 独立したものが 3 つ — Next.js のサイト、FastAPI のサイドサービス、
  Tauri のデスクトップアプリ。
- **制約:** 時間です。*保守対象のツールが 1 つ増える* ようなものは避けたい状況です。
- **目標:** 毎セッションで同じセットアップ指示を Copilot に打ち込むのをやめること。

## 選んだレイヤー

| レイヤー | 使う? | 理由 |
|---|---|---|
| カスタムインストラクション | ✅ | 手間なく効く改善です。各リポジトリに 1 ファイルで済みます。 |
| プロンプトファイル | ✅ | 繰り返しのワークフローで入力の手間を減らせます。 |
| スキル | ✅ | 1 つだけです。バージョン更新とリリースノート下書きを行う release スキルです。 |
| フック | ❌ | 整形とテストはすでに CI が実施しています。ローカルのフックは重複します。 |
| MCP サーバー | ✅ | 組み込みの `github-mcp-server` だけを使います。カスタムサーバーは使いません。増える価値が保守コストに見合いませんでした。 |
| カスタムエージェント | ❌ | 組み込みの `rubber-duck` と `code-review` で十分でした。 |

## 導入の進め方（順番どおり）

### 1 日目 — リポジトリごとの `AGENTS.md`（15 分）

```markdown
# AGENTS.md

This is a Next.js 14 app router project. Use TypeScript strict mode. Prefer server
components when possible. Tailwind for styling. Tests with Vitest. Don't introduce
new dependencies without asking. Run `pnpm lint && pnpm test --run` before claiming
done.
```

結果として、どの新しいセッションも共通コンテキスト付きで始められます。毎セッションの説明
時間を約 5 分削減できました。

### 1 週目 — `release` スキル

```
.github/skills/release/SKILL.md
```

ワークフローは、バージョン更新、`CHANGELOG.md` の `git log` からの更新、git タグ作成、
GitHub MCP サーバー経由での GitHub リリースノート下書き作成です。呼び出しは `/release patch` または
`/release minor` です。

面倒な 4 ステップの手作業が、1 コマンドに置き換わりました。

### 1 か月目 — 個人用 `~/.copilot/copilot-instructions.md`

リポジトリ横断の共通ルールです。「Conventional Commits を使う。依頼がない限り新しい依存関係
は追加しない。テストを書くときは、少なくとも 1 つはネガティブテストを書く。」

これは他人のリポジトリで作業するとき（たとえばオープンソースプロジェクトへの
コントリビュート時）にも適用されます。

### 2 か月目 — いくつかのプロンプトファイル

`~/.copilot/prompts/refactor-tests.prompt.md` と `weekly-cleanup.prompt.md`。用途は限定的
ですが、使う場面では高い価値があります。

## 結果

- セッション開始後すぐに作業に入れ、5 分のセットアッププロンプトが不要になりました。
- release スキルにより、1 回のリリースあたり約 10 分短縮できます。週 2 回程度のリリースなら、
  年間で約 17 時間の削減です。
- 保守コストの総量は、四半期に 1 回 `AGENTS.md` を読み返し、現状と合わなくなった内容を
  削る程度です。

## 振り返り

- **まず `AGENTS.md` から始め、`.github/copilot-instructions.md` は後に回します。** ほぼ同等
  ですが、`AGENTS.md` は複数のエージェント型ツール（Cursor、Codex など）で使われる
  コミュニティ慣習です。ツールをまたいで持ち運べます。
- **明確な痛みが出るまでは、カスタムの MCP サーバーを作りません。** 個人用ノートツール向けに
  1 つ作ろうとしましたが、保守の負担が得られる価値を上回りました。
- **CI がすでに行っていることのためにフックは書きません。** pre-commit の整形フックを試し
  ましたが、整形されていないコードは CI がすでに弾いていました。結果として、そのフックは
  信頼性の低い重複処理になっていました。

## テンプレート

このケーススタディで使った実際のファイルは、
[`examples/instructions/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/instructions)
と [`examples/prompts/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/prompts) にあります。
