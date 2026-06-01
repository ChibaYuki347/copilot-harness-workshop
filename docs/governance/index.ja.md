# 安全性とガバナンス

これまでの章は **Copilot にもっと働いてもらうための方法** を中心に説明してきました。
ここから先は逆 — **間違ったことをさせないための方法** を扱います。特に Agent
モードでは、モデルが直接ファイルを編集し、シェルコマンドを実行し、環境に届く
MCP ツールを呼び出すので、ガードレールの設計責任が一気に大きくなります。

!!! warning "なぜこのセクションが必要か"
    Agent モードでは「Copilot が良いコードを書いてくれたか?」ではなく
    「**今 自分は何を Approve したのか?**」が主問題になります。ここで紹介する
    パターンは、このサイトのカスタマイズ要素 (Custom Instructions / Hooks /
    MCP) を、生産性ブースターとしてではなく **ガードレール** として使う実例です。

## 推奨読書順

| ページ | ひとこと |
|---|---|
| [リスクの mental model](./risk-mental-model.md) | Ask モードから Agent モードに移った瞬間に変わるもの。どの種類のリスクが「ユーザー側の責任」になったか。 |
| [Approval cheat sheet](./approval-cheatsheet.md) | `y` を押すべき場面と `n` を押すべき場面の見分け方。自動承認をどこまで広げると安全か。 |
| [Blast-radius を絞る](./blast-radius.md) | サンドボックス、Shell コマンド allow-list、Hooks による deny-list、ネットワーク制限。最悪ケースで Copilot がやれる範囲を縛る。 |
| [事後の監査](./auditing.md) | Hook ベースのログ、セッション transcript、`~/.copilot/audit.log`。あとから確認する仕組み。 |
| [MCP サーバーを入れる前のチェックリスト](./mcp-vetting.md) | 第三者 MCP サーバーを繋ぐ前に確認すべき項目。自作 MCP の最低基準。 |

## TL;DR

今週やるなら最低この 3 つ:

1. **危険コマンド deny hook を入れる**。雛形は
   [`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands)。
   regex を自チームのポリシーに合わせて編集。
   → [Blast-radius を絞る](./blast-radius.md#deny-list-hook)
2. **監査 hook を入れる**。`~/.copilot/audit.log` に append するだけでも
   「あとから何が起きたか」を見返せます。
   → [事後の監査](./auditing.md#hook-based-audit-log)
3. **チームの Approval デフォルトを決める**。
   → [Approval cheat sheet](./approval-cheatsheet.md#team-defaults)
   「`rm` / `sudo` / `main` への書き込みは常に手動承認」が無難なスタートライン。

!!! tip "4 つ目に入れるべき hook"
    上記 3 つが入ったら、次のガバナンス hook は **session-end のシークレットスキャン**
    です — `stop` イベントで `gitleaks`（または好みのスキャナ）を走らせ、ターミナルを
    離れる前に漏れた認証情報を捕まえます。
    → [レシピ: セッション終了時のシークレットスキャン](../recipes/session-end-secret-scan.md)

## ホストについて

ここで扱う内容は **Copilot CLI** と **VS Code Copilot Chat の Agent モード**
の両方で有効です。Hook ファイル (`.github/hooks/*.json`) は両方で動作
([Hooks ページ](../customizations/hooks.md#vs-code-variant))、Approval プロンプトも
両 UI で存在 (見た目は異なる)、MCP サーバー設定ファイルはスキーマが違うが
リスクモデルは同一です。

## なぜ今このタイミングか

このサイトはもともと「Copilot をさらに使い倒したい人」向けに書かれていました。
ところがこのセクションの想定読者層はその逆 — ほぼ全員が Copilot Chat の Ask
モードを毎日使う一方で、**Agent モードを試したことがほぼない** という状況です。
最大の理由は「取り返しのつかないことが起きそう」というリスク不安。このセクションは
それに対する直接の回答です。
