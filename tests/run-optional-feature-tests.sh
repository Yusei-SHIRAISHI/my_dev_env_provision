#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_USER="${TEST_USER:-tester}"
DISTRO="${1:-ubuntu}"
DOCKER_CONFIG_DIR="${DOCKER_CONFIG_DIR:-}"
TEMP_DOCKER_CONFIG=0
CONTAINER_NAME=""

setup_docker_config() {
  if [[ -z "$DOCKER_CONFIG_DIR" ]]; then
    DOCKER_CONFIG_DIR="$(mktemp -d)"
    TEMP_DOCKER_CONFIG=1
  fi

  mkdir -p "$DOCKER_CONFIG_DIR"
  printf '{"auths":{}}\n' >"$DOCKER_CONFIG_DIR/config.json"
  export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"
}

cleanup_docker_config() {
  if [[ "$TEMP_DOCKER_CONFIG" -eq 1 && -n "$DOCKER_CONFIG_DIR" ]]; then
    rm -rf "$DOCKER_CONFIG_DIR"
  fi
}

cleanup_container() {
  local name="$1"

  if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    docker rm -f "$name" >/dev/null
  fi
}

preflight() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    printf 'This test harness requires a Linux host.\n' >&2
    exit 1
  fi

  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker is required to run integration tests.\n' >&2
    exit 1
  fi

  if [[ ! -d /sys/fs/cgroup ]]; then
    printf '/sys/fs/cgroup is required for systemd-based test containers.\n' >&2
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    printf 'Docker daemon is not reachable on the host.\n' >&2
    exit 1
  fi
}

wait_for_systemd() {
  local name="$1"
  local state
  local i

  for ((i = 0; i < 60; i++)); do
    state="$(docker exec "$name" systemctl is-system-running 2>/dev/null || true)"

    case "$state" in
      running|degraded)
        return 0
        ;;
    esac

    sleep 2
  done

  docker exec "$name" systemctl status || true
  return 1
}

main() {
  local image="bootstrap-test:${DISTRO}"
  local fixture_repo="/home/$TEST_USER/dotfiles-fixture"

  setup_docker_config
  preflight
  trap cleanup_docker_config EXIT

  docker build -t "$image" "$REPO_ROOT/tests/images/$DISTRO"
  CONTAINER_NAME="bootstrap-optional-${DISTRO}"
  cleanup_container "$CONTAINER_NAME"

  docker run -d \
    --privileged \
    --cgroupns=host \
    --tmpfs /run \
    --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    -v "$REPO_ROOT:/repo:ro" \
    --name "$CONTAINER_NAME" \
    "$image" >/dev/null

  trap 'cleanup_container "$CONTAINER_NAME"; cleanup_docker_config' EXIT

  wait_for_systemd "$CONTAINER_NAME"

  docker exec \
    -e SETUP_SKIP_PASSWORD_PROMPT=true \
    -e SETUP_SUDO_NOPASSWD=true \
    -e SETUP_SKIP_FULL_UPGRADE=true \
    "$CONTAINER_NAME" \
    bash -lc "cd /repo && ./setup.sh --user '$TEST_USER'"

  docker exec \
    -u "$TEST_USER" \
    -e HOME="/home/$TEST_USER" \
    "$CONTAINER_NAME" \
    bash -lc "rm -rf '$fixture_repo' && cp -R /repo/tests/fixtures/dotfiles '$fixture_repo' && git -C '$fixture_repo' init && git -C '$fixture_repo' config user.name 'Bootstrap Test' && git -C '$fixture_repo' config user.email 'bootstrap-test@example.com' && git -C '$fixture_repo' add . && git -C '$fixture_repo' commit -m 'fixture'"

  docker exec \
    -u "$TEST_USER" \
    -e HOME="/home/$TEST_USER" \
    -e DOTFILES_REPO="$fixture_repo" \
    -e MISE_GLOBAL_TOOLS="" \
    -e PACKAGE_SKIP_REFRESH=true \
    -e INSTALL_SYSTEM_SERVICES=true \
    -e ENABLE_SSH_SERVICE=true \
    -e INSTALL_SYNCTHING=true \
    -e ENABLE_SYNCTHING_SERVICE=true \
    -e INSTALL_TAILSCALE=true \
    -e ENABLE_TAILSCALE_SERVICE=false \
    -e INSTALL_FLATPAK_APPS=true \
    -e INSTALL_OBSIDIAN=true \
    -e INSTALL_CLI_TOOLS=true \
    -e INSTALL_BITWARDEN_CLI=true \
    -e INSTALL_OPENCODE=true \
    -e INSTALL_TGCLI=true \
    -e INSTALL_NGROK=true \
    -e INSTALL_STRIPE_CLI=true \
    -e PATH="/home/$TEST_USER/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    "$CONTAINER_NAME" \
    bash -lc 'cd /repo && ./install.sh'

  docker exec "$CONTAINER_NAME" bash -lc "/repo/tests/verify-optional-features.sh '$TEST_USER' '$DISTRO'"
  cleanup_container "$CONTAINER_NAME"
  CONTAINER_NAME=""
  trap cleanup_docker_config EXIT
}

main
