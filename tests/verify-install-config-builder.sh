#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

assert_equals() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$expected" != "$actual" ]]; then
    printf 'assertion failed for %s: expected=%s actual=%s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

main() {
  local tmpdir
  local input_file
  local output_file
  local interactive_selection_file
  local interactive_output_file

  tmpdir="$(mktemp -d)"
  trap 'rm -rf -- '"'"'$tmpdir'"'"'' EXIT
  input_file="$tmpdir/install.selection.env"
  output_file="$tmpdir/install.generated.env"
  interactive_selection_file="$tmpdir/interactive.selection.env"
  interactive_output_file="$tmpdir/interactive.generated.env"

  cat >"$input_file" <<'EOF'
SELECT_INSTALL_FEATURES=(
  docker
  syncthing
  stripe-cli
  bitwarden-cli
)

APPLY_CHEZMOI=true
EOF

  "$REPO_ROOT/scripts/build-install-config.sh" --from-file "$input_file" --output "$output_file" --selection-file "$input_file"

  # shellcheck disable=SC1090
  source "$output_file"

  assert_equals "00_base,10_shell,20_git,30_docker,60_services,80_cli_tools,90_verify" "$SETUP_ROLES" SETUP_ROLES
  assert_equals true "$ENABLE_DOCKER" ENABLE_DOCKER
  assert_equals false "$INSTALL_EDITORS" INSTALL_EDITORS
  assert_equals true "$INSTALL_SYSTEM_SERVICES" INSTALL_SYSTEM_SERVICES
  assert_equals true "$INSTALL_SYNCTHING" INSTALL_SYNCTHING
  assert_equals true "$INSTALL_CLI_TOOLS" INSTALL_CLI_TOOLS
  assert_equals true "$INSTALL_BITWARDEN_CLI" INSTALL_BITWARDEN_CLI
  assert_equals true "$INSTALL_STRIPE_CLI" INSTALL_STRIPE_CLI
  assert_equals false "$INSTALL_FLATPAK_APPS" INSTALL_FLATPAK_APPS
  assert_equals true "$APPLY_CHEZMOI" APPLY_CHEZMOI

  printf 'y\ny\ny\ny\nn\nn\nn\nn\nn\nn\nn\nn\nn\n' | \
    "$REPO_ROOT/scripts/build-install-config.sh" --interactive --selection-file "$interactive_selection_file" --output "$interactive_output_file"

  # shellcheck disable=SC1090
  source "$interactive_output_file"

  assert_equals "00_base,10_shell,20_git,30_docker,40_editors,50_languages,60_services,90_verify" "$SETUP_ROLES" INTERACTIVE_SETUP_ROLES
  assert_equals true "$INSTALL_EDITORS" INTERACTIVE_INSTALL_EDITORS
  assert_equals true "$ENABLE_DOCKER" INTERACTIVE_ENABLE_DOCKER
  assert_equals true "$INSTALL_MISE" INTERACTIVE_INSTALL_MISE
  assert_equals true "$ENABLE_SSH_SERVICE" INTERACTIVE_ENABLE_SSH_SERVICE
  assert_equals false "$INSTALL_SYNCTHING" INTERACTIVE_INSTALL_SYNCTHING
  assert_equals false "$INSTALL_CLI_TOOLS" INTERACTIVE_INSTALL_CLI_TOOLS
}

main
