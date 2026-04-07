#!/usr/bin/env bash

run_role_50_languages() {
  local repo_root="$1"

  if [[ "$INSTALL_MISE" != "true" ]]; then
    info "Skipping mise setup"
    return 0
  fi

  "$repo_root/scripts/installers/mise.sh" install
}
