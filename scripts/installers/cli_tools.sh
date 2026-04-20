#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
BITWARDEN_RELEASES_API_URL="https://api.github.com/repos/bitwarden/clients/releases?per_page=30"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/distro.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/packages.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/systemd.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

install_release_binary() {
  local url="$1"
  local binary_name="$2"
  local archive_type="${3:-raw}"
  local tmpdir

  ensure_home_local_bin
  tmpdir="$(mktemp -d)"

  case "$archive_type" in
    raw)
      curl -fsSL "$url" -o "$tmpdir/$binary_name"
      ;;
    tar.gz)
      curl -fsSL "$url" -o "$tmpdir/archive.tgz"
      tar -xzf "$tmpdir/archive.tgz" -C "$tmpdir"
      ;;
    zip)
      curl -fsSL "$url" -o "$tmpdir/archive.zip"
      unzip -q "$tmpdir/archive.zip" -d "$tmpdir"
      ;;
    *)
      rm -rf "$tmpdir"
      die "Unsupported archive type: $archive_type"
      ;;
  esac

  install -m 0755 "$tmpdir/$binary_name" "$HOME/.local/bin/$binary_name"
  rm -rf "$tmpdir"
}

install_opencode() {
  local arch
  local asset

  arch="$(linux_machine_arch)"

  case "$arch" in
    amd64)
      asset="opencode-linux-x64.tar.gz"
      ;;
    arm64)
      asset="opencode-linux-arm64.tar.gz"
      ;;
  esac

  info "Installing opencode"
  install_release_binary "https://github.com/anomalyco/opencode/releases/latest/download/$asset" opencode tar.gz
}

install_opencode_user_service() {
  local service_src="$REPO_ROOT/assets/systemd/user/opencode.service"
  local service_dst="$HOME/.config/systemd/user/opencode.service"

  if [[ "$ENABLE_OPENCODE_SERVICE" != "true" ]]; then
    return 0
  fi

  info "Installing opencode user service"
  install_user_file "$service_src" "$service_dst"
  reload_user_systemd
  enable_user_service opencode.service
}

install_tgcli() {
  local arch
  local asset

  arch="$(linux_machine_arch)"

  case "$arch" in
    amd64)
      asset="tgcli-linux-amd64"
      ;;
    arm64)
      asset="tgcli-linux-arm64"
      ;;
  esac

  info "Installing tgcli"
  install_release_binary "https://github.com/dgrr/tgcli/releases/latest/download/$asset" tgcli raw
}

install_ngrok() {
  local arch
  local asset

  arch="$(linux_machine_arch)"

  case "$arch" in
    amd64)
      asset="ngrok-v3-stable-linux-amd64.tgz"
      ;;
    arm64)
      asset="ngrok-v3-stable-linux-arm64.tgz"
      ;;
  esac

  info "Installing ngrok"
  install_release_binary "https://bin.equinox.io/c/bNyj1mQVY4c/$asset" ngrok tar.gz
}

install_stripe_cli() {
  load_distro
  load_package_config "$REPO_ROOT/config/packages.$DISTRO"
  install_package_group STRIPE_BUILD_PACKAGES
  ensure_home_local_bin

  info "Installing stripe CLI from source"
  GOBIN="$HOME/.local/bin" go install github.com/stripe/stripe-cli/cmd/stripe@latest
}

resolve_bitwarden_cli_asset_url() {
  local pattern="$1"

  require_command curl
  require_command jq

  curl -fsSL "$BITWARDEN_RELEASES_API_URL" \
    | jq -r --arg pattern "$pattern" 'first(.[] | select(.tag_name | startswith("cli-v")) | .assets[] | select(.name | test($pattern)) | .browser_download_url) // empty'
}

install_bitwarden_cli() {
  local arch
  local pattern
  local url

  arch="$(linux_machine_arch)"

  case "$arch" in
    amd64)
      pattern='^bw-linux-[0-9].*\.zip$'
      ;;
    arm64)
      pattern='^bw-linux-arm64-[0-9].*\.zip$'
      ;;
  esac

  url="$(resolve_bitwarden_cli_asset_url "$pattern")"

  if [[ -z "$url" ]]; then
    die "Could not find the latest Bitwarden CLI asset for $arch"
  fi

  info "Installing Bitwarden CLI"
  install_release_binary "$url" bw zip
}

install_cli_tools() {
  if [[ "$INSTALL_BITWARDEN_CLI" == "true" ]]; then
    install_bitwarden_cli
  fi

  if [[ "$INSTALL_OPENCODE" == "true" ]]; then
    install_opencode
    install_opencode_user_service
  fi

  if [[ "$INSTALL_TGCLI" == "true" ]]; then
    install_tgcli
  fi

  if [[ "$INSTALL_NGROK" == "true" ]]; then
    install_ngrok
  fi

  if [[ "$INSTALL_STRIPE_CLI" == "true" ]]; then
    install_stripe_cli
  fi
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_cli_tools
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
