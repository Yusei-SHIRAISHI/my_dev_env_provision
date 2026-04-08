# Setup Flow

`setup.sh` と `install.sh` は次の順序でセットアップを進めます。

1. `setup.sh --user <name>` を root で実行する
2. 最低限 package を導入する
3. 対象ユーザーを作成し、admin 権限を付与する
4. 通常ユーザーで repo を clone する
5. `install.sh` を実行する

`install.sh` の内部では次を行います。

1. distro を判定する
2. package 定義を読み込む
3. `sudo` を確認する
4. role を順番に実行する
5. 最後に `chezmoi` を使って dotfiles を適用する

role は `scripts/roles/`、共通処理は `scripts/lib/`、個別導入ロジックは `scripts/installers/` にあります。

## Example

```bash
sudo ./setup.sh --user yusei
DOTFILES_REPO="yusei-shiraishi/my_dotfiles" ./install.sh
```

## Partial Run

```bash
SETUP_ROLES="00_base,30_docker,90_verify" ./install.sh
```
