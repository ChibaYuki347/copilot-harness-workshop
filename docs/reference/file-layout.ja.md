# ファイルレイアウト リファレンス

Copilot CLI が参照する場所を 1 ページにまとめたものです。スコープの「repo」は
ワークスペース内で検出されること、「personal」はホームディレクトリ、「env」は
環境変数で制御されることを示します。

## カスタムインストラクション

| パス | スコープ | 形式 |
|---|---|---|
| `.github/copilot-instructions.md` | repo（リポジトリごとに 1 つ） | Markdown |
| `.github/instructions/**/*.instructions.md` | repo（再帰的） | `applyTo` を含む Markdown + YAML フロントマター |
| `AGENTS.md` | repo（存在する場合は `CLAUDE.md`、`GEMINI.md` も。git root と cwd の両方） | Markdown |
| `~/.copilot/copilot-instructions.md` | personal | Markdown |
| `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` に列挙したディレクトリ | env | `AGENTS.md` と `.github/instructions/**/*.instructions.md` を対象に走査 |

検出時には cwd から git root までたどり、その過程で見つかった repo スコープのファイルを
読み込みます。personal と env 由来のファイルは常に適用されます。

## プロンプトファイル（スラッシュコマンド）

| パス | スコープ |
|---|---|
| `.github/prompts/*.prompt.md` | repo |
| `~/.copilot/prompts/*.prompt.md` | personal |
| `~/.agents/prompts/*.prompt.md` | personal（ツール横断） |

`release.prompt.md` という名前のファイルは `/release` として呼び出されます。

## スキル

| パス | スコープ |
|---|---|
| `.github/skills/<name>/SKILL.md` | repo |
| `~/.copilot/skills/<name>/SKILL.md` | personal |
| `~/.agents/skills/<name>/SKILL.md` | personal（ツール横断） |

スキルフォルダーには `SKILL.md` と並べて `references/`、`templates/`、ヘルパー
スクリプトなど何でも置けます。モデルはまず `SKILL.md` を読み、残りはスキル側で指示が
あったときだけ読み込みます。

## フック

| パス | スコープ |
|---|---|
| `.github/hooks/<name>/hooks.json` | repo（複数フォルダー可） |
| `~/.copilot/hooks/<name>/hooks.json` | personal |

1 つの `hooks.json` で複数イベントを宣言できます。複数のフックフォルダーは合成され
（すべて実行され）ます。

## MCP

| パス | スコープ |
|---|---|
| `.mcp.json`（git root） | repo |
| `~/.copilot/mcp-config.json` | personal（`$COPILOT_HOME` が設定されていればその場所に従います） |

現行の Copilot CLI では、`.vscode/mcp.json` と `.devcontainer/devcontainer.json` は
MCP 設定ソースとして **もう読み込まれません**[^vscode]。ワークスペースの MCP サーバーは
git root の `.mcp.json`、ユーザーレベルの MCP サーバーは
`~/.copilot/mcp-config.json`（`mcp.json` ではありません）に置きます。

[^vscode]: CLI の changelog より: *「`.vscode/mcp.json` と
    `.devcontainer/devcontainer.json` を MCP サーバー設定ソースから削除し、CLI は
    `.mcp.json` だけを読むようになりました。`.vscode/mcp.json` を `.mcp.json` がない状態で
    検出すると、移行ヒントが表示されます。」*

## カスタムエージェント

| パス | スコープ |
|---|---|
| `.github/agents/<name>.agent.md` | repo |
| `~/.copilot/agents/<name>.agent.md` | personal |
| `agents/<name>.agent.md` がある `.github-private` の org / enterprise リポジトリ | org / enterprise |

正規の拡張子は `.agent.md` です（レガシー / VS Code 互換のため、プレーンな `.md` も
受け付けられます[^agent-ext]）。`security-reviewer.agent.md` という名前のファイルは
エージェント識別子 `security-reviewer` になります。

[^agent-ext]: CLI の changelog より: *「`.agent.md` 接尾辞が付いた VS Code 形式の
    カスタムエージェントの解析が改善されました。」* GitHub ドキュメントでは、名前の既定値は
    「ファイル名（`.md` または `.agent.md` の接尾辞を除く）」とされています。

## プロンプトモードの環境変数トグル { #prompt-mode-environment-toggles }

`copilot -p ...` で Copilot をヘッドレス / プロンプトモードで実行すると、ワークスペースを
信頼する機能は環境変数によって **有効化が制御** されます。

| 変数 | 既定値 | `=1` のときの効果 |
|---|---|---|
| `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS` | 未設定 | `.github/hooks/` のリポジトリレベルのフックが有効になります。 |
| `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` | 未設定 | ワークスペースの `.mcp.json` が読み込まれます。 |

これにより、悪意のある `git clone` をスクリプトから初めて `copilot -p` したときに、フック経由で
任意コードが自動実行されることを防ぎます。

## ツール横断の慣例 (`~/.agents/`)

`~/.agents/` ツリーは、複数のエージェント系ツールで使われているコミュニティ慣例です。
Copilot CLI でも **個人用** のソースとして読み込まれるため、次のように使えます。

- 再利用したいスキル / プロンプト / エージェントは `~/.agents/` 配下に置きます。
- そうすると、それらは Copilot CLI **と** この慣例を尊重する他ツール
  （Cursor、Codex、OpenCode など）で利用できます。

これは、本当にツール非依存な内容を置く場所として最も整理しやすい位置です。

## ログ

```
~/.copilot/logs/
```

セッションごとに 1 ファイルです。フックや MCP サーバーをデバッグする場合は
`--log-level debug` を付けて詳細ログにします。

## 一目で分かるディレクトリマップ

```
.
├── .github/
│   ├── copilot-instructions.md         # team baseline
│   ├── instructions/                   # path-specific (recursive)
│   │   └── **/*.instructions.md
│   ├── prompts/
│   │   └── *.prompt.md
│   ├── skills/
│   │   └── <name>/SKILL.md
│   ├── hooks/
│   │   └── <name>/hooks.json
│   └── agents/
│       └── *.agent.md
├── AGENTS.md                           # alternative to copilot-instructions.md
├── .mcp.json                           # MCP at git root
└── ...
~/
├── .copilot/
│   ├── copilot-instructions.md         # personal baseline
│   ├── prompts/, skills/, hooks/, agents/
│   ├── mcp-config.json                 # personal MCP servers
│   └── logs/
└── .agents/                            # cross-tool shared
    ├── prompts/, skills/, agents/
```
