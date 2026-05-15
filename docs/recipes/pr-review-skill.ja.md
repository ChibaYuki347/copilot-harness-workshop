# レシピ: PR Review スキル

**1 つのスラッシュコマンドで呼び出せる、再利用可能な複数フェーズの PR レビューです。**

## 課題

どのチームにも PR レビューのチェックリストはありますが、実際には誰かの頭の中にあるか、
`CONTRIBUTING.md` に書かれていても誰も読み返しません。ここでは、そのチェックリストを
決まった手順で実行するスキルが必要です。毎回同じ質問をし、同じ出力形式で、根拠に基づいて答えます。

## 使うレイヤー

- **スキル** で構造化されたワークフローを定義します。
- **カスタムエージェント**（組み込みの `code-review`）が主なレビューを担当します。
- 任意: 結果を PR に自動でコメントする **`postToolUse` フック**。

## ファイル構成

```
.github/skills/pr-review/
├── SKILL.md
└── references/
    └── checklist.md
```

## `SKILL.md`

```markdown
---
name: pr-review
description: |
  Use this skill when the user asks to review a pull request or the current branch's
  diff. Trigger phrases include "review this PR", "review the diff", "do a PR review".
  Do not trigger for one-line code suggestions or for general code-quality questions.
license: MIT
compatibility: "Cross-platform. Requires git and the gh CLI."
argument-hint: "Optional: base branch to diff against (default: origin/main)"
---

# PR Review Skill

## Output Contract

By the end:

1. A file `.pr-review/REVIEW.md` exists at the repo root.
2. Each section of the checklist (see `references/checklist.md`) is filled in or
   explicitly marked **N/A** with a one-line reason.
3. Every finding cites at least one `file:line` reference.
4. The final response includes a one-paragraph executive summary and a verdict:
   **Approve / Approve-with-comments / Request-changes**.

## Workflow

### Phase 1 — Ground

1. Determine the base branch from the argument (default: `origin/main`).
2. Run `git diff --stat <base>...HEAD` and capture the changed files.
3. Load `references/checklist.md`.

### Phase 2 — Investigate

Delegate to the built-in `code-review` agent: pass the diff and the checklist, ask
for a structured review. The agent should return findings as a JSON array
`[{ severity, file, line, what, why, fix }, ...]`.

### Phase 3 — Synthesize

1. Create `.pr-review/REVIEW.md` by filling in the checklist + the findings.
2. For each finding, verify the `file:line` actually exists in the diff before
   including it.
3. Compute the verdict:
   - any `Critical` → **Request-changes**
   - else any `High` → **Approve-with-comments**
   - else → **Approve**

### Phase 4 — Present

Print the executive summary and the verdict, and tell the user where the full review
is saved.
```

## `references/checklist.md`（抜粋）

```markdown
# Review checklist

- **Correctness** — Does the change do what its description claims?
- **Tests** — Are tests added/updated? Are they meaningful (not assert-true)?
- **Error handling** — Are failure modes considered?
- **Security** — Any secret-leak, SSRF, injection risk introduced?
- **Performance** — Any obviously hot paths added without bounds?
- **Backwards compat** — Are public types / endpoints stable?
- **Docs** — Is `CHANGELOG.md` updated for user-visible changes?
```

## 動作の流れ

```text
/pr-review
/pr-review develop
```

1. スキルが差分の範囲を決めます。
2. `code-review` サブエージェントがチェックリストに沿って解析します。
3. 構造化された `REVIEW.md` がリポジトリのルートに作成されます。
4. CLI が判定を表示します。

## 任意: PR に自動でコメントする

`gh pr` ツールの使用を監視し、レビュー結果をコメントとして投稿するフックを追加します:

```json
{
  "version": 1,
  "hooks": {
    "postToolUse": [
      {
        "type": "command",
        "matcher": "^bash$",
        "bash": ".github/hooks/pr-comment/comment.sh",
        "timeoutSec": 15
      }
    ]
  }
}
```

`comment.sh` は `.pr-review/REVIEW.md` が存在するかを確認し、存在すれば
`gh pr comment -F .pr-review/REVIEW.md` で投稿します。

## バリエーション

- **より厳格な判定ポリシー。** `gh pr merge` に対する `preToolUse` フックから
  `permissionDecision: "ask"` を返し、`Approve` 以外の判定では人間の承認を必須にします。
- **ドメイン別のチェックリスト。** チームごとにスキルを派生させます: `.github/skills/pr-review-backend/`,
  `.../pr-review-frontend/`。それぞれが独自の `checklist.md` を持ちます。
- **CI から起動。** 2 つの `allow-tool` フラグを繰り返して、すべての PR でスキルを実行します:

  ```bash
  copilot -p '/pr-review' \
    --allow-tool='shell(git:*)' \
    --allow-tool='shell(gh:*)'
  ```

  `--allow-tool` はフラグ 1 つにつき glob パターンを 1 つだけ受け取り、
  カンマ区切りの一覧は渡せません。`:*` の glob は「このバイナリの任意のサブコマンド」です。

## 試してみる

実行可能なスターターは [`examples/skills/pr-summary/SKILL.md`](https://github.com/ChibaYuki347/copilot-harness-workshop/blob/main/examples/skills/pr-summary/SKILL.md) にあります。
これをリポジトリの `.github/skills/pr-summary/` にコピーし、セッションを再起動して
`/pr-summary` を実行します。
