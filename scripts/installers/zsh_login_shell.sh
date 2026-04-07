#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

set_zsh_login_shell() {
  local target_user
  local zsh_path

  target_user="$(current_username)"
  zsh_path="$(command -v zsh)"

  if ! grep -qxF "$zsh_path" /etc/shells; then
    printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "$CHSH_TO_ZSH" != "true" ]]; then
    info "Skipping login shell change"
    return 0
  fi

  if [[ "$(getent passwd "$target_user" | cut -d: -f7)" == "$zsh_path" ]]; then
    info "Login shell already set to zsh for $target_user"
    return 0
  fi

  sudo chsh -s "$zsh_path" "$target_user" || warn "Could not change the login shell automatically."
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      set_zsh_login_shell
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
