# 用語集

このサイト全体で使う用語を、1 段落の定義と主な参照先とともにまとめます。

## Agent（エージェント）

Copilot CLI がその役割として動作できる存在です。セッションで対話する「メイン」
エージェントがあり、**サブエージェント** はメインエージェントから（`task` ツール経由で）
起動され、独自のコンテキストウィンドウで限定された作業を担当します。**カスタムエージェント**
は `.github/agents/`（リポジトリ）または `~/.copilot/agents/`（個人用）に置く Markdown
ファイルで、専用のシステムプロンプトとツール許可リストを持つ新しいエージェント識別子を
定義します。

→ [カスタムエージェント](../customizations/agents.md) を参照してください。

## `AGENTS.md`

Copilot CLI だけでなく複数のエージェント系ツールに慣例を伝える、リポジトリルートの
Markdown ファイルです。コミュニティ慣例であり、機能的には
`.github/copilot-instructions.md` に近いですが、ツール間で持ち運べます（Cursor、Codex、
OpenCode、…）。同様に `CLAUDE.md` と `GEMINI.md` も参照されます。

## Built-in agents（組み込みエージェント）

Copilot CLI に同梱されているサブエージェントです。特に有用なのは **`rubber-duck`**
（設計レビュー）、**`code-review`**（未ステージ / ブランチ差分の重点レビュー）、**`explore`**
（並列のコードベース調査）です。これらは `task` ツールで起動します。

## Custom instructions（カスタムインストラクション）

エージェントが自動で読み込むプレーンな Markdown ルールです。リポジトリスコープ
（`.github/copilot-instructions.md`、`AGENTS.md`、`.github/instructions/*.instructions.md`）、
個人スコープ（`~/.copilot/copilot-instructions.md`）、環境変数駆動
（`COPILOT_CUSTOM_INSTRUCTIONS_DIRS`）があります。

→ [カスタムインストラクション](../customizations/custom-instructions.md) を参照してください。

## Fleet mode（fleet モード）

セッション内モードで、`/fleet` で切り替えます。複数のサブエージェントを並列実行する
用途に最適化されています。「サブエージェントを 1 つ実行する」こととは異なり、fleet モードでは
メインエージェントの振る舞いが調整され、振り分けと結果統合を行います。

## Hooks（フック）

`hooks.json` で定義するイベント駆動の shell または HTTP コールアウトです。
`sessionStart`、`sessionEnd`、`preToolUse`、`postToolUse`、`userPromptSubmitted` などで発火
します。**助言的**（単に記録するだけ）にも **ブロッキング**（`permissionDecision: "deny"` を
返す）にもできます。

→ [フック](../customizations/hooks.md)、[フックイベント リファレンス](hook-events.md) を参照してください。

## MCP（Model Context Protocol）

ツールとデータを、型付きかつトランスポート非依存な形で AI エージェントに公開するための
オープンプロトコルです。Copilot CLI は `.mcp.json`（リポジトリ）または
`~/.copilot/mcp.json`（個人用）で構成された MCP サーバーをサポートします。トランスポートは
`stdio`、`http`、`sse` です。

→ [MCP](../customizations/mcp.md) を参照してください。

## Prompt file（プロンプトファイル）

`*.prompt.md` ファイルで、配置場所は `.github/prompts/`（または個人用の同等パス）配下です。
スラッシュコマンドになり、`release.prompt.md` → `/release` のように使えます。これは
「保存されたプロンプト」であり「スキル」ではありません。ワークフローの段階も、必須の出力
契約もありません。

→ [プロンプトファイル](../customizations/prompt-files.md) を参照してください。

## Prompt mode（プロンプトモード）

ヘッドレスモード（`copilot -p '...'`）です。1 つのプロンプトを入力し、レスポンスを
受け取り、終了します。CI やスクリプト実行に使います。ワークスペースを信頼する機能
（リポジトリフック、ワークスペース MCP）は、未信頼コードが自動実行されないように環境変数で
有効化が制御されます。

## Permission（パーミッション）

エージェントがツールを（指定した引数で）呼び出すための許可です。パーミッション
プロンプトで対話的に付与することも、`--allow-tool`、`.copilot/config.json`、フックで
事前承認することもできます。現在のセッションですべての確認を省略するには `/allow-all`
（別名 `/yolo`）を使い、取り消すには `/reset-allowed-tools` を使います。フックは
`permissionDecision` フィールドで個別のパーミッション要求を短絡できます。

## Ask モード

チャットだけのホストモード。あなたが聞き、モデルが答え、diff を提案することもあるが、
**自律的なアクションはしない**。VS Code Copilot Chat サイドバー、GitHub.com、
モバイルの既定。Ask と Agent の橋渡しは
[Ask モードと Agent モード](../getting-started/ask-vs-agent.md)。

## Agent モード

Copilot があなたの代わりに **アクションを取る** モード: ファイル読み取り、編集、
`bash` 実行、MCP ツール呼び出し、失敗時のリトライ。Copilot CLI の既定、VS Code
Copilot Chat はモードドロップダウンからオプトイン。事前許可されていない
限り全アクションは承認プロンプトを通る。

## Plan モード

CLI のサブモード (`Shift+Tab` で循環)。Copilot は **アクションを取らず**、
明確化質問と構造化プランの提案だけを行う。複数ファイルにわたる変更を任せる前に
有用。

## Edit モード

CLI のサブモード (`Shift+Tab` で循環)。**既知の一連のファイルに対する機械的な
編集** に最適化 — 「考えさせて」ループを減らし、直接ファイルを書く。Plan や
default ほど日常的ではない。

## Auto-approve（自動承認）

ツールのパーミッション判断が事前に与えられた状態 — セッション全体
(プロンプトの `A`llways allow、起動時 `--allow-tool '<tool>(<args>:*)'`、
VS Code の `chat.tools.autoApprove`)、または `permissionDecision: "allow"` を
返す hook によって。反対は **always-ask** — allow-list 上でもプロンプトを強制。

## MCP client（MCP クライアント）

MCP ツールを **呼び出す** 側 — 本ドキュメントの文脈では Copilot 自体。CLI と
VS Code Copilot Chat の両方に組み込み MCP クライアントが入っている。

## MCP server（MCP サーバー）

MCP ツールを **提供する** 側 — typed なツール一覧を公開し各コールを処理する別
プロセス (stdio) またはエンドポイント (http)。GitHub MCP サーバーは Copilot CLI に
バンドル。カスタムサーバーは `.mcp.json` (CLI) や `.vscode/mcp.json` (VS Code) に。

## Tool / Skill / Agent / Instruction の違い

よく混同される。クイック整理:

| 概念 | 何か | エージェントが使う条件 | 誰が書く |
|---|---|---|---|
| **Instruction** | 常時ロードされる散文 (`.github/copilot-instructions.md`) | 毎セッション、毎ターン | リポ / 個人 |
| **Skill** | 必要時にロードされる文書化された手順 (`SKILL.md`) | ユーザー意図が `description` にマッチしたとき | リポ / 個人 |
| **Tool** | エージェントが呼べる原子的能力 (`bash`、`view`、MCP 提供) | モデルが判断したとき | 組み込み or MCP サーバー |
| **Agent** | 専用 system prompt と tool allowlist を持つペルソナ (`.agent.md`) | `task` で委譲、または `/agent` で起動 | リポ / 個人 / 組み込み |

→ Instructions と Skills は Tools や Agents と競合しない — エージェントが
それらをどう使うかを形作る。

## Sidekick（サイドキック）

メインセッションと並行して動く、長時間実行の補助エージェントです（確認は `/sidekicks`）。
たとえば前景で機能実装を進めながら、背景で watcher エージェントにテスト失敗を修正させる、
といった使い方ができます。

## Skill（スキル）

`SKILL.md`（YAML フロントマター付き）として `.github/skills/<name>/` 配下で定義する、
再利用可能でモデル可読な手順です。スキルの `description` に基づいて **必要時にだけ**
読み込まれます。定義済みの出力契約を伴う複数段階ワークフローに向いています。

→ [スキル](../customizations/skills.md) を参照してください。

## Sub-agent（サブエージェント）

別のエージェントのセッションから起動されるエージェントです。`task` ツールがこれを
起動します。各サブエージェントは独自のコンテキストウィンドウで動作します。サブエージェントは
組み込み（`rubber-duck`、`code-review`、`explore`）にも、カスタム
（`.github/agents/` 配下のファイル）にもできます。

## Tool（ツール）

Copilot CLI が呼び出せる機能です。`view`、`edit`、`create`、`grep`、`glob`、
`bash`、`task`、MCP サーバーが提供するツールなどがあります。すべてのツール呼び出しで
パーミッション判断が必要になる場合があり、そこに `preToolUse` フックが差し込みます。

## Workspace trust（ワークスペース信頼）

「このワークスペースのカスタマイズは安全に読み込めるか」という CLI の考え方です。
clone した直後の初回実行では、信頼するか確認されることがあります。特にプロンプトモードで、
リポジトリの `.mcp.json` や `.github/hooks/` をいつ反映するかに影響します。

## 関連項目

- [ファイルレイアウト リファレンス](file-layout.md) — これらが *どこに* 置かれるか。
- [CLI コマンド リファレンス](cli-commands.md) — それらを *どう使うか*。
