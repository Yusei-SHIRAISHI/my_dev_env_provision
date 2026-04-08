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

configure_ubuntu_docker_repo() {
  install_package_group DOCKER_PREREQ_PACKAGES

  sudo install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  local arch
  local codename
  local repo_line

  arch="$(dpkg --print-architecture)"
  # shellcheck disable=SC1091
  . /etc/os-release
  codename="${VERSION_CODENAME:-}"
  repo_line="deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable"

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]] || ! grep -qxF "$repo_line" /etc/apt/sources.list.d/docker.list; then
    printf '%s\n' "$repo_line" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  fi

  reset_package_cache
}

install_docker() {
  local repo_root="${1:-$REPO_ROOT}"
  local target_user

  load_distro
  load_package_config "$repo_root/config/packages.$DISTRO"
  target_user="$(current_username)"

  if [[ "$DISTRO" == "ubuntu" ]]; then
    configure_ubuntu_docker_repo
    pkg_refresh force
  fi

  install_package_group DOCKER_PACKAGES
  install_root_file "$repo_root/assets/docker/daemon.json" /etc/docker/daemon.json 0644
  reload_systemd
  enable_system_service docker
  sudo systemctl restart docker

  if ! id -nG "$target_user" | grep -qw docker; then
    sudo usermod -aG docker "$target_user"
    warn "Added $target_user to docker group. Re-login is required for group membership to take effect."
  fi
}

main() {
  local action="${1:-install}"
  local repo_root="${2:-$REPO_ROOT}"

  case "$action" in
    install)
      install_docker "$repo_root"
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
