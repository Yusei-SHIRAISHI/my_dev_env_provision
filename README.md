# my_dev_env_provision

Ubuntu / Arch Linux 向けの開発マシン初期セットアップ repo です。

この repo は root 権限が必要な OS レベルのセットアップを担当し、dotfiles は別 repo の `chezmoi` source state として管理する前提です。

## What This Repo Owns

- パッケージ導入
- Docker 導入と daemon 設定
- `systemd` service の有効化
- `opencode` など開発環境向け user `systemd` service の配備
- `zsh` などの開発用 CLI の初期導入
- `chezmoi` のインストールと dotfiles 適用の起点

## What Stays In Dotfiles

- `~/.zshrc`
- `~/.gitconfig`
- `~/.config/nvim/*`
- `~/.local/bin/*`

例外として、開発環境の起動を前提にした user `systemd` service はこの repo で配備することがあります。

## Layout

```text
.
├── setup.sh
├── install.sh
├── config/
├── docs/
├── assets/
└── scripts/
```

導入対象ツールのメモは `docs/required-tools.md` にまとめています。

## Quick Start

```bash
sudo ./setup.sh --user yusei
su - yusei
git clone <repo-url> ~/my_dev_env_provision
cd ~/my_dev_env_provision
./install.sh
~/.local/bin/bw login
~/.local/bin/bw unlock
~/.local/bin/chezmoi init --apply Yusei-SHIRAISHI/my_dotfiles
```

`setup.sh` を GitHub raw から直接実行する場合は、`passwd` の対話入力を壊さないため `curl | sh` ではなく `bash -c` で実行してください。

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yusei-SHIRAISHI/my_dev_env_provision/refs/heads/master/setup.sh)" -- --user shira
```

`setup.sh` は root で実行します。ユーザー作成、sudo 設定、最低限の package 導入までを担当します。

`install.sh` は root ではなく通常ユーザーで実行してください。権限昇格が必要な箇所だけ内部で `sudo` を使います。

`install.sh` は `chezmoi` までは導入しますが、Bitwarden login が必要な dotfiles 適用は自動実行しません。完了時に `~/.local/bin/bw login` / `~/.local/bin/bw unlock` / `~/.local/bin/chezmoi init --apply Yusei-SHIRAISHI/my_dotfiles` を案内します。

`~/.local/bin` を今後の shell でも使いたい場合は、dotfiles 適用後または一時的に `export PATH="$HOME/.local/bin:$PATH"` を shell 設定へ追加してください。現在の shell に反映されていない場合でも、上の絶対パスならそのまま実行できます。

integration test は `tests/run-bootstrap-tests.sh` と `tests/run-optional-feature-tests.sh` から実行できます。

月次の latest-image test は `.github/workflows/monthly-latest-image-tests.yml` で実行します。

`DOTFILES_REPO` を省略した場合は `config/defaults.env` の `DEFAULT_DOTFILES_REPO` を参照します。既定値は `Yusei-SHIRAISHI/my_dotfiles` です。

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

`SETUP_ROLES=00_base,30_docker ./install.sh` のようにすると一部 role だけ実行できます。

`60_services` と `70_flatpak_apps` と `80_cli_tools` は `00_base` で base package が入っている前提です。

`70_flatpak_apps` は Obsidian を upstream の latest `AppImage` で導入し、Bitwarden は引き続き `flatpak` で導入します。

## Notes

- Arch の AUR は使いません
- Ubuntu の Docker は公式 Docker repository を使います
- `chezmoi` repo はこの repo に統合せず、外部 repo を適用します
- 旧トップレベルの install script 群は新しい role / installer 構成に置き換えました
- `setup.sh` は root 実行、`install.sh` は通常ユーザー実行です
