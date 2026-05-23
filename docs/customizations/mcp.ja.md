# 🔌 MCP サーバー

**Model Context Protocol 経由で、独自のツールをエージェントに接続します。**

!!! abstract "対応ホスト"
    🟢 **Copilot CLI**（プロジェクト: `.github/mcp.json` または `.mcp.json`、ユーザー: `~/.copilot/mcp-config.json`） · 🟢 **VS Code**（Preview — `.vscode/mcp.json` ワークスペース + `settings.json` の `mcp.servers` ユーザースコープ）。**MCP プロトコルは同じ** ですが、ファイルの場所とトップレベル JSON キーが異なります — CLI は `"mcpServers"`、VS Code は `"servers"`。混在チームでは両方を配布してください。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

MCP（Model Context Protocol）は、モデルが外部ツールとやり取りするためのオープン標準です。
Copilot CLI では **GitHub の MCP サーバーが既定で有効** になっており（Issue の一覧取得や
PR へのコメントなどが可能）、独自サーバーの追加にも対応しています。

## MCP を使う場面

- エージェントが、シェルコマンドではないシステムに読み書きする必要がある。たとえば社内
  CRM、チケット管理ツール、フィーチャーフラグ（feature flag）サービス、SaaS ダッシュボードなど。
- 自由形式の CLI 引数ではなく、*型付き* API（スキーマ付き）を公開したい。
- そのツールを、ほかの MCP 対応ホスト（Claude Desktop、Cursor など）とも共有したい。

## MCP 設定の配置場所

| スコープ | ファイル |
|---|---|
| **リポジトリ（推奨）** | git ルートの `.mcp.json`。コミットされます。 |
| **リポジトリ（代替）** | `.github/mcp.json` — CLI はこのパスも受け付けます。bot 設定をすべて `.github/` 配下に集約したいときに便利。 |
| **個人** | `~/.copilot/mcp-config.json`（`/mcp add` または直接編集で管理）。`$COPILOT_HOME` が設定されていれば、その場所に従います。 |
| **環境変数** | `GITHUB_COPILOT_MCP_JSON` — JSON 文字列を直接渡せます。最優先。CI / 一時的な上書き用途に便利。 |

!!! warning "移行に関する注意（CLI）"
    `.vscode/mcp.json` と `.devcontainer/devcontainer.json` は、CLI では MCP サーバー設定の
    読み込み元として **もう参照されません**。CLI は git ルートの `.mcp.json` または
    `.github/mcp.json`（+ ユーザースコープの `~/.copilot/mcp-config.json`）のみを読みます。
    `.vscode/mcp.json` が見つかってこれらがない場合は、CLI が移行ヒントを表示します。[^migration]
    **VS Code 側は `.vscode/mcp.json` を引き続き使う** ため、混在チームは両方を配布してください。
    下記の [VS Code 版セクション](#vs-code-equivalent) を参照。

[^migration]: `github/copilot-cli` changelog より: *「MCP サーバー設定の読み込み元から
    `.vscode/mcp.json` と `.devcontainer/devcontainer.json` を削除し、CLI は `.mcp.json`
    のみを読むようになりました。`.vscode/mcp.json` が検出され、`.mcp.json` がない場合は、
    移行ヒントが表示されます。」*

## VS Code 版 { #vs-code-equivalent }

VS Code Copilot Chat も MCP を話します（2026-05 時点で Preview）。CLI とは
別のファイル・若干違うスキーマを読みますが、**同じサーバー定義** が動きます。

| 項目 | Copilot CLI | VS Code |
|---|---|---|
| ワークスペース設定 | `.mcp.json` または `.github/mcp.json` | `.vscode/mcp.json` |
| ユーザー設定 | `~/.copilot/mcp-config.json` | VS Code 設定 → `mcp.servers` |
| JSON トップキー | `"mcpServers"` | `"servers"` |
| 環境変数参照 | `${VAR}` | `${env:VAR}` |
| サーバーのライフサイクル | CLI が spawn / IPC | VS Code Workbench が `vscode.lm.startMcpGateway()` で管理 |
| ツール命名 | `mcp__<server>__<tool>` | `<server>/<tool>`（仮想グルーピング後） |
| 認証保管 | OS keychain（`keytar`）+ `~/.copilot/config/mcp-oauth-config/` フォールバック | VS Code Secret Storage / Authentication API |

**同じ MCP サーバーバイナリが両ホストで動きます** — 違うのは設定ファイルだけ。

```jsonc
// .vscode/mcp.json (VS Code) — 上の .mcp.json と等価
{
  "servers": {
    "linear": {
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": { "LINEAR_API_KEY": "${env:LINEAR_API_KEY}" }
    }
  }
}
```

混在チームは、移行期間中 `.mcp.json` と `.vscode/mcp.json` の **両方をコミット** し、
同じサーバーリストを保ってください。小さな `npm run sync-mcp` で片方からもう片方を
生成すると同期が楽です。公式 VS Code ドキュメント:
[Use MCP servers in VS Code (Preview)](https://code.visualstudio.com/docs/copilot/chat/mcp-servers)。

## 最小例 — `.mcp.json`

```json
{
  "mcpServers": {
    "linear": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@linear/mcp-server"],
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    },
    "internal-search": {
      "type": "http",
      "url": "https://mcp.internal.example.com/search",
      "headers": {
        "Authorization": "Bearer ${INTERNAL_MCP_TOKEN}"
      }
    }
  }
}
```

一般的なのは次の 2 種類のトランスポートです。

| トランスポート | 使いどき |
|---|---|
| `stdio` | ローカルプロセス（`npx`、`uvx`、バイナリ）。CLI がプロセスを起動し、stdio 上で JSON-RPC をやり取りします。 |
| `http`（または `sse`） | リモートサービス。CLI は JSON-RPC 呼び出しごとに HTTP エンドポイントへアクセスします。 |

`${VARNAME}` 参照は、`command`、`args`、`env`、`cwd`、`headers` で使うと、
**環境変数から自動的に解決** されます。[^envref]

[^envref]: changelog より: *「command、args、cwd フィールドで参照された MCP
    サーバーの環境変数は、自動的にサーバー環境へ含まれるようになりました。」*

## CLI で MCP サーバーを管理する

```text
/mcp                  # interactive picker
/mcp add              # add a new MCP server interactively
```

起動ごとにサーバーを無効化するには:

```bash
copilot --disable-mcp-server <name>     # turn off one configured server
copilot --disable-builtin-mcps          # turn off bundled servers (e.g., the GitHub MCP)
```

起動時に設定をその場で追加するには:

```bash
copilot --additional-mcp-config '{"mcpServers":{"my-tool":{"type":"stdio","command":"./tool"}}}'
copilot --additional-mcp-config @./overrides.mcp.json
```


shell からは、`copilot mcp` サブコマンドでサーバーをプログラム的に管理できます。

## 認証パターン

- **環境変数の API キー。** もっとも簡単です。`${VAR}` を `env:` で参照します。
- **OAuth（対話型）。** Copilot がブラウザーを開きます。ヘッドレスモード環境では
  **device code（RFC 8628）** にフォールバックします。[^devicecode]
- **OAuth（`client_credentials`）。** 完全なヘッドレスモード / CI 用途に対応しています。
- **Microsoft Entra ID。** 対応しており、ログインのたびに同意画面を出さない構成も可能です。

[^devicecode]: changelog より: *「ヘッドレスモードおよび CI 環境の MCP OAuth 向けの
    フォールバックとして、device code flow（RFC 8628）が追加されました。」*

## セキュリティとポリシー

- 組織は利用可能な MCP サーバーを **許可リスト（allowlist）** で制限できます。ポリシーで
  ブロックされたサーバーがある場合、CLI は警告を表示し、`/mcp show` には出しません。
- サーバーは **LLM サンプリング（LLM sampling）**（Copilot のモデルに代理推論を依頼すること）を要求
  できます。その場合はレビュー用プロンプトで承認が求められます。

## 試してみる

まず試すなら、既定の `github-mcp-server` がもっとも手軽です。セッション内で次を
実行します。

```text
/mcp show
```

`github-mcp-server` が一覧に表示されます。続けて次を試します。

```text
List the 5 most recent open issues in this repo and group them by label.
```

エージェントは、その要求を満たすために GitHub MCP サーバーのツールを呼び出します。

## 検出と MCP レジストリ

Copilot CLI は、ガイド付き設定によって **レジストリから MCP サーバーをインストール**
できます。セッション内で `/mcp` を実行し、ピッカーに従います。`.mcp.json` を手で書く前の
導入手段として扱いやすい方法です。

## 落とし穴

!!! warning "よくある MCP のつまずき"
    - **セッションごとにサーバーを起動すると遅くなります。** 起動の重いサーバー
      （依存関係の多い Python パッケージなど）は、Copilot の起動すべてを遅くします。
      長時間稼働するサービスとして `http` MCP サーバーを動かす構成も検討します。
    - **スキーマの甘さ。** 標準外の JSON Schema を使う MCP ツールは、互換性問題の
      原因になります。ツールのスキーマは検証します。
    - **`.mcp.json` にシークレットを書く。** トークンのリテラルは **絶対に** 埋め込まず、
      `${VAR}` を使って README に必要な環境変数を記載します。
    - **信頼確認後に読み込み。** `.mcp.json` のワークスペース MCP サーバーは、
      フォルダーの信頼確認後にのみ読み込まれます。

## 確認方法

```text
/env       # shows loaded MCP servers and their status
/mcp show  # detailed view including reconnection state
```

## 次へ

→ [🤖 カスタムエージェント](agents.md) — タスク専用の *エージェント全体* を用意したい
場合に進みます。
→ レシピ: [GitHub MCP サーバー](../recipes/github-mcp-server.md) — 実例を見たい場合はこちらです。
