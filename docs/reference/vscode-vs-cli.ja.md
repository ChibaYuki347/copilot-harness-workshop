# VS Code と Copilot CLI — どこで何が動くか

このサイトは **ハーネス（カスタマイズの仕組み）** がテーマであり、ホストツール自体ではありません。ここで紹介するカスタマイズの多くは VS Code の GitHub Copilot 拡張と Copilot CLI の **両方** で動きます。一部だけ CLI 専用です。本ページは、サイトの他のページを読む前に「何をチームに展開できるか」を 1 画面で判断するためのチートシートです。

!!! info "このページの目的"
    Copilot を導入中のチームから「VS Code 派と CLI 派が混在しているが、どのカスタマイズを共有できるのか」とよく聞かれます。短い答えは **ほとんど共有できます**。長い答えが下の表です。

## ひと目で分かる対応表

| カスタマイズ | VS Code（Copilot 拡張 / Chat / Agent モード） | Copilot CLI | 設定ファイルは共有？ |
|---|---|---|---|
| [カスタムインストラクション](../customizations/custom-instructions.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/copilot-instructions.md` |
| [パス指定インストラクション (`applyTo`)](../customizations/custom-instructions.md#path-specific) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/instructions/*.instructions.md` |
| [プロンプトファイル](../customizations/prompt-files.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/prompts/*.prompt.md` |
| [スキル](../customizations/skills.md) | 🟡 個人スコープのみ (`~/.agents/skills/`) | 🟢 完全対応（リポジトリ + 個人） | ⚠️ リポジトリスコープの `.github/skills/` は **CLI 主体** |
| [MCP サーバー](../customizations/mcp.md) | 🟢 対応（別ファイル） | 🟢 対応 | ⚠️ 設定先が異なる（後述） |
| [カスタムエージェント](../customizations/agents.md) | 🟡 対応（`target: vscode` を frontmatter に付与） | 🟢 対応 | ⚠️ 同じファイル形式、`target` で切り替え |
| [フック](../customizations/hooks.md) | ❌ 非対応 | 🟢 対応 | 🟩 CLI 専用 |

凡例: 🟢 完全対応 · 🟡 制約付き対応 · ❌ 非対応。

## 設定ファイルの場所を並べて比較

各ツールが **読み込む** 設定の場所:

| 設定対象 | VS Code 拡張 | Copilot CLI |
|---|---|---|
| リポジトリ全体のインストラクション | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| パス指定インストラクション | `.github/instructions/<name>.instructions.md` | `.github/instructions/<name>.instructions.md` |
| プロンプトファイル | `.github/prompts/<name>.prompt.md` | `.github/prompts/<name>.prompt.md` |
| 個人スキル | `~/.agents/skills/<name>/SKILL.md` | `~/.agents/skills/<name>/SKILL.md` または `~/.copilot/skills/...` |
| リポジトリスキル | 非対応（個人スコープを使用） | `.github/skills/<name>/SKILL.md` |
| MCP サーバー（ワークスペース） | `.vscode/mcp.json` または `settings.json` の `"mcp.servers"` | リポジトリルートの `.mcp.json` |
| MCP サーバー（個人） | ユーザースコープの `settings.json` | `~/.copilot/mcp-config.json` |
| カスタムエージェント | `.github/agents/<name>.agent.md`（`target: vscode` 付き） | `.github/agents/<name>.agent.md`（`target` なし、または `target: github-copilot`） |
| フック | 非対応 | `.github/hooks/<name>/hooks.json`（+ スクリプト） |

!!! warning "MCP の設定ファイルは **共有されません**"
    CLI は **もう `.vscode/mcp.json` を読みません**。2026 年後半の changelog で、リポジトリルートの `.mcp.json` のみを読み、`.vscode/mcp.json` があって `.mcp.json` がない場合は移行ヒントだけ表示するようになりました。チームが混在しているなら、両方のファイルに同じサーバー定義を入れて配布してください。詳しいマッピングは [MCP カスタマイズページ](../customizations/mcp.md) を参照。

## スラッシュコマンド対応表

CLI はスラッシュコマンド（`/instructions`、`/skills` など）で現在のセッションに読み込まれているものを表示します。VS Code はコマンドパレットや Chat ビューを使います。大まかな対応関係:

| やりたいこと | Copilot CLI | VS Code |
|---|---|---|
| 有効なカスタムインストラクションを確認 | `/instructions` | Chat → `@workspace /instructions`（またはファイルを直接開く） |
| 検出されたスキルを確認 | `/skills` | 個人スキルのみ — Chat のピッカーから確認 |
| 検出された MCP サーバーとツールを確認 | `/mcp show` | MCP パネルを開く（Chat サイドパネル） |
| カスタムエージェントを選択 | `/agent` | Chat → エージェントをメンションするかピッカー使用 |
| すべての読み込み内容を確認 | `/env` | 該当機能なし |
| プロンプトファイルを実行 | `/<プロンプトファイル名>` | Chat → `/<プロンプトファイル名>` |
| フックを実行 | 該当なし（ライフサイクルイベントで自動発火） | 該当なし |

## 実務での指針

- **カスタムインストラクションとプロンプトファイルは万能。** チームが混在しているなら、まずここから始めれば同じファイルが両方の環境でそのまま動きます。
- **MCP は両対応だが設定ファイルが違う。** 移行期間中は `.vscode/mcp.json` と `.mcp.json` の両方に同じサーバーリストを書いて配布してください。
- **フックは CLI 専用。** VS Code でも `sessionEnd` 監査ログ相当が必要なら、Copilot の外（Git の post-commit フック、ラッパースクリプト、IDE のタスクランナー等）で実現する必要があります。
- **スキルとカスタムエージェントは両対応ですが**、本サイトで教えるリポジトリスコープのパターン（`.github/skills/`、`target` なしのカスタムエージェント）は CLI が主役という前提です。VS Code ユーザーに同等のものを届ける場合は、個人スコープ版（`~/.agents/skills/`、`target: vscode`）を使ってください。

## 混在チームへの導入順

「半分が VS Code、半分が CLI」のロールアウト例:

1. **カスタムインストラクション** — 1 週目。万能。
2. **プロンプトファイル** — 1 週目。万能。
3. **MCP** — 2 週目。1 つのサーバー（filesystem や GitHub MCP）を選び、両方の設定ファイルを配布。
4. **スキル（個人スコープ）** — 3 週目。CLI ユーザーから。VS Code ユーザーには `~/.agents/skills/` 経由で同じスキルを提供。
5. **カスタムエージェント** — 4 週目。CLI ユーザー優先。VS Code 向けには `target: vscode` 版を併用。
6. **フック** — 5 週目以降。**CLI ユーザーのみ**。組織全体の監査用途で使い、VS Code ユーザーが恋しがるようなユーザー向け機能には使わない。

## 関連ページ

- [カスタマイズ概要](../customizations/index.md) — 各レイヤーの詳細。
- [演習](../exercises/index.md) — **トラック A**（Copilot ユーザーなら誰でも）と **トラック B**（CLI が必要）に分けたラボ集。
- [ファイル配置](file-layout.md) — すべてのカスタマイズファイルを 1 枚の図で示した一覧。
