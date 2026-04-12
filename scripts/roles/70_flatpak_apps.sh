#!/usr/bin/env bash

run_role_70_flatpak_apps() {
  local repo_root="$1"

  if [[ "$INSTALL_FLATPAK_APPS" != "true" ]]; then
    info "Skipping flatpak app setup"
    return 0
  fi

  "$repo_root/scripts/installers/obsidian.sh" install "$repo_root"
  "$repo_root/scripts/installers/flatpak_apps.sh" install "$repo_root"
}
