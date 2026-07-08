#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
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

  if [[ ! -x "$HOME/.local/bin/hermes" ]]; then
    die "Hermes Agent command was not installed at $HOME/.local/bin/hermes"
  fi

  "$HOME/.local/bin/hermes" --version >/dev/null
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
