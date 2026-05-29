# 🪝 フック

**エージェントがライフサイクルイベントをまたぐタイミングで、スクリプト実行や HTTP
エンドポイント呼び出しを行います。**

!!! abstract "対応ホスト"
    🟢 **Copilot CLI** · 🟢 **VS Code（Preview）** — `.github/hooks/*.json` の JSON フォーマット（Claude Code 互換）を両ホストとも読み込みます。VS Code 対応は 2026-05 時点で Preview。詳細は [公式 VS Code Hooks ドキュメント](https://code.visualstudio.com/docs/copilot/customization/hooks)。ユーザースコープの置き場所は異なります（CLI は `~/.copilot/hooks/`、VS Code は `~/.copilot/hooks` または `~/.claude/settings.json`）。組織の **エンタープライズポリシー** で VS Code のフックが無効化されていることもあるため、依存する前に確認してください。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

フックは自動化レイヤーです。プロンプトの書き方を変えなくても、エージェントの動きを
観察し、制御できます。

## なぜ存在するか

インストラクション・プロンプトファイル・スキルはすべて **エージェントが正しい
選択をする** ことに頼ります。Hook はそうではありません — モデルの判断とは無関係に、
イベント毎に発火するあなたが書いたコードです。機械的に強制する必要があるルール
(監査ログ、deny-list、必須の事前チェック) を置く唯一の場所がここです。

## 代替手段 — hook を *使わない* 判断

- 振る舞いが **ユーザー意図の理解** に依存 → hook は意図を読めません。[instruction](custom-instructions.md)
  か [skill](skills.md) を
- 振る舞いが **モデルが好きなときに呼べるツール** → [プロンプトファイル](prompt-files.md)
  か [MCP ツール](mcp.md) として公開。Hook はライフサイクルイベントで発火、オンデマンドではない
- 何かおかしいときに **エージェント全体を止めたい** → hook は 1 つのツール呼び出しを
  拒否できるがセッション終了はできません。「hook に拒否されたら止まって尋ねる」と
  指示する instruction と組み合わせる

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

## VS Code 版（Preview） { #vs-code-variant }

VS Code Copilot Chat も同じ `.github/hooks/*.json` 形式を読み込みます。2026-05
時点では **Preview** です。

### VS Code が探す場所

| スコープ | 既定のファイル位置 |
|---|---|
| ワークスペース | `.github/hooks/*.json` |
| ワークスペース（Claude 形式） | `.claude/settings.json`、`.claude/settings.local.json` |
| ユーザー | `~/.copilot/hooks`、`~/.claude/settings.json` |
| エージェント固有 | カスタムエージェントの `.agent.md` frontmatter の `hooks:` フィールド（`chat.useCustomAgentHooks: true` を設定） |
| プラグイン | プラグイン内の `hooks.json` または `hooks/hooks.json`（CLI と同じ） |

同じイベントについてはワークスペースのフックがユーザーのフックを上書きします。
読み込み対象は `settings.json` の `chat.hookFilesLocations` でカスタマイズできます:

```jsonc
{
  "chat.hookFilesLocations": {
    ".github/hooks": true,
    ".claude/settings.local.json": true,
    ".claude/settings.json": true,
    "~/.claude/settings.json": true
  }
}
```

### イベント名の大文字小文字の違い

本サイトの例は camelCase（`sessionStart`、`preToolUse` …）を使っています — これは
`awesome-copilot` のリファレンス実装と CLI が受け付ける形式です。**公式 VS Code Hooks
ドキュメント** は **PascalCase**（`SessionStart`、`PreToolUse`、`Stop` …）を使い、
`sessionEnd` イベントは存在しません — VS Code ではセッション終了は **`Stop`** と呼ばれます。
CLI は両方の表記を受け付ける（`vsCodePreToolUseInputMapper` 経由で PascalCase エイリアスをサポート）
ので、camelCase で書いておけば両ホストとも認識します。ただし VS Code を先に対象とするなら、
`sessionEnd` ではなく PascalCase + `Stop` を推奨。正規のイベント一覧は
[公式 VS Code Hooks リファレンス](https://code.visualstudio.com/docs/copilot/customization/hooks)
を参照。

### VS Code でフックが発火したか確認する

VS Code の **表示 → 出力** を開き、**GitHub Copilot Chat Hooks** チャンネルを選択。
各フックの stdout / stderr がそこに出力されます。

!!! warning "エンタープライズポリシーで無効化される可能性"
    組織側で VS Code のフックを完全に無効化できます。公式ドキュメント:
    *「Your organization might have disabled the use of hooks in VS Code.」*
    セキュリティ重要な自動化に使う前に、必ず管理者に確認してください。

## 確認方法

```text
/env                # shows count of loaded hooks
copilot --verbose   # surfaces hook stdout/stderr inline
```

（VS Code ユーザー: *GitHub Copilot Chat Hooks* 出力チャンネルを参照。）

## 次へ

→ [🔌 MCP サーバー](mcp.md) — イベントに反応するだけでなく、**ツールそのもの** を公開したい場合に進みます。
→ レシピ: [session-end secret scan](../recipes/session-end-secret-scan.md)。
