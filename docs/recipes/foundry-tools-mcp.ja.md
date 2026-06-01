# Recipe: Microsoft Foundry Tools MCP

!!! info "対応: 🟢 Both"
    Foundry Tools は Azure AI Foundry 機能を **リモート MCP サーバー** として公開。
    Copilot CLI (`.mcp.json` で `"type": "http"`) と VS Code Copilot Chat
    (`.vscode/mcp.json` で `"servers"`) は同じプロトコルで同じエンドポイントへ接続。
    違いはトップレベル JSON キーと env 変数記法だけ — [MCP → VS Code variant](../customizations/mcp.md#vs-code-equivalent) 参照。

**Copilot セッションを Azure AI Foundry の Content Understanding、Document
Intelligence、PII マスキング、翻訳、音声等のツール群と直結 — SDK glue を一切
書かずに。**

## こんなとき

Agent セッション中に以下が必要なとき:

- 「このスキャン PDF から構造化フィールドを抜いて」 → Content Understanding
- 「このログをチケットに貼る前に PII を消して」 → PII 検出 + マスキング
- 「仕様のドイツ語セクションを日本語に翻訳してオフショアチームへ」 → Translator
- 「この音声メモを Markdown 化して」 → Speech-to-text

`az cognitiveservices …` を毎回叩くこともできますが、エージェントが subscription /
region / key 管理 / 結果形式すべてを知る必要が出ます。Foundry Tools はそれらを
MCP ツールとしてラップ、エージェントが自動拾い。

## なぜ MCP、bash ではなく

| bash + Azure CLI | Foundry Tools MCP |
|---|---|
| エージェントが正しい `az` 子コマンドを推測 | セッション開始時に typed なツール一覧を取得 |
| 認証はコール毎 (shell の env vars) | 認証は MCP サーバー起動時に 1 回 |
| 出力パースは場当たり的テキスト | 出力はモデルが消費可能な構造化 JSON |
| 各コールは `bash` 承認プロンプト | ツールカテゴリ毎に 1 回承認 → 自動許可 |

これが **MCP の価値提案・2 カラム版**。チームに MCP を紹介する際のピッチに。

## レイヤー

- **MCP** (`http` transport — リモートエンドポイント、ローカルプロセス無し)
- 任意: いつ Foundry を呼ぶかをエージェントに示す **Custom Instruction**

## Part 1 — Foundry の資格情報取得

Azure AI Foundry プロジェクトが必要。MCP サーバーは次のいずれかで認証:

- **API key** (最簡、シングルテナント)
- **Entra ID OAuth** (組織展開推奨、SSO 対応)
- **マネージド ID** (Copilot が Azure VM / Codespace で動く場合)

まずは API key を Azure AI Foundry ポータル → プロジェクトの **Keys and
Endpoint** から発行、保存:

```bash
# ~/.bashrc / ~/.zshrc / ~/.profile に追加。コミットしない
export FOUNDRY_ENDPOINT='https://<your-project>.cognitiveservices.azure.com'
export FOUNDRY_API_KEY='<paste-here>'
```

## Part 2 — Copilot CLI: `.mcp.json`

ワークスペーススコープ。リポ直下の `.mcp.json` (または `.github/mcp.json`) に:

```json
{
  "mcpServers": {
    "foundry-tools": {
      "type": "http",
      "url": "https://foundry-tools-mcp.azurewebsites.net/mcp",
      "headers": {
        "x-foundry-endpoint": "${FOUNDRY_ENDPOINT}",
        "Authorization": "Bearer ${FOUNDRY_API_KEY}"
      }
    }
  }
}
```

> Foundry Tools リモート MCP サーバーの正式 URL は [Foundry MCP カタログエントリ](https://learn.microsoft.com/azure/ai-foundry/concepts/mcp)。
> ポータルの値で置き換えてください — クラウドリージョン毎に変わります。

ロード確認:

```text
/mcp show
```

`foundry-tools` がツール数 (5–15、有効化されている Foundry 機能による) と共に
リストされていれば OK。

## Part 3 — VS Code: `.vscode/mcp.json`

同じサーバー、少し違う形:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "foundry-tools": {
      "type": "http",
      "url": "https://foundry-tools-mcp.azurewebsites.net/mcp",
      "headers": {
        "x-foundry-endpoint": "${env:FOUNDRY_ENDPOINT}",
        "Authorization": "Bearer ${env:FOUNDRY_API_KEY}"
      }
    }
  }
}
```

env 変数記法: `${env:VAR}` (VS Code) vs. `${VAR}` (CLI) に注意。

VS Code で確認: Chat パネル → tools ドロップダウン → `foundry-tools/*` が出ているか。

混在チーム展開期間中は **両方** コミット。`scripts/sync-mcp.mjs` 10 行で
片方からもう片方を生成すれば乖離防止。

## Part 4 — 試す

Copilot セッションを再起動して:

=== "Content Understanding"

    ```text
    foundry-tools の content-understanding を使って
    ./samples/invoice-2026-04.pdf から構造化フィールドを抽出してください。
    vendor、total、line items が欲しい。
    ```

    エージェントは `foundry-tools/content_understanding_analyze` 等 (正確な名前は
    `/mcp show` で確認) を呼び、ファイル URL かバイト列を渡し、表にそのまま
    貼れる JSON を返します。

=== "PII マスキング"

    ```text
    このログ片を Slack スレッドに共有したい。foundry-tools で PII を先にマスクして、
    マスク後だけ見せてください。原文は返信に含めないで。

    ---
    [ログを貼る]
    ```

    エージェントは `foundry-tools/pii_detect` → `pii_mask` を呼び、マスク済みのみ
    返却。顧客データをどこかに貼る前の習慣化に有効。

=== "翻訳"

    ```text
    README.md の "Build" と "Test" セクションを foundry-tools translator で
    日本語訳して、結果を README.ja.md に。
    ```

    シェル経由よりクリーン — エージェントがファイル読み・ツール呼び・結果書き込みを
    ツールカテゴリ毎 1 承認で完結。

## 承認パターン

各 Foundry ツールの初回コール:

```text
Copilot wants to call:

    foundry-tools/pii_detect
    input: { text: "..." }

[a]llow once  [A]lways allow this tool  [d]eny  [q]uit
```

推奨:

- **`A`llow always**: read-only ツール (翻訳、PII *検出*、言語 *識別*)
- **`a`llow once**: その入力で初めてサービスへデータを送るツール (PII *マスキング*
  — そのデータを送って良いか確認)
- 接続は [vetting](../governance/mcp-vetting.md) 済みエンドポイントのみ

## 任意 — エージェントを誘導する Custom Instruction

`.github/copilot-instructions.md` に:

```markdown
## Foundry Tools MCP の使用方針

**ドキュメントから構造化フィールドを抽出**、**PII マスキング**、**翻訳** が
求められたら、独自パーサや推測ではなく `foundry-tools/*` ツールを優先せよ。
`foundry-tools` がロードされていない (このワークスペース外で開始等) 場合は、
独自パーサにフォールバックせず、その旨を明示して停止せよ。
```

2 つの効果:

1. プロンプトなしで正しいツールに手が伸びる
2. Foundry 未設定 workspace では *声を上げて* 失敗する — サイレントな低品質
   フォールバックを起こさない

## コストと quota

Foundry Tools コールは Azure AI Foundry プロジェクトに課金。可視性のために:

- Azure ポータルで Foundry quota / budget alert
- [`postToolUse` audit hook](../governance/auditing.md#hook-based-audit-log) を
  `foundry-tools/*` でフィルタ → セッション毎コール数を取得

ワークショップでは捨て駒 low-cap キー (または日次 $ 数ドル quota のサンドボックス
プロジェクト) を配布。

## Azure AI Foundry のハンズオンとの橋渡し

最近 Azure AI Foundry のハンズオンを実施したチームなら、これは「では Copilot
から使いましょう」の続編にあたります。典型的にデモされる Foundry 機能
(Content Understanding、PII、translator) と同じ API です。違いは Copilot が
curl 例ではなく MCP で typed アクセスする点。

## バリエーション

- **特定 Foundry deployment に固定**: ヘッダに `x-foundry-deployment: <name>`。
  プロジェクトに複数 deployment がある場合
- **Private endpoint 裏で運用**: public URL を private endpoint FQDN に置換。
  Managed ID 認証なら API key 不要
- **GitHub MCP サーバーと組み合わせ**: PDF 添付の Issue を読む → Foundry Content
  Understanding で抽出 → コメントとして post-back、を 1 ターンで

## 関連

- [Customizations → MCP](../customizations/mcp.md) — 完全スキーマリファレンス
- [Recipe → GitHub MCP server](github-mcp-server.md) — 組み合わせ良し
- [Governance → MCP vetting](../governance/mcp-vetting.md) — 新規 MCP 接続前のチェックリスト
- [Governance → Auditing](../governance/auditing.md) — コスト / データ所在地可視化のため Foundry コールを記録
- [Azure AI Foundry docs → MCP](https://learn.microsoft.com/azure/ai-foundry/concepts/mcp)
  (canonical エンドポイント + ツール一覧)
