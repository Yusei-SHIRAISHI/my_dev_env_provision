#!/usr/bin/env bash

run_role_85_local_apps() {
  local repo_root="$1"

  if [[ "$INSTALL_LOCAL_APPS" != "true" ]]; then
    info "Skipping local app setup"
    return 0
  fi

  "$repo_root/scripts/installers/open_design.sh" install "$repo_root"
}
