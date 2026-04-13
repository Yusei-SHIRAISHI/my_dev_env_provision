#!/usr/bin/env bash

install_root_file() {
  local src="$1"
  local dst="$2"
  local mode="${3:-0644}"

  sudo install -D -m "$mode" "$src" "$dst"
}

reload_systemd() {
  sudo systemctl daemon-reload
}

reload_user_systemd() {
  systemctl --user daemon-reload
}

enable_system_service() {
  local service_name="$1"

  sudo systemctl enable --now "$service_name"
}

install_user_file() {
  local src="$1"
  local dst="$2"
  local mode="${3:-0644}"

  install -D -m "$mode" "$src" "$dst"
}

enable_user_service() {
  local service_name="$1"

  systemctl --user enable --now "$service_name"
}
