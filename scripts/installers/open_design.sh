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

remove_open_design_env_value() {
  local env_file="$1"
  local key="$2"
  local tmp_file

  if ! grep -q "^${key}=" "$env_file"; then
    return 0
  fi

  tmp_file="$(mktemp)"
  awk -v key="$key" '
    BEGIN { prefix = key "=" }
    index($0, prefix) != 1 { print }
  ' "$env_file" >"$tmp_file"
  install -m 0600 "$tmp_file" "$env_file"
  rm -f "$tmp_file"
}

remove_open_design_legacy_env_defaults() {
  local env_file="$1"

  remove_open_design_env_value "$env_file" OPEN_DESIGN_IMAGE
  remove_open_design_env_value "$env_file" OPEN_DESIGN_BIND_HOST
  remove_open_design_env_value "$env_file" OPEN_DESIGN_ALLOWED_ORIGINS
  remove_open_design_env_value "$env_file" OPEN_DESIGN_MEM_LIMIT
  remove_open_design_env_value "$env_file" NODE_OPTIONS
}

ensure_open_design_env_defaults() {
  local env_file="$1"

  ensure_open_design_env_value "$env_file" OPEN_DESIGN_REPO_URL "$OPEN_DESIGN_REPO_URL"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_SOURCE_DIR "$OPEN_DESIGN_SOURCE_DIR"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_DATA_DIR "$OPEN_DESIGN_DATA_DIR"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_NODE_VERSION "$OPEN_DESIGN_NODE_VERSION"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_PNPM_VERSION "$OPEN_DESIGN_PNPM_VERSION"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_NODE_OPTIONS "$OPEN_DESIGN_NODE_OPTIONS" true
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_NAMESPACE "$OPEN_DESIGN_NAMESPACE"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_PORT "$OPEN_DESIGN_PORT"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_DAEMON_PORT "$OPEN_DESIGN_DAEMON_PORT"
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_WEB_BIND_HOST "$OPEN_DESIGN_WEB_BIND_HOST" true
  ensure_open_design_env_value "$env_file" OPEN_DESIGN_ALLOWED_DEV_ORIGINS "$OPEN_DESIGN_ALLOWED_DEV_ORIGINS" true
}

ensure_open_design_env() {
  local env_file="$1"

  if [[ ! -f "$env_file" ]]; then
    (
      umask 077
      cat >"$env_file" <<EOF
# Managed by my_dev_env_provision. Existing files are preserved by the installer.
OPEN_DESIGN_REPO_URL=${OPEN_DESIGN_REPO_URL}
OPEN_DESIGN_SOURCE_DIR=${OPEN_DESIGN_SOURCE_DIR}
OPEN_DESIGN_DATA_DIR=${OPEN_DESIGN_DATA_DIR}
OPEN_DESIGN_NODE_VERSION=${OPEN_DESIGN_NODE_VERSION}
OPEN_DESIGN_PNPM_VERSION=${OPEN_DESIGN_PNPM_VERSION}
OPEN_DESIGN_NODE_OPTIONS=${OPEN_DESIGN_NODE_OPTIONS}
OPEN_DESIGN_NAMESPACE=${OPEN_DESIGN_NAMESPACE}
OPEN_DESIGN_PORT=${OPEN_DESIGN_PORT}
OPEN_DESIGN_DAEMON_PORT=${OPEN_DESIGN_DAEMON_PORT}
OPEN_DESIGN_WEB_BIND_HOST=${OPEN_DESIGN_WEB_BIND_HOST}
OPEN_DESIGN_ALLOWED_DEV_ORIGINS=${OPEN_DESIGN_ALLOWED_DEV_ORIGINS}
EOF
    )
    chmod 0600 "$env_file"
    return 0
  fi

  chmod 0600 "$env_file"
  remove_open_design_legacy_env_defaults "$env_file"
  ensure_open_design_env_defaults "$env_file"
}

source_open_design_env() {
  local env_file="$1"

  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
}

install_open_design_runtime() {
  require_command git
  require_command mise

  info "Installing Open Design Node runtime"
  mise install "node@$OPEN_DESIGN_NODE_VERSION"
  NODE_OPTIONS="$OPEN_DESIGN_NODE_OPTIONS" \
    mise exec "node@$OPEN_DESIGN_NODE_VERSION" -- npm install -g "pnpm@$OPEN_DESIGN_PNPM_VERSION"
}

sync_open_design_source() {
  local source_dir="$1"

  if [[ -d "$source_dir/.git" ]]; then
    if [[ -n "$(git -C "$source_dir" status --porcelain)" ]]; then
      die "Open Design source has local changes: $source_dir"
    fi

    info "Updating Open Design source"
    git -C "$source_dir" fetch --depth 1 origin main
    git -C "$source_dir" checkout -B main FETCH_HEAD
    return 0
  fi

  if [[ -e "$source_dir" ]]; then
    die "Open Design source dir exists but is not a git repository: $source_dir"
  fi

  info "Cloning Open Design source"
  git clone --depth 1 "$OPEN_DESIGN_REPO_URL" "$source_dir"
}

trust_open_design_mise_config() {
  local source_dir="$1"
  local mise_config="$source_dir/mise.toml"

  if [[ -f "$mise_config" ]]; then
    info "Trusting Open Design mise config"
    mise trust -y "$mise_config"
  fi
}

install_open_design_dependencies() {
  local source_dir="$1"

  info "Installing Open Design dependencies"
  NODE_OPTIONS="$OPEN_DESIGN_NODE_OPTIONS" \
    mise exec "node@$OPEN_DESIGN_NODE_VERSION" -- pnpm --dir "$source_dir" install
  NODE_OPTIONS="$OPEN_DESIGN_NODE_OPTIONS" \
    mise exec "node@$OPEN_DESIGN_NODE_VERSION" -- pnpm --dir "$source_dir" --filter @open-design/tools-dev build
}

write_open_design_run_script() {
  local install_dir="$HOME/.local/share/open-design"
  local run_script="$install_dir/run.sh"

  mkdir -p "$install_dir"
  cat >"$run_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

OPEN_DESIGN_HOME="${OPEN_DESIGN_HOME:-$HOME/.local/share/open-design}"
ENV_FILE="$OPEN_DESIGN_HOME/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

SOURCE_DIR="${OPEN_DESIGN_SOURCE_DIR:-$OPEN_DESIGN_HOME/source}"
NODE_VERSION="${OPEN_DESIGN_NODE_VERSION:-24}"
NODE_OPTIONS_VALUE="${OPEN_DESIGN_NODE_OPTIONS:---max-old-space-size=2048}"
NAMESPACE="${OPEN_DESIGN_NAMESPACE:-open-design}"
WEB_PORT="${OPEN_DESIGN_PORT:-7456}"
DAEMON_PORT="${OPEN_DESIGN_DAEMON_PORT:-17456}"

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
export NODE_OPTIONS="$NODE_OPTIONS_VALUE"
export OD_HOST="${OPEN_DESIGN_WEB_BIND_HOST:-0.0.0.0}"
export OD_ALLOWED_DEV_ORIGINS="${OPEN_DESIGN_ALLOWED_DEV_ORIGINS:-http://devpc:${WEB_PORT},http://127.0.0.1:${WEB_PORT}}"
export OD_DATA_DIR="${OPEN_DESIGN_DATA_DIR:-$OPEN_DESIGN_HOME/data}"

exec "$HOME/.local/bin/mise" exec "node@$NODE_VERSION" -- \
  pnpm --dir "$SOURCE_DIR" tools-dev run web \
    --namespace "$NAMESPACE" \
    --daemon-port "$DAEMON_PORT" \
    --web-port "$WEB_PORT"
EOF
  chmod 0755 "$run_script"
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
  local install_dir="$HOME/.local/share/open-design"
  local env_file="$install_dir/.env"

  if [[ "$INSTALL_OPEN_DESIGN" != "true" ]]; then
    info "Skipping Open Design install"
    return 0
  fi

  mkdir -p "$install_dir"
  ensure_open_design_env "$env_file"
  source_open_design_env "$env_file"
  export OPEN_DESIGN_NODE_OPTIONS="${OPEN_DESIGN_NODE_OPTIONS:---max-old-space-size=2048}"
  install_open_design_runtime
  sync_open_design_source "$OPEN_DESIGN_SOURCE_DIR"
  trust_open_design_mise_config "$OPEN_DESIGN_SOURCE_DIR"
  install_open_design_dependencies "$OPEN_DESIGN_SOURCE_DIR"
  write_open_design_run_script
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
