# レシピ: パス別インストラクション

!!! info "対応ホスト: 🟪 VS Code Copilot Chat 主体"
    **`applyTo` glob によるパスフィルタリングは VS Code 固有の機能です。**
    `.github/instructions/*.instructions.md` に `applyTo: "frontend/**"` を
    指定すると、それが効くのは **VS Code Copilot Chat の中だけ** です — VS Code の
    `CustomInstructionsService` が、開いている／編集対象のファイルを glob と
    照合し、マッチした指示ファイルだけを注入します。

    **Copilot CLI でも** 同じファイルは（VS Code 連携リーダー経由で）読み込まれますが、
    CLI は **`applyTo` glob を尊重しません** — マッチング処理を行わず、すべての
    インストラクションファイルを system prompt にフラットに結合します。よって以下で
    説明する path-specific 挙動は **VS Code 固有** です。

    **CLI ネイティブな等価機能: 入れ子の `AGENTS.md`。** CLI はサブディレクトリを
    巡回して `AGENTS.md` を拾います。`frontend/AGENTS.md` と `backend/AGENTS.md` を
    配置することで「ディレクトリごとに違うルール」を glob なしで実現できます。
    後述の *CLI 等価構成* セクションを参照。

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

## どう組み合わさるか（VS Code Copilot Chat の場合）

Copilot に `frontend/src/components/Button.tsx` の変更を依頼すると、

- **ベースライン** が適用されます（Conventional Commits、force-push しない、など）。
- **フロントエンド用インストラクション** が適用されます（TypeScript strict、Vitest など）。
- **バックエンド用インストラクションは** 適用されません（パスが一致しないためです）。

変更が両方にまたがる場合、**両方** のパス別インストラクションが適用され、
**さらに** ベースラインも適用されます。[^combined]

[^combined]: GitHub Docs には次のようにあります: *「指定したパスが
    Copilot の作業対象ファイルに一致し、リポジトリ全体向けのカスタムインストラクションファイルも存在する場合、
    両方のファイルのインストラクションが使用されます。」* この合成は VS Code の
    `CustomInstructionsService` が行います。Copilot CLI は `.instructions.md` に対する
    glob フィルタリングを **行いません** — 下記の *CLI 等価構成* セクションを参照。

## 確認方法（VS Code）

VS Code Copilot Chat では **Instructions ピッカー**（または `Add Context → Instructions`）
で、現在のコンテキストにアタッチされているファイルを確認できます。`applyTo` のマッチングは
アクティブファイルが変わるたびに再評価されます。

## CLI 等価構成 — 入れ子の `AGENTS.md` { #cli-equivalent }

Copilot CLI は `.github/instructions/*.instructions.md` を（VS Code 連携リーダー
経由で）**読み込みます** が、`applyTo` glob を尊重せずすべてフラットに system prompt
へ結合します — どのインストラクションも常時スコープ内です。CLI で
「ディレクトリごとに違うルール」を実現するには、代わりに **入れ子の `AGENTS.md`**
を使います:

```
.
├── AGENTS.md                # チーム共通のベースライン（トップレベル）
├── frontend/
│   └── AGENTS.md            # フロントエンド用ルール
└── backend/
    └── AGENTS.md            # バックエンド用ルール
```

`frontend/` の中で CLI セッションを開始（または途中で `cd`）すると、CLI はディレクトリ
ツリーを遡り、近くにある `AGENTS.md` をすべて拾って prompt に結合します。トップレベルの
`AGENTS.md` は常に含まれ、サブディレクトリの `AGENTS.md` はそれに加わります。[^nested-agents]

[^nested-agents]: Copilot CLI 仕様によると、`readNestedAgentsInstructions` が
    サブディレクトリの `AGENTS.md` を検出します（リポジトリルートは別経路で読まれます）。
    これが CLI ネイティブのパス別インストラクション機構です。

| 目的 | VS Code | Copilot CLI |
|---|---|---|
| リポジトリ全体のベースライン | `.github/copilot-instructions.md` | `.github/copilot-instructions.md` または ルートの `AGENTS.md` |
| `frontend/` 用ルール | `.github/instructions/frontend.instructions.md`（`applyTo: "frontend/**"`） | `frontend/AGENTS.md` |
| `backend/` 用ルール | `.github/instructions/backend.instructions.md`（`applyTo: "backend/**"`） | `backend/AGENTS.md` |
| 個人オーバーレイ | ユーザープロファイル `.instructions.md` | `~/.copilot/copilot-instructions.md` |

**両ホストで動く 1 セット** にしたい場合は、`.instructions.md` ファイル（VS Code 用、
`applyTo` で絞る）と、入れ子 `AGENTS.md`（CLI 用、近接で絞る）の **両方** を配置します。
CLI が `applyTo` をネイティブ対応するまで、この二重定義がクロスホスト両立のコストです。

### CLI 側の確認

CLI 側でも、どのインストラクションソースが読まれたかは確認できます:

```text
/env             # 結合された全インストラクションソースを表示
```

`.instructions.md` ファイルも一覧に出てきますが、CLI はそれらを `applyTo` glob で
**絞りこまない** ことだけ忘れずに。

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
