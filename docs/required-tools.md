# Required Tools

開発マシン初期セットアップで入れたいツール一覧です。

## Core CLI

- `curl`
- `git`
- `zsh`
- `tmux`
- `ssh` (client + daemon)
- `gh`
- `fzf`
- `ripgrep`
- `jq`
- `tig`
- `direnv`
- `wget`
- `unzip`
- `rsync`
- `make`
- `lsof`
- `netcat`
- `nslookup`
- `dig`
- `traceroute`

## Base Packages

- `build-essential` / `base-devel`

## Runtime Management

- `mise`

`mise` 経由で管理したいもの:

- `ruby`
- `python`
- `node`
- `rust`
- `terraform`
- `awscli`

## Dev Tools

- `docker`
- `chezmoi`
- `opencode`
- `tgcli`
- `stripe`
- `ngrok`
- `bw` (`bitwarden cli`)
- `gcloud`
- `open-design` (source checkout)

## Services / Apps

- `tailscale`
- `syncthing`
- `obsidian` (upstream の latest `AppImage`)
- `bitwarden cli` (standalone install)
- `open-design` (Node 24 + pnpm + user systemd service)

## Notes

- `mise` は language runtime 本体と CLI plugin の導入方針を分けて整理する
- `obsidian` は package manager ではなく upstream の latest release asset で扱う
- `bw` は standalone CLI binary を直接導入する
- `gcloud` は Google 公式 archive を `~/.local/google-cloud-sdk` に展開し、認証は手動で行う
- `ssh` は client だけでなく daemon も必要
- `build-essential` は Ubuntu 側の表現で、Arch 側は `base-devel` で吸収する
- `netcat` は distro ごとの標準的な package を採用する
- `nslookup` と `dig` は distro ごとの DNS utility package で吸収する
- `tailscale` と `syncthing` は package install に加えて `systemd` enable 方針も決める
- `docker` は daemon 設定と `docker` group 追加までこの repo で担当する
- `open-design` は source checkout を使い、`~/.local/share/open-design/source` と `~/.local/share/open-design/.env` を置く。既定では `devpc:7456` で LAN からアクセスできるように web sidecar を bind する
