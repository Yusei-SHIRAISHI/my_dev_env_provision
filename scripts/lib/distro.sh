#!/usr/bin/env bash

DISTRO=""

load_distro() {
  if [[ ! -r /etc/os-release ]]; then
    die "/etc/os-release is not available"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  case "${ID:-}" in
    ubuntu)
      DISTRO="ubuntu"
      ;;
    arch|archlinux)
      DISTRO="arch"
      ;;
    *)
      case " ${ID_LIKE:-} " in
        *" ubuntu "*)
          DISTRO="ubuntu"
          ;;
        *" arch "*)
          DISTRO="arch"
          ;;
        *)
          die "Unsupported distribution: ${ID:-unknown}"
          ;;
      esac
      ;;
  esac

  export DISTRO
  info "Detected distro: $DISTRO"
}
