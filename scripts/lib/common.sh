#!/usr/bin/env bash

require_sudo() {
  sudo -v
}

ensure_non_root_invocation() {
  if [[ "$(id -u)" -eq 0 ]]; then
    die "Run bootstrap as your regular user, not via root or sudo."
  fi
}

current_username() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    printf '%s\n' "$SUDO_USER"
    return 0
  fi

  if [[ -n "${USER:-}" ]]; then
    printf '%s\n' "$USER"
    return 0
  fi

  id -un
}

ensure_home_local_bin() {
  mkdir -p "$HOME/.local/bin"

  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    die "Required command not found: $command_name"
  fi
}

linux_machine_arch() {
  case "$(uname -m)" in
    x86_64|amd64)
      printf 'amd64\n'
      ;;
    aarch64|arm64)
      printf 'arm64\n'
      ;;
    *)
      die "Unsupported architecture: $(uname -m)"
      ;;
  esac
}

clone_if_missing() {
  local repo_url="$1"
  local target_dir="$2"

  if [[ -d "$target_dir/.git" ]]; then
    return 0
  fi

  git clone "$repo_url" "$target_dir"
}
