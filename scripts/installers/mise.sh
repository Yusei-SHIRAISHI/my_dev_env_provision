#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/distro.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/packages.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

install_mise_binary() {
  ensure_home_local_bin

  if command -v mise >/dev/null 2>&1; then
    info "mise already installed"
    return 0
  fi

  info "Installing mise"
  curl https://mise.run | sh
}

install_mise_global_tools() {
  local tool_spec

  if [[ -z "$MISE_GLOBAL_TOOLS" ]]; then
    return 0
  fi

  for tool_spec in $MISE_GLOBAL_TOOLS; do
    info "Installing mise tool: $tool_spec"
    mise use --global "$tool_spec"
  done
}

install_mise() {
  load_distro
  load_package_config "$REPO_ROOT/config/packages.$DISTRO"
  install_package_group MISE_PREREQ_PACKAGES
  install_mise_binary
  install_mise_global_tools
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_mise
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
