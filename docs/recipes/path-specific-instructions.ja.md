# レシピ: パス別インストラクション

**残りの内容を重複させることなく、フロントエンドには 1 組のルール、バックエンドには別の
ルールを Copilot に伝えます。**

## 課題

モノレポでは、`frontend/` は厳格な ESLint を使う TypeScript + React、
`backend/` は Ruff を使う Python + FastAPI かもしれません。1 つの `copilot-instructions.md` は
長い `if frontend then… else…` の一覧になるか、その違いを無視するかのどちらかになりがちです。

## 使うレイヤー

- **カスタムインストラクション** — リポジトリ全体 + パス別（frontmatter の `applyTo`）。

## ファイル構成

```
.github/
├── copilot-instructions.md            # team-wide baseline (small)
└── instructions/
    ├── frontend.instructions.md       # applyTo: frontend/**
    └── backend.instructions.md        # applyTo: backend/**
```

## ベースライン — `.github/copilot-instructions.md`

ここは短く保ちます。どこにでも当てはまる規約だけを書きます。

```markdown
# Conventions — monorepo

- This is a monorepo with `frontend/` (React/TS) and `backend/` (Python/FastAPI).
- We use Conventional Commits (`feat:`, `fix:`, `chore:`…).
- Cross-language changes that touch both halves must update `CHANGELOG.md`.
- Never `git push --force` on `main`.
```

## パス別 — `.github/instructions/frontend.instructions.md`

```markdown
---
applyTo: "frontend/**"
---

# Frontend conventions

- TypeScript strict mode; never use `any` — prefer `unknown` + a type guard.
- React 18+. Functional components only. Hooks rules apply.
- State: Zustand for global, `useReducer` for component-local complex state.
- Tests: Vitest + React Testing Library. Files `*.test.tsx` next to the component.
- Run `pnpm lint && pnpm test --run` before claiming done.
```

## パス別 — `.github/instructions/backend.instructions.md`

```markdown
---
applyTo: "backend/**"
---

# Backend conventions

- Python 3.12. Type hints mandatory on public functions.
- Web framework: FastAPI. Routers live in `backend/app/routers/`.
- DB access through `backend/app/db.py` only — never `import asyncpg` directly.
- Tests: pytest + httpx.AsyncClient. Files in `backend/tests/`.
- Run `ruff check --fix && pytest -q` before claiming done.
```

## どう組み合わさるか

Copilot に `frontend/src/components/Button.tsx` の変更を依頼すると、

- **ベースライン** が適用されます（Conventional Commits、force-push しない、など）。
- **フロントエンド用インストラクション** が適用されます（TypeScript strict、Vitest など）。
- **バックエンド用インストラクションは** 適用されません（パスが一致しないためです）。

変更が両方にまたがる場合、**両方** のパス別インストラクションが適用され、
**さらに** ベースラインも適用されます。[^combined]

[^combined]: GitHub Docs には次のようにあります: *「指定したパスが
    Copilot の作業対象ファイルに一致し、リポジトリ全体向けのカスタムインストラクションファイルも存在する場合、
    両方のファイルのインストラクションが使用されます。」*

## 確認方法

```text
/instructions   # see each instruction file and toggle them
/env            # confirms what's loaded for the current context
```

ファイルに言及すると、どのパス別ルールが紐づくかをピッカーが表示します。

## バリエーション

- **複数 glob の `applyTo`。** `applyTo` フィールドは文字列と配列の両方を受け付けます:

    ```markdown
    ---
    applyTo:
      - "backend/**/*.py"
      - "scripts/**/*.py"
    ---
    ```

- **個人用オーバーレイ。** スペースではなくタブを好むチームメイトは、その設定を
  `~/.copilot/copilot-instructions.md` に置けば、チーム用ファイルに混ぜずに済みます。
- **サブツリーごとの `AGENTS.md`。** `frontend/` と `backend/` に `AGENTS.md` を置きます。
  Copilot は cwd からディレクトリツリーをたどり、最も近い `AGENTS.md` を尊重します。

## 落とし穴

!!! warning "glob パターンの落とし穴"
    - **引用符のない glob パターン** は古い CLI バージョンで問題になることがありました — `applyTo:
      **/*.ts` が誤って解釈されていました。[^unquoted] 現在のバージョンでは正しく処理されますが、
      引用符付き（`applyTo: "**/*.ts"`）のほうが依然として安全です。
    - **glob パターンが一致するのは cwd ではなく Copilot が操作しているパス** です。Copilot
      に「frontend/src をリファクタリングして」と頼んでも、glob が `frontend/src/**/*.ts` なら、
      実際にインストラクションが読み込まれるのは `.ts` ファイルだけです。

[^unquoted]: changelog には次のようにあります: *「`applyTo` frontmatter で引用符のない glob パターン
    （例: `applyTo: \*\*/\*.ts`）を使ったインストラクションファイルも、正しく適用されるようになりました」*。

## 試してみる

実行可能なサンプルは [`examples/instructions/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/instructions) にあります。
