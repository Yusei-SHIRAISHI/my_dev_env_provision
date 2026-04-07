#!/usr/bin/env bash

run_role_90_verify() {
  local required_commands=(git zsh vim nvim)
  local cmd

  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      warn "Missing command after bootstrap: $cmd"
    fi
  done

  if command -v docker >/dev/null 2>&1; then
    info "docker ready: $(docker --version)"

    if ! systemctl is-active docker >/dev/null 2>&1; then
      warn "docker service is installed but not active"
    fi
  fi
}
