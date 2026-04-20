#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SELECTION_FILE="$REPO_ROOT/config/install.selection.env"
OUTPUT_FILE="$REPO_ROOT/config/install.generated.env"
MODE="auto"

declare -a SELECT_INSTALL_FEATURES=()
declare -A ENABLED_FEATURES=()
declare -A OPTIONAL_FLAGS=(
  [INSTALL_EDITORS]=false
  [ENABLE_DOCKER]=false
  [INSTALL_MISE]=false
  [INSTALL_SYSTEM_SERVICES]=false
  [ENABLE_SSH_SERVICE]=false
  [INSTALL_SYNCTHING]=false
  [ENABLE_SYNCTHING_SERVICE]=false
  [INSTALL_TAILSCALE]=false
  [ENABLE_TAILSCALE_SERVICE]=false
  [INSTALL_FLATPAK_APPS]=false
  [INSTALL_OBSIDIAN]=false
  [INSTALL_CLI_TOOLS]=false
  [INSTALL_BITWARDEN_CLI]=false
  [INSTALL_OPENCODE]=false
  [ENABLE_OPENCODE_SERVICE]=false
  [INSTALL_TGCLI]=false
  [INSTALL_NGROK]=false
  [INSTALL_STRIPE_CLI]=false
)
declare -a ENABLED_ROLES=(00_base 10_shell 20_git 90_verify)

FEATURE_ORDER=(
  editors
  docker
  mise
  ssh-service
  syncthing
  tailscale
  obsidian
  bitwarden-cli
  opencode
  tgcli
  ngrok
  stripe-cli
)

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

info() {
  printf '[INFO] %s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build-install-config.sh
  ./scripts/build-install-config.sh --interactive
  ./scripts/build-install-config.sh --from-file <selection-file> [--output <generated-file>]

Options:
  --interactive            Build from interactive prompts and write config/install.selection.env
  --from-file <path>       Build from an existing selection file without prompts
  --output <path>          Path to generated install env
  --selection-file <path>  Path to persisted selection env
  -h, --help               Show this help
EOF
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --interactive)
        MODE="interactive"
        shift
        ;;
      --from-file)
        MODE="file"
        SELECTION_FILE="${2:-}"
        [[ -n "$SELECTION_FILE" ]] || die "--from-file requires a path"
        shift 2
        ;;
      --output)
        OUTPUT_FILE="${2:-}"
        [[ -n "$OUTPUT_FILE" ]] || die "--output requires a path"
        shift 2
        ;;
      --selection-file)
        SELECTION_FILE="${2:-}"
        [[ -n "$SELECTION_FILE" ]] || die "--selection-file requires a path"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

require_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    die "Missing config file: $file_path"
  fi
}

append_unique() {
  local value="$1"
  local current

  for current in "${ENABLED_ROLES[@]}"; do
    if [[ "$current" == "$value" ]]; then
      return 0
    fi
  done

  ENABLED_ROLES+=("$value")
}

feature_is_selected() {
  local target="$1"
  local feature

  for feature in "${SELECT_INSTALL_FEATURES[@]}"; do
    if [[ "$feature" == "$target" ]]; then
      return 0
    fi
  done

  return 1
}

enable_feature() {
  local feature="$1"

  if [[ -n "${ENABLED_FEATURES[$feature]:-}" ]]; then
    return 0
  fi

  ENABLED_FEATURES[$feature]=true

  case "$feature" in
    editors)
      OPTIONAL_FLAGS[INSTALL_EDITORS]=true
      append_unique 40_editors
      ;;
    docker)
      OPTIONAL_FLAGS[ENABLE_DOCKER]=true
      append_unique 30_docker
      ;;
    mise)
      OPTIONAL_FLAGS[INSTALL_MISE]=true
      append_unique 50_languages
      ;;
    ssh-service)
      OPTIONAL_FLAGS[INSTALL_SYSTEM_SERVICES]=true
      OPTIONAL_FLAGS[ENABLE_SSH_SERVICE]=true
      append_unique 60_services
      ;;
    syncthing)
      OPTIONAL_FLAGS[INSTALL_SYSTEM_SERVICES]=true
      OPTIONAL_FLAGS[INSTALL_SYNCTHING]=true
      OPTIONAL_FLAGS[ENABLE_SYNCTHING_SERVICE]=true
      append_unique 60_services
      ;;
    tailscale)
      OPTIONAL_FLAGS[INSTALL_SYSTEM_SERVICES]=true
      OPTIONAL_FLAGS[INSTALL_TAILSCALE]=true
      OPTIONAL_FLAGS[ENABLE_TAILSCALE_SERVICE]=true
      append_unique 60_services
      ;;
    obsidian)
      OPTIONAL_FLAGS[INSTALL_FLATPAK_APPS]=true
      OPTIONAL_FLAGS[INSTALL_OBSIDIAN]=true
      append_unique 70_flatpak_apps
      ;;
    bitwarden-cli)
      OPTIONAL_FLAGS[INSTALL_CLI_TOOLS]=true
      OPTIONAL_FLAGS[INSTALL_BITWARDEN_CLI]=true
      append_unique 80_cli_tools
      ;;
    opencode)
      OPTIONAL_FLAGS[INSTALL_CLI_TOOLS]=true
      OPTIONAL_FLAGS[INSTALL_OPENCODE]=true
      OPTIONAL_FLAGS[ENABLE_OPENCODE_SERVICE]=true
      append_unique 80_cli_tools
      ;;
    tgcli)
      OPTIONAL_FLAGS[INSTALL_CLI_TOOLS]=true
      OPTIONAL_FLAGS[INSTALL_TGCLI]=true
      append_unique 80_cli_tools
      ;;
    ngrok)
      OPTIONAL_FLAGS[INSTALL_CLI_TOOLS]=true
      OPTIONAL_FLAGS[INSTALL_NGROK]=true
      append_unique 80_cli_tools
      ;;
    stripe-cli)
      OPTIONAL_FLAGS[INSTALL_CLI_TOOLS]=true
      OPTIONAL_FLAGS[INSTALL_STRIPE_CLI]=true
      append_unique 80_cli_tools
      ;;
    *)
      die "Unsupported install feature: $feature"
      ;;
  esac
}

feature_prompt() {
  case "$1" in
    editors) printf 'Install editors (vim, neovim)' ;;
    docker) printf 'Install Docker and enable service' ;;
    mise) printf 'Install mise and language toolchains' ;;
    ssh-service) printf 'Enable SSH service' ;;
    syncthing) printf 'Install Syncthing and enable user service' ;;
    tailscale) printf 'Install Tailscale and enable service' ;;
    obsidian) printf 'Install Obsidian AppImage integration' ;;
    bitwarden-cli) printf 'Install Bitwarden CLI' ;;
    opencode) printf 'Install opencode and user service' ;;
    tgcli) printf 'Install tgcli' ;;
    ngrok) printf 'Install ngrok' ;;
    stripe-cli) printf 'Install Stripe CLI' ;;
    *) die "Unsupported install feature: $1" ;;
  esac
}

prompt_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local input
  local suffix

  case "$default_value" in
    true) suffix='[Y/n]' ;;
    false) suffix='[y/N]' ;;
    *) die "Unsupported default value: $default_value" ;;
  esac

  while true; do
    printf '%s %s: ' "$prompt" "$suffix" >&2
    IFS= read -r input || die "Interactive input was interrupted"
    input="${input,,}"

    if [[ -z "$input" ]]; then
      printf '%s\n' "$default_value"
      return 0
    fi

    case "$input" in
      y|yes)
        printf 'true\n'
        return 0
        ;;
      n|no)
        printf 'false\n'
        return 0
        ;;
    esac

    printf 'Please answer y or n.\n' >&2
  done
}

load_selection_file() {
  require_file "$SELECTION_FILE"
  # shellcheck disable=SC1090
  source "$SELECTION_FILE"
}

maybe_load_existing_selection() {
  if [[ -f "$SELECTION_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$SELECTION_FILE"
  fi
}

collect_selection_interactively() {
  local feature
  local answer
  local defaults=()

  maybe_load_existing_selection

  for feature in "${FEATURE_ORDER[@]}"; do
    if feature_is_selected "$feature"; then
      defaults+=(true)
    else
      defaults+=(false)
    fi
  done

  SELECT_INSTALL_FEATURES=()

  printf 'Select install features. Dependencies are added automatically.\n\n'

  local index=0
  for feature in "${FEATURE_ORDER[@]}"; do
    answer="$(prompt_yes_no "$(feature_prompt "$feature")" "${defaults[$index]}")"
    if [[ "$answer" == "true" ]]; then
      SELECT_INSTALL_FEATURES+=("$feature")
    fi
    index=$((index + 1))
  done
}

write_selection_file() {
  local output_dir
  local feature

  output_dir="$(dirname -- "$SELECTION_FILE")"
  mkdir -p "$output_dir"

  {
    printf 'SELECT_INSTALL_FEATURES=(\n'
    for feature in "${SELECT_INSTALL_FEATURES[@]}"; do
      printf '  %s\n' "$feature"
    done
    printf ')\n\n'

    if [[ -n "${APPLY_CHEZMOI:-}" ]]; then
      printf 'APPLY_CHEZMOI=%q\n' "$APPLY_CHEZMOI"
    else
      printf '# APPLY_CHEZMOI=true\n'
    fi

    if [[ -n "${DOTFILES_REPO:-}" ]]; then
      printf 'DOTFILES_REPO=%q\n' "$DOTFILES_REPO"
    else
      printf '# DOTFILES_REPO=Yusei-SHIRAISHI/my_dotfiles\n'
    fi

    if [[ -n "${MISE_GLOBAL_TOOLS:-}" ]]; then
      printf 'MISE_GLOBAL_TOOLS=%q\n' "$MISE_GLOBAL_TOOLS"
    else
      printf '# MISE_GLOBAL_TOOLS="ruby@latest python@latest node@latest rust@latest terraform@latest awscli@latest"\n'
    fi
  } >"$SELECTION_FILE"
}

ordered_roles_csv() {
  local ordered_roles=(
    00_base
    10_shell
    20_git
    30_docker
    40_editors
    50_languages
    60_services
    70_flatpak_apps
    80_cli_tools
    90_verify
  )
  local role
  local selected=()
  local enabled

  for role in "${ordered_roles[@]}"; do
    for enabled in "${ENABLED_ROLES[@]}"; do
      if [[ "$role" == "$enabled" ]]; then
        selected+=("$role")
        break
      fi
    done
  done

  local IFS=,
  printf '%s\n' "${selected[*]}"
}

write_output() {
  local output_dir
  local role_csv
  local flag

  output_dir="$(dirname -- "$OUTPUT_FILE")"
  mkdir -p "$output_dir"
  role_csv="$(ordered_roles_csv)"

  {
    printf '# Generated by scripts/build-install-config.sh from %s\n' "${SELECTION_FILE#$REPO_ROOT/}"
    printf 'SETUP_ROLES=%q\n' "$role_csv"

    for flag in \
      INSTALL_EDITORS \
      ENABLE_DOCKER \
      INSTALL_MISE \
      INSTALL_SYSTEM_SERVICES \
      ENABLE_SSH_SERVICE \
      INSTALL_SYNCTHING \
      ENABLE_SYNCTHING_SERVICE \
      INSTALL_TAILSCALE \
      ENABLE_TAILSCALE_SERVICE \
      INSTALL_FLATPAK_APPS \
      INSTALL_OBSIDIAN \
      INSTALL_CLI_TOOLS \
      INSTALL_BITWARDEN_CLI \
      INSTALL_OPENCODE \
      ENABLE_OPENCODE_SERVICE \
      INSTALL_TGCLI \
      INSTALL_NGROK \
      INSTALL_STRIPE_CLI; do
      printf 'export %s=%q\n' "$flag" "${OPTIONAL_FLAGS[$flag]}"
    done

    if [[ -n "${APPLY_CHEZMOI:-}" ]]; then
      printf 'export APPLY_CHEZMOI=%q\n' "$APPLY_CHEZMOI"
    fi

    if [[ -n "${DOTFILES_REPO:-}" ]]; then
      printf 'export DOTFILES_REPO=%q\n' "$DOTFILES_REPO"
    fi

    if [[ -n "${MISE_GLOBAL_TOOLS:-}" ]]; then
      printf 'export MISE_GLOBAL_TOOLS=%q\n' "$MISE_GLOBAL_TOOLS"
    fi
  } >"$OUTPUT_FILE"
}

main() {
  local feature

  parse_args "$@"

  if [[ "$MODE" == "auto" ]]; then
    if [[ -t 0 ]]; then
      MODE="interactive"
    else
      MODE="file"
    fi
  fi

  case "$MODE" in
    interactive)
      collect_selection_interactively
      write_selection_file
      ;;
    file)
      load_selection_file
      ;;
    *)
      die "Unsupported mode: $MODE"
      ;;
  esac

  for feature in "${SELECT_INSTALL_FEATURES[@]}"; do
    enable_feature "$feature"
  done

  write_output
  info "Wrote selection config: $SELECTION_FILE"
  info "Wrote install config: $OUTPUT_FILE"
}

main "$@"
