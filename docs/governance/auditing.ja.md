# 事後の監査

Approval プロンプトは「悪いことを *起こさない* ための仕組み」、監査ログは「起きた
ことを *あとから確かめる* ための仕組み」。両方が必要。

このページは監査ログ側 — 構造化された append-only でクエリ可能な全ツール呼び出し
レコードの作り方。純粋な可観測性であり、強制はしません。

## デフォルトで得られるもの

ほぼ何も。チャット transcript には *エージェントの自己語り* が出ますが:

- `/clear` や `/exit` で消える
- MCP ツール呼び出しは UI で短縮表示。完全な入力は見えない
- ユーザー発言・エージェント推論・ツール呼び出しが一本のタイムラインに混在 →
  「ディスクに書いたもの全部」を `grep` するのが面倒
- VS Code Chat には会話コピー機能があるが結果も結局散文

なので自前で作ります。

## Hook ベースの監査ログ { #hook-based-audit-log }

最小の有用な監査は「1 ツール呼び出し = 1 行の JSON」だけの append-only ファイル。
[`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls) を入れるだけ:

```bash
mkdir -p .github/hooks/audit-all-tool-calls
cp examples/hooks/audit-all-tool-calls/* .github/hooks/audit-all-tool-calls/
chmod +x .github/hooks/audit-all-tool-calls/log.sh
```

`preToolUse` / `postToolUse` / `postToolUseFailure` を hook し、JSON Lines を
`~/.copilot/audit.log` に書きます:

```json
{"ts":"2024-09-14T12:00:01Z","phase":"pre","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolInput":{"command":"npm test"},"sessionId":"abc-123"}}
{"ts":"2024-09-14T12:00:14Z","phase":"post","user":"ada","host":"laptop","repo":"/home/ada/work/api","branch":"feat/login","payload":{"toolName":"bash","toolResult":{"exitCode":0,"stdout":"..."}}}
```

Copilot CLI と VS Code Chat の両方で同じ hook 仕様で動きます。

## 便利クエリ

ログさえあれば `jq` が事実上のクエリ言語になります:

```bash
# エージェントが試した全 bash コマンド (履歴全部)
jq -c 'select(.phase=="pre" and .payload.toolName=="bash")
       | {ts, cmd: .payload.toolInput.command}' \
  ~/.copilot/audit.log

# 失敗したもの + エラー
jq -c 'select(.phase=="fail")
       | {ts, tool: .payload.toolName, err: .payload.toolResult.error}' \
  ~/.copilot/audit.log

# 過去 24h のツール別呼び出し回数
jq -r 'select(.phase=="pre") | .payload.toolName' ~/.copilot/audit.log \
  | sort | uniq -c | sort -rn

# 現リポで Copilot が編集したファイル
jq -c --arg repo "$(git rev-parse --show-toplevel)" \
  'select(.phase=="post"
          and .repo==$repo
          and (.payload.toolName=="edit" or .payload.toolName=="create"))
   | .payload.toolInput.path' \
  ~/.copilot/audit.log

# ネットワーク呼び出しっぽいもの
jq -c 'select(.phase=="pre"
              and .payload.toolName=="bash"
              and (.payload.toolInput.command | test("curl|wget|http")))
       | {ts, cmd: .payload.toolInput.command}' \
  ~/.copilot/audit.log
```

これらをシェルヒストリに残しておくと、「チャット transcript を信じる」から
「SQL ライクなログを持つ」へ思考が切り替わります。

## セッション中の live tailing

ハイステークス案件では別ペインで:

```bash
tail -F ~/.copilot/audit.log | jq -c 'select(.phase=="pre") | {ts, tool: .payload.toolName, cmd: .payload.toolInput.command // .payload.toolInput.path // .payload.toolInput}'
```

「いま何が試されているか」のリアルタイムフィード。auto-approval を広げているとき、
拒否されたものも試行されているのは見えるし、想定外の繰り返しに気付けます。

## セッション終了時のサマリ

`sessionEnd` hook が最終サマリ向けの場所。5 行のシェルで:

- 各種ツール呼び出しの回数
- 触ったファイル (`git diff --stat HEAD`)
- 作業ツリーの dirty 状況
- このセッション分の audit log スライス

[`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
の start/end ロガーをベースに、`sessionId` で audit log をフィルタする `jq` を
足してください。

## SIEM / 中央ログへ転送

2 パターン:

- **Hook 内で fire-and-forget**: `log.sh` の末尾に
  `| curl -X POST https://siem/api/log -d @- &` を追加。ローカル追記後に shipping。
  `&` を忘れずに (ネットワーク遅延でエージェントが止まらないように)
- **Tail-and-ship sidecar**: `log.sh` はローカルのみ。`vector` / `fluent-bit` /
  `promtail` 等の別プロセスが `~/.copilot/audit.log` を tail して shipping。
  分離が綺麗、組織展開ではこちら推奨

組織展開なら Microsoft Foundry Tools の PII マスキング (recipe は後続 PR で
追加予定) をかませて、ラップトップを出る前にユーザー識別子やコード片を消すと安全。

## `/delegate` のトレースも見失わない

`/delegate` でクラウドエージェントに渡すと、ローカル audit log にはリモート行動が
出ません。クラウド側は GitHub に痕跡を残します (PR description、check runs)。
完全可視化のために:

- `/delegate` は常に **fine-grained PAT** で (GitHub の audit log に bot identity と
  scope が出る)
- クラウド側 PR とローカル audit log の `delegate` 呼び出しを cross-reference
  (`jq 'select(.payload.toolName | startswith("delegate"))'`)

## インシデント対応観点で得られるもの

- 「Copilot が `~/work/foo` を消した?」 → 時刻範囲で `rm` を grep
- 「`.env` を読んだ?」 → `toolName == view` かつ `toolInput.path == ".env"`
- 「先週木曜の `git push` がなぜ失敗?」 → `phase == "fail"` で `toolName == bash`
- 「この MCP ツールは呼ばれた?」 → `payload.toolName` でフィルタ

## 注意

- **ログは急速に成長する** — `logrotate` で daily ローテ推奨。1 セッション 1–5 MB
- **ペイロードにコード片が含まれる** — sensitive 扱い (公開バケット禁止、Slack
  アップロード禁止)
- **Hook 失敗はチェックしないと silent** — `jq -e . ~/.copilot/audit.log >/dev/null && echo OK` を定期実行
- **VS Code Chat Hook Preview** は現状 preview。enterprise policy で全 hook 無効化
  可能。監査を hook に依存するなら、ポリシー依存を明文化しておくこと

## 関連

- [リスクの mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [Blast-radius を絞る](./blast-radius.md)
- [`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls)
- [`examples/hooks/session-logger/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/session-logger)
- [Recipe → セッション終了時のシークレットスキャン](../recipes/session-end-secret-scan.md)
