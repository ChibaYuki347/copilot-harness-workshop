# レシピ: GitHub MCP サーバー

**まず既定の GitHub MCP サーバーを使い、その後にプライベートなものを追加します。**

## 課題

Issue の参照、PR へのコメント、org メタデータの照会を行いたいものの、
毎回 `gh` を実行するためにシェルへ戻るのは避けたい場面があります。さらに **型付き** の
ツール呼び出しを使えれば、モデルにはスキーマ検証済みの引数が渡されます。

## 使うレイヤー

- **MCP**（組み込みの `github-mcp-server` と、追加したカスタムサーバー）。

## パート 1 — 組み込みの GitHub MCP サーバー

朗報です。すでに利用できます。確認しましょう:

```text
/mcp show
```

`github-mcp-server` が一覧に表示されます。`github/copilot-cli` の README には、
次のようにあります:

> 「MCP による拡張性: コーディングエージェントには GitHub の MCP サーバーが既定で含まれており、
> カスタム MCP サーバーにも対応しています。」

既定のスコープは、CLI 自体と同じ認証を使う GitHub アカウントです。

### 利用できる機能

GitHub MCP サーバーは、次のためのツールを公開します:

- Issues: 一覧、参照、コメント、ラベル付け。
- Pull requests: 一覧、参照、差分、レビュー、マージ。
- Repositories: 検索、ファイル内容の取得、コミット一覧。
- Actions: ワークフロー一覧、実行の取得、ログの取得。
- Copilot Spaces と Copilot Extensions の関連機能（利用できる場合）。

これらを覚える必要はありません。Copilot が自動で選びます。次のように伝えるだけです:

```text
List the 5 most recently updated issues labeled "bug" and group them by the file
mentioned most often in their bodies.
```

### ツールセットの制御

起動時のフラグで、公開するツールを絞り込めます:

```bash
copilot --enable-all-github-mcp-tools     # widest surface
copilot --add-github-mcp-toolset issues   # subset
copilot --add-github-mcp-tool issue_read  # single tool
```

（正確なフラグ名は CLI の changelog を確認してください。最近のバージョンでは
安定しています。）

## パート 2 — プライベート MCP サーバーを追加する

Node ベースの MCP サーバーを持つ社内の「deploys」サービスがあるとします。これを
**git ルート** の `.mcp.json` に追加します:

```json
{
  "mcpServers": {
    "deploys": {
      "type": "stdio",
      "command": "node",
      "args": ["./tools/deploys-mcp/server.js"],
      "env": {
        "DEPLOYS_API_TOKEN": "${DEPLOYS_API_TOKEN}"
      }
    }
  }
}
```

セッションを再起動するか `/mcp reload` を実行し、次を確認します:

```text
/mcp show
```

`deploys` が `connected` ステータスで表示されるはずです。以後、エージェントは
そのツールを名前で呼び出せます: *「`deploys` サーバーを使って、`payments-api` の保留中デプロイを一覧してください。」*

## パート 3 — リモート HTTP MCP サーバー

自分で管理するリモートサービスの場合:

```json
{
  "mcpServers": {
    "kb-search": {
      "type": "http",
      "url": "https://kb.internal.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${KB_TOKEN}"
      }
    }
  }
}
```

リモート HTTP MCP サーバーは[^retry] **一時的なネットワーク障害時に自動再試行** されるため、
不安定なネットワークでもセッションが台無しになりにくくなります。

[^retry]: changelog には次のようにあります: *「MCP のリモートサーバー接続は、一時的な
    ネットワーク障害時に自動で再試行されます。」*

## OAuth で保護されたサーバー

MCP サーバーで OAuth が必要な場合は、次を実行します:

```text
/mcp auth <name>
```

Copilot はブラウザーを開きます。ヘッドレス環境では **device code flow** にフォールバック
するため、WSL、SSH、devcontainers でも動作します。

## 削除せずに無効化する

`.mcp.json` からサーバーを消さなくても無効化できます:

```text
/mcp disable kb-search
```

この設定は、`/mcp enable kb-search` を実行するまでセッションをまたいで保持されます。

## 落とし穴

- **シークレットをインラインで書かない。** `${VAR}` を使い、必要な環境変数は
  `README.md` に記載します。
- **起動が長いとセッションも遅い。** 初期化に 5 秒かかるサーバーは、毎回の
  セッション開始を遅らせます。重い依存関係は HTTP サーバーに寄せるか、事前ウォームアップを検討します。
- **ワークスペース MCP の読み込み順序。** `.mcp.json` のワークスペースサーバーは
  **フォルダーの信頼が確認された後にのみ** 読み込まれます。新規 clone 直後の最初の
  プロンプトから利用できるとは限りません。
