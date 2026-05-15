# 3 · スキル

🟡 **中級 · 約45分**

## 学習目標

この演習を終えると、次のことができるようになります:

- スキルディレクトリ（`SKILL.md` + scripts + references）を構成できるようになります。
- エージェントが呼び出し判断に使う `SKILL.md` のフロントマターを書けるようになります。
- スキルが呼び出す小さな **補助スクリプト** を同梱できるようになります。
- スキルが検出されること（`/skills`）と、契約どおりの出力を生成することを確認できるようになります。

## 前提条件

- これまでの演習で使った作業用リポジトリ（または 1 コミット入った新しいリポジトリ）。
- `$PATH` で `bash` が使えること。
- 約45分。

## チェックポイントコミット

```bash
git commit --allow-empty -m "checkpoint: before skills exercise"
```

## シナリオ

チームの半分は `feat(api): add login` のようにコミットを書き、もう半分は `fix stuff` のように書いています。そこで、ステージ済み diff から Conventional Commits のメッセージを下書きし、さらに小さな lint スクリプトで結果を検証する `/commit-hygiene` スキルが欲しい状況です。こうしておけば、誰が実行しても出力が揃います。

## 手順

### 1. スキルフォルダーを作る

```bash
mkdir -p .github/skills/commit-hygiene/{scripts,references}
```

最終的に次の構成になります:

```text
.github/skills/commit-hygiene/
├── SKILL.md
├── scripts/
│   └── lint-message.sh
└── references/
    └── conventional-commits.md
```

### 2. lint スクリプトを書く

`.github/skills/commit-hygiene/scripts/lint-message.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FILE="${1:?usage: lint-message.sh <file>}"
FIRST="$(head -n1 "$FILE")"

if [[ ! "$FIRST" =~ ^(feat|fix|docs|test|refactor|chore|perf|build|ci)(\(.+\))?:[[:space:]].+$ ]]; then
  echo "FAIL: first line must match Conventional Commits."
  echo "  got: $FIRST"
  exit 1
fi

if (( ${#FIRST} > 72 )); then
  echo "FAIL: first line exceeds 72 chars (${#FIRST})."
  exit 1
fi

echo "OK: $FIRST"
exit 0
```

実行可能にします:

```bash
chmod +x .github/skills/commit-hygiene/scripts/lint-message.sh
```

**確認できる結果**:

```bash
echo "feat: hello world" > /tmp/m && \
  .github/skills/commit-hygiene/scripts/lint-message.sh /tmp/m
# OK: feat: hello world
```

### 3. リファレンスを書く

`.github/skills/commit-hygiene/references/conventional-commits.md`:

```markdown
# Conventional Commits cheat-sheet

Type prefixes we use:

- **feat** — a user-visible new capability
- **fix** — a user-visible bug fix
- **docs** — docs only
- **test** — tests only
- **refactor** — no behavior change
- **chore** — tooling, deps
- **perf** — performance only
- **build / ci** — build/CI plumbing

Format: `type(scope): subject` — subject in imperative mood, no trailing period,
72-char first-line limit.
```

### 4. `SKILL.md` を書く

`.github/skills/commit-hygiene/SKILL.md`:

```markdown
---
name: commit-hygiene
description: |
  Use this skill when the user asks to draft, write, or fix a commit message,
  or asks about commit style. Triggers: "commit message", "commit msg", "draft
  a commit", "/commit-hygiene". Do not trigger for general PR/branch summaries.
license: MIT
---

# commit-hygiene

Draft a Conventional Commits message from the staged diff, then validate it
with the bundled lint script.

## Output Contract

When this skill finishes:

1. A file `.commit-message.txt` exists at the repo root.
2. `scripts/lint-message.sh .commit-message.txt` exits 0.
3. The final response is the message contents.

## Workflow

1. Read `references/conventional-commits.md` for the type list.
2. Run `git diff --staged --stat` and `git diff --staged` (truncate at ~400 lines).
3. Pick **one** type that best matches the dominant change kind. If multiple
   apply, prefer `feat` > `fix` > `refactor` > everything else.
4. Pick a scope only if the staged files are confined to one obvious directory.
5. Write a subject in the imperative ("add login", not "added login").
6. Save to `.commit-message.txt`:
   ```text
   type(scope): subject
   ```
7. Run `scripts/lint-message.sh .commit-message.txt`. If it fails, fix and retry.
8. Print the final message and the path.

## Rules

- One commit message. No alternatives, no "or maybe…".
- If the staged diff is empty, say so and stop. Don't invent.
- Never include explanations in the file itself — only the message lines.
```

**確認できる結果**: 4 つのファイルがすべて存在し、lint スクリプトが実行可能になっています。

### 5. 変更をステージしてスキルを呼び出す

```bash
echo "// hello" > hello.js && git add hello.js
copilot
```

セッション内で、まずは明示的にスキルを呼び出します:

```text
/commit-hygiene
```

…あるいは暗黙的に次のように依頼します:

```text
Draft me a commit message for the staged changes.
```

### 6. 契約を確認する

```bash
.github/skills/commit-hygiene/scripts/lint-message.sh .commit-message.txt
# OK: feat: ...
```

## 完了条件 { #definition-of-done }

次の 5 つをすべて満たせば完了です:

- [ ] `.github/skills/commit-hygiene/SKILL.md` が存在し、フロントマターに `name` と `description` がある。
- [ ] `scripts/lint-message.sh` が実行可能であり（`ls -l` に `x` が見える）、有効なサンプルで終了コード 0 を返す。
- [ ] セッション内の `/skills` に `commit-hygiene` が表示される。
- [ ] 呼び出し後、リポジトリルートに `.commit-message.txt` が存在する。
- [ ] `lint-message.sh .commit-message.txt` が終了コード 0 を返す。

## 参考解答 { #reference-solution }

??? success "参考解答を表示"
    docs サイトに同梱されている `pr-summary` 例から、完全な `SKILL.md` の形を確認できます:

    ```markdown
    --8<-- "examples/skills/pr-summary/SKILL.md"
    ```

    検出順序（cwd から git ルートまで、および `~/.copilot/skills/`）については、[カスタマイズ → スキル](../customizations/skills.md)
    を参照してください。

## クリーンアップ

```bash
rm -rf .github/skills .commit-message.txt
git restore --staged hello.js && rm -f hello.js
```

## トラブルシューティング

- **`/skills` に `commit-hygiene` が出ません。** フォルダーが正確に `.github/skills/commit-hygiene/SKILL.md` になっているか確認してください（Linux では大文字小文字も区別されます）。識別子はフロントマターの `name:` ではなく、フォルダー名から決まります。
- **スキルは動くのに lint スクリプトを呼びません。** スキルはツール呼び出しを強制しません。`Workflow` セクションはモデルへのガイダンスです。文言を強めてください: "**You must** run `scripts/lint-message.sh` and only finish when it exits 0."

## やってはいけないこと

- macOS で GNU オプション前提の shell スクリプトを書かないでください（`sed -i ''` と `sed -i` など）。移植可能なフラグを使うか、要件をスキルに明記してください。
- lint スクリプトを、警告でも失敗終了するようにしないでください。終了コードは「契約を満たしたか」を表すべきです。警告は stdout に出します。

## 発展課題

1. body の検証ルールを追加します。ステージ済み diff が 5 ファイルを超える場合、コミットメッセージにはグルーピング理由を説明する body 段落を **必ず** 入れるようにします。`lint-message.sh` と `Workflow` セクションの両方を拡張してください。
2. `references/scope-map.md` を追加し、実リポジトリのディレクトリ → scope 対応（例: `src/api/ → api`, `web/ → web`）を記載します。手順 4 でスキルにそれを読ませてください。
