# Integration Tests

`setup.sh` と `install.sh` を Ubuntu / Arch のコンテナ上で実行し、主要な CLI と Docker daemon の動作を確認するための integration test です。

## What It Does

1. systemd を含む test image を build する
2. privileged container を起動する
3. root で `./setup.sh --user tester` を実行する
4. test user で `./install.sh` を実行する
5. `docker` service と主要 command を verify する

## Run

```bash
./tests/run-bootstrap-tests.sh
```

optional feature branch の integration test:

```bash
./tests/run-optional-feature-tests.sh
```

片方だけ試す場合:

```bash
./tests/run-bootstrap-tests.sh ubuntu
./tests/run-bootstrap-tests.sh arch
```

## Notes

- test container は `systemd` を使うため `--privileged` で起動します
- Linux host と利用可能な Docker daemon が必要です
- `/sys/fs/cgroup` を mount できる環境が必要です
- repo は container 内へ read-only mount します
- test では `tests/fixtures/dotfiles` から一時 git repo を作り、`chezmoi init --apply` も検証します
- smoke suite は Ubuntu / Arch を並列に実行します
- test では `SETUP_SKIP_FULL_UPGRADE=true` と `PACKAGE_SKIP_REFRESH=true` を使って重複処理を減らします
- `run-optional-feature-tests.sh` は Ubuntu コンテナで `tailscale`, `syncthing`, `Obsidian`, `Bitwarden`, `opencode`, `tgcli`, `ngrok`, `stripe`, `bw` wrapper まで検証します
- Obsidian は upstream latest `AppImage` release を毎回解決するため、asset 名や導入手順の破損は optional suite で検知します
- `stripe` は native binary として source build しており、optional suite では `stripe version` まで検証します
- `.github/workflows/monthly-latest-image-tests.yml` で月次の latest-image test を実行します
