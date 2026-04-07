#!/usr/bin/env bash

run_role_20_git() {
  if ! command -v git >/dev/null 2>&1; then
    die "git is not available after base setup"
  fi

  info "git ready: $(git --version)"
}
