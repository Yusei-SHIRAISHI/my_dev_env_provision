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

print_chezmoi_next_steps() {
  local dotfiles_repo="$1"

  if [[ -z "$dotfiles_repo" ]]; then
    warn "Skipping chezmoi apply; set DOTFILES_REPO or DEFAULT_DOTFILES_REPO to enable it."
    return 0
  fi

  info "Bitwarden login and chezmoi apply are left as a manual step."
  printf '\nNext steps:\n'
  printf '1. ~/.local/bin/bw login\n'
  printf '2. ~/.local/bin/bw unlock\n'
  printf '3. ~/.local/bin/chezmoi init --apply %q\n\n' "$dotfiles_repo"
  printf 'To make ~/.local/bin available in future shells, add this to your shell config:\n'
  printf 'export PATH="$HOME/.local/bin:$PATH"\n\n'
}

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
    print_chezmoi_next_steps "$dotfiles_repo"
  fi

  info "Bootstrap finished."
}

main "$@"
