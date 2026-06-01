# このレポを live demo として試す

ハーネスの各レイヤーがどう組み合わさるかを体感するのに、別のサンプル
プロジェクトを用意する必要はありません。**`copilot-harness-workshop`
レポ自体が、本サイトで説明している customization をすべて wired-up した
状態でデモになっています**。クローンしてレポルートでセッションを開けば、
各レイヤーが live で動きます。

> **既定で read-only。** wiring は *安全側に倒して* あります — `preToolUse`
> フックは一切なく (ツール呼び出しを block / 改変できない)、同梱の MCP
> 設定はサーバー 0 件、audit フックはレポ外のログファイルにのみ書き出します。
> 各レイヤーは 1 ステップで opt-out できます (下記 [opt-out 方法](#opt-out)
> 参照)。

## レポルートに wired-up されているもの

| レイヤー | パス | 何が見えるか | 確認コマンド |
|---|---|---|---|
| Custom Instructions (レポ全体) | `.github/copilot-instructions.md` | サイト固有の規約がセッション開始時にロード | `/instructions` |
| Custom Instructions (パス指定) | `.github/instructions/markdown.instructions.md` | `docs/**/*.md` 編集時にだけ追加適用される規約 | `/instructions` → `docs/` 配下を編集してもらう |
| Prompt Files | `.github/prompts/new-recipe.prompt.md` | `/new-recipe` スラッシュコマンドが追加 | `/help` → `/new-recipe my-slug` |
| Skills | `.github/skills/site-build-check/`, `.github/skills/translate-page/` | このレポ固有の Skill 2 つが discover される | `/skills` |
| Hooks | `.github/hooks/audit-demo/` | 成功したツール呼び出しごとに metadata のみの JSONL 1 行を audit ログへ追記 | `tail -f ~/.copilot/copilot-harness-audit.log` |
| MCP サーバー | `.mcp.json` (ルート) | 設定はロードされるが、サーバーは 0 件 (既定) | `/mcp` |
| Custom Agents | `.github/agents/docs-reviewer.agent.md` | `docs-reviewer` サブエージェントが登録される | `/agents` |

すべて [`examples/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples)
にコピペ用テンプレートとしてミラーされています — そちらが docs から参照される
正本リソースです。上記 `.github/` のコピーは、**同じパターンをこのレポ自身に
wired-up したもの** と考えてください。

## 5 分ウォークスルー

### 1. クローンしてセッションを開く

```bash
git clone https://github.com/ChibaYuki347/copilot-harness-workshop.git
cd copilot-harness-workshop
copilot
```

trust 確認に答えると、Copilot は起動時に `.github/copilot-instructions.md` を
読みます — 最初の応答が「これは MkDocs サイトです」とすでに理解した上で
返ってくることで確認できます。

!!! tip "ゼロインストールで試したい場合"
    Python / Node / `gh` / `jq` / Copilot CLI をホストに入れたくない場合、
    本レポには Python 3.12 + Node LTS + 必要ツール一式を事前インストールした
    **devcontainer** が同梱されています。GitHub レポページの
    **Code → Codespaces → Create codespace** か、ローカルなら
    **Dev Containers: Reopen in Container** で開けます。詳細は
    [devcontainer README](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md)
    を参照。

### 2. ロードされた customization をすべて一覧する

セッション内で次を順番に実行:

```text
/instructions
/skills
/agents
/mcp
```

以下が見えるはずです:

- **`/instructions`** — `.github/copilot-instructions.md` と、パス指定の
  `markdown.instructions.md` (該当ファイル編集時のみ有効)。
- **`/skills`** — `site-build-check` と `translate-page`。
- **`/agents`** — `docs-reviewer`。
- **`/mcp`** — config はロード済み、サーバーマップが空 (0 件)。

もしいずれかが空の場合は下記 [トラブルシューティング](#troubleshooting)
を参照。

### 3. Skill を発火させる

```text
Verify the docs build is clean.
```

`site-build-check` Skill が `mkdocs build --strict` を実行し、結果をパースして
clean build か警告テーブルかで返します。**diagnostic 専用** — ファイル編集は
しません。

### 4. Hook の発火を見る

別ターミナルで:

```bash
mkdir -p ~/.copilot && touch ~/.copilot/copilot-harness-audit.log
tail -f ~/.copilot/copilot-harness-audit.log
```

> **`bash` が必要。** hook スクリプトは Bash です。macOS / Linux / WSL /
> Git Bash であれば動作します。Windows-native 環境では Copilot CLI
> の hook runner が自動でスキップし、ログは増えません。

Copilot に具体的な作業を依頼:

```text
List the recipe pages we have today.
```

**成功した** ツール呼び出しごとに、metadata のみの JSON-Lines が 1 行
追記されます:

```json
{"ts":"2026-06-01T12:00:01Z","repo":"copilot-harness-workshop","branch":"main","source":"copilot-harness-workshop","mode":"metadata","toolName":"bash","sessionId":"abc-123"}
```

既定モードでは **記録されない** もの: Copilot が実行したコマンド本体、
触ったファイルパス、ファイル内容、stdout、stderr。自分用のデバッグで
フル payload を見たいときは opt-in:

```bash
export COPILOT_HARNESS_AUDIT_FULL_PAYLOAD=1
copilot
```

フルモードのログは Copilot が見た内容を保持するため、機密扱いとして
取り扱ってください。

### 5. パス指定 instructions を試す

```text
Add a new H2 section to docs/getting-started/installation.md titled "Updating".
```

ファイルが `docs/**/*.md` にマッチするので、`.github/instructions/markdown.instructions.md`
の規約がレポ全体規約に上乗せで適用されます — Copilot が `##` 深さを使い、
英語の canonical な書き方を選び、些細な出力にも `bash` / `text` のフェンス
言語を付ける、といった違いを感じられるはずです。コミットしないで `/undo` で
巻き戻してください — 体感目的だけです。

### 6. カスタムエージェントへ委譲

```text
Run the docs-reviewer agent on the current diff.
```

diff が無ければエージェントは **OK 判定** ("No issues found") を返します。
実際の diff があれば (例えば `git checkout -b experiment` + 小さな編集後)
conventions 違反、リンク切れ、strict-build 警告などを検出します。

## first-session ツアーをこのレポでなぞる

[最初のセッション](first-session.md) は汎用的な 6 ステップ — エージェント起動 →
リポ把握 → プラン → ツール承認 → diff 確認 → コミット — を歩きます。**この**
レポで同じ流れを試せます:

| first-session のステップ | このレポでの試し方 |
|---|---|
| プロジェクトを選ぶ | `cd copilot-harness-workshop` |
| エージェントに把握させる | `Take a look at this repo and tell me what it's for, the build command, and the riskiest file.` (`mkdocs.yml` と `.github/workflows/deploy-pages.yml` を挙げてきます) |
| プランモード | `Shift+Tab` → `Add a "Updating" section to the Installation page. Plan it.` |
| ツール承認 | `mkdocs build` と `git diff` は session 限定で承認、`git push` は絶対に auto-approve しない |
| diff 確認 | `Show me the diff for the installation page.` |
| コミット | コミットせず `/undo` で巻き戻す (実験 edit を branch に残さない) |

## opt-out

各レイヤーは fork せずに無効化できます。Audit hook は env var で
ワーキングツリーを汚さずに切れます。

| レイヤー | opt-out (per-machine, リポ編集なし) | opt-out (ワーキングツリーを変更) |
|---|---|---|
| Audit hook | `copilot` 起動前に `export COPILOT_HARNESS_AUDIT=0` | `rm -rf .github/hooks/audit-demo` か `"postToolUse": []` |
| Skills | `~/.copilot/skills/<name>/` で user-scoped 上書き | `rm -rf .github/skills/<name>` |
| Prompt file | — | `rm .github/prompts/new-recipe.prompt.md` |
| パス指定 instructions | — | `rm .github/instructions/markdown.instructions.md` |
| Custom agent | `~/.copilot/agents/` で user-scoped 上書き | `rm .github/agents/docs-reviewer.agent.md` |
| MCP config | — | `rm .mcp.json` (既定で 0 サーバーなので、削除すれば `/mcp` から完全に消える) |

`~/.copilot/` 配下のユーザースコープ設定は workspace スコープと並行して
ロードされます。Audit hook を切るときは `COPILOT_HARNESS_AUDIT=0` が
最もクリーンです — `.github/` 配下のファイルを編集すると `git status`
に出てしまうので。

## トラブルシューティング { #troubleshooting }

| 症状 | 原因として多いもの | 対処 |
|---|---|---|
| `/skills` が何も表示しない | workspace skills discovery 未対応の古い Copilot CLI、もしくはサブディレクトリで起動した | Copilot CLI を最新化、レポルートで `copilot` を起動 |
| `/mcp` が空サーバーマップ表示でなくエラーになる | 空オブジェクトの `.mcp.json` を読めない CLI バージョン | [Customizations → MCP](../customizations/mcp.md) のダミーエントリを追加するか `.mcp.json` を削除 |
| audit ログファイルができない (Linux / macOS) | `.github/hooks/audit-demo/log.sh` が実行可能でない | `chmod +x .github/hooks/audit-demo/log.sh` |
| audit ログファイルができない (Windows-native) | `bash` が PATH に無い環境では hook runner が Bash hook をスキップ | Git Bash / WSL を導入する、もしくは「この環境では hook が no-op」と受け入れる |
| ログ行に `"jq not installed"` と出る | jq 未インストール時の最小フォーマットへフォールバック | `jq` をインストール (`brew install jq` / `apt install jq`) |
| パス指定 instructions が発動しない | 編集対象ファイルが `applyTo` の glob に一致していない | `.github/instructions/markdown.instructions.md` の `applyTo` は `docs/**/*.md` と `examples/**/README.md` のみ |

## See also

- [Workshop 事前準備](workshop-prep.md) — 上のウォークスルー前に Copilot CLI / VS Code Copilot Chat をインストール
- [カスタマイズ概要](../customizations/index.md) — wiring が示している各レイヤーの概念ページ
- [Exercises トラック](../exercises/index.md) — 同じレイヤーを自分のプロジェクトで作れるようになったら 1 → 6 を順に
- [リファレンス → ファイル配置](../reference/file-layout.md) — どの customization ファイルがどこに置かれ、何が discover するか
- [レシピ — ハーネスを社内で紹介する](../recipes/presenting-the-harness.md) — 自分で試した後、5 / 15 / 45 分の presenter ラダーでチームに見せる
