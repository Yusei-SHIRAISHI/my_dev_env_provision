#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/distro.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/packages.sh"

install_nvim() {
  local first_line

  load_distro
  load_package_config "$REPO_ROOT/config/packages.$DISTRO"
  pkg_install neovim
  IFS= read -r first_line < <(nvim --version)
  info "nvim ready: $first_line"
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_nvim
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
