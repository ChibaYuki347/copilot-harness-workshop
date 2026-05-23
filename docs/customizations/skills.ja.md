# 🦾 スキル

**スクリプト・テンプレート・評価基準を含む複数ステップの手順を、エージェントが 1 つの
名前付き機能として実行できる形にまとめます。**

スキルはこのページで最も重量級のカスタマイズであり、もっとも強力でもあります。
プロンプトファイルが「引数付きプロンプト」だとすれば、スキルは **`SKILL.md` に加えて、
必要な補助スクリプト・参照ドキュメント・出力テンプレートを含むフォルダー** です。

!!! abstract "対応ホスト"
    🟢 **Copilot CLI** · 🟢 **VS Code** — `.github/skills/<name>/SKILL.md` のワークスペーススキルは **両ホスト** が読み込みます（上流 `vscode-copilot-chat` 設計より）。両ホストが受け付ける追加のワークスペース置き場所: `.agents/skills/`、`.claude/skills/`。ユーザースコープ: `~/.copilot/skills/`、`~/.agents/skills/`、`~/.claude/skills/`。本サイトのラボは CLI の慣習に沿っていますが、同じ `SKILL.md` は無編集で VS Code でも読み込めます。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

## スキルを使う場面（プロンプトファイルとの違い）

| **プロンプトファイル** を選ぶのは… | **スキル** を選ぶのは… |
|---|---|
| 1 つの Markdown 本文に収まる。 | フェーズ、検証、または専用のデータファイルがある。 |
| 補助スクリプトは不要。 | `scan.py` や `validate.sh` をプロンプトと一緒に配布したい。 |
| 出力は会話形式でよい。 | 出力が構造化されている（特定レイアウトのファイル、評価基準、チェックリスト）。 |

## スキルの構成

```
.github/skills/<skill-name>/
├── SKILL.md                       # the entry point — YAML frontmatter + body
├── scripts/                       # optional helper scripts
│   └── scan.py
├── assets/                        # optional templates the agent fills in
│   └── templates/
│       └── REPORT.md
└── references/                    # optional reference docs the agent loads on demand
    └── checklist.md
```

`SKILL.md` は次のようになります。

```markdown
---
name: pr-summary
description: |
  Use this skill when the user asks to summarize the current branch's PR or to draft a
  PR description. Trigger on prompts like "summarize my PR", "draft PR description",
  "what changed in this branch".
license: MIT
compatibility: "Cross-platform. Requires git and the gh CLI."
argument-hint: "Optional: target branch to diff against (default: origin/main)"
---

# PR Summary Skill

Generates a PR description following our team template, grounded in the actual diff.

## Output Contract

Before finishing, all of the following must be true:

1. A file `PR_BODY.md` exists in the repo root with the populated template.
2. Every section in the template is filled in or explicitly marked `N/A`.
3. The summary references only changes that appear in the diff.

## Workflow

### Phase 1 — Gather

1. Determine the base branch (default `origin/main`, override from argument).
2. Run `git diff --stat <base>...HEAD` and `git log <base>..HEAD --oneline`.
3. Identify the highest-risk file in the diff (largest churn or sensitive path).

### Phase 2 — Draft

Copy `assets/templates/PR_BODY.md` into the repo root and fill in:

- **Summary** — one paragraph.
- **Motivation** — link to the issue if found in commit messages.
- **What changed** — bullet list grouped by area.
- **Risk** — the high-risk file from Phase 1, plus mitigations.
- **Validation** — tests run, commands executed.

### Phase 3 — Validate

1. Re-read `PR_BODY.md`. Check every section is filled.
2. Confirm every bullet in "What changed" maps to a hunk in the diff.
3. If any check fails, fix and re-run.
```

## Copilot がスキルを見つける仕組み

ユーザーのプロンプトが **スキルの `description` に一致すると**（意味的に一致すればよく、
description はモデルに渡されます）、Copilot はそのスキルの呼び出しを提案します。
スラッシュコマンドを入力して明示的に呼び出すこともできます。

```text
/pr-summary
/pr-summary develop
```

## スキルの配置場所

スキルは、cwd から git ルートまでの各ディレクトリ階層に加え、いくつかの既知の
個人用ディレクトリでも検出されます。[^skills-loc]

[^skills-loc]: `github/copilot-cli` changelog より: *「個人用スキルの検出ディレクトリとして
    `~/.agents/skills/` が追加されました」* および *「カスタムインストラクション、MCP
    サーバー、スキル、エージェントは、作業ディレクトリから git ルートまでの各階層で
    検出されるようになり、モノレポを完全にサポートできるようになりました。」*

| 配置場所 | スコープ |
|---|---|
| `.github/skills/<name>/SKILL.md` | リポジトリ（コミットされる）。 |
| `~/.copilot/skills/<name>/SKILL.md` | 個人。 |
| `~/.agents/skills/<name>/SKILL.md` | 個人（ツール横断。VS Code GHCP でも利用）。 |
| 上記配下で、直下に `SKILL.md` を持つ任意のサブディレクトリ | 再帰的に検出される。 |

## CLI でスキルを管理する

```text
/skills            # list discovered skills, enable/disable
/skills add <dir>  # add a directory of skills
/env               # confirm which skills are active
```

無効化したスキルはセッションをまたいで記憶されます。

## フロントマターのリファレンス

| キー | 必須 | 用途 |
|---|---|---|
| `name` | はい | 識別子。スラッシュコマンド (`/<name>`) になります。小文字、ハイフン区切りにします。 |
| `description` | はい | スキルの内容 **と起動条件**。モデルはこれを使って呼び出すべきか判断します。 |
| `license` | いいえ | スキル自身のライセンスを表す SPDX 識別子。 |
| `allowed-tools` | いいえ | 特定のツール（例: `shell`、`bash`、MCP ツール名）を事前承認し、Copilot が毎回確認しないようにします。**多用は避けてください。以下の警告を参照してください。** |
| `disable-model-invocation` | いいえ | `true` の場合、このスキルは `/<name>` で明示的に呼び出したときだけ実行され、モデル側では自動起動できません。 |
| `compatibility` | いいえ | 実行環境 / OS 要件を自由記述で示します（情報提供用）。 |
| `argument-hint` | いいえ | スラッシュコマンドピッカーに表示される引数ヒント。 |

!!! danger "`allowed-tools: shell` はセキュリティゲートを外します"
    ソースを **自分で確認して信頼できる** スキルに限って、`shell` / `bash` を事前承認
    します。端末コマンドを事前承認すると、悪意あるスキル（または無害なスキルへの
    プロンプトインジェクション）でも、確認なしで任意コードを実行できてしまいます。
    GitHub のドキュメントでも、次のように明確に述べられています。*「迷った場合は、
    `shell` と `bash` を `allowed-tools` から外し、Copilot が端末コマンド実行前に
    明示的な確認を求めるようにしてください。」*

## 良い `description` の書き方

description は **最重要フィールド** です。モデルはこれをもとに、スキルを起動するか
どうか判断します。拾いたいユーザー表現だけでなく、*拾いたくない表現* も明示します。

> **良い例:** *"ユーザーが PR の要約や PR 説明文のドラフト作成を明示的に求めた
> ときにこのスキルを使います。'summarize my PR'、'draft PR description'、'what changed
> in this branch' のような表現で起動します。単なる `git diff` の依頼や一般的な
> コードレビューでは起動しません。"*

> **悪い例:** *"PR 要約。"*

## 落とし穴

!!! warning "よくある落とし穴"
    - **トークン上限を超えるスキル** でも検出と呼び出しは可能ですが、本文は遅延読み込み
      されます。`SKILL.md` 自体は要点だけに絞り、詳細はスキル本文から必要時に読み込む
      `references/*.md` に逃がします。
    - **`BOM` を付けない。** `SKILL.md` はプレーンな UTF-8（Byte Order Mark なし）で
      保存します。古い CLI では BOM 付きフロントマターを解析できませんでした。現在の
      バージョンでは扱えますが、移植性の面では危険です。
    - **絶対パスをハードコードしない。** スキル自身のフォルダーは `$SKILL_ROOT` を
      使います。

## 次へ

→ [🪝 フック](hooks.md) — スキルに対するイベント駆動の対になる仕組みです。
→ または、実例に進みます: [レシピ: PR レビュースキル](../recipes/pr-review-skill.md)。
