#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
OBSIDIAN_RELEASE_API_URL="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"

# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/distro.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/scripts/lib/packages.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/config/defaults.env"

install_obsidian_runtime_dependencies() {
  load_distro

  case "$DISTRO" in
    ubuntu)
      pkg_install libasound2t64 libatk-bridge2.0-0 libgbm1 libgtk-3-0 libnspr4 libnss3 libxss1 libxtst6 xdg-utils
      ;;
    arch)
      pkg_install alsa-lib at-spi2-core gtk3 libxss libxtst nspr nss xdg-utils
      ;;
    *)
      die "Unsupported distro for Obsidian install: $DISTRO"
      ;;
  esac
}

resolve_obsidian_asset_url() {
  local pattern="$1"
  local exclude_pattern="${2:-}"

  require_command curl
  require_command jq

  curl -fsSL "$OBSIDIAN_RELEASE_API_URL" \
    | jq -r --arg pattern "$pattern" --arg exclude_pattern "$exclude_pattern" 'first(.assets[] | select((.name | test($pattern)) and ($exclude_pattern == "" or (.name | test($exclude_pattern) | not))) | .browser_download_url) // empty'
}

install_obsidian_appimage() {
  local arch
  local pattern
  local exclude_pattern=""
  local url
  local install_dir
  local target
  local wrapper
  local desktop_dir
  local desktop_file

  arch="$(linux_machine_arch)"

  case "$arch" in
    amd64)
      pattern='^Obsidian-.*\.AppImage$'
      exclude_pattern='-arm64\.AppImage$'
      ;;
    arm64)
      pattern='^Obsidian-.*-arm64\.AppImage$'
      ;;
  esac

  url="$(resolve_obsidian_asset_url "$pattern" "$exclude_pattern")"

  if [[ -z "$url" ]]; then
    die "Could not find the latest Obsidian AppImage asset for $arch"
  fi

  ensure_home_local_bin
  install_dir="$HOME/.local/lib/obsidian"
  target="$install_dir/Obsidian.AppImage"
  wrapper="$HOME/.local/bin/obsidian"
  desktop_dir="$HOME/.local/share/applications"
  desktop_file="$desktop_dir/obsidian.desktop"

  mkdir -p "$install_dir" "$desktop_dir"

  info "Installing Obsidian from latest AppImage release: ${url##*/}"
  curl -fsSL "$url" -o "$target"
  chmod +x "$target"

  cat >"$wrapper" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

appimage_path="$HOME/.local/lib/obsidian/Obsidian.AppImage"

if ! command -v fusermount >/dev/null 2>&1 && ! command -v fusermount3 >/dev/null 2>&1; then
  export APPIMAGE_EXTRACT_AND_RUN=1
elif ! ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
  export APPIMAGE_EXTRACT_AND_RUN=1
fi

exec "$appimage_path" "$@"
EOF
  chmod +x "$wrapper"

  cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Exec=$wrapper %u
Terminal=false
Categories=Office;Utility;
MimeType=x-scheme-handler/obsidian;
EOF
}

install_obsidian() {
  if [[ "$INSTALL_OBSIDIAN" != "true" ]]; then
    info "Skipping Obsidian install"
    return 0
  fi

  install_obsidian_runtime_dependencies
  install_obsidian_appimage
}

main() {
  local action="${1:-install}"

  case "$action" in
    install)
      install_obsidian
      ;;
    *)
      die "Unsupported action: $action"
      ;;
  esac
}

main "$@"
