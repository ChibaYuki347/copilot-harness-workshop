# CLI コマンドとスラッシュコマンド

`copilot` CLI と、セッション内で使うスラッシュコマンドの実用的なリファレンスです。これは
**自動生成された CLI の一覧** ではなく、実際によく使うものを「なぜ使うのか」とあわせて
まとめた注釈付きガイドです。

!!! tip "一次情報"
    `copilot --help` と、セッション内の `/help` が一次情報です。これらはターミナルのタブに
    固定しておき、このページは **注釈付き** 版として参照してください。

## `copilot` の起動

```bash
copilot                       # interactive session in the current directory
copilot --resume              # resume the most recent session for this dir
copilot --resume <session-id> # resume a specific session
copilot --log-level debug     # verbose logs (in addition to the session log file)
copilot --version             # print version
```

### ヘッドレス / プロンプトモード

```bash
copilot -p "Summarize the last 5 commits"          # one-shot
copilot -p "$(cat my-prompt.md)" --allow-tool=shell
copilot -p "/pr-review"                            # run a slash command headless
```

CI、スクリプト実行、「コミット前の AI チェック」に便利です。プロンプトモードでは、リポジトリ
レベルのフックとワークスペース MCP サーバーは環境変数によって **有効化が制御** されます
（[リファレンス: ファイルレイアウト](file-layout.md#prompt-mode-environment-toggles) を参照）。

### 主なフラグ

| フラグ | 効果 |
|---|---|
| `-p, --prompt <text>` | 1 回のプロンプトを実行して終了します。 |
| `--allow-tool <pattern>` | 確認なしでツールを許可します。glob マッチングに対応し、例: `--allow-tool='shell(npm run test:*)'`。複数パターンを指定するにはフラグを繰り返します。 |
| `--deny-tool <pattern>` | ツールを完全にブロックします。構文は `--allow-tool` と同じです。 |
| `--allow-all` / `--yolo` | **危険です。** すべてのパーミッションプロンプトをスキップします。CI 専用です。 |
| `--allow-all-paths` | `-p` モードで、ディレクトリアクセスの確認をすべて自動承認します。 |
| `--resume [id]` / `--continue` | 最新または特定のセッションを再開します。 |
| `--enable-all-github-mcp-tools` | GitHub MCP の全ツールセットを有効にします。 |
| `--add-github-mcp-toolset <name>` | 1 つの MCP ツールセットを有効にします（例: `issues`）。 |
| `--add-github-mcp-tool <name>` | 名前を指定して 1 つの MCP ツールを有効にします。 |
| `--disable-mcp-server <name>` | この実行に限り、構成済みの MCP サーバーを無効にします。 |
| `--additional-mcp-config <json\|@file>` | 追加の MCP 設定をインラインまたはファイルから注入します（繰り返し指定可。後の指定が前の指定を上書きします）。 |
| `--model <name>` / `--reasoning-effort <level>` / `--effort <level>` | モデルと推論の強度を選択します。 |
| `--agent=<name>` | カスタムエージェントでセッションを実行します。 |
| `--experimental` | 実験的機能（autopilot など）を有効にします。 |
| `--list-env` | `-p` モードで、読み込まれたプラグイン / エージェント / スキル / MCP サーバーを出力します（CI で便利です）。 |

正確なバージョン別一覧は、次を参照してください。

```bash
copilot help            # all CLI flags
copilot help permissions
copilot help environment
copilot help config
copilot help logging
```

## セッション内のスラッシュコマンド

これらは実行中のセッションで `/help` を開くと表示されます。利用頻度の高いものは太字にして
います。ここでは実用的な主要項目だけを載せているので、完全な一覧は `?` を押すか、
CLI で `/help` を実行して確認してください。

### セッションと会話

| コマンド | 内容 |
|---|---|
| **`/help`** | すべてのスラッシュコマンドを表示します。 |
| **`/exit`** | セッションを終了します。 |
| `/clear` | このセッションを破棄し、新しく開始します。 |
| `/new` | 同じワークスペースで新しい会話を開始します。 |
| `/compact` | 古いコンテキストを要約してトークンを空けます。 |
| `/context` | 現在のトークン使用量を可視化します。 |
| `/usage` | セッション統計（プレミアムリクエスト、実行時間、編集行数、モデル別トークン数）を表示します。 |
| `/share` | セッション / リサーチレポートを Markdown、HTML、または gist として共有します。 |
| `/copy` | 直前のレスポンスをクリップボードにコピーします。 |
| `/rewind` / `/undo` | 直前のターンを巻き戻し、ファイル変更を元に戻します。 |
| `/resume` | 別のセッションに切り替えます（id / task id / name）。 |
| `/rename` | 現在のセッション名を変更します（引数がなければ履歴から自動命名します）。 |

### パーミッション

| コマンド | 内容 |
|---|---|
| **`/allow-all`**（別名 **`/yolo`**） | このセッションですべてのパーミッションを有効にします。サブコマンド: `on`, `off`, `show`。 |
| **`/reset-allowed-tools`** | `/allow-all` を取り消し、autopilot のパーミッションダイアログを再度表示させます。 |
| `/add-dir <path>` | ファイルアクセスで許可するディレクトリを追加します。 |
| `/list-dirs` | 許可済みディレクトリをすべて表示します。 |
| `/cwd <path>` | 作業ディレクトリを変更します（別名: `/cd`）。 |

### カスタマイズ

| コマンド | 内容 |
|---|---|
| **`/instructions`** | 読み込み済みのカスタムインストラクションファイルを表示し、オン / オフを切り替えます。 |
| **`/skills`** | スキルの一覧表示、有効 / 無効の切り替え、再読み込みを行います。サブコマンド: `list`, `info`, `add`, `reload`, `remove`。 |
| **`/mcp`** | MCP サーバーを管理します（下記参照）。 |
| **`/agent`** | 利用可能なカスタムエージェントを閲覧して選択します（複数形の `/agents` ではありません）。 |
| `/plugin` | プラグインとプラグインマーケットプレイスを管理します。 |
| `/env` | 読み込まれた環境の詳細（インストラクション、MCP サーバー、スキル、エージェント、プラグイン、LSP、拡張機能）を表示します。 |
| `/lsp` | Language Server の設定を管理します。 |
| `/init` | このリポジトリ向けの Copilot インストラクションを初期化します。 |

### エージェントとサブエージェント

| コマンド | 内容 |
|---|---|
| `/fleet` | fleet モード（サブエージェントの並列実行）を有効にします。 |
| `/tasks` | バックグラウンドタスク / サブエージェントを表示・管理します。 |
| `/sidekicks` | 実行中の sidekick エージェントを表示します。 |
| `/model` | このセッションで使うモデルを選択します。 |
| `/delegate` | このセッションを GitHub に送信し、Copilot に PR を作成させます。 |
| `/plan` | コーディング前に実装計画を作成します。 |
| `/research` | GitHub と Web 検索を使って詳細な調査を実行します。 |
| `/review` | 現在の変更に対して code-review エージェントを実行します。 |
| `/diff` | 現在のディレクトリの変更を確認します。 |
| `/pr` | 現在のブランチの PR を操作します。 |
| `/autopilot` | autopilot モードを切り替えます（実験的）。 |

### ヘルプとメタ機能

| コマンド | 内容 |
|---|---|
| `/feedback` | Copilot チームにフィードバックを送信します。 |
| `/changelog` | CLI の changelog を表示します（`summarize` を付けると AI が要約します）。 |
| `/version` / `/update` | CLI のバージョンを表示 / 更新します。 |
| `/theme` / `/statusline` / `/footer` | UI を調整します。 |
| `/experimental` | 実験的機能を有効 / 無効にします。 |
| `/streamer-mode` | プレビュー版モデル名とクォータ詳細を隠します（画面録画向け）。 |

### `/mcp` のサブコマンド

| コマンド | 内容 |
|---|---|
| `/mcp` | 対話式の MCP ピッカーを開きます。 |
| `/mcp add` | 対話式に新しい MCP サーバーを追加します。 |
| `/mcp show`（または `/mcp`） | 設定済みサーバーとその状態を一覧表示します。 |

起動時に `--disable-mcp-server <name>` を指定して、CLI からサーバーを無効化することもできます。

## 押さえておきたい環境変数

| 変数 | 意味 |
|---|---|
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | インストラクションファイルを追加で走査するディレクトリです。 |
| `COPILOT_AGENT_SESSION_ID` | **フックスクリプトに** 渡されます。セッションを識別します。 |
| `COPILOT_CLI` | フックスクリプトでは `1` に設定されます。共有スクリプトが「Copilot CLI 配下で実行中」であることを判定できます。 |
| `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS` | `=1` を設定すると、プロンプトモードでリポジトリのフックを許可します。 |
| `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` | `=1` を設定すると、プロンプトモードでワークスペース MCP を許可します。 |
| `GITHUB_TOKEN` | GitHub MCP サーバーが参照します。 |

## ログの保存場所

```
~/.copilot/logs/
```

各セッションに 1 つずつログファイルが作成されます。フックや MCP の起動をデバッグする場合は
`--log-level debug` を付けて、最新のファイルを確認してください。

## 関連項目

- [カスタムインストラクション](../customizations/custom-instructions.md)
- [フック](../customizations/hooks.md)
- [MCP](../customizations/mcp.md)
