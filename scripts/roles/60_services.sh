#!/usr/bin/env bash

run_role_60_services() {
  local repo_root="$1"

  if [[ "$INSTALL_SYSTEM_SERVICES" != "true" ]]; then
    info "Skipping system service setup"
    return 0
  fi

  "$repo_root/scripts/installers/system_services.sh" install "$repo_root"
}
