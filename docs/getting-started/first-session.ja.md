# 最初のセッション

エージェントループを 10 分で体験し、最後には実際にファイルを 1 つ変更できるチュートリアルです。

!!! abstract "トラックを選ぶ"
    === "🟦 Ask モードはすでに使っている — 速習コース"

        すでに **Copilot の Ask モード**（チャットサイドバー）は使っていて、
        Copilot が **ファイルを編集しコマンドを自分で実行する** ようになると
        何が変わるかを体感したい方向け。次の順で:

        1. 下の最初の 2 セクション — **プロジェクトを選ぶ** + **リポを理解してもらう**
           — を読む。両トラック共通です。
        2. **「ステップ 3 — 変更を計画する（プランモード）」の詳細はスキップ** し、
           `Shift+Tab` を 1 回押してプランモードが何をするか触ったら戻る。
        3. **ステップ 4 — ツールの承認** と **ステップ 5 — コミット前に diff を確認**
           に集中する。Ask モードからの mental model の本当の差分はここ。
        4. その後、[Ask vs Agent モード](ask-vs-agent.md) で side-by-side の参考資料、
           [ガバナンス → 承認チートシート](../governance/approval-cheatsheet.md) で
           実務での許可・拒否基準を確認。

    === "🟢 完全に初見 — ガイドツアー"

        Copilot エージェントは初めて（または Ask モードを少し触っただけ）の方は、
        以下のステップを順番に全部やってください。15〜20 分の想定です。「完璧な
        初プロンプト」を狙う必要はありません — 目標はエージェントループ
        （prompt → tool call → 承認 → 結果）を一度体感することだけ。

        - 途中で混乱したら、[Ask vs Agent モード](ask-vs-agent.md) プライマーで
          mental model を 5 分で押さえて戻る
        - このページの後は [カスタマイズ概要](../customizations/index.md) で、
          チームに合わせて Copilot を整えていく方法へ

---

## ステップ 1 — プロジェクトを選ぶ

試しに使っても差し支えないリポジトリを用意します。このツアーでは、小さめの
Python / Node / Go プロジェクトを想定します。手元にない場合は、よく知っている公開リポジトリを `git clone` します。

```bash
cd ~/code/my-project
copilot
```

スプラッシュ画面、信頼確認のプロンプト、その後に空の入力欄が表示されます。

## ステップ 2 — Copilot にリポジトリを把握させる

いきなり変更には入りません。まずはエージェントにプロジェクトを *理解* してもらいます:

```text
Take a look at this repo and tell me:
1. What is it for, in one sentence?
2. What's the build/test command?
3. What's the riskiest file or function I should know about before changing things?
```

Copilot はファイルを読み（承認を求められる場合があります）、ディレクトリ構成を確認し、
`git log` なども実行します。出力を見ることで、エージェントが大まかに正しい理解を持っていると
判断しやすくなります。

!!! tip "`@` で正確に指定する"
    対象のファイルがわかっている場合は、直接指定します。`@src/server.ts` を使うと、そのファイルが
    すぐにプロンプトコンテキストへ入ります。エージェントに検索させるより速くなります。

## ステップ 3 — 変更を計画する（プランモード）

**`Shift+Tab`** を押して **プランモード** に切り替えます。プランモードでは Copilot は
コードを書かず、確認質問をしながら構造化された計画を提案します。

```text
Add a /healthz endpoint that returns {"status":"ok"} as JSON. Plan it.
```

計画を確認します。納得できない点があれば修正を求めます。準備ができたら、もう一度 `Shift+Tab`
でプランモードを終了し、実装を依頼します。

## ステップ 4 — 適切なツールを承認する

Copilot がツール（`bash`, `npm`, `pytest`, …）を実行しようとすると、次のようなプロンプトが表示されます:

```
Allow npm test?
  1. Yes
  2. Yes, and approve npm for the rest of this session
  3. No, and tell Copilot what to do differently
```

安全で頻繁に使うツール（`npm`, `pytest`, `git status`）には **(2)** を選びます。
破壊的な操作（`rm`, `git push`, `gh pr merge`）には **(1)** を選びます。承認前には必ず引数を
確認します。`rm -rf node_modules` ならおそらく問題ありませんが、`rm -rf ~/` であれば
**拒否** してフィードバックします。

!!! warning "`--allow-all-tools` は危険です"
    `-p` / `--prompt` のプログラマティックモードでは `--allow-all-tools` を利用できます。
    Copilot の影響範囲が小さい CI 環境（コンテナ化された環境、使い捨ての checkout）でのみ使います。開発マシンでは
    使わないでください。

## ステップ 5 — 受け入れる前に確認する

Copilot の処理が終わったら、次を実行します:

```text
Show me the diff and explain what changed in each hunk.
```

その後、テストは自分で実行するか、Copilot に実行してもらいます:

```text
Run the tests and report failures only.
```

## ステップ 6 — 仕上げる

問題なければ:

```text
Commit the changes with a conventional commit message and push.
```

納得できなければ:

```text
Revert your changes; let's redo the implementation differently.
```

`/undo` を使うと、ファイル編集を含めて直前のターンを巻き戻せます。

## このツアーのチートシート

| 操作 | 方法 |
|---|---|
| ファイルを指定する | `@path/to/file` |
| Issue / PR を指定する | `#123` |
| シェルコマンドをそのまま実行する | `!ls -la` |
| プランモードに切り替える | `Shift+Tab` |
| 現在のターンを中断する | `Esc` |
| 直前のターンを巻き戻す | `/undo` |
| コンテキストウィンドウの容量を節約する | `/compact` |
| コンテキストに読み込まれている内容を表示する | `/env` |

→ [スラッシュコマンド入門](slash-commands.md)
→ あるいは [カスタマイズ](../customizations/index.md) に進み、ハーネスを形に
していきます。
