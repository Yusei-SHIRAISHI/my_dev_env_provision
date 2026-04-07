#!/usr/bin/env bash

run_role_80_cli_tools() {
  local repo_root="$1"

  if [[ "$INSTALL_CLI_TOOLS" != "true" ]]; then
    info "Skipping CLI tool setup"
    return 0
  fi

  "$repo_root/scripts/installers/cli_tools.sh" install
}
