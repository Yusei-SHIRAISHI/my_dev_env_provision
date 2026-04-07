#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"

install_chezmoi() {
  ensure_home_local_bin

  if command -v chezmoi >/dev/null 2>&1; then
    info "chezmoi already installed"
    return 0
  fi

  info "Installing chezmoi"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
}

apply_chezmoi() {
  local target_repo="$1"

  if [[ -z "$target_repo" ]]; then
    die "apply requires a dotfiles repo argument"
  fi

  install_chezmoi
  info "Applying chezmoi source state from $target_repo"
  chezmoi init --apply "$target_repo"
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_chezmoi
      ;;
    apply)
      apply_chezmoi "${2:-}"
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
