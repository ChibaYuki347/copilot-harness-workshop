# 📜 カスタムインストラクション

**規約を一度伝えれば、どこでも適用できます。**

カスタムインストラクションは、もっともシンプルで効果の高いカスタマイズです。Copilot が
システムプロンプトに読み込む、ただの Markdown ファイルです。スクリプトも JSON も DSL も
不要です。

## 使いどき

- 毎回同じことを Copilot に伝えている。
- プロジェクト固有の規約（ビルドコマンド、フォーマッター、テストランナー）がある。
- コードベースの部分ごとにルールが異なる（フロントエンドとバックエンドなど）。
- 個人の好み（文体、冗長さ）をプロジェクトをまたいで引き継ぎたい。

## 配置場所

Copilot CLI は、`cwd` から git ルートまでの各ディレクトリ階層にある
インストラクションファイルに加え、ホームディレクトリのものも検出します。[^locations]

[^locations]: `/help` の出力より: *「Copilot は次の場所のインストラクションを尊重します:
    CLAUDE.md, GEMINI.md, AGENTS.md（git ルートと cwd）, .github/instructions/**/*.instructions.md
    （git ルートと cwd）, .github/copilot-instructions.md, $HOME/.copilot/copilot-instructions.md,
    COPILOT_CUSTOM_INSTRUCTIONS_DIRS（環境変数で追加したディレクトリ）」*

| 種類 | パス | 適用対象 |
|---|---|---|
| **リポジトリ全体** | `.github/copilot-instructions.md` | このリポジトリ内のすべてのプロンプト。 |
| **パス別** | `.github/instructions/**/*.instructions.md` | `applyTo` の glob パターンに一致するファイル。再帰的に適用され、サブフォルダーも対象になります。 |
| **エージェント形式** | `AGENTS.md`（git ルートまたは cwd。`CLAUDE.md` / `GEMINI.md` も含む） | `AGENTS.md` が置かれたディレクトリ配下。 |
| **個人** | `~/.copilot/copilot-instructions.md` | このマシン上のすべてのプロジェクト。 |
| **カスタムディレクトリ** | `$COPILOT_CUSTOM_INSTRUCTIONS_DIRS` に含まれる任意のパス | 列挙した各ディレクトリで `AGENTS.md` と `.github/instructions/**/*.instructions.md` が探索されます。キュレーションしたインストラクションを複数リポジトリで共有するのに便利です。 |

## 最小例 — リポジトリ全体

`.github/copilot-instructions.md`:

```markdown
# Conventions — payments-service

- This is a TypeScript project. **Always** target Node 20 features.
- Use `pnpm`, never `npm` or `yarn`.
- Tests live in `*.test.ts` next to the file under test, not in a `__tests__` folder.
- We use `zod` for runtime validation — prefer `z.object({...}).parse()` over manual checks.
- Database access goes through `@/db/client.ts`. Never `import postgres` directly.
- When changing public types in `src/types/`, update `CHANGELOG.md` under "Unreleased".
```

このファイルはリポジトリにコミットされるため、コントリビューター全員の Copilot
セッションで同じ基準が共有されます。

## 最小例 — パス別

`.github/instructions/python.instructions.md`:

```markdown
---
applyTo: "**/*.py"
---

# Python conventions

- Python 3.12+. Use `match` statements where they improve clarity.
- Type hints are mandatory for public functions.
- We use `ruff` for both linting and formatting. Run `ruff check --fix` before declaring done.
- Prefer `pathlib.Path` over `os.path`.
```

パス別ファイルでは、`applyTo` フロントマターで適用範囲を指定します。これらは
リポジトリ全体のファイルと **組み合わせて** 使用され、一致したファイルを触ると両方が
適用されます。[^combined]

[^combined]: 公式ドキュメントより: *「指定したパスが Copilot の作業対象ファイルに一致し、
    かつリポジトリ全体のカスタムインストラクションファイルも存在する場合は、両方の
    ファイルのインストラクションが使用されます。」*

## 最小例 — 個人

`~/.copilot/copilot-instructions.md`:

```markdown
- Be terse. I read fast.
- Always show me the diff in unified format before committing.
- Default to `gh` CLI for GitHub operations.
- Never run `git push --force` without asking explicitly.
```

## 良い書き方

!!! tip "うまく機能するコツ"
    1. **短いほどよい。** 追加した内容は毎ターン、トークンを消費します。文章は削ぎ落とします。
    2. **命令形で書く。** *"`pnpm` を使う。"* で十分です。*"一般的には…が望ましい"* のような表現は避けます。
    3. **自明でないルールには理由を書く。** *"`pnpm` を使う — ワークスペースのシンボリックリンクがこれに依存している。"*
    4. **Copilot の既定動作を言い直さない。** "良いコードを書く" はノイズです。
    5. **更新する。** 規約が廃れたらルールも削除します。古いインストラクションは、ない状態より悪くなります。

!!! warning "アンチパターン"
    - **長文の壁。** 400 行のインストラクションファイルは、そのまま 400 行分の
      システムプロンプト負荷になります。
    - **言語ドキュメントの繰り返し。** Copilot はすでに Python 構文を理解しています。
    - **個人の好みをリポジトリファイルに入れる。** 個人の嗜好は `~/.copilot/...` に分けます。

## 確認方法

```text
/instructions       # toggle individual files
/env                # see everything that's loaded
```

正しく読み込まれたパス別ファイルは `/instructions` に表示され、`/env` の
"Instructions" にも記載されます。

## `AGENTS.md` 形式

`AGENTS.md` は、複数の AI ツールで共有されている
[agent-instructions 規約](https://github.com/agentsmd/agents.md) です。Copilot CLI は、
cwd から上方向にたどったディレクトリツリーで最も近い `AGENTS.md` を尊重します。
Claude Code、Codex、Gemini CLI などでも使えるように、インストラクションを持ち運びたい
場合に向いています。

リポジトリルートの `CLAUDE.md` と `GEMINI.md` も、主にツール間互換性のために
尊重されます。

## 次へ

→ [⌨️ プロンプトファイルとスラッシュコマンド](prompt-files.md) — インストラクションが
常時適用のルールではなく、*タスクテンプレート* に近い場合の次の抽象化です。
