# Ask モードと Agent モードの違い

Copilot を使ったことがある人のほとんどは **Ask モード** だけを使っています — 
質問に答えて diff を提案するチャットサイドバー。**Agent モード** は 2 つ目のモード
で、Copilot があなたの代わりに行動します: ファイルを編集、コマンドを実行、ツールを
呼び出し、1 ユーザーターンの中で判断を下す。

「どうやって X する?」を Copilot Chat で聞いたことがあれば、Ask モードは使えています。
Copilot が自律的にリポを編集して `npm test` を流すのを見たことがなければ、まだ
Agent モードは触っていないのと同じです。

このページがその橋渡し。

## 横並び比較

| | **Ask mode** | **Agent mode** |
|---|---|---|
| 起動場所 | VS Code Chat パネル (既定)、Copilot Chat web、GitHub.com モバイル | Copilot CLI、VS Code Chat agent (Preview)、GitHub.com Copilot Workspace |
| 何をする | 回答、コード生成、diff 提案 | ファイル読み取り、編集、`bash` 実行、MCP ツール呼び出し、失敗時のリトライ |
| 各ステップの決定者 | あなた — 提案をコピーするか「Apply」をクリック | Copilot。あなたは各ツール呼び出しを承認 |
| 1 タスクあたりのターン数 | しばしば複数 (「聞く・コピペ・また聞く」) | しばしば 1 つ (「ゴールはこれ」とだけ伝えてループ) |
| Mental model | 肩越しのペアプロパートナー | キーボード前のジュニアメンバー |
| 失敗モード | コンテキスト不足、間違った提案 | 自信を持って間違った行動を取る |

## どっちを使う?

- **Ask モード**: 小さく scope された質問、見慣れないコードの説明、目視レビュー前提
  のクイック refactor、副作用を起こしたくないもの
- **Agent モード**: 多段階タスク (「`/healthz` エンドポイントを追加 → ルーターに
  繋ぐ → テスト書く → テストスイートを流す」)、複数ファイルに渡る refactor、
  spec より反復で進めたい spike

経験則: Ask で始めて、回答が「では 5 ファイルでそれをやって」になった瞬間に
Agent へ切り替える。

## Agent モードの起動

### Copilot CLI

```bash
cd ~/work/my-project
copilot
```

デフォルトが agent 的な振る舞いです — ゴールを打てばエージェントがファイルを
読み行動を提案。allow-list を設定していない限り、各ツール呼び出しに承認を求めます。

### VS Code Chat (Preview)

1. Chat ビューを開く (View → Chat、または `Ctrl/Cmd + Alt + I`)
2. 下部のドロップダウンで **Ask** から **Agent** へ切替
3. チャット入力に「tools」ピッカーが現れる — エージェントが使えるツール
4. プロンプトを送信。ツール呼び出しが inline で `Approve` / `Deny` ボタンと共に表示

「Agent」がドロップダウンに無ければ Copilot Chat 拡張がエージェント展開前のバージョン。
更新してウィンドウを再読み込み。

## 「承認」の見え方

Agent モードでは、新しいプロンプトを受けた最初の本能はコンテキスト収集。つまり
ツール呼び出しが発生し、以下のようなプロンプトを見ます。

**CLI**:

```text
Copilot wants to run:

    bash: npm test

[a]llow once  [A]lways allow  [d]eny  [q]uit
```

**VS Code**:

チャットパネルが一時停止し、ツール名・正確な引数 (ファイルパス、shell コマンド、
MCP ツール入力) を表示、`Approve` / `Deny` を提示。「Approve」ボタンの dropdown に
「Approve and don't ask again for this tool」あり。

初回に覚えておくこと 2 つ:

1. **引数は全文表示される**。エージェントは category ではなく具体コマンドへの
   許可を求めている。コマンドが変ならば deny
2. **「Always allow」はセッション残り全体に効く** (「for this workspace」を選べば
   今後のセッションにも)。摩擦なく繰り返して欲しい (`npm test`、`pytest`) に
   使い、`bash` をカテゴリ丸ごとには使わない

## 画面の見方 — CLI

エージェントが思考中:

- ストリーミングしてくる応答 (モデルの言葉)
- 「Tool call」ブロック (ツール名と要約)
- ネストしたツール呼び出し (実行結果を読んで次を決める)
- 最後に回答や「これらのファイルを変更しました: …」サマリ

覚えるキー:

- `Ctrl+C` 1 回 — 今のターンを中断 (エージェントは止まり、プロンプトを直せる)
- `Ctrl+C` 2 回 — 終了
- `Shift+Tab` — モード切替 (Plan / Edit / Default)
- `/help` — スラッシュコマンド一覧
- `/usage` — トークン + 課金状況

## 画面の見方 — VS Code

エージェント作業中:

- チャットバブルがストリーミング
- ツール呼び出しカード (既定は折りたたみ — クリックで全入力)
- ファイル diff が標準の accept/reject リボン付きでエディタに出現
- チャットパネル下部のステータス: "Working…" / "Waiting for approval" / "Done"

下部が「Waiting for approval」なのにボタンが見えない場合、承認プロンプトは上の方の
別のツール呼び出しカードにある — スクロールアップ。

## 同じスキル、異なるホスト

次に学ぶカスタマイズ (Instructions / Skills / Hooks / MCP) は両ホスト共通。日常で
触る方をライブセッション用に選んでください。カスタマイズファイルは失わずに
あとから乗り換え可能。

## 関連

- [Workshop 事前準備](./workshop-prep.md) — ライブ用に両ホストをインストール
- [最初のセッション](./first-session.md) — 実 Agent セッションをステップごとに
- [Reference → VS Code vs Copilot CLI](../reference/vscode-vs-cli.md) — どの機能がどこで動くか
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — 何を allow し何を deny するか
