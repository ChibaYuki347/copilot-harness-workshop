# 2 · プロンプトファイル

🟢 **入門 · 約25分**

🟪 **トラック A — VS Code でも Copilot CLI でも動作します**（[詳細](../reference/vscode-vs-cli.md)）

## 学習目標

この演習を終えると、次のことができるようになります:

- YAML フロントマターと引数ヒントを持つプロンプトファイルを定義できるようになります。
- セッション内からスラッシュコマンド (`/pr-description`) として呼び出せるようになります。
- 引数を渡し、それがプロンプト本文に入ることを確認できるようになります。

## 前提条件

- `main` に少なくとも 1 コミットある、スクラッチ用の git リポジトリ。
- Copilot CLI で認証済みであること。
- 約25分。

## チェックポイントコミット

```bash
git commit --allow-empty -m "checkpoint: before prompt-files exercise"
```

## シナリオ

誰かが PR を開くたびに、説明文を毎回ゼロから書いていて、構成も少しずつばらついています。チーム全員が `/pr-description` として呼び出せて、しかも作り話ではなく実際の diff に基づく、1 つの標準テンプレートが欲しい状況です。

## 手順

### 1. 要約する diff があることを確認する

作業用リポジトリの中で、小さな変更を作って、プロンプトが実際の内容を扱えるようにします:

```bash
echo "# Lab repo" > README.md
git add README.md
git commit -m "feat: add README"
echo "## New section" >> README.md   # leave this one uncommitted on purpose
```

これで `git diff` と `git log origin/main..HEAD` の両方に内容が入ります。

### 2. プロンプトファイルを作成する

```bash
mkdir -p .github/prompts
```

`.github/prompts/pr-description.prompt.md` を作成します:

```markdown
---
description: "Draft a PR description from the current branch's diff."
argument-hint: "Optional base branch (default: origin/main)"
---

# /pr-description

The user gave you `$ARGUMENT` as the base branch. If empty, use `origin/main`.
If `origin/main` doesn't exist, fall back to `HEAD~1`.

## Task

1. Run `git log --oneline <base>..HEAD` and `git diff --stat <base>...HEAD`.
2. Read the diff hunks that look most interesting (≤ 10 files).
3. Produce a PR description with exactly these sections:
   - **Summary** (one sentence)
   - **What changed** (bulleted by area)
   - **Tests** (what's covered; "no test changes" if none)
   - **Risks** (≤ 3 specific risks, or "no notable risks identified")
4. Write the result to `.pr-description.md` and print its path.

## Constraints

- Don't invent reasons that aren't visible in the diff.
- If the diff is empty, say so and stop. Don't write a file.
```

**確認できる結果**: `ls .github/prompts/pr-description.prompt.md` が成功します。

### 3. セッションを開始してコマンドが登録されたことを確認する

=== "Copilot CLI"

    ```bash
    copilot
    ```

    セッション内で `/` を入力し、続けて `pr` と打ち始めます。自動補完に、フロントマターの説明付きで `/pr-description` が表示されるはずです。

=== "VS Code Copilot Chat"

    ワークスペースを VS Code で開き (`code .`)、Chat ビューを開きます
    (`Ctrl+Alt+I`)。**新しい prompt file を作った後はウィンドウのリロードが
    必要なケースが多い** です — VS Code は `.github/prompts/` をウィンドウ
    起動時にスキャンします。コマンドパレット → **Developer: Reload
    Window** で再読み込みします。

    その後、チャット入力で `/` を打ち、`pr` と打ち始めると、自動補完に
    `/pr-description` が出るはずです。

    出ない場合は、VS Code がファイルを検出しているか確認します:

    ```text
    /prompts
    ```

    このショートカットで **Configure Prompt Files** メニューが開き、VS Code
    が認識している prompt files が全部表示されます。ここに
    `pr-description` が無ければ、[トラブルシューティング](#troubleshooting)
    へ。

### 4. プロンプトを呼び出す

```text
/pr-description
```

エージェントの動きを見ます。`git log` と `git diff` を実行し、その後 `.pr-description.md` を書き出すはずです。

### 5. 引数付きで呼び出す

```text
/pr-description HEAD~1
```

今回は base が `HEAD~1` になるので、diff は小さくなります。生成されるファイルにも、その狭いスコープが反映されているはずです。

## 完了条件 { #definition-of-done }

次の 4 つをすべて満たせば完了です:

- [ ] `.github/prompts/pr-description.prompt.md` が存在し、フロントマターに `description` と `argument-hint` がある。
- [ ] セッション内で `/pr-` と入力すると、自動補完に `/pr-description` が表示される。
- [ ] `/pr-description` を呼び出すと、リポジトリルートに `.pr-description.md` が作成される。
- [ ] ファイルに、必須の 4 セクション（Summary / What changed / Tests / Risks）がすべて入っている。短くても構いません。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    docs サイトで使っている、整えたプロンプトファイルの例です:

    ```markdown
    --8<-- "examples/prompts/refactor-tests.prompt.md"
    ```

    上の `pr-description` プロンプトも、同じ形に従っています。番号付きの Task、明示的な Constraints、そして出力契約です。

    プロンプトファイルのフロントマターと引数について詳しくは、[カスタマイズ → プロンプトファイル](../customizations/prompt-files.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .github/prompts .pr-description.md
git restore README.md
```

## トラブルシューティング { #troubleshooting }

- **`/pr-description` が自動補完に出ません（CLI）。** ファイル名は必ず `.prompt.md` で終わる必要があります。`pr-description.md`（`.prompt` なし）のような名前だと無視されます。
- **`/pr-description` が自動補完に出ません（VS Code）。** 上から順に確認してください:
    1. **ウィンドウをリロード** (コマンドパレット → **Developer: Reload Window**)。VS Code は `.github/prompts/` をウィンドウ起動時にスキャンするため、セッション中に作成した新規ファイルはリロードまで認識されないことがあります。
    2. チャット入力で **`/prompts`** を実行。これで **Configure Prompt Files** が開き、VS Code が検出した prompt files の一覧が出ます。ここに無ければ VS Code は拾えていません — 下に進んでください。
    3. ファイルパスがちょうど `.github/prompts/pr-description.prompt.md` になっていることを確認 (拡張子は `.prompt.md`、`.md` ではない。フォルダは複数形の `prompts/`)。
    4. ファイルを VS Code で開き、YAML フロントマターが正しいことを確認 (`---` の閉じ忘れ、タブ文字混入が無いか)。フロントマターが壊れていると、エラーを出さずに discover からドロップされます。
    5. Settings で **`chat.promptFilesLocations`** を検索。デフォルトの `.github/prompts` エントリが `true` になっている必要があります。この設定をカスタマイズしているなら、自分のフォルダが含まれているか確認。
    6. monorepo で prompt file が親リポにある場合は **`chat.useCustomizationsInParentRepositories`** を有効化。
- **プロンプトは動くのに diff が見えません。** いまのブランチが `main` / `master` そのものではないことを確認してください。base との差分がないためです。まず `git checkout -b feature/test` で feature ブランチを作ってください。

## やってはいけないこと

- 本文に `origin/main` をハードコードしないでください。`$ARGUMENT` を使うことで、既定ブランチが `master` や `develop` など別名のリポジトリでも動くようになります。
- ユーザー確認を飛ばす `--yes` や非対話型 shell コマンドを本文に入れないでください。プロンプトファイルは **あなた** のパーミッションで実行されます。

## 発展課題

1. 2 つ目の引数を追加します: `argument-hint: "<base> [--draft]"`。`--draft` が渡されたら、Summary の先頭に `[DRAFT] ` を付けます。
2. `gh` を使って、結果をそのまま GitHub PR に流し込みます:
   ```text
   /pr-description origin/main && gh pr create --body-file .pr-description.md
   ```
   （これをプロンプト本文の *suggestion* として表示するだけにしてください。自動実行はしません。）
