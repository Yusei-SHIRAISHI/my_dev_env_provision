#!/usr/bin/env bash

APT_UPDATED=0
PACMAN_REFRESHED=0

load_package_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    die "Missing package config: $config_file"
  fi

  # shellcheck disable=SC1090
  source "$config_file"
}

reset_package_cache() {
  APT_UPDATED=0
  PACMAN_REFRESHED=0
}

pkg_refresh() {
  local mode="${1:-normal}"

  if [[ "$mode" != "force" && "${PACKAGE_SKIP_REFRESH:-false}" == "true" ]]; then
    return 0
  fi

  case "$DISTRO" in
    ubuntu)
      if [[ "$APT_UPDATED" -eq 0 ]]; then
        info "Refreshing apt metadata"
        sudo env DEBIAN_FRONTEND=noninteractive apt-get update
        APT_UPDATED=1
      fi
      ;;
    arch)
      if [[ "$PACMAN_REFRESHED" -eq 0 ]]; then
        info "Refreshing pacman metadata"
        sudo pacman -Sy --noconfirm
        PACMAN_REFRESHED=1
      fi
      ;;
    *)
      die "Unsupported distro for package refresh: $DISTRO"
      ;;
  esac
}

pkg_install() {
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi

  pkg_refresh

  case "$DISTRO" in
    ubuntu)
      sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
      ;;
    arch)
      sudo pacman -S --needed --noconfirm "$@"
      ;;
    *)
      die "Unsupported distro for package install: $DISTRO"
      ;;
  esac
}

install_package_group() {
  local group_name="$1"
  local -n group_ref="$group_name"

  if [[ "${#group_ref[@]}" -eq 0 ]]; then
    return 0
  fi

  info "Installing ${group_name,,}"
  pkg_install "${group_ref[@]}"
}
