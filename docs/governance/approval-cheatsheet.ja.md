# Approval cheat sheet

Agent モードで最も効く意思決定は **「何を auto-approve するか / 何は必ず聞かせるか
/ 何は完全に禁止か」** を決めること。このページがそのチートシートです。

!!! tip "デフォルトの判断ルール"
    **「取り消し可能 *かつ* 失敗にすぐ気付ける → auto-approve。それ以外は必ず聞かせる」**

## 必ず Ask する { #always-ask }

以下は何があっても **人間が必ずプロンプトで答える** よう Harness を組みましょう:

| 操作 | 理由 | 強制方法 |
|---|---|---|
| 現在のリポやスクラッチ外への `rm` | 取り消しが系全体に及ぶ | preToolUse hook (`command` への regex) |
| `git push --force` / `-f` / `--force-with-lease` で `main` / リリース branch を上書き | 共有履歴の書き換え | 同じ hook + リモート側 CODEOWNERS 補強 |
| `git reset --hard`、`git clean -fd` | 未コミット作業の喪失 | 同じ hook |
| `sudo …` (任意) | 権限昇格 | 同じ hook + Copilot を root で起動しない |
| `gh repo delete`、`gh secret set`、`gh api -X DELETE …` | 破壊 / シークレット書き込み | 同じ hook |
| `terraform apply` / `destroy`、`kubectl delete ns …`、`docker system prune` | インフラ blast radius | 同じ hook + 環境分離 / role-scoped 資格情報 |
| `~/.ssh`、`~/.aws`、`~/.kube`、`.env*` への書き込み | 資格情報相当 | `edit` / `create` ツールに matcher 付き hook、または FS 権限 (chmod 600 + 不変属性) |
| 許可リスト外ホストへのネットワーク呼び出し | データ持ち出しリスク | ネットワーク層 — [Blast-radius → ネットワーク](./blast-radius.md#network) 参照 |

スターター `examples/hooks/deny-dangerous-commands/` には大半が同梱済み。regex は
自チームに合わせて調整。

## Auto-approve して大丈夫 { #safe-to-auto-approve }

通常のセッションのほとんどは以下を auto-approve しても大丈夫 — read-only か
スクラッチ作業に閉じており、最悪「数秒のムダ」程度:

- `ls`、`cat`、`head`、`tail`、`grep`、`rg`、`fd`、`find` (検索 / 読み込み)
- `git status`、`git log --oneline`、`git diff`、`git branch --show-current`
- `npm test`、`pnpm test`、`pytest`、`go test`、`cargo test`、`mvn test`
- `npm run lint`、`eslint`、`ruff check`、`mypy`、`tsc --noEmit`
- リポ作業ツリー内のファイル編集 (Copilot は適用前に必ず diff を見せる)

### Copilot CLI のフラグ

```bash
copilot \
  --allow-tool 'bash(npm test:*)' \
  --allow-tool 'bash(pytest:*)' \
  --allow-tool 'bash(git status:*)' \
  --allow-tool 'bash(git diff:*)' \
  --allow-tool 'view' \
  --deny-tool  'bash(rm -*:*)' \
  --deny-tool  'bash(sudo *:*)'
```

`bash(<prefix>:*)` は `<prefix>` で始まる bash コマンドにマッチ。allow と deny を
重ねた場合、現行ビルドでは deny が勝ちます。

これらを `.copilot/config.json` に書く、または `sessionStart` hook で
`--allow-tool` 候補を表示する、といった形でチーム共有できます。

### VS Code Copilot Chat

Settings → **"Chat Tools"** で検索。主要キー:

```jsonc
// .vscode/settings.json または User settings
{
  // 都度確認なしで Agent が呼べるツール
  "chat.tools.autoApprove": false,                       // マスタースイッチ (デフォルト false)
  "chat.agent.allowList": ["fetch", "search"],           // ツール ID allow-list
  "chat.agent.denyList":  ["github.copilot.terminal.execute:rm*"]  // 例
}
```

正確なキー名は VS Code Copilot Chat のバージョンによって異なるため、依存する前に
**Settings → Features → Chat** で確認してください。UI が違ってもリスクモデルは同じ。

## 無人時は absolutely auto-approve しない { #never-auto-approve-unattended }

他のあらゆるルールを上書きする 1 行:

> **チャットパネルを能動的に見ていない時間は、auto-approve を一切有効にしない。例外なし。**

具体的には:

- `--allow-tool` を広げた状態で `copilot -p '<長いタスク>'` を放置しない
- 席を立つ前に `/exit` でセッション終了、またはタブを閉じる (セッションは資格情報を保持)
- クラウドエージェントに委譲 (`/delegate`) する場合は、デフォルト資格情報ではなく
  scope を絞った短命 PAT を使う
- Prompt injection ([リスクモデル](./risk-mental-model.md) のカテゴリ 5) が理由 —
  エージェントは読み取ったテキストによって「やろうとすること」が変わる。ツール呼び出しを
  見ていなければその変化に気付けません。

## チームデフォルト { #team-defaults }

小規模チーム向けのコピペ可能スターターポリシー:

| Auto-approve | 毎回 Ask | 常に Deny |
|---|---|---|
| `view`、`grep`、`ls`、`cat`、`git status`、`git diff` | `edit`、`create` (各 diff を 1 度はユーザーに見せる) | `rm -rf /`、`rm -rf ~`、`curl … \| sh`、`mkfs`、fork bomb |
| テストランナー、リンター | `bash(git push …)`、`bash(git reset --hard …)` | コンテナ外での `bash(sudo …)` |
| `bash(npm test:*)`、`bash(pytest:*)` | 未審査の書き込み MCP ツール ([MCP vetting](./mcp-vetting.md) 参照) | `bash(gh secret set …)` |

これをチーム共有の `.github/copilot-instructions.md` に書いておけば、デフォルト設定の
新規メンバーも同じベースラインで始められます:

```markdown
## Approval policy

以下は私の明示的承認なしには実行しないでください:
- `/`、`~`、`$HOME` で始まるパスを対象とする `rm`、`mv`、`cp`
- `git push --force*`、`git reset --hard`、`git clean -fd`
- `sudo`、`chmod 777`、`chown`
- `gh secret`、`gh repo delete`、`gh api -X DELETE`
- `terraform apply` / `destroy`、`kubectl delete`、`docker system prune`
- `.github/`、`.env*`、`~/.ssh/`、`~/.aws/`、`~/.kube/` 配下のファイル編集

以下は確認なしで実行して構いません:
- `ls`、`cat`、`grep`、`git status`、`git log`、`git diff` などの読み取り系
- プロジェクトのテスト / リント
```

このようなカスタムインストラクションは **ヒントであって強制ではありません**。
実際のブロックは `deny-dangerous-commands` hook とセットで運用してください。

## よくある失敗

- **「`bash` を許可して目で見てればいい」** — `bash` は粒度が大きすぎ。モデルは任意の
  コマンドを書けます。プレフィックスで絞ること (`bash(npm test:*)`)
- **「スクラッチリポだし全部 auto-approve」** — エージェントが README のリンクから
  スクリプトを読んだ瞬間に破綻。デフォルト read-only から始めて拡張するのが正解
- **「Approval プロンプトは雑音」** — 安い保険です。最悪ケースを既に許容した
  アクションだけ抑制してください

## 関連

- [リスクの mental model](./risk-mental-model.md) — なぜこのルールが必要か
- [Blast-radius を絞る](./blast-radius.md) — hook を超えた強制
- [`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands)
- [`examples/hooks/audit-all-tool-calls/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/audit-all-tool-calls)
