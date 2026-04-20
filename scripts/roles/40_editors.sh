#!/usr/bin/env bash

run_role_40_editors() {
  if [[ "$INSTALL_EDITORS" != "true" ]]; then
    info "Skipping editor setup"
    return 0
  fi

  install_package_group EDITOR_PACKAGES
}
