# 🪝 フック

**エージェントがライフサイクルイベントをまたぐタイミングで、スクリプト実行や HTTP
エンドポイント呼び出しを行います。**

フックは自動化レイヤーです。プロンプトの書き方を変えなくても、エージェントの動きを
観察し、制御できます。

## 使いどき

- すべてのセッションでプロンプトやツール呼び出しを **ログ** として残したい。
- 危険なコマンド（`rm -rf /`、`git push --force` を `main` で行う操作）を止める **ガードレール** が欲しい。
- **セッション終了時** の処理が欲しい。自動コミット、シークレットスキャン、依存関係監査など。
- ツール呼び出しの引数に応じて、特定の呼び出しへ **コンテキストを注入** したい。
- イベントを社内の SIEM / Slack / 可観測性基盤へ **POST** したい。

## 構成

フックは、`hooks.json` 設定ファイルと、それが呼び出すスクリプトを含むディレクトリです。

```
.github/hooks/<hook-name>/
├── hooks.json
├── README.md
└── <your-script>.sh
```

同じ構成を、個人スコープの `~/.copilot/hooks/<hook-name>/` にも置けます。

## 最小例 — `sessionEnd` でのシークレットスキャン

`.github/hooks/secrets-scanner/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/secrets-scanner/scan-secrets.sh",
        "cwd": ".",
        "env": {
          "SCAN_MODE": "warn",
          "SCAN_SCOPE": "diff"
        },
        "timeoutSec": 30
      }
    ]
  }
}
```

これは [`github/awesome-copilot` の secrets-scanner](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner)
で使われているパターンです。セッション終了時に `scan-secrets.sh` が diff を対象に
実行され、一致した項目を出力します。

## フックイベント

| イベント | 発火タイミング |
|---|---|
| `sessionStart` | 新しいセッションが始まったとき（セッションごとに 1 回）。 |
| `sessionEnd` | セッションが終了したとき（セッションごとに 1 回）。 |
| `userPromptSubmitted` | ユーザーがプロンプトを送信したとき。**モデルを呼び出さずに** 応答を返して打ち切ることもできます。 |
| `preToolUse` | エージェントがツールを呼び出す直前。`allow` / `ask` / `deny` を返したり、引数を変更したりできます。 |
| `postToolUse` | ツールが成功したとき。 |
| `postToolUseFailure` | ツールが失敗したとき。 |
| `notification` | 非同期イベント: shell 完了、パーミッションプロンプト表示、エリシテーション（elicitation）ダイアログ、エージェント完了。 |
| `permissionRequest` | ツールのパーミッションプロンプトが表示される直前。事前承認 / 拒否できます。 |
| `preCompact` | コンテキスト圧縮の実行直前。 |
| `subagentStart` | サブエージェントの起動時。追加コンテキストを注入できます。 |
| `subagentStop` | サブエージェントの停止時。 |
| `agentStop` | エージェントが停止したとき（`task_complete` など）。 |

完全なイベントリファレンスとペイロード形状については、[リファレンス → フックイベント](../reference/hook-events.md)
を参照してください。

## フックの種類

`hooks` 配列には、3 種類のフックエントリを記述できます。

=== "Command（ローカル実行）"

    ```json
    {
      "type": "command",
      "bash": "./scripts/audit.sh",
      "cwd": ".",
      "env": { "AUDIT_LEVEL": "high" },
      "timeoutSec": 30
    }
    ```

    クロスプラットフォームの別名 `command` を `bash` の代わりに使うと、Windows では
    `cmd` や PowerShell 経由でスクリプトを実行できます。

=== "HTTP（JSON を POST）"

    ```json
    {
      "type": "http",
      "url": "https://hooks.example.com/copilot-events",
      "headers": { "Authorization": "Bearer ${SIEM_TOKEN}" },
      "timeoutSec": 5
    }
    ```

    フックのペイロードは JSON として POST されます。shell を起動せずに、外部の
    可観測性 / セキュリティ基盤へイベントを送る用途に向いています。

=== "matcher 付き（preToolUse のみ）"

    ```json
    {
      "type": "command",
      "matcher": "^bash$",
      "bash": "./guard-bash.sh",
      "timeoutSec": 10
    }
    ```

    `matcher` はツール名に対する正規表現です。名前が完全一致したツールでのみフックが
    発火します。

## フックの戻り値契約

イベントがリッチな応答をサポートしている場合、フックスクリプトの **stdout は JSON として
解釈** されます。たとえば `preToolUse` フックでは、次のような値を返せます。

```json
{
  "permissionDecision": "deny",
  "response": "Force-push on protected branch refused by org policy.",
  "additionalContext": "Branch=main, user=alice"
}
```

また、`userPromptSubmitted` ではモデル呼び出しを打ち切り、直接応答を返すこともできます。

```json
{
  "response": "I won't run that — the prompt contains a `--force-yes` flag in production scope.",
  "stopProcessing": true
}
```

`preToolUse` フックは、`modifiedArgs` または `updatedInput`[^modify] を返すことで、
実行前にツール呼び出しを書き換えることもできます。

```json
{
  "modifiedArgs": { "command": "git push --dry-run" }
}
```

[^modify]: changelog より: *「preToolUse フックは modifiedArgs/updatedInput と
    additionalContext フィールドを尊重するようになりました。」*

特別な戻り値が不要なフックは、単に `0` で終了し、人が読めるステータスを stderr に
出力すれば十分です（`--verbose` で表示されます）。

## 配置場所

| パス | スコープ |
|---|---|
| `.github/hooks/<name>/hooks.json` | リポジトリ（コミットされる）。 |
| `~/.copilot/hooks/<name>/hooks.json` | 個人。 |
| `settings.json`、`settings.local.json`、`config.json` のような settings 形式設定 | あまり一般的ではありません。 |

リポジトリのフックが読み込まれるのは **フォルダーの信頼が確認された後** です。新しく clone
した直後のリポジトリでは、明示的な同意なしに Copilot が実行することはありません。

## フックが受け取る環境変数

- `COPILOT_AGENT_SESSION_ID` — このセッションの一意 ID。
- `COPILOT_CLI=1` — `git` フックの中で「Copilot 経由で実行されている」と判別し、
  対話的プロンプトをスキップするのに便利です。
- そのほか、`env:` に指定した `hooks.json` の内容も渡されます。

## フックに影響するモード

- **プロンプトモード (`-p`)** では、リポジトリフックとワークスペース MCP サーバーは
    環境変数で opt-in します:
    - `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=1`
    - `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP=1`
- **対話モード** では、どちらも信頼確認後に読み込まれます。

## 落とし穴

!!! warning "問題を起こしやすいフック"
    - **遅いフックはエージェントを止めます。** `timeoutSec` は短めに設定します。
      `sessionStart` フックが 30 秒かかると、すべてのセッションが重く感じられます。
    - **フックはサンドボックスではありません。** 悪意あるフックは何でも実行できます。
      ほかのリポジトリコードと同じようにレビューします。
    - **フックは信頼確認後にしか発火しません。** 新規リポジトリでの「最初の印象」を
      左右する処理を `sessionStart` フックに入れても遅すぎます。発火する時点では、
      エージェントはすでに少し動いています。

## 確認方法

```text
/env                # shows count of loaded hooks
copilot --verbose   # surfaces hook stdout/stderr inline
```

## 次へ

→ [🔌 MCP サーバー](mcp.md) — イベントに反応するだけでなく、**ツールそのもの** を公開したい場合に進みます。
→ レシピ: [session-end secret scan](../recipes/session-end-secret-scan.md)。
