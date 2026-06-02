#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/systemd.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

open_design_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return 0
  fi

  od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
  printf '\n'
}

open_design_env_has_token() {
  local env_file="$1"

  grep -Eq '^OD_API_TOKEN=.+$' "$env_file"
}

ensure_open_design_env_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local update_blank="${4:-false}"
  local current_value
  local tmp_file

  if grep -q "^${key}=" "$env_file"; then
    current_value="$(grep -m1 "^${key}=" "$env_file" | cut -d= -f2-)"
    if [[ "$update_blank" != "true" || -n "$current_value" ]]; then
      return 0
    fi

    tmp_file="$(mktemp)"
    awk -v key="$key" -v value="$value" '
      BEGIN { prefix = key "=" }
      index($0, prefix) == 1 && done == 0 {
        print key "=" value
        done = 1
        next
      }
      { print }
    ' "$env_file" >"$tmp_file"
    install -m 0600 "$tmp_file" "$env_file"
    rm -f "$tmp_file"
    return 0
  fi

  printf '%s=%s\n' "$key" "$value" >>"$env_file"
}

ensure_open_design_env_defaults() {
  local env_file="$1"

  ensure_open_design_env_value "$env_file" OPEN_DESIGN_IMAGE "$OPEN_DESIGN_IMAGE"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_PORT "$OPEN_DESIGN_PORT"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_BIND_HOST "$OPEN_DESIGN_BIND_HOST" true
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_ALLOWED_ORIGINS "$OPEN_DESIGN_ALLOWED_ORIGINS" true
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_MEM_LIMIT "$OPEN_DESIGN_MEM_LIMIT"
  ensure_open_design_env_value "$env_file" NODE_OPTIONS "${OPEN_DESIGN_NODE_OPTIONS:---max-old-space-size=192}"
  ensure_open_design_env_value "$env_file" OD_CODEX_SANDBOX "${OD_CODEX_SANDBOX:-}"
}

ensure_open_design_env() {
  local env_file="$1"
  local tmp_file
  local token

  if [[ ! -f "$env_file" ]]; then
    token="$(open_design_token)"
    (
      umask 077
      cat >"$env_file" <<EOF
# Managed by my_dev_env_provision. Existing files are preserved by the installer.
OPEN_DESIGN_IMAGE=${OPEN_DESIGN_IMAGE}
OPEN_DESIGN_PORT=${OPEN_DESIGN_PORT}
OPEN_DESIGN_BIND_HOST=${OPEN_DESIGN_BIND_HOST}
OPEN_DESIGN_ALLOWED_ORIGINS=${OPEN_DESIGN_ALLOWED_ORIGINS}
OD_API_TOKEN=${token}
OPEN_DESIGN_MEM_LIMIT=${OPEN_DESIGN_MEM_LIMIT}
NODE_OPTIONS=${OPEN_DESIGN_NODE_OPTIONS:---max-old-space-size=192}
OD_CODEX_SANDBOX=${OD_CODEX_SANDBOX:-}
EOF
    )
    chmod 0600 "$env_file"
    return 0
  fi

  chmod 0600 "$env_file"

  if ! open_design_env_has_token "$env_file"; then
    token="$(open_design_token)"
    tmp_file="$(mktemp)"

    if grep -q '^OD_API_TOKEN=' "$env_file"; then
      awk -v token="$token" '
        /^OD_API_TOKEN=/ && done == 0 {
          print "OD_API_TOKEN=" token
          done = 1
          next
        }
        { print }
      ' "$env_file" >"$tmp_file"
    else
      cp "$env_file" "$tmp_file"
      printf '\nOD_API_TOKEN=%s\n' "$token" >>"$tmp_file"
    fi

    install -m 0600 "$tmp_file" "$env_file"
    rm -f "$tmp_file"
  fi

  ensure_open_design_env_defaults "$env_file"
}

install_open_design_files() {
  local repo_root="${1:-$REPO_ROOT}"
  local install_dir="$HOME/.local/share/open-design"
  local env_file="$install_dir/.env"

  mkdir -p "$install_dir"
  install -m 0644 "$repo_root/assets/open-design/docker-compose.yml" "$install_dir/docker-compose.yml"
  ensure_open_design_env "$env_file"
  docker compose --project-directory "$install_dir" --project-name open-design config >/dev/null
}

install_open_design_service() {
  local repo_root="${1:-$REPO_ROOT}"
  local service_src="$repo_root/assets/systemd/user/open-design.service"
  local service_dst="$HOME/.config/systemd/user/open-design.service"

  install_user_file "$service_src" "$service_dst"
  reload_user_systemd

  if [[ "$ENABLE_OPEN_DESIGN_SERVICE" == "true" ]]; then
    enable_user_service open-design.service
    systemctl --user restart open-design.service
  fi
}

install_open_design() {
  local repo_root="${1:-$REPO_ROOT}"

  if [[ "$INSTALL_OPEN_DESIGN" != "true" ]]; then
    info "Skipping Open Design install"
    return 0
  fi

  require_command docker
  docker compose version >/dev/null
  install_open_design_files "$repo_root"
  install_open_design_service "$repo_root"
  info "Open Design is available at http://devpc:${OPEN_DESIGN_PORT}"
}

main() {
  local action="${1:-install}"
  local repo_root="${2:-$REPO_ROOT}"

  case "$action" in
    install)
      install_open_design "$repo_root"
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
