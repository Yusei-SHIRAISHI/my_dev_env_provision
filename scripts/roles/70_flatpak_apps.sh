#!/usr/bin/env bash

run_role_70_flatpak_apps() {
  local repo_root="$1"

  if [[ "$INSTALL_FLATPAK_APPS" != "true" ]]; then
    info "Skipping app setup"
    return 0
  fi

  "$repo_root/scripts/installers/obsidian.sh" install "$repo_root"
}
