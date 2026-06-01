# VS Code と Copilot CLI — どこで何が動くか

このサイトは **ハーネス（カスタマイズの仕組み）** がテーマであり、ホストツール自体ではありません。ここで紹介するカスタマイズは **ほぼすべて** VS Code の GitHub Copilot 拡張と Copilot CLI の **両方** で動きます。両ホストは主要なレイヤー（`.agent.md` / `*.instructions.md` / `*.prompt.md` / `SKILL.md` / `hooks.json`）で **同じファイル形式を共有** しています。違いは「どこを探すか」「どの UI で見せるか」「Preview か GA か」だけです。

!!! info "このページの目的"
    Copilot を導入中のチームから「VS Code 派と CLI 派が混在しているが、どのカスタマイズを共有できるのか」とよく聞かれます。短い答えは **ほぼすべて共有できます**。長い答えが下の表です。

## ひと目で分かる対応表

| カスタマイズ | VS Code（Copilot Chat / Agent モード） | Copilot CLI | 設定ファイルは共有？ |
|---|---|---|---|
| [カスタムインストラクション](../customizations/custom-instructions.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/copilot-instructions.md` |
| [パス指定インストラクション (`applyTo`)](../customizations/custom-instructions.md#path-specific) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/instructions/*.instructions.md` |
| [プロンプトファイル](../customizations/prompt-files.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/prompts/*.prompt.md` |
| [スキル](../customizations/skills.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/skills/<name>/SKILL.md`（`.agents/skills/` / `.claude/skills/` も可） |
| [MCP サーバー](../customizations/mcp.md) | 🟢 対応 | 🟢 対応 | ⚠️ ファイルは別、**プロトコルは同じ** — 移行期間は両方配布 |
| [カスタムエージェント](../customizations/agents.md) | 🟢 対応 | 🟢 対応 | ✅ 同じ `.github/agents/<name>.agent.md` — スキーマは相互運用可能[^agent-compat] |
| [フック](../customizations/hooks.md) | 🟢 対応（Preview）[^hooks-preview] | 🟢 対応 | ✅ 同じ `.github/hooks/*.json` 形式（Claude Code 互換） |

凡例: 🟢 完全対応 · 🟡 制約付き対応 · ❌ 非対応。

[^agent-compat]: 上流の `microsoft/vscode-copilot-chat` 設計ノートによれば、CLI 向けに書いた `.agent.md` は VS Code で開いても **だいたいそのまま動く**。違うのは *ツール参照名* くらい（CLI は組み込みの `task` ツール、VS Code は `agent` エイリアスとピッカー経由のサブエージェント解決）。
[^hooks-preview]: 公式ドキュメント [VS Code Hooks](https://code.visualstudio.com/docs/copilot/customization/hooks) のとおり、VS Code 側のフックは引き続き Preview です。CLI と同じ JSON スキーマ・同じイベント名を VS Code が読み込みます。組織のエンタープライズポリシーで VS Code のフックが無効化されている可能性もあるため、`chat.hookFilesLocations` 設定と管理者の Copilot ポリシーを確認してから本番運用してください。

## 設定ファイルの場所を並べて比較

各ツールが **読み込む** 設定の場所:

| 設定対象 | VS Code 拡張 | Copilot CLI |
|---|---|---|
| リポジトリ全体のインストラクション | `.github/copilot-instructions.md`（または `AGENTS.md`） | `.github/copilot-instructions.md`（`AGENTS.md` / `CLAUDE.md` も読む） |
| パス指定インストラクション | `.github/instructions/<name>.instructions.md` | `.github/instructions/<name>.instructions.md`[^cli-vscode-instr] |
| プロンプトファイル | `.github/prompts/<name>.prompt.md` | `.github/prompts/<name>.prompt.md` |
| 個人スキル | `<user profile>/skills/`（Settings Sync）、`~/.copilot/skills/`、`~/.claude/skills/`、`~/.agents/skills/` | `~/.copilot/skills/`、`~/.agents/skills/`、`~/.claude/skills/` |
| リポジトリスキル | `.github/skills/<name>/SKILL.md`（`.agents/skills/` / `.claude/skills/` も読む） | `.github/skills/<name>/SKILL.md`（同様の代替パス対応） |
| MCP サーバー（ワークスペース） | `.vscode/mcp.json`（`"servers"` キー） | `.github/mcp.json` または `.mcp.json`（`"mcpServers"` キー） |
| MCP サーバー（個人） | VS Code 設定 `mcp.servers`（ユーザースコープ） | `~/.copilot/mcp-config.json` |
| カスタムエージェント | `.github/agents/<name>.agent.md`（ワークスペース）または `<user profile>/agents/` | `.github/agents/<name>.agent.md`（ワークスペース）または `~/.copilot/agents/` |
| フック | `.github/hooks/*.json`（ワークスペース）、`~/.copilot/hooks` または `~/.claude/settings.json`（ユーザー） | `.github/hooks/*.json`（ワークスペース）、`~/.copilot/hooks/`（ユーザー）、プラグインのフックも |

[^cli-vscode-instr]: CLI は VS Code 互換のため `.vscode/copilot.instructions.json` も読みます。つまり VS Code で書いた指示構成はリネーム不要で CLI に持ち込めます。出典: 上流 `copilot-agent-runtime` の `readVSCodeInstructions` / `readVSCodeInstructionFiles`。

!!! note "MCP: 同じプロトコル、2 つの設定ファイル"
    両ホストとも MCP を話します。**プロトコルの意味論は同じ** ですが、読み込むファイルと JSON のトップキーが異なります:

    | ホスト | ファイル | トップレベルキー | 環境変数記法 |
    |---|---|---|---|
    | Copilot CLI | `.github/mcp.json` または `.mcp.json`（プロジェクト） | `"mcpServers"` | `${ENV_VAR}` |
    | VS Code | `.vscode/mcp.json`（ワークスペース） | `"servers"` | `${env:ENV_VAR}` |

    混在チームは移行期間中、**両方** のファイルを配布してください（あるいは片方からもう片方を生成する小さなスクリプトを書く）。詳しい例は [MCP カスタマイズページ](../customizations/mcp.md) を参照。

## スラッシュコマンド対応表

CLI はスラッシュコマンド（`/instructions`、`/skills` など）で現在のセッションに読み込まれているものを表示します。VS Code はコマンドパレットや Chat ビューを使います。大まかな対応関係:

| やりたいこと | Copilot CLI | VS Code |
|---|---|---|
| 有効なカスタムインストラクションを確認 | `/instructions` | Chat → `@workspace /instructions`（またはファイルを直接開く） |
| 検出されたスキルを確認 | `/skills` | **Chat: Open Customizations**（コマンドパレット）→ Agent Customizations editor |
| 検出された MCP サーバーとツールを確認 | `/mcp show` | Chat ビューの MCP サーバーパネル |
| カスタムエージェントを選択 | `/agent` | Chat ビュー下部のエージェントピッカー |
| すべての読み込み内容を確認 | `/env` | Agent Customizations editor（Preview） |
| プロンプトファイルを実行 | `/<プロンプトファイル名>` | Chat → `/<プロンプトファイル名>`（記法は同じ） |
| フックの実行を確認 | `/hooks show` および `~/.copilot/logs/` | **GitHub Copilot Chat Hooks** 出力チャンネル |

## 実務での指針

- **ほぼすべてが共通。** カスタムインストラクション・プロンプトファイル・スキル・カスタムエージェント・フックはすべて両ホストで同じファイルを使います。片方のために構築したハーネスがもう片方でも効きます。
- **MCP は両対応だが設定ファイルが違う。** プロトコルは同じ。移行期間は `.vscode/mcp.json`（VS Code、`servers`）と `.mcp.json`（CLI、`mcpServers`）の両方を配布してください。CLI は `.github/mcp.json` も受け付けます。
- **フックは両ホスト対応に（VS Code は Preview）。** CLI の方がより成熟（豊富なイベント、テンプレート変数）ですが、同じ `.github/hooks/*.json` を VS Code ユーザーが置けば同じフックが発火します。
- **スラッシュコマンド UX は CLI 固有。** 検出系コマンド（`/skills` / `/instructions` / `/mcp show`）は VS Code では各種パネルや Agent Customizations editor（Preview）に置き換わります。

## 混在チームへの導入順

「半分が VS Code、半分が CLI」のロールアウト例:

1. **カスタムインストラクション** — 1 週目。万能、同じファイル。
2. **プロンプトファイル** — 1 週目。万能、同じファイル。
3. **MCP** — 2 週目。1 つのサーバー（GitHub MCP や filesystem）を選び、両方の設定ファイル（`.vscode/mcp.json` + `.mcp.json`）を配布。
4. **スキル（ワークスペース）** — 3 週目。`.github/skills/<name>/` に `SKILL.md` を置けば両ホストが認識。
5. **カスタムエージェント** — 4 週目。`.github/agents/` 配下の `.agent.md` を共有 — 両ホストで同じファイル形式。CLI は `/agent`、VS Code はエージェントピッカーで提示。
6. **フック** — 5 週目以降。VS Code 対応は Preview。エンタープライズポリシーで許可されているなら `.github/hooks/*.json` を両方に配布。許可されていなければ CLI 側のみに留める。

## 関連ページ

- [カスタマイズ概要](../customizations/index.md) — 各レイヤーの詳細。
- [演習](../exercises/index.md) — **トラック A**（万能、同じファイルが両ホストで動く）と **トラック B**（CLI 主体 — 同じファイルが VS Code でも動くが、ラボは CLI 固有 UX を使う）に分けたラボ集。
- [ファイル配置](file-layout.md) — すべてのカスタマイズファイルを 1 枚の図で示した一覧。
