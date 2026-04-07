#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

ensure_flathub_remote() {
  if ! flatpak remote-list --user | awk '{print $1}' | grep -qx flathub; then
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

install_flatpak_apps() {
  require_command flatpak
  ensure_flathub_remote

  if [[ "$INSTALL_OBSIDIAN" == "true" ]]; then
    info "Installing Obsidian via flatpak"
    flatpak install --user -y flathub md.obsidian.Obsidian
  fi

  if [[ "$INSTALL_BITWARDEN_FLATPAK" == "true" ]]; then
    info "Installing Bitwarden via flatpak"
    flatpak install --user -y flathub com.bitwarden.desktop
  fi
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_flatpak_apps
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
