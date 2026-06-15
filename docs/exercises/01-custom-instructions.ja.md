# 1 · カスタムインストラクション

🟢 **入門 · 約20分**

🟪 **トラック A — VS Code でも Copilot CLI でも動作します**（[詳細](../reference/vscode-vs-cli.md)）

## 学習目標

この演習を終えると、次のことができるようになります:

- セッションをまたいでも効く、リポジトリ全体向けの `.github/copilot-instructions.md` を書けるようになります。
- リポジトリの一部にだけ適用される **パス別** のインストラクションファイルを追加できるようになります。
- `/instructions` を使って、両方のファイルがセッション内で検出されたことを確認できるようになります。

## 前提条件

- スクラッチ用の git リポジトリ（`mkdir lab-01 && cd lab-01 && git init`）。
- Copilot CLI で認証済みであること。
- 約20分。

## チェックポイントコミット

```bash
git commit --allow-empty -m "checkpoint: before custom-instructions exercise"
```

## シナリオ

あなたはテックリードです。チームには、すべての PR で守ってほしいルールが 3 つあり、さらに Python ファイルにだけ適用したい追加ルールが 1 つあります。いまはそのルールが、誰も読まない Slack のピン留めに埋もれています。チャットに毎回コンテキストをコピペしなくても、Copilot が自動で従うようにしたい状況です。

## 手順

### 1. リポジトリ全体向けのインストラクションを作成する

チームにとって意味のある **具体的なルールを 3 つ以上** 入れて `.github/copilot-instructions.md` を作成します。テンプレートとして
[`examples/instructions/copilot-instructions.md`](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/examples/instructions/copilot-instructions.md)
を使ってください。

最小構成の例です（詰まったらそのまま使って構いません）:

```markdown
# Lab repo conventions

## Stack
- Language: Python 3.12
- Tests: pytest

## Conventions
- Use **Conventional Commits** (`feat:`, `fix:`, etc.).
- Every new public function gets a docstring with one example.
- Tests live next to the code: `foo.py` ↔ `test_foo.py`.

## What not to do
- Don't introduce a new runtime dependency without asking.
```

**確認できる結果**: `cat .github/copilot-instructions.md` でファイル内容が表示されます。

### 2. パス別インストラクションを追加する

フロントマターで `**/*.py` にスコープした `.github/instructions/python.instructions.md` を作成します:

```markdown
---
applyTo: "**/*.py"
---

# Python-specific rules

- Prefer `pathlib.Path` over `os.path`.
- Type hints are required on public function signatures.
- No `print()` for logging — use the `logging` module.
```

**確認できる結果**: 上記の正確なパスにファイルが存在し、フロントマターに `applyTo` があります。

### 3. セッションを開始して読み込まれたものを確認する

=== "Copilot CLI"

    ```bash
    copilot
    ```

    セッション内で次を実行します:

    ```text
    /instructions
    ```

    CLI は両方のファイルをインライン表示し、2 つ目には `**/*.py` の
    スコープが付きます。

=== "VS Code Copilot Chat"

    ワークスペースを VS Code で開き、Chat ビューを開きます (`Ctrl+Alt+I`)。

    チャット入力で `/instructions` と打つと、**コマンドパレット経由で
    「Configure Instructions and Rules」メニュー** が開きます — これが
    正規仕様です。**そのメニューに表示されているリスト自体が**、VS Code が
    検出した instructions の一覧です。CLI のようなインライン表示は VS Code
    にはありません。

    確認手段は他に 3 つあり、いずれか 1 つで足ります:

    1. **コマンドパレット → "Chat: Open Customizations"** で Agent
       Customizations エディタ (Preview) が開く。検出済みの instructions、
       prompt files、skills、agents が 1 つのツリーで見える
    2. **`.github/copilot-instructions.md` を直接開く** — ファイルがあれば
       always-on instructions として読み込まれていることが確定
    3. **Agent Logs ビュー** (コマンドパレット → "Chat: Show Agent Logs") に
       各リクエストでの prompt file / instruction discovery が時系列で出る

    両方のファイルが見え、2 つ目に `applyTo` glob が付いていれば OK。

一覧に **両方のファイル** が表示され、2 つ目のファイルには `**/*.py` のスコープが付いているはずです。

### 4. ルールが効く Python を Copilot に書かせる

セッション内で次のように依頼します:

```text
Add a small module fizzbuzz.py with one public function and a test file.
```

結果を確認します:

- docstring はありますか（`copilot-instructions.md` のルール）。
- パスが出てくるなら `pathlib` を使っていますか（`python.instructions.md` のルール）。
- テストファイル名は `test_fizzbuzz.py` になっていますか（`copilot-instructions.md` のルール）。

## 完了条件 { #definition-of-done }

次の 4 つをすべて満たせば完了です:

- [ ] `.github/copilot-instructions.md` が存在し、ルールを 3 つ以上含んでいる。
- [ ] `.github/instructions/python.instructions.md` が存在し、フロントマターに `applyTo: "**/*.py"` がある。
- [ ] 新しいセッション内の `/instructions` に **両方** のファイルが表示される。
- [ ] Python コードを依頼したとき、生成結果が各ファイルから少なくとも 1 つずつ見て分かるルールに従っている（例: docstring があり、**かつ** 型ヒントを使っている）。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    この docs サイトで使っているそのままのファイルは `examples/` にあります:

    `.github/copilot-instructions.md`:

    ```markdown
    --8<-- "examples/instructions/copilot-instructions.md"
    ```

    `.github/instructions/python.instructions.md`:

    ```markdown
    --8<-- "examples/instructions/instructions/python.instructions.md"
    ```

    検出順序について詳しくは、[リファレンス → ファイル配置](../reference/file-layout.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .github/copilot-instructions.md .github/instructions
```

## トラブルシューティング

- **`/instructions` に自分のファイルが出ません。** ほとんどの場合はパスかファイル名のタイプミスです。リポジトリ全体向けファイルは必ず `.github/copilot-instructions.md`（単数形、ハイフン区切り）である必要があります。パス別ファイルは `.github/instructions/` 配下に置き、末尾を `.instructions.md` にしなければなりません。
- **VS Code: `/instructions` を打つと画面上部の検索窓（コマンドパレット）にフォーカスされる。** これが正規の挙動です。VS Code Chat の `/instructions` は **「Configure Instructions and Rules」メニュー** を開くショートカットで、開いたコマンドパレットに表示されているもの自体が VS Code が検出した instructions の一覧です。検出できなかったというサインではありません。すべての customization をツリービューで見たい場合は **Chat: Open Customizations** を使ってください。
- **Copilot がルールを無視します。** インストラクションは *強制* ではなく *ガイダンス* です。重要なルールなら、より強い制約として書き直してください（例: "**Never** use `print()` for logging"）。そのうえで `## What not to do` 見出しの下に置きます。

## やってはいけないこと

- `copilot-instructions.md` にシークレット、社内ホスト名、非公開プロジェクト名を書かないでください。ファイルはコミットされ、公開されます。
- パス別ファイルに `applyTo: "**"` を使わないでください。リポジトリ全体向けファイルの重複になるだけで、更新し忘れる場所が増えます。

## 発展課題

1. テスト向けの **2 つ目のパス別ファイル**
   （`.github/instructions/tests.instructions.md` と `applyTo: "**/test_*.py"`）を追加し、`unittest.mock` を禁止して `pytest` フィクスチャを優先するようにします。
2. 環境変数 `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` で `~/.copilot/lab-overrides/` を指すようにし、そこへ個人用の好み（例: 「コミット前に必ず diff を表示する」）を書きます。`/env` で読み込まれたことを確認してください。
