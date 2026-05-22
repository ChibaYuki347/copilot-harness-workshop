# 6 · フック

🟡 **中級 · 約30分**

🟩 **トラック B — Copilot CLI 専用**（フックは CLI 専用機能 · [詳細](../reference/vscode-vs-cli.md)）

## 学習目標

この演習を終えると、次のことができるようになります:

- `hooks.json` 経由で `sessionStart` と `sessionEnd` フックを設定できるようになります。
- 有用な診断情報をログファイルへ記録するフックスクリプトを書けるようになります。
- 正常な `/exit` でフックが発火することを確認し、その出力を点検できるようになります。
- どのセッション終了パスで `sessionEnd` が発火し、どれでは発火しないかを考えられるようになります。

## 前提条件

- スクラッチ用の git リポジトリ。
- `bash` が使えること。
- 約30分。

## チェックポイントコミット

```bash
git commit --allow-empty -m "checkpoint: before hooks exercise"
```

## シナリオ

小さな監査ログが欲しい状況です。このリポジトリで Copilot のセッションが始まるたび・終わるたびに、タイムスタンプ、ブランチ、HEAD sha、dirty なファイル数を `.copilot-logs/sessions.log` に 1 行ずつ追記したいと考えています。コンプライアンス目的ではなく、自分のためです。`tail` して、先週何をしていたか思い出せる程度で十分です。

!!! warning "`sessionEnd` は正常終了でしか発火しません"
    `sessionEnd` が動くのは `/exit`、EOF、そしてプロセスが正常終了したときだけです。`kill -9` で止めた場合、`/exit` せずにターミナルを閉じた場合、クラッシュした場合には **発火しません**。コンプライアンスレベルの監査に使うものではありません。そうした用途は enterprise policy の守備範囲です。これは、自分のラップトップ向けのちょっとした自動化として使ってください。

## 手順

### 1. ログディレクトリを gitignore 対象にする

```bash
mkdir -p .copilot-logs
echo ".copilot-logs/" >> .gitignore
git add .gitignore && git commit -m "chore: ignore .copilot-logs"
```

ログファイル自身のせいで作業ツリーが dirty になるのは避けたいからです。

### 2. フックスクリプトを作成する

```bash
mkdir -p .github/hooks/session-logger
```

`.github/hooks/session-logger/log-session-start.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

echo "[$TS] START session=$SESSION_ID branch=$BRANCH head=$HEAD_SHA dirty_files=$DIRTY" \
  >> "$LOG_DIR/sessions.log"
```

`.github/hooks/session-logger/log-session-end.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${LOG_DIR:-.copilot-logs}"
mkdir -p "$LOG_DIR"

SESSION_ID="${COPILOT_AGENT_SESSION_ID:-unknown}"
TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo not-a-git-repo)"
HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo none)"
DIRTY="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ' || echo 0)"

echo "[$TS] END   session=$SESSION_ID branch=$BRANCH head=$HEAD_SHA dirty_files=$DIRTY" \
  >> "$LOG_DIR/sessions.log"
```

両方を実行可能にします:

```bash
chmod +x .github/hooks/session-logger/*.sh
```

### 3. フックを接続する

`.github/hooks/session-logger/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": ".github/hooks/session-logger/log-session-start.sh",
        "cwd": ".",
        "env": { "LOG_DIR": ".copilot-logs" },
        "timeoutSec": 10
      }
    ],
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/session-logger/log-session-end.sh",
        "cwd": ".",
        "env": { "LOG_DIR": ".copilot-logs" },
        "timeoutSec": 10
      }
    ]
  }
}
```

### 4. セッションを開始して正常終了する

```bash
copilot
```

必要に応じてフォルダー信頼を承認します（リポジトリのフックは信頼済みディレクトリで **のみ** 読み込まれます）。セッション内で `/env` を実行すると、`sessionStart` と `sessionEnd` の 2 つを表す「Hooks loaded: 2」のような行が見えるはずです。

何か簡単な入力をしたあと、**正常に終了** します:

```text
/exit
```

### 5. ログを確認する

```bash
cat .copilot-logs/sessions.log
```

今実行したセッションについて、次の 2 行が見えるはずです:

```text
[2026-05-15T12:34:56Z] START session=abc-123 branch=main head=44bec3d dirty_files=0
[2026-05-15T12:35:42Z] END   session=abc-123 branch=main head=44bec3d dirty_files=0
```

## 完了条件 { #definition-of-done }

次の 4 つをすべて満たせば完了です:

- [ ] `.github/hooks/session-logger/hooks.json` が存在し、`sessionStart` と `sessionEnd` の両方のエントリを持つ。
- [ ] 2 つの shell スクリプトがどちらも実行可能である。
- [ ] セッション内の `/env` に、フックが読み込まれたことが表示される。
- [ ] 1 回正常に `/exit` したあと、`.copilot-logs/sessions.log` に **1 行の START と 1 行の END** が同じ `session=` 値で記録されている。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    docs サイトで使っている session-logger 一式です（構造は同じです）:

    `hooks.json`:

    ```json
    --8<-- "examples/hooks/session-logger/hooks.json"
    ```

    `log-session-end.sh`:

    ```bash
    --8<-- "examples/hooks/session-logger/log-session-end.sh"
    ```

    フックイベント（`sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `userPromptSubmit`, …）の一覧と、それぞれで渡される環境変数については、[リファレンス → フックイベント](../reference/hook-events.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .github/hooks .copilot-logs
git restore --staged .gitignore && git checkout -- .gitignore
# (or just delete the ".copilot-logs/" line you added)
```

## トラブルシューティング

- **ログ行が 1 つも出ません。** セッション開始時にフォルダー信頼を承認しましたか。`/env` にフック読込済みと出ていましたか。もしそうなら、スクリプトを手で実行してください: `./.github/hooks/session-logger/log-session-end.sh`。これで行が追記されるはずです。これも失敗するなら、shebang / パーミッション / GNU と BSD の差異が原因です。
- **START だけで END が出ません。** `/exit` せずにターミナルを閉じた可能性が高いです。`sessionEnd` は正常終了が必要です。もう一度 `/exit` で試してください。
- **フックは動くがスクリプトが error-exit します。** フックには `timeoutSec` 制限があり、非ゼロ終了は構成によってセッションライフサイクルを止めることがあります。デバッグ中はスクリプトに `set -x` を入れてログを tail するか、単に `set -e` を外してください。

## やってはいけないこと

- **ログを gitignore せずに作業ツリーの中へ書かないでください。** リポジトリが常に dirty になります。
- **`sessionStart` フックにネットワーク呼び出しを入れないでください。** プロンプトの *前* に動くため、毎回のセッション開始を数秒単位で遅くします。
- **フックから `sudo` や破壊的な処理を実行しないでください。** リポジトリフックは `cwd` の信頼承認で動くので、見知らぬリポジトリの悪意ある `hooks.json` が実害を与えられてはいけません。

## 発展課題

1. **`preToolUse` ガードを追加する。** `**/secrets/**` に一致するファイルに対して `edit` ツールを拒否するようにします。フック出力では `block` アクションを使ってください。セッション内でそのようなファイルを編集しようとしてテストします。
2. **セッションをまたいでログを集計する。** *tool call* ごとに 1 行（切り詰め可）を記録する `postToolUse` フックを追加します。そのあと `awk` / `jq` でセッションサマリーを集計してください。
