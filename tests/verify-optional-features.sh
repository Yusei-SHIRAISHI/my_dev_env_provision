#!/usr/bin/env bash

set -euo pipefail

TEST_USER="${1:-tester}"
DISTRO="${2:-ubuntu}"
USER_HOME="/home/$TEST_USER"
USER_PATH="$USER_HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
USER_ID="$(id -u "$TEST_USER")"
USER_RUNTIME_DIR="/run/user/$USER_ID"
USER_BUS_ADDRESS="unix:path=$USER_RUNTIME_DIR/bus"

assert_command() {
  local command_name="$1"

  command -v "$command_name" >/dev/null 2>&1
}

assert_user_command() {
  local command_name="$1"

  su - "$TEST_USER" -c "PATH='$USER_PATH' command -v '$command_name' >/dev/null"
}

assert_user_executable() {
  local file_path="$1"

  su - "$TEST_USER" -c "test -x '$file_path'"
}

assert_obsidian_installed() {
  assert_user_executable "$USER_HOME/.local/bin/obsidian"
  assert_user_executable "$USER_HOME/.local/lib/obsidian/Obsidian.AppImage"
  su - "$TEST_USER" -c "'$USER_HOME/.local/lib/obsidian/Obsidian.AppImage' --appimage-version >/dev/null"
}

assert_open_design_installed() {
  su - "$TEST_USER" -c "test -d '$USER_HOME/.local/share/open-design/source/.git'"
  su - "$TEST_USER" -c "test -f '$USER_HOME/.local/share/open-design/.env'"
  su - "$TEST_USER" -c "test -x '$USER_HOME/.local/share/open-design/run.sh'"
  su - "$TEST_USER" -c "grep -qx 'OPEN_DESIGN_WEB_BIND_HOST=0.0.0.0' '$USER_HOME/.local/share/open-design/.env'"
  su - "$TEST_USER" -c "grep -qx 'OPEN_DESIGN_ALLOWED_DEV_ORIGINS=http://devpc:7456,http://127.0.0.1:7456' '$USER_HOME/.local/share/open-design/.env'"
  su - "$TEST_USER" -c "XDG_RUNTIME_DIR='$USER_RUNTIME_DIR' DBUS_SESSION_BUS_ADDRESS='$USER_BUS_ADDRESS' systemctl --user is-enabled open-design.service >/dev/null"
  su - "$TEST_USER" -c "XDG_RUNTIME_DIR='$USER_RUNTIME_DIR' DBUS_SESSION_BUS_ADDRESS='$USER_BUS_ADDRESS' systemctl --user is-active open-design.service >/dev/null"
}

main() {
  local root_commands=(syncthing tailscale)
  local user_commands=(bw gcloud ngrok opencode stripe tgcli)
  local cmd

  for cmd in "${root_commands[@]}"; do
    assert_command "$cmd"
  done

  for cmd in "${user_commands[@]}"; do
    assert_user_command "$cmd"
  done

  systemctl is-enabled "syncthing@${TEST_USER}" >/dev/null
  systemctl is-active "syncthing@${TEST_USER}" >/dev/null
  systemctl cat "syncthing@${TEST_USER}" | grep -q 'Environment=STGUIADDRESS=0.0.0.0:8384'

  if [[ "$DISTRO" == "ubuntu" ]]; then
    test -f /etc/apt/sources.list.d/tailscale.list
  fi

  assert_obsidian_installed
  su - "$TEST_USER" -c "PATH='$USER_PATH' bw --version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' gcloud version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' ngrok version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' opencode --version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' stripe version >/dev/null"
  su - "$TEST_USER" -c "PATH='$USER_PATH' tgcli --version >/dev/null"
  assert_open_design_installed
}

main
