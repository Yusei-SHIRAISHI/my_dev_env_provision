# Obsidian Headless

Obsidian の公式 CLI は headless 専用 binary ではなく、起動中の Obsidian desktop process に IPC 接続する方式です。

そのため GUI を使わないマシンでは、`Xvfb` のような仮想 X server 上で Obsidian を常駐させる必要があります。

## 前提

- Obsidian は `scripts/installers/obsidian.sh` で導入済み
- `~/.local/bin/obsidian` が存在する
- vault の実体が local filesystem 上に存在する

Arch Linux の例:

```bash
sudo pacman -S --needed xorg-server-xvfb xorg-xauth
```

Ubuntu の例:

```bash
sudo apt-get install -y xvfb xauth
```

## Headless 起動

最小確認は次でできます。

```bash
Xvfb :99 -screen 0 1280x800x24 >/tmp/xvfb-obsidian.log 2>&1 &
DISPLAY=:99 ~/.local/bin/obsidian --no-sandbox --disable-gpu ~/obsidian-vault/task-manage
```

常用する場合は `systemd --user` service にします。

例:

```ini
[Unit]
Description=Obsidian headless service
After=default.target

[Service]
Type=simple
WorkingDirectory=%h
Environment=HOME=%h
Environment=PATH=%h/.local/share/mise/shims:%h/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/usr/bin/bash -lc 'Xvfb :99 -screen 0 1280x800x24 >/tmp/xvfb-obsidian.log 2>&1 & xvfb_pid=$!; trap "kill $xvfb_pid" EXIT; export DISPLAY=:99; exec %h/.local/bin/obsidian --no-sandbox --disable-gpu %h/obsidian-vault/task-manage'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

反映:

```bash
systemctl --user daemon-reload
systemctl --user enable --now obsidian-headless.service
systemctl --user status obsidian-headless.service
```

## Vault 追加

GUI 環境で一度でも対象 vault を開いていれば、`~/.config/obsidian/obsidian.json` に vault registry が保存されます。

この registry が無いと、公式 CLI は `Vault not found.` を返します。

保存先:

```text
~/.config/obsidian/obsidian.json
```

形式:

```json
{
  "vaults": {
    "8c5a3fc64c078739": {
      "path": "/home/shira/obsidian-vault/task-manage",
      "ts": 1776018732033,
      "open": true
    }
  },
  "cli": true
}
```

意味:

- `cli`: 公式 CLI を有効にするフラグ
- `vaults`: ローカル Obsidian が認識している vault 一覧
- `8c5a3fc64c078739`: vault ID
- `path`: vault の絶対 path
- `ts`: 最終アクセス時刻相当の timestamp
- `open`: 直近で開かれていた vault であることを示すフラグ

GUI を使わずに追加する場合は、この `obsidian.json` に対象 vault を追記します。

例:

```json
{
  "vaults": {
    "8c5a3fc64c078739": {
      "path": "/home/shira/obsidian-vault/task-manage",
      "ts": 1776018732033,
      "open": true
    }
  },
  "cli": true
}
```

既に別 vault がある場合は、既存の `vaults` を壊さずに対象 entry だけ追加します。

## 動作確認

headless service 起動後に確認します。

```bash
obsidian vaults --verbose
obsidian search query="task" vault="task-manage" format=json
```

`Vault not found.` が出なければ vault registration は通っています。

検索結果が 0 件のときは、正常系でも `No matches found.` になります。
