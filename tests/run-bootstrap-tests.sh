#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_USER="${TEST_USER:-tester}"
DISTROS=("$@")
DOCKER_CONFIG_DIR="${DOCKER_CONFIG_DIR:-}"
TEMP_DOCKER_CONFIG=0
LOG_DIR=""

if [[ "${#DISTROS[@]}" -eq 0 ]]; then
  DISTROS=(ubuntu arch)
fi

setup_docker_config() {
  if [[ -z "$DOCKER_CONFIG_DIR" ]]; then
    DOCKER_CONFIG_DIR="$(mktemp -d)"
    TEMP_DOCKER_CONFIG=1
  fi

  mkdir -p "$DOCKER_CONFIG_DIR"

  if [[ ! -f "$DOCKER_CONFIG_DIR/config.json" ]]; then
    printf '{"auths":{}}\n' >"$DOCKER_CONFIG_DIR/config.json"
  fi

  export DOCKER_CONFIG="$DOCKER_CONFIG_DIR"
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

build_image() {
  local distro="$1"
  local image="bootstrap-test:${distro}"

  docker build -t "$image" "$REPO_ROOT/tests/images/$distro"
}

run_test() {
  local distro="$1"
  local image="bootstrap-test:${distro}"
  local container_name="bootstrap-test-${distro}"
  local fixture_repo="/home/$TEST_USER/dotfiles-fixture"

  (
    cleanup_container "$container_name"
    trap 'cleanup_container "$container_name"' EXIT

    build_image "$distro"

    docker run -d \
      --privileged \
      --cgroupns=host \
      --tmpfs /run \
      --tmpfs /run/lock \
      -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
      -v "$REPO_ROOT:/repo:ro" \
      --name "$container_name" \
      "$image" >/dev/null

    wait_for_systemd "$container_name"

    docker exec \
      -e SETUP_SKIP_PASSWORD_PROMPT=true \
      -e SETUP_SUDO_NOPASSWD=true \
      -e SETUP_SKIP_FULL_UPGRADE=true \
      "$container_name" \
      bash -lc "cd /repo && ./setup.sh --user '$TEST_USER'"

    docker exec \
      -u "$TEST_USER" \
      -e HOME="/home/$TEST_USER" \
      "$container_name" \
      bash -lc "rm -rf '$fixture_repo' && cp -R /repo/tests/fixtures/dotfiles '$fixture_repo' && git -C '$fixture_repo' init && git -C '$fixture_repo' config user.name 'Bootstrap Test' && git -C '$fixture_repo' config user.email 'bootstrap-test@example.com' && git -C '$fixture_repo' add . && git -C '$fixture_repo' commit -m 'fixture'"

    docker exec \
      -u "$TEST_USER" \
      -e HOME="/home/$TEST_USER" \
      -e DOTFILES_REPO="$fixture_repo" \
      -e MISE_GLOBAL_TOOLS="" \
      -e PACKAGE_SKIP_REFRESH=true \
      -e INSTALL_SYSTEM_SERVICES=true \
      -e ENABLE_SSH_SERVICE=true \
      -e INSTALL_SYNCTHING=false \
      -e ENABLE_SYNCTHING_SERVICE=false \
      -e INSTALL_TAILSCALE=false \
      -e ENABLE_TAILSCALE_SERVICE=false \
      -e INSTALL_FLATPAK_APPS=true \
      -e INSTALL_OBSIDIAN=false \
      -e INSTALL_BITWARDEN_CLI=false \
      -e INSTALL_CLI_TOOLS=false \
      -e PATH="/home/$TEST_USER/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
      "$container_name" \
      bash -lc 'cd /repo && ./install.sh'

    docker exec "$container_name" bash -lc "/repo/tests/verify-bootstrap.sh '$TEST_USER'"
  )
}

main() {
  local distro
  local failed=0
  local -a pids=()

  setup_docker_config
  preflight
  LOG_DIR="$(mktemp -d)"
  trap 'cleanup_docker_config; rm -rf "$LOG_DIR"' EXIT

  for distro in "${DISTROS[@]}"; do
    printf '==> Running bootstrap integration test for %s\n' "$distro"
    (run_test "$distro") >"$LOG_DIR/$distro.log" 2>&1 &
    pids+=("$!")
  done

  for i in "${!DISTROS[@]}"; do
    if ! wait "${pids[$i]}"; then
      failed=1
    fi

    cat "$LOG_DIR/${DISTROS[$i]}.log"
  done

  if [[ "$failed" -ne 0 ]]; then
    return 1
  fi
}

main
