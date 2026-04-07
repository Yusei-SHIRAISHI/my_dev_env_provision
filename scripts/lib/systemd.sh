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

enable_system_service() {
  local service_name="$1"

  sudo systemctl enable --now "$service_name"
}
