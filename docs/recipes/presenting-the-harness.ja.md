# レシピ — ハーネスを社内で紹介する

!!! info "対応: 🟢 Copilot CLI + VS Code Copilot Chat"
    どちらのホストでも回せる台本です。各 money shot に CLI / VS Code 両方の
    手順を載せています。**本番中にホストを切り替えないこと。** 事前に 1 つ選ぶ。

**5 分 / 15 分 / 45 分の presenter ラダー。このレポをそのまま live demo として
使って、社内チームや meetup で Copilot ハーネスを紹介する台本です。**

## 何のためのページか

このサイトには既に 2 つの導線があります:

- **学習者向け** — [Try this repo as a live demo](../getting-started/try-this-repo.md)
  と [Exercises](../exercises/index.md)。**あなたが** キーボードを触る前提。
- **ワークショップ受講者向け** — [Exercise 0: 60 分ライブツアー](../exercises/00-live-tour.md)。
  **誰か他の人が** 1 時間キーボードを触る前提。

抜けているのが **presenter** 視点 — 5 分のチーム MTG で見せる人、コーヒーチャットで
15 分話す人、45 分のブラウンバッグを回す人。聞き手にハーネスの概念
(Skills + Hooks + MCP + Instructions + Agents) と、自走するための次の一手を
持ち帰ってもらうための台本がない。

このレシピがそれです。

## 使うレイヤー

- リポルートの live demo 全部 — `.github/{skills,instructions,hooks,prompts,agents}/`、`.mcp.json`
- 監査フック (`.github/hooks/audit-demo/log.sh`) — エージェントの動きをリアルタイムで可視化
- [devcontainer](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md) — 借り物の PC でもゼロインストールでデモ可能

## バケットを選ぶ

| Bucket | こういう時に | 持ち帰るもの |
|---|---|---|
| **5 分 — lightning** | 朝会、チーム MTG、廊下デモ | 「Copilot は単なるチャットボックスじゃなくて、**ハーネス**で形を変えられる」というメンタルモデル + money shot 1 つ |
| **15 分 — コーヒーチャット** | コーヒー、軽めのデモ、興味を持った上司への紹介 | Lightning + Skills + path-specific instructions + audit log。聞き手は **語彙** を持ち帰る |
| **45 分 — ブラウンバッグ** | 社内ブラウンバッグ、勉強会発表、ランチ&ラーン | コーヒーチャット + Hooks + MCP の触り + ガバナンス一行 + 演習への引き継ぎ。聞き手は **始められる** 状態で帰る |

既存の [Exercise 0 — 60 分ライブツアー](../exercises/00-live-tour.md) は受講者が
手を動かすハンズオン用の 60 分トラック。presenter としてやるのではなく、
**ファシリテート** してください。

## 共通セットアップ (どのバケットでも最初に)

下記の順で実行。初めての PC でも 3〜4 分、慣れていれば 30 秒。

### 1. Codespaces でレポを開く

```text
https://codespaces.new/ChibaYuki347/copilot-harness-workshop
```

[devcontainer](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/.devcontainer/README.md)
が Python / Node / `gh` / `jq` / Copilot CLI / mkdocs を全部入れます。
`✅ copilot-harness-workshop devcontainer ready.` が出たら準備完了。
組織で Codespaces が禁止なら **Dev Containers: Reopen in Container** で
ローカル Docker でも同じことができます。

### 2. ペインを 3 つ並べる

ターミナル分割 (VS Code 分割、tmux、iTerm splits) でペイン 3 つを同時に
見せます。観客はこの 3 つを同時に読んで、**それがデモの全部** です:

```text
┌────────────────────────────┬────────────────────────────┐
│                            │                            │
│   PANE 1: copilot セッション│  PANE 2: 監査ログ tail     │
│   (あなたが入力する)        │  (触らない — エージェントが  │
│                            │   ツール呼ぶたびに流れる)  │
│                            │                            │
├────────────────────────────┴────────────────────────────┤
│                                                         │
│   PANE 3: VS Code エディタ on .github/                  │
│   (最後の "実はこれが裏で動いていた" の reveal 用)       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Pane 2 で:

```bash
tail -f ~/.copilot/copilot-harness-audit.log
```

### 3. 一度だけ認証

```bash
gh auth status || gh auth login --web
```

Codespaces はだいたい既に認証済み。ローカルなら device-code フロー。
`copilot` は同じ認証情報を再利用するので、別途 `/login` する必要はありません
(求められたらする)。

### 4. ブラウザでサイトを開いておく

```text
https://chibayuki347.github.io/copilot-harness-workshop/
```

最悪 live demo が固まったら、サイトを画面共有しながら同じ内容を口頭で
話せます。これが最後の保険。

## 5 分版台本 — lightning

**ゴール**: 「Copilot にはハーネスがある」を持ち帰ってもらう。

| 時刻 | 言うこと | 画面 |
|---|---|---|
| 0:00 — 0:30 | 「Copilot をチャットボックスとしか見ていない人が多いけど、その周りに **ハーネス** がある。リポの中のファイルで挙動を変えられる。5 つある: Instructions / Skills / Prompt Files / Hooks / MCP。4 分で見せます」 | ブラウザタブで [Mental model](../customizations/mental-model.md) の図 |
| 0:30 — 1:00 | 「このレポ自体がデモ — これから見せるものは全部 `.github/` の中にある」 | Pane 3 に切替。`.github/` をスクロールして `instructions/` `skills/` `hooks/` `prompts/` `agents/` を見せる。**ファイルは開かない** |
| 1:00 — 3:30 | 「起動時にエージェントが何を読んだか見てください」と言って下のプロンプトを打つ | Pane 1: `copilot`、続いて **下のプロンプト**。Pane 2 がリアルタイムで流れる |
| 3:30 — 4:30 | 「右ペインの 1 行 = エージェントが呼んだツール 1 つ。これが **監査フック** のログ。エージェントは 7 つの instruction ファイルも自動で読んでる — `.github/instructions/` から。これがハーネス」 | 両ペイン同時表示のまま |
| 4:30 — 5:00 | 「試したい人は [chibayuki347.github.io/copilot-harness-workshop](https://chibayuki347.github.io/copilot-harness-workshop/) — Codespaces のボタンがあります。質問は後で」 | ブラウザタブをサイト Home に |

Pane 1 で打つプロンプト:

```text
Read .github/copilot-instructions.md and the files in .github/instructions/
then tell me in two sentences what conventions this repo enforces.
```

これが lightning の money shot: 右ペインが流れて、左ペインが
**instructions を読んだから** 正しい答えを返す。コードは 1 行も書いてない。

## 15 分版台本 — コーヒーチャット

5 分版を先にやってから、下の 3 ビートを足す。

### Beat 1 — 「他に何を知ってた?」 (3 分)

Pane 1、lightning の答えが終わった後で:

```text
/instructions
```

続いて:

```text
/skills
```

続いて:

```text
/agents
```

リストが流れる間に「これらは `.github/instructions/` `.github/skills/`
`.github/agents/` から来てる。全部リポにあるので、push すれば即チーム共有」と
ナレーション。

### Beat 2 — 「しかも *スコープ付き*」 (3 分)

```text
Show me what would change if I asked you to edit docs/recipes/foo.md
versus .github/workflows/ci.yml. Which conventions apply to each?
```

答えは前者に対しては path-specific instructions
(`.github/instructions/markdown.instructions.md` の `applyTo` glob)、後者には
リポ全体の instructions を引用する。

Money shot: instructions は **ファイルパスで条件分岐できる**。興味を
持っていた上司がここで「フロントとバックでルール分けるのにフォークしなくていいのか」
と気付くポイント。

### Beat 3 — 「しかも *監査可能*」 (2 分)

Pane 2 の tail を一瞬止めて:

```bash
wc -l ~/.copilot/copilot-harness-audit.log
head -5 ~/.copilot/copilot-harness-audit.log | jq -c '{tool: .toolName, repo: .repo}'
```

「今日エージェントが呼んだツール全部、append-only、構造化、session ID 付き。
Splunk に流すもよし、夜間で `rm -rf` パターンを scan するもよし、セキュリティ
チーム向けのエビデンスにするもよし。フック本体は `.github/hooks/audit-demo/log.sh`
の 30 行の bash。自分で書くなら午後で書ける」

最後にブラウザの [governance overview](../governance/index.md) タブを指差して
「こういう話、専用セクションがあります」 (開かなくていい)。

## 45 分版台本 — ブラウンバッグ

コーヒーチャット (≈ 15 分) を回した後、下の 4 ビートを足す。

### Beat 4 — instruction をライブで書く (8 分)

```bash
mkdir -p /tmp/demo-repo && cd /tmp/demo-repo && git init -q
cat > .github/copilot-instructions.md <<'EOF'
# Project conventions
- Reply in bullet points, never prose.
- Always end with a single 🦆 emoji.
EOF
copilot
```

セッション内で:

```text
Tell me what this repo is about.
```

返事は bullet で、🦆 で終わる。「2 行の instructions、再学習なし、デプロイなし、
`git add` でチーム全員が明日から使える」

次の Beat に進む前に workshop レポに戻る。

### Beat 5 — Skills > Prompt Files > Slash Commands (8 分)

Pane 3 で `.github/skills/site-build-check/SKILL.md` を開く。
Frontmatter (`name` / `description`) を音読する。「Skills は再利用可能な
ワークフロー。エージェントが `description` を見て自律的に発見する。チームの
業務ボキャブラリーを Copilot に教える方法」

Pane 1 で:

```text
/skills
```

`site-build-check` を選ぶ:

```text
Use site-build-check to verify the docs build.
```

エージェントが `mkdocs build --strict` を回して結果を返す。Pane 2 に全 step が
ログされる。

「同じファイルが VS Code Chat でもそのまま動く — `.github/skills/` 配下、
同じパス、同じ `SKILL.md`。ホストを問わない」

### Beat 6 — Hooks は止め、MCP は広げる (8 分)

Pane 3 で `.github/hooks/audit-demo/hooks.json` を開く。「これは
**観測用** のフック — `postToolUse`、読みだけ。`preToolUse` 版もあって、
ツール呼び出しを **ブロック** できる。`examples/hooks/deny-dangerous-commands/`
に `rm -rf` を止める実例がある。今日 live で入れないのはデモが地味になる
から; リポには入ってる」

`.mcp.json` (root) を開く。「初期状態で MCP サーバーは 0 件 — 安全側に
振ってる。ここに GitHub MCP server を足したり、社内 MCP を足したりする。
[専用のレシピ](github-mcp-server.md) がある」

Pane 1 で:

```text
/mcp
```

空リストが出る、それが大事。「Trust はだんだん上げる、下げない」

### Beat 7 — 演習トラックに引き継ぐ (5 分)

ブラウザを [Exercises track](../exercises/index.md) に。読まないで、
ラダーを指差す: 1 → 2 → 3 → 4 → 5 → 6 → capstone。「今日刺さった人は、
来週 1 番、再来週 3 番、capstone はいつでも。全部 self-contained で、
今日と同じ Codespace で回せる」

続けて [governance overview](../governance/index.md):「チームに展開
するなら、このセクションは 30 分の必読」

最後 1 分: 質問。

## Money shot — カメラを向けるべきフレーム

聞き手が各バケットで 1 フレームだけ覚えて帰るとしたら、これ:

| Bucket | フレーム |
|---|---|
| 5 分 | Pane 2 (監査ログ) が流れている隣で Pane 1 (エージェント) が正しく答える。**ライブの可観測性** |
| 15 分 | エージェントが `docs/recipes/foo.md` と `.github/workflows/ci.yml` で適用ルールを正しく区別する答え。**スコープ付き instructions** |
| 45 分 | `/tmp/demo-repo` の 2 行の `copilot-instructions.md` で挙動が bullet + 🦆 に変わる。**小さな変更、本物の挙動変化** |

## フォールバック — 本番で壊れた時

| 障害 | 代替手 |
|---|---|
| Codespaces が立ち上がらない | ブラウザで [Try this repo as a live demo](../getting-started/try-this-repo.md) を開き、サイトを音読。スクショは同じフローを示している |
| `copilot` が認証通らない | 5 分版を完全にブラウザ画面共有でやる。[Mental model](../customizations/mental-model.md) と [Customizations overview](../customizations/index.md) で台本がそのまま回る |
| 監査ログが煩い | セッション内で `export COPILOT_HARNESS_AUDIT=0` して `copilot` 再起動。フックは no-op に、他は普通に動く |
| `tail -f` に何も出ない | フックは `bash` と `jq` が必要。devcontainer 内なら両方保証。ローカルなら `which jq` で確認、無ければ `brew install jq` / `apt-get install jq` |
| ネット落ち | Beat 4 (instruction をライブで書く) に飛ぶ。初回応答以降ネット不要で、**結果** が学びの本体 (応答速度ではない) |

## トーク後に送る一文

セッション後にチャット / メールにそのまま貼れる:

```text
今日見せた内容: https://chibayuki347.github.io/copilot-harness-workshop/
カスタマイズは 5 レイヤー、全部 live でリポに wired: .github/{instructions,skills,prompts,hooks,agents}
インストール無しで触りたい人: https://codespaces.new/ChibaYuki347/copilot-harness-workshop
自走演習: docs/exercises/ (まず 1 番、来週 2 番、capstone はいつでも)
```

## バリエーション

- **社内チャンピオン版** — レポ URL を自分の fork に差し替え、Beat 5 のスキルを
  チーム固有のもの (例: Jira チケット要約) に置き換える。聞き手が自分の業務を
  認識して、ハーネスの学びが刺さる強さが倍違う
- **meetup スピーカー版** — このレポをそのまま使う (内部コンテキストの漏洩リスク
  がゼロ)。ただし 5 分版の前に「自分のチームが Copilot で何をやってるか」の
  スライドを 1 枚足すこと。無いと聞き手は「GitHub の中の人かな?」と勝手に
  仮定する
- **ブラウンバッグはやめて workshop を回す** — 1 時間あって、参加者にも手を
  動かしてほしいなら、このレシピは捨てて [Exercise 0](../exercises/00-live-tour.md)
  をファシリテーター cue 通りに回す。**プレゼンとファシリテーションを同時に
  やろうとしないこと**
