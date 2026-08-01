#!/usr/bin/env bash

USER_SYSTEMD_RUNTIME_DIR=""
USER_SYSTEMD_BUS_ADDRESS=""

start_user_systemd_session() {
  local container_name="$1"
  local user_name="$2"
  local user_id
  local i

  user_id="$(docker exec "$container_name" id -u "$user_name")"
  USER_SYSTEMD_RUNTIME_DIR="/run/user/$user_id"
  USER_SYSTEMD_BUS_ADDRESS="unix:path=$USER_SYSTEMD_RUNTIME_DIR/bus"

  docker exec "$container_name" loginctl enable-linger "$user_name"
  docker exec "$container_name" systemctl start "user@${user_id}.service"

  for ((i = 0; i < 60; i++)); do
    if docker exec "$container_name" test -S "$USER_SYSTEMD_RUNTIME_DIR/bus"; then
      return 0
    fi

    sleep 1
  done

  docker exec "$container_name" systemctl status "user@${user_id}.service" || true
  return 1
}
