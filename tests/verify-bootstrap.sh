#!/usr/bin/env bash

set -euo pipefail

TEST_USER="${1:-tester}"
USER_HOME="/home/$TEST_USER"
USER_PATH="$USER_HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

assert_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'missing command: %s\n' "$command_name" >&2
    exit 1
  fi
}

assert_user_command() {
  local command_name="$1"

  if ! su - "$TEST_USER" -c "PATH='$USER_PATH' command -v '$command_name' >/dev/null"; then
    printf 'user command not available: %s\n' "$command_name" >&2
    exit 1
  fi
}

assert_service_active() {
  local service_name="$1"

  systemctl is-enabled "$service_name" >/dev/null
  systemctl is-active "$service_name" >/dev/null
}

assert_ssh_service_active() {
  if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
    assert_service_active ssh
    return 0
  fi

  assert_service_active sshd
}

assert_user_shell() {
  local expected_shell="$1"
  local actual_shell

  actual_shell="$(getent passwd "$TEST_USER" | cut -d: -f7)"

  if [[ "$actual_shell" != "$expected_shell" ]]; then
    printf 'unexpected shell for %s: %s\n' "$TEST_USER" "$actual_shell" >&2
    exit 1
  fi
}

main() {
  local root_commands=(curl direnv docker flatpak fzf gh git jq nc nvim nslookup dig rg rsync ssh tig tmux traceroute unzip vim wget zsh)
  local user_commands=(chezmoi mise)
  local cmd

  for cmd in "${root_commands[@]}"; do
    assert_command "$cmd"
  done

  for cmd in "${user_commands[@]}"; do
    assert_user_command "$cmd"
  done

  getent passwd "$TEST_USER" >/dev/null
  id -nG "$TEST_USER" | grep -Eq '(^| )(sudo|wheel)( |$)'
  assert_user_shell "$(command -v zsh)"
  test -f "$USER_HOME/.bootstrap-test-marker"
  test -f /etc/docker/daemon.json
  assert_service_active docker
  assert_ssh_service_active
  getent group docker | grep -qw "$TEST_USER"
  su - "$TEST_USER" -c "sudo -n true"
  su - "$TEST_USER" -c "PATH='$USER_PATH' docker info >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' chezmoi --version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' flatpak remote-list --user | grep -q '^flathub'"
  su - "$TEST_USER" -c "PATH='$USER_PATH' mise --version >/dev/null"
}

main
