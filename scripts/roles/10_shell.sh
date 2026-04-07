#!/usr/bin/env bash

run_role_10_shell() {
  local repo_root="$1"

  "$repo_root/scripts/installers/zsh_login_shell.sh" install
}
