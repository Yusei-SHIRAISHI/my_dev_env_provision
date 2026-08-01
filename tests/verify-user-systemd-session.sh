#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
  printf 'XDG_RUNTIME_DIR is not set\n' >&2
  exit 1
fi

if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  printf 'DBUS_SESSION_BUS_ADDRESS is not set\n' >&2
  exit 1
fi

if [[ ! -S "$XDG_RUNTIME_DIR/bus" ]]; then
  printf 'user systemd bus is not available: %s/bus\n' "$XDG_RUNTIME_DIR" >&2
  exit 1
fi

systemctl --user show-environment >/dev/null
