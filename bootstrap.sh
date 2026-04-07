#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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

main() {
  ensure_non_root_invocation
  load_distro
  load_package_config "$REPO_ROOT/config/packages.$DISTRO"
  require_sudo
  ensure_home_local_bin

  local roles=(
    00_base
    10_shell
    20_git
    30_docker
    40_editors
    50_languages
    60_services
    70_flatpak_apps
    80_cli_tools
    90_verify
  )

  if [[ -n "${SETUP_ROLES:-}" ]]; then
    IFS=',' read -r -a roles <<<"$SETUP_ROLES"
  fi

  local role
  for role in "${roles[@]}"; do
    # shellcheck source=/dev/null
    source "$REPO_ROOT/scripts/roles/${role}.sh"
    "run_role_${role}" "$REPO_ROOT"
  done

  "$REPO_ROOT/scripts/installers/chezmoi.sh" install

  local dotfiles_repo="${DOTFILES_REPO:-$DEFAULT_DOTFILES_REPO}"
  if [[ "${APPLY_CHEZMOI}" == "true" && -n "$dotfiles_repo" ]]; then
    "$REPO_ROOT/scripts/installers/chezmoi.sh" apply "$dotfiles_repo"
  else
    warn "Skipping chezmoi apply; set DOTFILES_REPO or DEFAULT_DOTFILES_REPO to enable it."
  fi

  info "Bootstrap finished."
}

main "$@"
