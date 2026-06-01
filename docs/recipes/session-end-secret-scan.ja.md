# レシピ: セッション終了時のシークレットスキャン

!!! info "対応ホスト: 🟢 Copilot CLI + VS Code Copilot Chat（フックは VS Code では Preview）"
    `.github/hooks/<name>/hooks.json` は両ホストが読みます。**イベント名はホストで異なります**:

    - Copilot CLI: `sessionEnd`（camelCase）。クロスツール互換のため PascalCase
      `SessionStart` / `Stop` も受け付けます。
    - VS Code Copilot Chat: `Stop` が公式のセッション終了イベント
      （PascalCase）。CLI の `sessionEnd` は取り込み時に自動マッピングされます。
      VS Code のフックは引き続き Preview です。

    `bash`/`command`/`timeoutSec` のスキーマや環境変数注入は同じです。
    VS Code 側のセットアップ（`chat.hookFilesLocations` 設定 + エンタープライズポリシー
    の留意点）は [フックのカスタマイズページ](../customizations/hooks.md#vs-code-variant)
    を参照。

**Copilot セッションが終わった瞬間に、漏えいしたシークレットを検出します — push する前に。**

## 課題

Copilot は、ときどき本物の設定ファイルのように *見える* コードを生成します。
無関係な作業を解決している途中で、うっかり認証情報を `.env.local` に書き込んだなら、
それを知りたいのは **すぐその場** です。レビューでチームメイトに指摘されてからでは遅すぎます。

## 使うレイヤー

- **フック** を `sessionEnd` に設定します。

## ファイル構成

```
.github/hooks/secrets-scanner/
├── README.md
├── hooks.json
└── scan-secrets.sh
```

## `hooks.json`

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

これは [`github/awesome-copilot/hooks/secrets-scanner`](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner) と同じパターンです。
そのまま採用してもよいですし、次の簡略版を使ってもかまいません。

## `scan-secrets.sh`（最小版）

```bash
#!/usr/bin/env bash
set -euo pipefail

SCAN_MODE="${SCAN_MODE:-warn}"   # warn | block
SCAN_SCOPE="${SCAN_SCOPE:-diff}" # diff | all

if [[ "$SCAN_SCOPE" == "diff" ]]; then
  # Files modified during this session.
  FILES=$(git diff --name-only HEAD || true)
else
  FILES=$(git ls-files)
fi

[[ -z "$FILES" ]] && exit 0

# Patterns adapted from common secret-scan rules. Add your own.
PATTERN='(AKIA[0-9A-Z]{16})|(ghp_[A-Za-z0-9]{36})|(xox[abps]-[A-Za-z0-9-]{10,})|(-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)'

HITS=$(echo "$FILES" | xargs grep -EnH "$PATTERN" 2>/dev/null || true)

if [[ -z "$HITS" ]]; then
  echo "🔒 secrets-scanner: clean ($SCAN_SCOPE)" >&2
  exit 0
fi

echo "🚨 secrets-scanner: possible secrets detected:" >&2
echo "$HITS" >&2

if [[ "$SCAN_MODE" == "block" ]]; then
  echo "{\"response\": \"Possible secret detected. Review the files above before committing.\", \"stopProcessing\": true}"
  exit 0
fi

# warn mode: print only
exit 0
```

実行権限を付与します:

```bash
chmod +x .github/hooks/secrets-scanner/scan-secrets.sh
```

## 動作の流れ

1. Copilot CLI での作業を終え、セッションを終了します（`/exit`、`Ctrl+D`、またはタスク完了）。
2. `sessionEnd` イベントが発火します。
3. `scan-secrets.sh` が変更されたファイルを grep し、認証情報らしい文字列を探します。
4. 検出結果がターミナルに表示されます。

## バリエーション

- **`block` モード。** `SCAN_MODE=block` にすると、このフックは CLI 出力に明確な
  警告を表示する JSON レスポンスを返します。セッション自体を「巻き戻す」ことはできません
  （すでに終了しているため）が、確実に目に入るようになります。
- **`sessionEnd` ではなく `preToolUse`。** シークレットがローカルのリポジトリ外へ出る前に
  止めたい場合は、引数に `git commit` や `gh pr create` を含む `bash` ツールに一致する
  `preToolUse` を使います。このフックは `{ "permissionDecision": "deny" }` を返します。
- **外部スキャナー。** インラインの grep を `trufflehog`、`gitleaks`、または
  組織標準のツールに置き換えます。レシピのシェル部分は同じままです。
- **SIEM に POST。** `command` ではなく `http` フックタイプを使い、差分の
  メタデータをセキュリティ基盤へ送信します。

## 落とし穴

!!! warning "コンプライアンス目的で warn-only モードを信用しない"
    warn-only のフックは **助言的** なものです。本当にコンプライアンス要件がある場合は、
    環境を制御できる CI で同等のスキャンを実行し、その結果でマージを制御します。
    ローカルフックは **フィードバックループを短くする** ために使い、唯一の防御線にはしません。

## 試してみる

実行可能なスターターは [`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
にあります（上流の [`hooks/secrets-scanner`](https://github.com/github/awesome-copilot/tree/main/hooks/secrets-scanner) も、より充実した参考例です）。
