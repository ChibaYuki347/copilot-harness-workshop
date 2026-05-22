# 4 · MCP サーバー

🟡 **中級 · 約30分**

🟪 **トラック A — VS Code でも Copilot CLI でも動作します**（設定ファイルが異なります — ステップ 2.5 参照 · [詳細](../reference/vscode-vs-cli.md)）

## 学習目標

この演習を終えると、次のことができるようになります:

- `.mcp.json` 経由で、ワークスペーススコープの MCP サーバーを追加できるようになります。
- `/mcp show` で接続を確認し、利用できるツールを見られるようになります。
- セッション内で、新しいサーバーのツールを 1 つ使えるようになります。
- 同じセッションを、そのサーバー **だけ**（ほかはすべて無効）に制限できるようになります。

## 前提条件

- スクラッチ用の git リポジトリ。
- `$PATH` に **Node.js** があること（`npx` が動く必要があります）。確認方法: `node --version` が 18 以上。
- 約30分。

!!! tip "この演習では GitHub 認証は不要です"
    `@modelcontextprotocol/server-filesystem` の **filesystem** リファレンスサーバーを使います。これは npm で公開されており、API トークンは不要です。指定したディレクトリにスコープされた read / write ツールを公開するだけなので、サンドボックス用途にぴったりです。

!!! warning "組織の MCP ポリシーを確認してください"
    Copilot Enterprise / Business のテナントによっては、読み込める MCP サーバーが制限されています。手順 3 で `/mcp show` が `notes-fs` を **blocked by policy** と表示した場合は、管理者に確認するか [GitHub Copilot ポリシー ドキュメント](https://docs.github.com/copilot/managing-copilot/managing-copilot-as-an-individual-subscriber/managing-copilot-policies-as-an-individual-subscriber) を参照してください。filesystem サーバーは通常許可されていますが、このレイヤーを土台にする前に確認しておくとよいでしょう。

## チェックポイントコミット

```bash
git commit --allow-empty -m "checkpoint: before mcp exercise"
```

## シナリオ

Copilot に、特定のディレクトリのファイルだけを一覧・読み取りできるようにしたい状況です。リポジトリ全体でも `$HOME` でもなく、自分で制御できるツール経由にしたいので、作業用リポジトリ内の `notes/` フォルダーにスコープした filesystem MCP サーバーを追加します。

## 手順

### 1. MCP サーバーに見せるディレクトリを作成する

```bash
mkdir -p notes
echo "# Meeting Tue" > notes/2026-05-12.md
echo "# Meeting Wed" > notes/2026-05-13.md
```

### 2. `.mcp.json` を追加する

リポジトリルートに `.mcp.json` を作成します:

```json
{
  "mcpServers": {
    "notes-fs": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${PWD}/notes"]
    }
  }
}
```

**確認できる結果**: `cat .mcp.json | jq .mcpServers.notes-fs.type` で `"stdio"` が表示されます。

### 2.5. （VS Code ユーザーのみ）`.vscode/mcp.json` にも同じ設定を書く

🟦 **Copilot CLI を使っている方は、このステップは飛ばしてください。**

CLI は **もう `.vscode/mcp.json` を読みません**。リポジトリルートの `.mcp.json` のみを読みます。一方、VS Code Copilot 拡張は `.vscode/mcp.json` を読みます。両方のホストで同じサーバーを動かしたい場合は、両方のファイルに同じサーバー定義を書きます:

```bash
mkdir -p .vscode
cat > .vscode/mcp.json <<'EOF'
{
  "servers": {
    "notes-fs": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}/notes"]
    }
  }
}
EOF
```

違いに注意:

| | CLI (`.mcp.json`) | VS Code (`.vscode/mcp.json`) |
|---|---|---|
| 最上位キー | `mcpServers` | `servers` |
| パス変数 | `${PWD}` | `${workspaceFolder}` |

VS Code 側では Chat ビュー → MCP サーバーパネルを開くと `notes-fs` が接続済みと表示されるはずです。VS Code 内での確認は、CLI の `/mcp show` に相当します。

### 3. セッションを開始して接続を確認する

```bash
copilot
```

必要に応じてフォルダー信頼を承認します（ワークスペースの MCP サーバーは信頼済みディレクトリでのみ読み込まれます）。そのうえで次を実行します:

```text
/mcp show
```

次のような行が見えるはずです:

```text
notes-fs              connected     tools: read_file, list_directory, …
```

サーバーが出てこない場合は、下のトラブルシューティングを見てください。

### 4. 新しいサーバーのツールを使う

```text
List the files in the notes/ directory and show me what's in the most recent one.
```

エージェントは次のように動くはずです:

1. `notes-fs/list_directory` を呼び出す（初回はパーミッションプロンプトが出ます）。
2. `2026-05-13.md` に対して `notes-fs/read_file` を呼び出す。
3. 内容を表示する。

### 5. このサーバーだけにセッションを制限する（発展的な検証）

セッションを終了し、今度は **`notes-fs` だけ** を有効にした新しいセッションを開始します:

```bash
copilot --allow-tool 'notes-fs/*' --deny-tool '*'
```

この状態では、手順 4 と同じプロンプトは成功する一方で、`Read .github/copilot-instructions.md` は拒否されるはずです（組み込みの `read` ツールが allow-list に入っていないためです）。

## 完了条件 { #definition-of-done }

次の 4 つをすべて満たせば完了です:

- [ ] リポジトリルートの `.mcp.json` に、`type: "stdio"` を持つ `notes-fs` エントリがある。
- [ ] `/mcp show` に `notes-fs` が **connected** として表示される。
- [ ] エージェントに `notes/` の一覧を依頼すると、`notes-fs/list_directory` が呼ばれる。（ツール名はパーミッションプロンプトか `--debug` で確認できます。）
- [ ] `notes/` 内のファイルを読ませると、実際のファイル内容が返ってくる。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    **3 つ** のサーバー（stdio、http、認証不要の filesystem）を含む `.mcp.json` の例です:

    ```json
    --8<-- "examples/mcp/.mcp.json"
    ```

    MCP サーバー種別、環境変数補間、そして既定で有効な組み込み GitHub MCP サーバー（`.mcp.json` 不要）については、[カスタマイズ → MCP サーバー](../customizations/mcp.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .mcp.json notes/
```

## トラブルシューティング

- **`/mcp show` で `notes-fs` が `failed` になる、またはまったく表示されません。**
    - セッション開始時にフォルダー信頼を承認しましたか。ワークスペース MCP サーバーは、信頼されていないディレクトリでは読み込まれません。
    - コマンドを手で試してください: `npx -y @modelcontextprotocol/server-filesystem $PWD/notes`。これが失敗するなら、Copilot ではなく Node / npm のセットアップ問題です。
- **ツール呼び出しが固まります。** npm のプロキシによっては、初回 `npx` ダウンロードがブロックされます。別ターミナルで `npx` コマンドを 1 回実行してキャッシュを温めてから、再試行してください。

## やってはいけないこと

- **`.mcp.json` にシークレットを直書きしないでください。** `${ENV_VAR}` 補間を使います（参考解答の `kb-search` 例を参照）。ファイルはコミットされます。
- **filesystem サーバーの向き先を `$HOME` や `/` にしないでください。** 「何が見えるか試したい」だけでも、エージェントにすべての読み取り権限を渡すことになります。
- **信頼していない HTTP MCP サーバーを追加しないでください。** そのサーバーは、このセッションのツールパーミッションで動作します。悪意あるサーバーなら、危険な組み込みツールを呼ばせようとする可能性があります。

## 発展課題

1. `.mcp.json` に組み込み GitHub MCP を追加し、`"disabled": true` を設定して、このセッションでは無効化します。`/mcp show` でもう表示されないことを確認してください。
2. Python（`mcp` パッケージ）で 20 行程度の MCP サーバーを書き、現在時刻の ISO タイムスタンプを返す単一ツール `now()` を公開します。`.mcp.json` の `type: "stdio"` で接続し、セッション内で「what time is it, according to my custom MCP server?」と呼び出してみてください。
