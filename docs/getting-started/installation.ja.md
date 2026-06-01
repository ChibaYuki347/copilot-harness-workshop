# インストール

このページでは **GitHub Copilot CLI**（`copilot`）のインストール方法を説明します。すべての選択肢と
プラットフォーム別の詳細は、[公式インストールガイド](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli) を参照してください。

!!! info "VS Code で Ask モードはすでに使っている方"
    **VS Code Copilot Chat と Copilot CLI を両方** を一度にセットアップしたい場合は、
    統合版の [ワークショップ準備](workshop-prep.md) ページが最短です — 両方の
    インストーラと、それぞれのスモークテスト手順を 1 つのフローにまとめています。

## 前提条件

- **有効な GitHub Copilot サブスクリプション**（individual、Business、Enterprise のいずれか）。
- macOS、Linux、または Windows（PowerShell 6+ または WSL）。
- Windows では PowerShell 6 以降。

## インストール

=== "macOS / Linux（スクリプト）"

    ```bash
    curl -fsSL https://gh.io/copilot-install | bash
    ```

    システム全体に `/usr/local/bin` へインストールするには `| sudo bash` を付けます。付けない
    場合は `$HOME/.local/bin` にインストールされるため、`PATH` に含まれていることを確認します。

=== "Homebrew"

    ```bash
    brew install copilot-cli
    ```

    プレリリース版を使う場合（更新は速いですが、不具合も増えます）:

    ```bash
    brew install copilot-cli@prerelease
    ```

=== "npm（クロスプラットフォーム）"

    ```bash
    npm install -g @github/copilot
    ```

=== "Windows（winget）"

    ```powershell
    winget install GitHub.Copilot
    ```

## 確認

```bash
copilot --version
```

`copilot 1.0.x` のような表示になれば問題ありません。

## 初回起動

```bash
copilot
```

あるディレクトリで初めてセッションを開始すると、Copilot は **そのディレクトリを信頼するか**
を確認します。信頼はフォルダー単位です。「yes and remember」を選ぶと設定が保存されます。
それ以外の場合は、次回も再度確認されます。

ログインしていない場合は `/login` を実行し、device-code フローに従います。

!!! tip "ヘッドレス認証"
    CI やスクリプトで使う場合は、**Copilot Requests** パーミッションを有効にした
    ファイングレインド PAT を `GH_TOKEN`（または `GITHUB_TOKEN`）に設定します。詳細なスコープは
    [PAT 設定ドキュメント](https://docs.github.com/copilot/how-tos/set-up/install-copilot-cli)
    を参照してください。

## あると便利なもの

- **複数行入力に対応したターミナル**（最近のターミナルであれば通常対応しています。
  Copilot CLI 内では `/terminal-setup` を実行して `Shift+Enter` を有効にできます）。
- 動作する **`git`** バイナリ（Copilot は常に利用します）。
- LSP ベースのコードインテリジェンスを使う場合は、利用しているスタック向けの
  言語サーバーをインストールします（例: `npm install -g typescript-language-server`）。[`/lsp`](../reference/cli-commands.md) も参照してください。

## 更新

```bash
copilot /update
```

……またはシェルから、使っているインストーラーの通常の更新手順（`brew upgrade copilot-cli`,
`npm i -g @github/copilot@latest` など）を使います。

## アンインストール

- **スクリプトでインストール:** `$HOME/.local/bin`（または `/usr/local/bin`）から `copilot` バイナリを削除します。
- **Homebrew:** `brew uninstall copilot-cli`。
- **npm:** `npm uninstall -g @github/copilot`。

ローカルの状態（セッション、キャッシュされた MCP トークン、個人用のフック / スキル）も削除するには:

```bash
rm -rf ~/.copilot
```

→ [最初のセッションを始める](first-session.md)
