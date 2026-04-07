#!/usr/bin/env bash

set -euo pipefail

TEST_USER="${1:-tester}"
DISTRO="${2:-ubuntu}"
USER_HOME="/home/$TEST_USER"
USER_PATH="$USER_HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

assert_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1
}

assert_user_command() {
  local command_name="$1"

  su - "$TEST_USER" -c "PATH='$USER_PATH' command -v '$command_name' >/dev/null"
}

main() {
  local root_commands=(syncthing tailscale)
  local user_commands=(bw ngrok opencode stripe tgcli)
  local cmd

  for cmd in "${root_commands[@]}"; do
    assert_command "$cmd"
  done

  for cmd in "${user_commands[@]}"; do
    assert_user_command "$cmd"
  done

  systemctl is-enabled "syncthing@${TEST_USER}" >/dev/null
  systemctl is-active "syncthing@${TEST_USER}" >/dev/null

  if [[ "$DISTRO" == "ubuntu" ]]; then
    test -f /etc/apt/sources.list.d/tailscale.list
  fi

  su - "$TEST_USER" -c "PATH='$USER_PATH' flatpak list --user --app --columns=application | grep -qx 'md.obsidian.Obsidian'"
  su - "$TEST_USER" -c "PATH='$USER_PATH' flatpak list --user --app --columns=application | grep -qx 'com.bitwarden.desktop'"
  su - "$TEST_USER" -c "PATH='$USER_PATH' bw --version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' ngrok version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' opencode --version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' stripe version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' tgcli --version >/dev/null"
}

main
