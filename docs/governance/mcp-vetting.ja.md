# MCP サーバーを繋ぐ前の vetting

`.mcp.json` (CLI) や `.vscode/mcp.json` (VS Code) に新しいエントリを足すことは、
エージェントのツール表面を広げる行為。繋いだ後はそれらのツールも `bash` と同じ
ように呼ばれます。サーバーが悪意ある / バグありの場合、blast radius は
そのツールにできることと等しい。

このページは「最初の接続」前に流すチェックリスト。

## いつ使うか

- レジストリ / ブログ / `awesome-*` で見つけた新規 third-party MCP サーバー
- 別チームから来た内部 MCP サーバーを組織展開する前
- 既存 MCP サーバーのメジャーバージョンアップ前
- 規制対象 workload (PII、金融、本番資格情報) に近づく前

自チーム維持の first-party サーバーには走らせなくて良いですが、答えくらいは
言えるようにしておく。

## 5 つの問い

### 1. 何をするか、書き込みするか?

- どのツールを露出? (MCP inspector の `list_tools`、または scratch sandbox で
  接続後に CLI で `/mcp`)
- 各ツール: read-only か、ローカル書き込みか、リモート書き込みか?
- リモート書き込みなら: *どの* システムへ、*誰の* 資格で、*誰の* 名義で?
- 確認なしで delete/overwrite するツールはあるか?

パターン: 初回は read-only サーバーを優先。read/write 混在なら `--read-only`
モードや `--allow-tool` / `--deny-tool` での絞り込みを確認。

### 2. どこへデータを送るか?

- 完全ローカル? それとも SaaS への proxy?
- SaaS なら: privacy policy、保持期間、training opt-out は?
- 起動時に phone home する? (5 分 audit には `strace -f -e trace=connect`)
- 表に出ないモデル呼び出し (例: 「AI summarizer」と称して裏で OpenAI 叩く) は?

パターン: 渡した入力はサーバー側ログに残ると想定。初回はシークレットや PII を
渡さない。

### 3. 認証はどうなっているか?

- 環境変数 API key / OAuth / mTLS / 匿名?
- OAuth 後の資格情報はどこに保存? (ファイル? Keychain?)
- 狭く scope できる? (例: `repo` scope の classic PAT ではなく fine-grained PAT)
- 失効する? ローテできる?

パターン: 短命 + 狭い scope を優先。広い資格情報しか動かないサーバーは黄色信号。

### 4. サプライチェーンは?

- インストール元は? (`npm`、`pip`、`cargo`、`uvx`、`npx` レジストリ、または
  `git+` で GitHub 直)
- 公開者は信頼できるか、リポは活発か、最終 commit は最近か?
- 自身の依存関係をピンしているか、起動時に `latest` を引いてくるか?
- 公開者 = 元サービス主体 (例: `github/` 配下) か、サードパーティラッパか?

パターン: `npx @some-random-user/cool-mcp` は毎起動でその人物の未審査コードを
実行する行為。バージョンをピン、可能なら first-party を選ぶ。

### 5. 組織ポリシーは?

- Enterprise Copilot policy で MCP 全体無効化 / allow-list 制限が可能。`/usage`
  または GitHub Copilot enterprise admin で確認
- データ分類: 送信先がそのデータ分類を満たすか?
- 調達 / vendor onboarding: そのサーバーは既に承認済みか? なければ軽量経路は?

パターン: 迷ったら接続前に Security に確認。聞くコストは exfiltration コストより
ずっと安い。

## 5 分間の first-contact 手順

上の質問を通った server について:

1. **Sandbox**。新規 scratch dir、可能なら `--network=none`
2. **最小 config**。`.mcp.json` にそのサーバーだけ追加。資格情報は捨て駒 / read-only
3. **ツール一覧**。`copilot` 起動 → `/mcp` (VS Code は `Chat: List MCP tools`)。
   docs と一致するか確認
4. **Probe**。read-only ツールを 1 つ、非機微入力で呼ばせる。応答形式と
   想定外の outbound 通信が無いことを確認 (`audit.log` + `netstat`)
5. **書き込みパスを 1 本だけ叩く**。明らかな捨て駒対象 (scratch repo、ダミー
   レコード) に write ツール 1 つ。期待先「だけ」に書かれたことを確認
6. **判定**。本物の `.mcp.json` に昇格、または削除

## サーバー単位のロックダウン

入れた後も絞れます:

```bash
copilot \
  --allow-tool 'github(get_issue:*)' \
  --allow-tool 'github(search_code:*)' \
  --deny-tool 'github(delete_repository)'
```

VS Code 側は `chat.tools.autoApprove` と MCP サーバー自体の設定パネル。

## クイック判定表

緑信号サーバーが揃えて持つ性質:

- First-party または著名な維持者
- バージョンピン済みインストール (`@1.2.3`、`latest` ではない)
- 既定 read-only、write はオプトイン
- 狭い資格情報 (fine-grained PAT、scope された API key)
- ローカルのみ、または SaaS だが privacy policy と opt-out 明示

赤信号サーバーがどれか持つ性質:

- 知らない個人アカウントからの `npx`
- 広い資格情報要求 (`admin:org`、AWS フル資格、root API key)
- どこに何を送るかの記述なし
- 主目的を超えるツールを同梱
- minified / obfuscated コードしか公開しない

## 関連

- [Customizations → MCP](../customizations/mcp.md)
- [リスクの mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [Recipe → Foundry Tools MCP](../recipes/foundry-tools-mcp.md)
- [Recipe → GitHub MCP server](../recipes/github-mcp-server.md)
