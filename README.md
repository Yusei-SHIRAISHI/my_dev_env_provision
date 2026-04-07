# my_dev_env_provision

Ubuntu / Arch Linux 向けの開発マシン初期セットアップ repo です。

この repo は root 権限が必要な OS レベルのセットアップを担当し、dotfiles は別 repo の `chezmoi` source state として管理する前提です。

## What This Repo Owns

- パッケージ導入
- Docker 導入と daemon 設定
- `systemd` service の有効化
- `zsh` などの開発用 CLI の初期導入
- `chezmoi` のインストールと dotfiles 適用の起点

## What Stays In Dotfiles

- `~/.zshrc`
- `~/.gitconfig`
- `~/.config/nvim/*`
- `~/.local/bin/*`
- `~/.config/systemd/user/*`

## Layout

```text
.
├── bootstrap.sh
├── config/
├── docs/
├── assets/
└── scripts/
```

導入対象ツールのメモは `docs/required-tools.md` にまとめています。

## Quick Start

```bash
DOTFILES_REPO="yusei-shiraishi/my_dotfiles" ./bootstrap.sh
```

`bootstrap.sh` は root ではなく通常ユーザーで実行してください。権限昇格が必要な箇所だけ内部で `sudo` を使います。

integration test は `tests/run-bootstrap-tests.sh` と `tests/run-optional-feature-tests.sh` から実行できます。

`DOTFILES_REPO` を省略した場合は `config/defaults.env` の `DEFAULT_DOTFILES_REPO` を参照します。

## Role Order

1. `00_base.sh`
2. `10_shell.sh`
3. `20_git.sh`
4. `30_docker.sh`
5. `40_editors.sh`
6. `50_languages.sh`
7. `60_services.sh`
8. `70_flatpak_apps.sh`
9. `80_cli_tools.sh`
10. `90_verify.sh`

`10_shell` は `scripts/installers/zsh_login_shell.sh` を使って login shell を `zsh` に設定します。

`SETUP_ROLES=00_base,30_docker ./bootstrap.sh` のようにすると一部 role だけ実行できます。

`60_services` と `70_flatpak_apps` と `80_cli_tools` は `00_base` で base package が入っている前提です。

## Notes

- Arch の AUR は使いません
- Ubuntu の Docker は公式 Docker repository を使います
- `chezmoi` repo はこの repo に統合せず、外部 repo を適用します
- 旧トップレベルの install script 群は新しい role / installer 構成に置き換えました
