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

- `flatpak`
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

## Services / Apps

- `tailscale`
- `syncthing`
- `obsidian` (`flatpak` 経由)
- `bitwarden cli` (`flatpak` 経由を優先)

## Notes

- `mise` は language runtime 本体と CLI plugin の導入方針を分けて整理する
- `obsidian` は package manager ではなく `flatpak` role で扱う
- `bw` は native package よりも `flatpak` 導入を優先する
- `ssh` は client だけでなく daemon も必要
- `build-essential` は Ubuntu 側の表現で、Arch 側は `base-devel` で吸収する
- `netcat` は distro ごとの標準的な package を採用する
- `nslookup` と `dig` は distro ごとの DNS utility package で吸収する
- `tailscale` と `syncthing` は package install に加えて `systemd` enable 方針も決める
- `docker` は daemon 設定と `docker` group 追加までこの repo で担当する
