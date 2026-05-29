# Workshop 事前準備 — 5 分で貼れるチェックリスト

社内ワークショップで、参加者の環境がバラバラな状況向けの単一ページチェックリスト。
このページの URL (または本文) をセッション前に共有してください。当日までに
**VS Code Copilot Chat** と **Copilot CLI** の両方が動く状態がゴール。当日に
どちらを使うか選びます。

> 時間目安: VS Code が既に入っているなら **5–10 分**

## 前提

- [ ] Copilot サブスクリプション (Free / Pro / Business / Enterprise) 付きの GitHub アカウント
- [ ] ラップトップの管理者権限 (または Node.js と VS Code 拡張をインストールできる権限)
- [ ] 普段使いのターミナル (Terminal.app、Windows Terminal、iTerm2 等)

Copilot 加入が会社の Enterprise tenant 経由なら、**Agent モードと MCP がポリシーで
無効化されていないか** を事前に確認。インストール後に `copilot /usage` を実行 — 
MCP が「policy disabled」表記なら管理者にエスカレ。

## トラック 1 — VS Code Copilot Chat

1. **VS Code をインストール**: <https://code.visualstudio.com/>
2. **GitHub Copilot 拡張をインストール** (Chat が同梱):
   - VS Code → Extensions パネル (`Ctrl/Cmd + Shift + X`)
   - **GitHub Copilot** を検索 → GitHub 公式のエントリで **Install**
   - 「GitHub Copilot Chat」拡張は依存として一緒に入る
3. **サインイン**。右下のトースト「Sign in to GitHub」→ ブラウザ → authorize
4. **スモークテスト**
   - Chat ビューを開く (`Ctrl/Cmd + Alt + I`)
   - `Hello, are you ready?` と打って返信を確認
   - 下部のモードドロップダウンで **Agent** に切替。「Agent」が無ければ
     Copilot Chat 拡張を最新へ更新

✅ VS Code トラック完了条件: Agent モードに切り替えて返信が得られた

## トラック 2 — Copilot CLI

1. **Node.js 22+ をインストール**
   - macOS: `brew install node@22`
   - Windows: <https://nodejs.org/> (LTS installer) または `winget install OpenJS.NodeJS.LTS`
   - Linux: [nodesource](https://github.com/nodesource/distributions) かディストロのパッケージ
   - 確認: `node --version` で `v22.x` 以上
2. **Copilot CLI をグローバルインストール**

   ```bash
   npm install -g @github/copilot
   ```

3. **サインイン**

   ```bash
   copilot
   ```

   初回起動で device-code OAuth フロー — URL を開いてコード貼り付け、authorize

4. **スモークテスト**

   ```bash
   copilot --version       # 1.0.x 形式が出る
   ```

   そのまま対話セッションを起動:

   ```bash
   mkdir -p ~/copilot-warmup && cd ~/copilot-warmup
   copilot
   ```

   プロンプトで `Hello, are you ready?` と打ち、返信を確認。`/exit` で終了

✅ CLI トラック完了条件: `copilot --version` が動き、**かつ** 対話セッションで
1 つ返信を見た

## クイックトラブルシュート

| 症状 | 対処 |
|---|---|
| `npm install -g` 後に `copilot: command not found` | npm の global bin が PATH 外。`npm config get prefix` → `<prefix>/bin` を `PATH` に |
| `copilot` が「not signed in」を繰り返す | `~/.copilot/auth.json` を削除 → `copilot` 再起動 |
| VS Code Chat ドロップダウンに「Agent」が無い | Copilot Chat 拡張を更新、ウィンドウ reload |
| 社内プロキシ / TLS エラー | `HTTPS_PROXY` を設定。TLS は `NODE_EXTRA_CA_CERTS=/path/to/cert.pem` |
| `npm install -g` が permission denied | nvm を使う、または `mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global && export PATH=$HOME/.npm-global/bin:$PATH` |

## 当日の前提

ライブセッションでは 2 ホストの **どちらか 1 つ** だけ使えれば OK — 普段慣れている方を
選んでください。両方入れるのは比較のため。

当日はさらに:

- 試せる小さなリポ (clone 済み、`cd` 済み)
- スクリーンショットを撮れる状態 (承認プロンプト周りで画面共有します)

## 関連

- [インストール](./installation.md) — 詰まった場合の詳しいリファレンス
- [Ask モードと Agent モードの違い](./ask-vs-agent.md) — モード切替の実体
- [最初のセッション](./first-session.md) — 最初の 10 分の流れ
- [Governance → Approval cheat sheet](../governance/approval-cheatsheet.md) — 当日のためにブックマーク
