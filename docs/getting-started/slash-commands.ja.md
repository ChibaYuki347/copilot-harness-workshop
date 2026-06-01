# スラッシュコマンド入門

スラッシュコマンドは Copilot CLI を操作するための基本インターフェースです。入力の先頭に
`/command` を書くと起動します。

完全な一覧は、どのセッションでも `/help` を実行すると表示できます。以下では、
エージェントを **カスタマイズ** するときによく使うものを絞って紹介します。

## 環境と状態

| コマンド | 内容 |
|---|---|
| `/env` | 読み込まれているすべてのインストラクション、MCP サーバー、スキル、エージェント、プラグイン、LSP サーバーを表示します。**「なぜカスタマイズが反映されないのか」を調べるときに最初に実行するコマンドです。** |
| `/context` | コンテキストウィンドウのトークン使用量を可視化します。 |
| `/compact` | 履歴を要約してコンテキスト予算を空けます。 |
| `/init` | 現在のリポジトリ向けに `.github/copilot-instructions.md` のひな形を生成します。 |
| `/instructions` | 個別のインストラクションファイルを表示し、切り替えます。 |

## カスタマイズの管理

| コマンド | 内容 |
|---|---|
| `/skills` | スキルを一覧表示し、有効 / 無効を切り替えたり、新しいものを `add` したりします。 |
| `/mcp` | MCP サーバーを管理します（`show`, `enable`, `disable`, `auth`, `reload`）。 |
| `/agent` | 次のターンに使うカスタムエージェントを参照して選択します。 |
| `/plugin` | プラグインマーケットプレイスを管理します。 |
| `/lsp` | LSP サーバーを表示 / 設定します。 |

## コードワークフロー

| コマンド | 内容 |
|---|---|
| `/plan` | コーディング前に実装計画を作ります（`Shift+Tab` でも可）。 |
| `/diff` | このセッションでエージェントが行った変更を確認します。 |
| `/review` | 変更差分に対して組み込みのコードレビューエージェントを実行します。 |
| `/pr` | 現在のブランチの PR を操作します。 |
| `/delegate` | タスクをクラウド上の Copilot に渡します。PR が非同期で開かれます。 |
| `/undo` | 直前のターンを巻き戻します（ファイル編集も含みます）。 |
| `/rewind` | `/undo` と同じです。 |

## マルチエージェント / 並列実行

| コマンド | 内容 |
|---|---|
| `/fleet` | 並列のサブエージェント実行に使う **fleet mode** を有効にします。 |
| `/tasks` | バックグラウンドタスク（サブエージェントとシェルコマンド）を表示・管理します。 |
| `/sidekicks` | 実行中のサイドキックエージェントを表示します。 |

## セッション

| コマンド | 内容 |
|---|---|
| `/resume` | 別のセッションに切り替えます（ID、タスク ID、または名前で指定します）。 |
| `/share` | セッションを Markdown、HTML、または GitHub gist にエクスポートします。 |
| `/chronicle` | セッション履歴のインサイトを表示します。 |
| `/remote` | GitHub Web / mobile からのリモート操作を切り替えます。 |

## パーミッション

| コマンド | 内容 |
|---|---|
| `/allow-all` | このセッションのすべてのパーミッション（ツール、パス、URL）を有効にします。**危険です** — [セキュリティに関する注意](#permissions) を読んでください。 |
| `/add-dir` | ファイルアクセスを許可するディレクトリを追加します。 |
| `/reset-allowed-tools` | セッションのツール許可リストをリセットします。 |

## インライン修飾子（スラッシュコマンドではありませんが便利です）

| トークン | 効果 |
|---|---|
| `@path` | ファイル内容をプロンプトに含めます。 |
| `#123` | Issue または PR を参照します。 |
| `!cmd` | シェルで `cmd` を実行し、その出力を使います。 |

## パーミッション { #permissions }

Copilot は **シェルツールに対してデフォルト拒否（deny-by-default）** です。セッションで許可していない限り、
すべてのコマンドで承認が必要です。承認プロンプトには次が表示されます:

1. 実行される正確なコマンドライン。
2. 実行される cwd。
3. 2 つの yes オプション（「yes once」と「yes for this session」）と、指示を返せる
   no オプション。

`/allow-all` は `sudo` と同じ感覚で扱います。影響範囲を把握しているときだけ使います。

## VS Code Copilot Chat — 対応する操作 { #vscode-equivalents }

上のテーブルは **Copilot CLI** のコマンドです。VS Code Copilot Chat も同じ機能を
提供しますが、サーフェスが異なります — `settings.json` の設定、Chat パネルのボタン、
専用 VS Code コマンド（**Command Palette → `Chat: ...`**）のいずれかになります。

| CLI スラッシュコマンド | VS Code 対応 | 補足 |
|---|---|---|
| `/help` | **Chat: View Help** コマンド、または Chat ヘッダの `?` ボタン | |
| `/env` | **Chat: Show Configuration** + Chat の **「View tools」** ドロップダウン | 現セッションでロードされた instructions / agents / MCP servers / tools を表示 |
| `/context` | Chat 入力欄のトークン使用量バッジ | ホバーで内訳 |
| `/compact` | **Chat: Start New Chat**（持ち越し無効化） | VS Code は履歴を in-place で要約しない。新しいチャットを始める |
| `/init` | **GitHub Copilot: Generate Instructions** コマンド | `.github/copilot-instructions.md` を生成 |
| `/instructions` | Settings → `github.copilot.chat.codeGeneration.useInstructionFiles`（トグル） + Chat 入力欄の **「Instructions」** ピッカー | ファイル毎の有効/無効はピッカーで |
| `/skills` | **Chat: Manage Skills** コマンド | `.github/skills/` のスキルは自動ロード、このコマンドで有効/無効切り替え |
| `/mcp` | `.vscode/mcp.json`（プロジェクト） + Settings → `mcp.servers`（ユーザー） + **MCP: List Servers** コマンド | VS Code は別の設定ファイルを使うが、ランタイムの振る舞いは同じ。[MCP](../customizations/mcp.md#config-locations) 参照 |
| `/agent` | Chat ヘッダの **agent ピッカー**（モード横のドロップダウン） | `.github/agents/*.agent.md` のカスタムエージェントが自動表示 |
| `/plan`（Plan mode） | Chat ヘッダの **Plan mode** トグル（「Ask」「Edit」「Agent」の隣） | 同じ概念、UI が違うだけ。[Ask vs Agent](./ask-vs-agent.md) 参照 |
| `/diff` | Agent モードでファイル編集時に自動で開く **diff ビュー** | 明示コマンド不要、編集毎に diff が開く |
| `/review` | **GitHub Copilot: Review Selection / Review Changes** コマンド | 同じ code-review agent を使う |
| `/pr` | **GitHub Pull Requests** 拡張のパネル（別拡張） | Copilot Chat のコマンドではない、Copilot Chat がこの拡張のコマンドを *使う* |
| `/undo` / `/rewind` | 影響を受けた各ファイルでの標準 **VS Code Undo**（Ctrl/Cmd+Z） | Chat はトランザクション巻き戻しがない、ファイル毎に undo |
| `/fleet`、`/tasks`、`/sidekicks` | **VS Code には直接対応なし** | 並列サブエージェント fan-out は今のところ CLI 専用 |
| `/resume` | **Chat: Open Chat...** ピッカー（最近のチャット） | |
| `/share` | **Chat: Export...** コマンド（Markdown / クリップボード） | |
| `/allow-all` | Settings → `chat.tools.autoApprove`（boolean） | 同じリスクプロファイル、同じアドバイス — deny-list hook とペアで使う |
| `/add-dir` | Workspace trust ダイアログ（フォルダごとに 1 回） | VS Code の workspace-trust プロンプトがカバー |
| `/reset-allowed-tools` | **Chat: Reset Trusted Tools** コマンド | |
| `@path` | Chat 入力欄の **`#file:path/to/file`** | プレフィクス文字が違うだけ、効果は同じ |
| `#123` | Chat 内の **`#issue:123`** または **`#pr:123`** | プレフィクスで明示 |
| `!cmd` | Chat 入力欄では直接サポートなし | Agent モードでコマンドを実行させる |

!!! tip "迷ったら Command Palette"
    Copilot Chat の機能はほぼすべて、**Chat: ...**、**GitHub Copilot: ...**、または
    **MCP: ...** のいずれかの Command Palette エントリです。上にない CLI スラッシュ
    コマンドは、キーワードでパレット検索すれば大抵対応物が見つかります。

## プログラマティックモード

CI やスクリプトでは、**ヘッドレスモード** を使います:

```bash
copilot -p "Summarize the diff between main and HEAD" --allow-tool='shell(git)'
```

`--allow-tool` の構文とすべてのフラグは `copilot --help` を参照してください。

→ [カスタマイズ概要](../customizations/index.md)
