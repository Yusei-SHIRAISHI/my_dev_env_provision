# Setup Flow

`bootstrap.sh` は次の順序でセットアップを進めます。

1. distro を判定する
2. package 定義を読み込む
3. `sudo` を確認する
4. role を順番に実行する
5. 最後に `chezmoi` を使って dotfiles を適用する

role は `scripts/roles/`、共通処理は `scripts/lib/`、個別導入ロジックは `scripts/installers/` にあります。

## Example

```bash
DOTFILES_REPO="yusei-shiraishi/my_dotfiles" ./bootstrap.sh
```

## Partial Run

```bash
SETUP_ROLES="00_base,30_docker,90_verify" ./bootstrap.sh
```
