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
source "$REPO_ROOT/scripts/lib/systemd.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

ssh_service_name() {
  case "$DISTRO" in
    ubuntu)
      printf 'ssh\n'
      ;;
    arch)
      printf 'sshd\n'
      ;;
  esac
}

configure_ubuntu_tailscale_repo() {
  local codename

  install_package_group TAILSCALE_PREREQ_PACKAGES

  # shellcheck disable=SC1091
  . /etc/os-release
  codename="${VERSION_CODENAME:?VERSION_CODENAME is required}"

  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.noarmor.gpg" | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.tailscale-keyring.list" | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  reset_package_cache
}

install_tailscale() {
  if [[ "$INSTALL_TAILSCALE" != "true" ]]; then
    return 0
  fi

  if [[ "$DISTRO" == "ubuntu" ]]; then
    configure_ubuntu_tailscale_repo
    pkg_refresh force
  fi

  install_package_group TAILSCALE_PACKAGES

  if [[ "$ENABLE_TAILSCALE_SERVICE" == "true" ]]; then
    enable_system_service tailscaled
  fi
}

install_syncthing() {
  local repo_root="$REPO_ROOT"

  if [[ "$INSTALL_SYNCTHING" != "true" ]]; then
    return 0
  fi

  install_package_group SYNCTHING_PACKAGES

  install_root_file \
    "$repo_root/assets/systemd/syncthing@.service.d/override.conf" \
    "/etc/systemd/system/syncthing@.service.d/override.conf"
  reload_systemd

  if [[ "$ENABLE_SYNCTHING_SERVICE" == "true" ]]; then
    enable_system_service syncthing@"$(id -un)"
  fi
}

configure_ssh_service() {
  local service_name

  if [[ "$ENABLE_SSH_SERVICE" != "true" ]]; then
    return 0
  fi

  require_command ssh
  service_name="$(ssh_service_name)"
  enable_system_service "$service_name"
}

install_services() {
  local repo_root="${1:-$REPO_ROOT}"

  load_distro
  load_package_config "$repo_root/config/packages.$DISTRO"

  configure_ssh_service
  install_syncthing
  install_tailscale
}

main() {
  local action="${1:-install}"
  local repo_root="${2:-$REPO_ROOT}"

  case "$action" in
    install)
      install_services "$repo_root"
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
