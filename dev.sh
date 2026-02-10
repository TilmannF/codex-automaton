#!/usr/bin/env bash
set -euo pipefail

TOTAL_STEPS=4
CURRENT_STEP=0
BACKUP_STAGE=""

if [[ -t 1 ]]; then
  BOLD="$(tput bold)"
  RESET="$(tput sgr0)"
  CYAN="$(tput setaf 6)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  RED="$(tput setaf 1)"
  MAGENTA="$(tput setaf 5)"
else
  BOLD=""
  RESET=""
  CYAN=""
  GREEN=""
  YELLOW=""
  RED=""
  MAGENTA=""
fi

usage() {
  cat <<'USAGE'
Usage:
  ./dev install
  ./dev help

Commands:
  install   Check tools, back up existing framework files in CODEX_HOME, and install this framework.
  help      Show this help.
USAGE
}

banner() {
  echo "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo "${BOLD}${MAGENTA}✨ Agentic AI Coding Kit Dev CLI • we shipping fr fr ✨${RESET}"
  echo "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

step() {
  local label="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local pct=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  echo
  echo "${BOLD}${CYAN}[${CURRENT_STEP}/${TOTAL_STEPS}] ${pct}% • ${label}${RESET}"
}

ok() {
  echo "  ${GREEN}✅ $1${RESET}"
}

warn() {
  echo "  ${YELLOW}⚠️  $1${RESET}"
}

fail() {
  echo "  ${RED}💥 $1${RESET}" >&2
  echo "  ${RED}No cap, stopped early so we don't brick your setup.${RESET}" >&2
  exit 1
}

require_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    ok "Tool check passed: ${tool} -> $(command -v "$tool")"
  else
    fail "Missing required tool '${tool}'. Install it first, then rerun."
  fi
}

cleanup() {
  if [[ -n "$BACKUP_STAGE" && -d "$BACKUP_STAGE" ]]; then
    rm -rf "$BACKUP_STAGE"
  fi
}
trap cleanup EXIT

run_install() {
  if [[ $# -ne 0 ]]; then
    fail "Unexpected arguments for 'install'. Use: ./dev install"
  fi

  local script_dir repo_root framework_src codex_home timestamp backup_dir backup_zip
  local source_count existing_count rel target_path

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$script_dir"
  framework_src="$repo_root/.codex"
  codex_home="${CODEX_HOME:-$HOME/.codex}"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="$codex_home/backups/codex-automaton"
  backup_zip="$backup_dir/framework-backup-$timestamp.zip"

  CURRENT_STEP=0
  banner

  step "Vibe check: required tools"
  require_tool codex
  require_tool yq
  require_tool zip

  if [[ ! -d "$framework_src" ]]; then
    fail "Framework source folder not found at '$framework_src'."
  fi
  ok "Framework source detected: $framework_src"
  ok "Install target (CODEX_HOME): $codex_home"

  step "Backup mode: zipping current framework files"
  mkdir -p "$codex_home" "$backup_dir"
  BACKUP_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/codex-framework-backup.XXXXXX")"

  source_count=0
  existing_count=0

  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    source_count=$((source_count + 1))
    target_path="$codex_home/$rel"
    if [[ -e "$target_path" ]]; then
      mkdir -p "$BACKUP_STAGE/$(dirname "$rel")"
      cp -R "$target_path" "$BACKUP_STAGE/$rel"
      existing_count=$((existing_count + 1))
    fi
  done < <(cd "$framework_src" && find . -type f -print0)

  {
    echo "timestamp=$timestamp"
    echo "codex_home=$codex_home"
    echo "framework_source=$framework_src"
    echo "source_file_count=$source_count"
    echo "existing_file_count=$existing_count"
  } > "$BACKUP_STAGE/backup-manifest.txt"

  (cd "$BACKUP_STAGE" && zip -rq "$backup_zip" .)
  ok "Backup zip created: $backup_zip"
  if (( existing_count == 0 )); then
    warn "No matching framework files were present. Backup still created with manifest."
  else
    ok "Backed up $existing_count existing framework file(s)."
  fi

  step "Install mode: copying framework into CODEX_HOME"
  cp -R "$framework_src/." "$codex_home/"
  ok "Framework files copied into $codex_home"

  step "Recap + next move"
  echo "  ${GREEN}🧠 Install complete. You are locked in.${RESET}"
  echo "  ${GREEN}📦 Backup: $backup_zip${RESET}"
  echo "  ${GREEN}🏠 Installed to: $codex_home${RESET}"
  echo "  ${GREEN}🔥 Next: boot Codex and ship.${RESET}"
}

main() {
  local command="${1:-help}"
  shift || true
  case "$command" in
    install)
      run_install "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Unknown command: $command" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
