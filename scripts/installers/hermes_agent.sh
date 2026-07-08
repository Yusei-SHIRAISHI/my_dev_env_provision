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

HERMES_AGENT_INSTALLER_TMPDIR=""
declare -a HERMES_AGENT_INSTALL_ARGS=()

cleanup_hermes_agent_installer_tmpdir() {
  if [[ -n "$HERMES_AGENT_INSTALLER_TMPDIR" ]]; then
    rm -rf -- "$HERMES_AGENT_INSTALLER_TMPDIR"
  fi
}

download_hermes_agent_installer() {
  local installer_url="$1"
  local installer_path="$2"

  require_command curl
  info "Downloading Hermes Agent installer"
  curl -fsSL "$installer_url" -o "$installer_path"
  chmod 0700 "$installer_path"
}

build_hermes_agent_install_args() {
  HERMES_AGENT_INSTALL_ARGS=(
    --dir "$HERMES_AGENT_INSTALL_DIR"
    --hermes-home "$HERMES_AGENT_HOME"
    --skip-setup
    --non-interactive
  )

  if [[ "$HERMES_AGENT_SKIP_BROWSER" == "true" ]]; then
    HERMES_AGENT_INSTALL_ARGS+=(--skip-browser)
  fi

  if [[ -n "$HERMES_AGENT_BRANCH" ]]; then
    HERMES_AGENT_INSTALL_ARGS+=(--branch "$HERMES_AGENT_BRANCH")
  fi

  if [[ -n "$HERMES_AGENT_COMMIT" ]]; then
    HERMES_AGENT_INSTALL_ARGS+=(--commit "$HERMES_AGENT_COMMIT")
  fi
}

ignore_hermes_agent_install_stamp() {
  local exclude_file="$HERMES_AGENT_INSTALL_DIR/.git/info/exclude"

  if [[ ! -f "$exclude_file" ]]; then
    return 0
  fi

  if ! grep -qx '.install_method' "$exclude_file"; then
    printf '.install_method\n' >>"$exclude_file"
  fi
}

apply_hermes_agent_compat_patches() {
  local patch_file="$REPO_ROOT/assets/patches/hermes-agent/password-dashboard-login-redirect.patch"

  if [[ ! -f "$patch_file" ]]; then
    return 0
  fi

  if [[ ! -d "$HERMES_AGENT_INSTALL_DIR/.git" ]]; then
    warn "Skipping Hermes Agent compatibility patch because install dir is not a git checkout"
    return 0
  fi

  require_command git

  if git -C "$HERMES_AGENT_INSTALL_DIR" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
    info "Hermes Agent dashboard password-login patch is already applied"
    return 0
  fi

  if git -C "$HERMES_AGENT_INSTALL_DIR" apply --check "$patch_file" >/dev/null 2>&1; then
    info "Applying Hermes Agent dashboard password-login patch"
    git -C "$HERMES_AGENT_INSTALL_DIR" apply "$patch_file"
    return 0
  fi

  warn "Skipping Hermes Agent dashboard password-login patch because upstream no longer matches"
}

write_hermes_dashboard_env() {
  local env_dir="$HOME/.config/hermes-dashboard"
  local env_file="$env_dir/dashboard.env"

  mkdir -p "$env_dir"
  cat >"$env_file" <<EOF
HERMES_HOME=${HERMES_AGENT_HOME}
HERMES_DASHBOARD_HOST=${HERMES_DASHBOARD_HOST}
HERMES_DASHBOARD_PORT=${HERMES_DASHBOARD_PORT}
EOF
  chmod 0644 "$env_file"
}

remove_opencode_user_service() {
  local service_dst="$HOME/.config/systemd/user/opencode.service"

  if systemctl --user list-unit-files opencode.service >/dev/null 2>&1; then
    info "Disabling opencode user service"
    systemctl --user disable --now opencode.service >/dev/null 2>&1 || true
  fi

  if [[ -f "$service_dst" ]]; then
    rm -f "$service_dst"
    reload_user_systemd
  fi
}

install_hermes_dashboard_service() {
  local repo_root="${1:-$REPO_ROOT}"
  local service_src="$repo_root/assets/systemd/user/hermes-dashboard.service"
  local service_dst="$HOME/.config/systemd/user/hermes-dashboard.service"

  if [[ "$ENABLE_HERMES_DASHBOARD_SERVICE" != "true" ]]; then
    info "Skipping Hermes dashboard user service"
    return 0
  fi

  remove_opencode_user_service
  write_hermes_dashboard_env
  install_user_file "$service_src" "$service_dst"
  reload_user_systemd

  info "Enabling Hermes dashboard user service"
  enable_user_service hermes-dashboard.service
  systemctl --user restart hermes-dashboard.service
  info "Hermes dashboard is available at http://devpc:${HERMES_DASHBOARD_PORT}"
}

install_hermes_agent() {
  local installer_path

  if [[ "$INSTALL_HERMES_AGENT" != "true" ]]; then
    info "Skipping Hermes Agent install"
    return 0
  fi

  ensure_non_root_invocation
  ensure_home_local_bin
  require_command bash

  HERMES_AGENT_INSTALLER_TMPDIR="$(mktemp -d)"
  trap cleanup_hermes_agent_installer_tmpdir EXIT
  installer_path="$HERMES_AGENT_INSTALLER_TMPDIR/hermes-agent-install.sh"

  download_hermes_agent_installer "$HERMES_AGENT_INSTALLER_URL" "$installer_path"
  mkdir -p "$HERMES_AGENT_HOME"
  build_hermes_agent_install_args

  info "Installing Hermes Agent"
  HERMES_HOME="$HERMES_AGENT_HOME" \
    HERMES_INSTALL_DIR="$HERMES_AGENT_INSTALL_DIR" \
    bash "$installer_path" "${HERMES_AGENT_INSTALL_ARGS[@]}"
  ignore_hermes_agent_install_stamp
  apply_hermes_agent_compat_patches

  if [[ ! -x "$HOME/.local/bin/hermes" ]]; then
    die "Hermes Agent command was not installed at $HOME/.local/bin/hermes"
  fi

  "$HOME/.local/bin/hermes" --version >/dev/null
  install_hermes_dashboard_service
  info "Hermes Agent installed at $HERMES_AGENT_INSTALL_DIR"
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_hermes_agent
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
