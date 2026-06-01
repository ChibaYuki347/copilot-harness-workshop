# ⌨️ プロンプトファイルとスラッシュコマンド

**繰り返し使うプロンプトを、引数付きの 1 回呼び出しコマンドにします。**

!!! abstract "対応ホスト"
    🟢 **Copilot CLI** · 🟢 **VS Code**（Copilot 拡張） — 同じ `.github/prompts/*.prompt.md` ファイル。どちらでも `/<name>` で呼び出せます。詳細は [VS Code と Copilot CLI](../reference/vscode-vs-cli.md) を参照。

カスタムインストラクションは *常時適用* です。プロンプトファイル（別名: カスタム
スラッシュコマンド）は *必要なときだけ* 使います。`/command-name` と入力して
呼び出します。

## なぜ存在するか

一部のプロンプトはインストラクションには **狭すぎる** (毎ターンには適用しない) が、
毎回打ち直すには **構造化されすぎている**。プロンプトファイルはその中間層 — チームで
共有できるバージョン管理済みパラメータ付きテンプレートで、エージェントはそれを
ファーストクラスのコマンドとして扱います。

## 代替手段 — プロンプトファイルを *使わない* 判断

- プロンプトに **検証ステップ、出力ファイル、スクリプト** がある → [Skill](skills.md)
  の方が正しい形。プロンプトファイルは平らな Markdown body です
- プロンプトが **人間ではなくライフサイクルイベント** で起動 → [hook](hooks.md) が
  自動発火。プロンプトファイルは `/foo` をタイプする必要があります
- プロンプトが **全員・毎ターン同じ** → それは [instruction](custom-instructions.md)
  です

## 使いどき

- 6 行程度のプロンプトを、少なくとも週に 1 回は貼り付けている。
- その作業は繰り返し可能だが、毎ターン読み込ませたいものでは **ない**。
- Git 経由でチームとレシピを共有したい。
- プロンプトテンプレートにパラメーター（ファイルパス、チケット番号など）を注入したい。

## プロンプトファイルの仕組み

プロンプトファイルは、コマンドを呼び出したときに **本文がそのままプロンプトになる**
Markdown ファイルです。フロントマターにはコマンド名、説明、必要に応じて引数を
記述します。

このファイルは、Copilot CLI がコマンドを検出する場所に置きます。ほかの
カスタマイズと同様に、cwd から git ルートまでの各ディレクトリ階層と
`~/.copilot/` が対象です。

!!! info "スキルとプロンプトファイル"
    **スキル** は、専用フォルダー・スクリプト・テンプレートを持てる、よりリッチな
    構造です。**プロンプトファイル** は、軽量な単一ファイルのテンプレートです。
    コマンドに補助スクリプトや複数フェーズのワークフローが必要なら、代わりに
    [スキル](skills.md) を選びます。

## 最小例

`.github/prompts/refactor-tests.prompt.md`:

```markdown
---
description: "Refactor stale tests in the given file to current conventions"
argument-hint: "<path-to-test-file>"
---

You are refactoring the test file at: $ARGUMENTS

Apply these rules in order:

1. Replace any `expect(x).to.equal(y)` (chai) with `expect(x).toBe(y)` (vitest).
2. Convert callback-style tests to `async/await`.
3. Co-locate `beforeEach` set-up next to the `describe` it applies to.
4. Remove tests that only assert that the test file itself loads (`expect(true).toBe(true)`).
5. Run the file with `pnpm vitest run $ARGUMENTS` and report any failures verbatim.
```

Copilot CLI の中で次のように呼び出します。

```text
/refactor-tests src/services/payments.test.ts
```

`$ARGUMENTS` トークンは、渡した引数に置き換えられます。

## ほかの機能との組み合わせ

プロンプトファイルは、ほかの機能とも相性よく組み合わせられます。

- プロンプトファイルの本文から **スキルを参照** できます: *"コミット前に diff を
  レビューするために `/code-review` スキルを使う。"*
- プロンプトファイルから **MCP ツールを名前で呼べます**: *"`linear:get-issue` ツールを
 使って $ARGUMENTS のチケット詳細を取得する。"*
- プロンプトファイルはプランモードで **連鎖実行** できます。まず計画を立てさせ、その
 1 ステップとしてプロンプトファイルを実行させます。

## 検出と呼び出し

```text
/help     # lists all available commands, including prompt files
/env      # confirms which prompt files were picked up
```

検出されると、そのコマンドはスラッシュコマンドの自動補完ピッカーに表示されます。

## アンチパターン

!!! warning "避けたい例"
    - **観測できない手順を抱えた作業を詰め込む。** ファイル内容に応じて複数の分岐を
      選ぶ必要があるなら、フェーズを明示できるスキルのほうが適しています。
    - **シークレットを埋め込む。** プロンプトファイルはコミットされます。トークンを
      直書きせず、環境変数または `gh secret` で注入した環境変数を使います。
    - **巨大な「全部やる」コマンドを作る。** `/do-the-thing` が実際には 6 つの別タスクを
      意味するなら、それは `copilot` 自体を作り直しているのと同じです。

## 典型パターン

| パターン | 本文のイメージ |
|---|---|
| **Issue のトリアージ** | "Issue #$ARGUMENTS を取得し、要約し、ラベル候補、マイルストーン候補、担当者候補を提案する。" |
| **PR 要約** | "現在のブランチと `origin/main` の diff を読み、チームのテンプレートで PR 説明文を作成する。" |
| **移行ステップ** | "`oldFn(...)` の使用箇所を検索し、ADR-042 に従って `newFn(...)` に置き換える。`legacy/**` に一致するファイルは除外する。" |
| **依存関係監査** | "`pnpm audit --json` を実行する。重大度ごとにまとめ、high/critical については修正案を提案する。" |

## 次へ

→ [🦾 スキル](skills.md) — プロンプトファイルではワークフローを収めきれない場合に進みます.
