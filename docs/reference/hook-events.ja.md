# フックイベント リファレンス

フックを関連付けられる Copilot CLI の全イベントを、発火タイミング、スクリプトが stdin で
受け取るペイロード、CLI が返り値として解釈するレスポンス形式（あれば）とともにまとめた
リファレンスです。

!!! note
    フックイベント名はここでは **camelCase** で記載しています（`hooks.json` における
    正規形です）。VS Code の Chat フックとの互換性のため、PascalCase 版（`SessionStart`）も
    受け付けられますが、新規ファイルでは camelCase を推奨します。

## ライフサイクルイベント

### `sessionStart`

| | |
|---|---|
| 発火タイミング | 新しい Copilot CLI セッションが作成されたとき（新規の `copilot` 実行。`/clear` は含みません）。 |
| ペイロード（stdin） | JSON: `{ "sessionId": "...", "cwd": "...", "modelId": "...", "instructions": [...] }` |
| 反映されるレスポンス | なし（情報提供のみ）。 |
| 主な用途 | セッション開始の記録、キャッシュの事前ウォームアップ、ログファイルへのセッションヘッダー書き込み。 |

### `sessionEnd`

| | |
|---|---|
| 発火タイミング | セッションが終了したとき（`/exit`、EOF、またはプロセスが正常終了した場合）。 |
| ペイロード | セッション要約の各項目を含む JSON。 |
| レスポンス | 主に情報提供用です。`response` フィールドは最終メッセージとして表示され、`stopProcessing` は無視されます（セッションはすでに終了しています）。 |
| 主な用途 | シークレットスキャン、git status の要約、通知チャネルへの投稿。 |

### `preCompact`

| | |
|---|---|
| 発火タイミング | `/compact` が実行される直前（手動または自動のコンテキスト圧縮）。 |
| ペイロード | 現在の会話サイズとしきい値を含む JSON。 |
| レスポンス | 特にありません。 |
| 主な用途 | 要約される前に完全なトランスクリプトをスナップショットします。 |

## ツールイベント

### `preToolUse`

| | |
|---|---|
| 発火タイミング | エージェントがツール（例: `bash`、`edit`、`view`、MCP ツール）を呼び出す直前。 |
| ペイロード | JSON: `{ "toolName": "bash", "toolInput": {...}, "sessionId": "..." }` |
| 反映されるレスポンス | **はい — このフックはブロックできます。** |
| 主な用途 | パーミッション制御、危険なコマンドの deny-list 化、ツール呼び出しのリダイレクト。 |

#### レスポンス形式

```json
{
  "permissionDecision": "allow" | "deny" | "ask",
  "response": "Reason shown to the agent and the user.",
  "stopProcessing": false
}
```

- `permissionDecision: "deny"` — ツール呼び出しは拒否されます。`response` は
  エージェントに表示されるため、それに応じて振る舞いを変えられます。
- `permissionDecision: "ask"` — 保存済みのパーミッションに関係なく、実行前に Copilot が
  ユーザーへ確認します。
- `permissionDecision: "allow"` — 明示的に許可します（プロンプトを省略します）。
- このフィールドを省略すると、通常のパーミッションフローになります。

#### マッチャー

```json
{
  "type": "command",
  "matcher": "^bash$",
  "bash": "./check.sh"
}
```

`matcher` はツール名に対する正規表現です。これを使うとフックの対象を限定できます（例:
`bash` のみ、`edit` のみ）。

### `postToolUse`

| | |
|---|---|
| 発火タイミング | ツール呼び出しが成功した後。 |
| ペイロード | JSON: `{ "toolName", "toolInput", "toolResult", "sessionId" }` |
| 反映されるレスポンス | 情報提供用の `response` です。事後的にブロックはできません。 |
| 主な用途 | `edit`/`create` で書き込んだファイルの自動整形、ファイル変更の記録、長いジョブが終わったときの通知。 |

### `postToolUseFailure`

| | |
|---|---|
| 発火タイミング | ツール呼び出しが失敗した後（非 0 終了、例外など）。 |
| ペイロード | 失敗の詳細を含む JSON。 |
| レスポンス | 情報提供用です。 |
| 主な用途 | 失敗した `bash` 呼び出しをデバッグ用にログへ記録します。 |

## プロンプトイベント

### `userPromptSubmitted`

| | |
|---|---|
| 発火タイミング | ユーザーがプロンプトを送信した直後で、エージェントがそれについて推論する前。 |
| ペイロード | JSON: `{ "prompt": "...", "sessionId": "..." }` |
| レスポンス | `response` は **エージェントのコンテキストの先頭に追加** されるため、動的な
   事実（「現在のスプリントは XYZ」など）を注入できます。`stopProcessing: true` でプロンプトを中止します。 |
| 主な用途 | now() / ブランチ名 / 現在のチケットを注入し、明らかなシークレットが
   モデルに渡る前にマスクします。 |

### `notification`

| | |
|---|---|
| 発火タイミング | CLI がデスクトップ / インライン通知（例: 長いタスクが完了）を表示する直前。 |
| ペイロード | 通知テキストとメタデータ。 |
| レスポンス | 情報提供用です。 |
| 主な用途 | 通知を Slack に転送し、ノイジーなものを抑制します。 |

### `permissionRequest`

| | |
|---|---|
| 発火タイミング | CLI がパーミッション判断をユーザーに求める直前。 |
| ペイロード | 提案された操作。 |
| レスポンス | `permissionDecision` によって確認プロンプトを短絡できます。 |
| 主な用途 | 集中管理されたポリシー（「`prod/` に触るものは常に確認する」など）。 |

## サブエージェントイベント

### `subagentStart`

| | |
|---|---|
| 発火タイミング | サブエージェント（組み込みまたはカスタム）が開始したとき。 |
| ペイロード | `{ "agent": "...", "prompt": "...", "sessionId": "..." }` |
| レスポンス | 返された `additionalContext` はサブエージェントのプロンプトに注入されます。 |
| 主な用途 | ファンアウトの記録、サブエージェント実行のテレメトリ転送、親セッションのコンテキスト注入。 |

### `subagentStop`

| | |
|---|---|
| 発火タイミング | サブエージェントが停止したとき（成功、失敗、またはキャンセル）。 |
| ペイロード | 停止理由とサブエージェント識別子。 |
| レスポンス | 情報提供用です。 |
| 主な用途 | サブエージェントの結果取得、エージェント種別ごとの実行時間記録。 |

### `agentStop`

| | |
|---|---|
| 発火タイミング | メインエージェントが停止したとき（`task_complete`、エラー、またはユーザーによるキャンセル）。 |
| ペイロード | 停止理由。 |
| レスポンス | 情報提供用です。 |
| 主な用途 | クリーンアップ、総実行時間の記録。 |

## フックスクリプトの環境変数

すべてのフックスクリプト（`type: "command"`）は、次の環境変数付きで起動されます。

| 変数 | 設定元 | 意味 |
|---|---|---|
| `COPILOT_AGENT_SESSION_ID` | CLI | 安定したセッション識別子です。イベントを関連付けられます。 |
| `COPILOT_CLI` | CLI | 常に `1` です。共有スクリプトが「Copilot CLI 配下で実行中」と判断できます。 |
| `env: {...}` が `hooks.json` にある変数 | ユーザー | フック設定で指定した任意の値です。`${VAR}` は親環境から解決されます。 |

## レスポンス JSON: 完全なスキーマ

```jsonc
{
  // Shown to the user and (for prompt / preToolUse hooks) added to model context.
  "response": "Some message",

  // Additional structured context the agent should see (preToolUse, subagentStart,
  // sessionStart).
  "additionalContext": "Extra grounding info",

  // For preToolUse: "allow" | "deny" | "ask". Other events: ignored.
  "permissionDecision": "deny",

  // For preToolUse: rewrite the tool's arguments before it runs.
  "modifiedArgs": { "command": "..." },
  "updatedInput": { /* alternative name accepted */ },

  // Abort whatever was about to happen. Honored on userPromptSubmitted, preToolUse;
  // ignored on terminal events like sessionEnd.
  "stopProcessing": true
}
```

スクリプトが stdout に **プレーンテキスト** を書き出すと、それは `response` として扱われます。
ほかのフィールドが必要な場合は JSON を使ってください。

## 関連項目

- [フックのカスタマイズ](../customizations/hooks.md)
- [セッション終了時のシークレットスキャン レシピ](../recipes/session-end-secret-scan.md)
