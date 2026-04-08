#!/usr/bin/env bash

set -euo pipefail

TARGET_USER=""
SETUP_SKIP_PASSWORD_PROMPT="${SETUP_SKIP_PASSWORD_PROMPT:-false}"
SETUP_SUDO_NOPASSWD="${SETUP_SUDO_NOPASSWD:-false}"
SETUP_SKIP_FULL_UPGRADE="${SETUP_SKIP_FULL_UPGRADE:-false}"

info() {
  printf '[INFO] %s\n' "$*"
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "Run setup.sh as root."
  fi
}

load_distro() {
  if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release is not available"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    ubuntu)
      printf 'ubuntu\n'
      ;;
    arch|archlinux)
      printf 'arch\n'
      ;;
    *)
      case " ${ID_LIKE:-} " in
        *" ubuntu "*) printf 'ubuntu\n' ;;
        *" arch "*) printf 'arch\n' ;;
        *) die "Unsupported distribution: ${ID:-unknown}" ;;
      esac
      ;;
  esac
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --user)
        TARGET_USER="${2:-}"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
Usage: setup.sh --user <username>

Root-only pre-bootstrap entrypoint for Ubuntu / Arch.
Creates the target user, grants admin access, and installs the minimum tools
needed before running ./install.sh as that user.
EOF
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done

  if [[ -z "$TARGET_USER" ]]; then
    die "--user is required"
  fi
}

ensure_arch_keyring() {
  mkdir -p /etc/pacman.d/gnupg
  chmod 700 /etc/pacman.d/gnupg
  rm -f /etc/pacman.d/gnupg/*.lock

  if ! pacman-key --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
    info "Initializing pacman keyring"
    pacman-key --init
  fi

  if ! pacman-key --list-keys 2>/dev/null | grep -q 'Arch Linux'; then
    info "Populating pacman keyring"
    pacman-key --populate archlinux
  fi
}

install_minimum_packages() {
  local distro="$1"

  case "$distro" in
    ubuntu)
      info "Refreshing apt metadata"
      env DEBIAN_FRONTEND=noninteractive apt-get update
      info "Installing minimum packages"
      env DEBIAN_FRONTEND=noninteractive apt-get install -y sudo curl ca-certificates git
      ;;
    arch)
      ensure_arch_keyring
      info "Refreshing pacman metadata"
      pacman -Sy --noconfirm archlinux-keyring

      if [[ "$SETUP_SKIP_FULL_UPGRADE" != "true" ]]; then
        info "Upgrading system packages"
        pacman -Syu --noconfirm
      else
        info "Skipping full system upgrade"
      fi

      info "Installing minimum packages"
      pacman -S --needed --noconfirm sudo curl ca-certificates git
      ;;
  esac
}

admin_group_for() {
  local distro="$1"

  case "$distro" in
    ubuntu)
      printf 'sudo\n'
      ;;
    arch)
      printf 'wheel\n'
      ;;
  esac
}

ensure_user() {
  local distro="$1"
  local admin_group

  admin_group="$(admin_group_for "$distro")"
  groupadd -f "$admin_group"

  if id "$TARGET_USER" >/dev/null 2>&1; then
    info "User already exists: $TARGET_USER"
    usermod -aG "$admin_group" "$TARGET_USER"
    return 0
  fi

  info "Creating user: $TARGET_USER"
  useradd -m -s /bin/bash -G "$admin_group" "$TARGET_USER"

  if [[ "$SETUP_SKIP_PASSWORD_PROMPT" == "true" ]]; then
    info "Skipping password prompt for $TARGET_USER"
    return 0
  fi

  passwd "$TARGET_USER"
}

configure_sudo_access() {
  local sudoers_file="/etc/sudoers.d/90-${TARGET_USER}"
  local sudoers_line

  if [[ "$SETUP_SUDO_NOPASSWD" == "true" ]]; then
    sudoers_line="$TARGET_USER ALL=(ALL:ALL) NOPASSWD: ALL"
  else
    sudoers_line="$TARGET_USER ALL=(ALL:ALL) ALL"
  fi

  printf '%s\n' "$sudoers_line" >"$sudoers_file"
  chmod 0440 "$sudoers_file"
  visudo -cf "$sudoers_file" >/dev/null
}

print_next_steps() {
  cat <<EOF

Next steps:
1. Switch to the target user:
   su - $TARGET_USER
2. Clone this repository as that user if you have not already.
3. Run ./install.sh as that user.

If you cloned the repository as root, clone it again under /home/$TARGET_USER instead of reusing the root-owned checkout.
EOF
}

main() {
  local distro

  require_root
  parse_args "$@"
  distro="$(load_distro)"
  install_minimum_packages "$distro"
  ensure_user "$distro"
  configure_sudo_access
  print_next_steps
}

main "$@"
