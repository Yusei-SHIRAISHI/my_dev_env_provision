#!/usr/bin/env bash

run_role_30_docker() {
  local repo_root="$1"

  if [[ "$ENABLE_DOCKER" != "true" ]]; then
    info "Skipping Docker setup"
    return 0
  fi

  "$repo_root/scripts/installers/docker.sh" install "$repo_root"
}
