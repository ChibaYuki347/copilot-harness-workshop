# 🔌 MCP サーバー

**Model Context Protocol 経由で、独自のツールをエージェントに接続します。**

!!! abstract "対応ホスト"
    🟢 **Copilot CLI**（リポジトリルートの `.mcp.json`） · 🟢 **VS Code**（別の設定: `.vscode/mcp.json` または `settings.json`）。CLI は **もう `.vscode/mcp.json` を読みません**。混在チームでは **両方** のファイルを配布してください。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

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
| **リポジトリ** | git ルートの `.mcp.json`。コミットされます。 |
| **個人** | `~/.copilot/mcp-config.json`（`/mcp add` または直接編集で管理）。`$COPILOT_HOME` が設定されていれば、その場所に従います。 |

!!! warning "移行に関する注意"
    `.vscode/mcp.json` と `.devcontainer/devcontainer.json` は、CLI では MCP サーバー設定の
    読み込み元として **もう参照されません**。対象は git ルートの `.mcp.json` のみです。
    `.vscode/mcp.json` が見つかり、`.mcp.json` がない場合は、CLI が移行ヒントを
    表示します。[^migration]

[^migration]: `github/copilot-cli` changelog より: *「MCP サーバー設定の読み込み元から
    `.vscode/mcp.json` と `.devcontainer/devcontainer.json` を削除し、CLI は `.mcp.json`
    のみを読むようになりました。`.vscode/mcp.json` が検出され、`.mcp.json` がない場合は、
    移行ヒントが表示されます。」*

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
