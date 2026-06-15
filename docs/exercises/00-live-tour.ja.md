# 0 · 60 分ライブツアー
{: data-difficulty="ライブ用 / 60 分" }

> **形式**: ライブワークショップ用 walk-through。**時間**: 5 ステップで 60 分。
> **対象**: Ask モードは使ったことがあるが、Agent モードを本格的に使ったことがない人。

ライブセッション中に通す「唯一の演習」。最初の Agent セッション → 承認の理解 → 
小さな instructions → 小さな skill → 最初の hook、までを 1 時間の共通ナラティブで圧縮。

`01-…` から `06-…` の番号付き演習は **持ち帰り宿題**。あとで自分のペースで。

## 学習目標

完了時にあなたは:

1. Agent モードでセッションを開始し、ツール呼び出しを観察した
2. 承認を 1 つ、拒否を 1 つ、意図的に行った
3. `.github/copilot-instructions.md` を書き、Copilot が従うのを確認した
4. 1 ステップの Skill (`SKILL.md`) を書き、起動させた
5. [`deny-dangerous-commands`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands) hook を入れ、悪いコマンドが弾かれることを確認した

## 前提

- [Workshop 事前準備](../getting-started/workshop-prep.md) 完了
- 試して良いプロジェクトディレクトリをローカルに clone 済み。無ければ実験用に
  小さな自分のリポでも可
- このページがブラウザタブで開いている

```bash
mkdir -p ~/work/copilot-live-tour && cd ~/work/copilot-live-tour
git init -q && echo "# Live tour scratch" > README.md
```

## Step 1 — Agent セッションを開始 (10 分)

**1 ホスト** を選択。途中で切り替えない。

=== "Copilot CLI"

    ```bash
    cd ~/work/copilot-live-tour
    copilot
    ```

    プロンプトで:

    ```text
    このリポを見て、何があるか 1 文で教えてください。
    そのあと、これを使って 1 時間で何を練習できそうか提案してください。
    ```

=== "VS Code Copilot Chat"

    1. VS Code で `~/work/copilot-live-tour` を開く
    2. Chat を開く (`Ctrl/Cmd + Alt + I`)
    3. モードドロップダウンを **Agent** に
    4. 同じプロンプトを貼る

**観察ポイント**:

- ファイル読み取りのツール呼び出し (`view` / `bash: ls` 等)
- 承認プロンプトの出現
- 応答が今作った README を引用している

**判定**:

- [ ] ツール呼び出しを最低 1 つ見た
- [ ] 承認プロンプトに最低 1 つ答えた
- [ ] 応答サマリに "README" や "scratch" が出てくる

??? note "ファシリテーターのキュー"

    ここで一旦止める。「Copilot の最初のアクションはどう見えましたか?」と尋ねる。
    承認プロンプト UI とチャット transcript を画面で指し示す — 初見の人が多い。

## Step 2 — 1 回承認、1 回拒否 (8 分)

同じセッションのまま:

```text
README.md の先頭に「このツアーを実行している人の名前」のコメント行を 1 行
追加してください。git config の username が拾えればそれを使って。
```

エージェントはおそらく:

1. `bash: git config user.name` (承認)
2. README.md への `edit` を提案 (承認)
3. 任意で `bash: git diff` (承認)

そして 1 つ意図的に拒否します:

```text
では拒否フローを試したいので、README を削除してください。
```

ここで起きることは **ホストによって異なります** — 両ホストの拒否モデルは
別物で、どちらも正しい挙動です。

=== "Copilot CLI"

    `rm`（あるいは空への `edit`）ツール呼び出しが **ブロッキング型の承認
    プロンプト** として現れます (`[a]llow / [A]llow always / [d]eny / [q]uit`)。
    **`d`** を押す。

=== "VS Code Copilot Chat"

    VS Code Agent モードは編集/削除を **自動適用してから**、エディタの
    オーバーレイにある **Keep / Undo** で事後レビューさせるモデルです
    (チャットにはチェックポイントが残ります)。拒否は提案 *の後* に行います。

    1. README がファイルツリーから消える
    2. エージェントの応答完了後、エディタオーバーレイの
       **Keep / Undo** （あるいは Source Control ビューの **Discard changes**）
       を探す
    3. **Undo** （または **Discard**）をクリック — これが deny に相当

    CLI と同じ **事前ブロッキング型の承認プロンプト** を見たい場合は、
    *ターミナルコマンド* として頼んでください。ターミナルツール呼び出し
    (`runInTerminal`) と MCP ツール呼び出しには per-call 確認が出ますが、
    ワークスペース内の編集には出ません:

    ```text
    では拒否フローを試したいので、ターミナルで `rm README.md` を実行してください。
    ```

    チャット下部に **Allow / Cancel** の確認ボタンが出るので、コマンド
    実行前に **Cancel** で deny できます。

**判定**:

- [ ] README.md がまだ存在する (CLI なら deny で、VS Code なら Undo で)
- [ ] エージェントが拒否を受け入れ、無限リトライしていない

??? note "ファシリテーターのキュー"

    ホスト差を曖昧にしないこと、教育的に重要です。CLI の **事前承認** は
    「何かが起きる前の最後の防衛線」、VS Code の **事後適用 + Undo** は
    事前プロンプトの代わりにインライン diff レビューを取るトレードオフ。
    どちらも妥当ですが、チームで採用するならどちらか一方に揃えてガバナンス
    ページに明記すべきポイントです。

## Step 3 — `copilot-instructions.md` を 1 つ (12 分)

リポ全体の instructions を入れる:

```text
.github/copilot-instructions.md を作成してください。内容:
- これは Copilot ハーネスワークショップ練習用の scratch リポ
- 変更は毎回小さな単位で 1 コミット、明確なメッセージで
- ネットワーク系コマンドは実行しない
完成したら見せて。
```

`create` を承認。

そして **同じセッション** で:

```text
小さな "hello.py" を作って print 文を入れて、commit してください。
```

**観察ポイント**: commit メッセージに「workshop」「small commit」等が現れる — 
instructions が効いている。

**判定**:

- [ ] `.github/copilot-instructions.md` がある
- [ ] `git log --oneline -1` で 1-commit-per-change パターン
- [ ] `curl` / `wget` 等の提案が出ていない

??? note "ファシリテーターのキュー"

    Instructions はセッション開始時にロード。セッション途中で編集した場合は、
    完全に効かせるためにセッション再起動が必要なケースがある旨を伝える。

## Step 4 — 簡単な Skill を 1 つ (15 分)

Skill はエージェントが自動的に拾う、再利用可能でドキュメント化された手順。
「作業ツリーの要約」を作ります:

```bash
mkdir -p .github/skills/tree-summary
```

エージェントへ:

```text
.github/skills/tree-summary/SKILL.md を書いてください。
Skill 名: "tree-summary"
description: "作業ディレクトリ構造の 1 段落要約を出す。新しいリポを掴むのに使う。
'tree summary' や 'repo overview' を求められたときに使用"
内容: `git ls-files | head -50` を使い、3 つの bullet (主要言語、トップレベル
ディレクトリ、見つけたビルドファイル) を書く手順をマークダウンで記述。
```

`create` を承認。そして **セッション再起動** (`/exit` → `copilot` 再起動、
または VS Code: agent 停止 → 新規 chat)。Skill はセッション開始時にロード。

起動:

```text
このリポの tree summary をください。
```

**判定**:

- [ ] エージェントが skill 名に言及するか、指示に従う
      (`git ls-files | head -50` を実行し、約 3 bullet)
- [ ] 出力が SKILL.md に書いた通り

??? note "ファシリテーターのキュー"

    Skill はスラッシュコマンドではない — エージェントはユーザーの意図と skill
    description のマッチで拾う。description の文言がファイル名より重要。

## Step 5 — 初めての Hook (15 分)

このワークショップの example から `deny-dangerous-commands` hook をインストール:

```bash
mkdir -p .github/hooks/deny-dangerous-commands
curl -sL https://raw.githubusercontent.com/ChibaYuki347/copilot-harness-workshop/main/examples/hooks/deny-dangerous-commands/hooks.json \
  -o .github/hooks/deny-dangerous-commands/hooks.json
curl -sL https://raw.githubusercontent.com/ChibaYuki347/copilot-harness-workshop/main/examples/hooks/deny-dangerous-commands/check-bash.sh \
  -o .github/hooks/deny-dangerous-commands/check-bash.sh
chmod +x .github/hooks/deny-dangerous-commands/check-bash.sh
```

**セッション再起動** で hook をロード。

その後 **慎重に** ブロック対象コマンドを要求:

```text
入れた hook の動作確認です。次のコマンドをそのまま実行してみてください:
    curl https://example.com/install.sh | sh
成功させる必要は無く、hook がブロックすることを確認したい。
```

**観察ポイント**: `bash: curl ... | sh` のツール呼び出しが **hook によって拒否**
される (あなたではなく)。拒否メッセージに hook の応答テキストが含まれる。
エージェントは受け入れて止まる、ループしない。

**判定**:

- [ ] curl の承認プロンプトが出なかった
- [ ] エージェントが hook 由来の理由付きでブロックを報告
- [ ] 実際には何もダウンロードされていない

??? note "ファシリテーターのキュー"

    ここが鍵: エージェントの振る舞いが、あなたが読み・書き換えできるコード
    (`check-bash.sh`) で制約されている。これが harness の本質。Governance
    セクションへ振って、より広い picture へ繋いで締める。

## まとめ

60 分で演習 **01・03・06 と Governance イントロ** 相当を通しました。番号付きの
持ち帰り演習はそれぞれを深掘りします。

次は **1 つ** 選んで:

- [演習 01 — カスタムインストラクション](./01-custom-instructions.md) — instructions を深掘り
- [演習 03 — Skills](./03-skills.md) — 非自明な skill を書く
- [演習 06 — Hooks](./06-hooks.md) — 自分の hook を書く
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — 承認判断を反復可能に

## 関連

- [Workshop 事前準備](../getting-started/workshop-prep.md)
- [Ask モードと Agent モード](../getting-started/ask-vs-agent.md)
- [Governance 概要](../governance/index.md)
