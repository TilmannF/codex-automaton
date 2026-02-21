#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: validate-spec.sh [--require-approved] <path-to-spec.yaml>

Validates a feature-intake spec.yaml against required structural rules.
Implementation uses Bash + yq.
USAGE
}

require_approved="false"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    --require-approved)
      require_approved="true"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

spec_path="$1"
if [[ ! -f "$spec_path" ]]; then
  echo "ERROR: File not found: $spec_path" >&2
  exit 2
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq not found in PATH." >&2
  exit 2
fi
YQ_BIN="$(command -v yq)"

if ! "$YQ_BIN" eval '.' "$spec_path" >/dev/null 2>&1; then
  echo "FAIL: Invalid YAML in $spec_path" >&2
  exit 1
fi

errors=()

add_error() {
  errors+=("$1")
}

yq_value() {
  local expr="$1"
  "$YQ_BIN" eval -r "$expr" "$spec_path" 2>/dev/null
}

require_top_key() {
  local key="$1"
  local exists
  exists="$(yq_value "has(\"$key\")")"
  if [[ "$exists" != "true" ]]; then
    add_error "Missing required top-level key: $key"
  fi
}

require_map() {
  local path="$1"
  local label="$2"
  local t
  t="$(yq_value "$path | type")"
  if [[ "$t" != "!!map" ]]; then
    add_error "$label must be a mapping/object"
  fi
}

require_list() {
  local path="$1"
  local label="$2"
  local t
  t="$(yq_value "$path | type")"
  if [[ "$t" != "!!seq" ]]; then
    add_error "$label must be a list"
  fi
}

require_non_empty_string() {
  local path="$1"
  local label="$2"
  local t
  local value

  t="$(yq_value "$path | type")"
  if [[ "$t" != "!!str" ]]; then
    add_error "$label must be a non-empty string"
    return
  fi

  value="$(yq_value "$path // \"\"")"
  if [[ -z "${value//[[:space:]]/}" ]]; then
    add_error "$label must be a non-empty string"
  fi
}

validate_non_empty_string_list() {
  local path="$1"
  local label="$2"
  local t
  local len
  local item
  local i

  t="$(yq_value "$path | type")"
  if [[ "$t" != "!!seq" ]]; then
    add_error "$label must be a non-empty string list"
    return
  fi

  len="$(yq_value "$path | length")"
  if [[ ! "$len" =~ ^[0-9]+$ ]] || (( len == 0 )); then
    add_error "$label must be a non-empty string list"
    return
  fi

  for ((i = 0; i < len; i++)); do
    t="$(yq_value "$path[$i] | type")"
    if [[ "$t" != "!!str" ]]; then
      add_error "$label[$i] must be a non-empty string"
      continue
    fi
    item="$(yq_value "$path[$i] // \"\"")"
    if [[ -z "${item//[[:space:]]/}" ]]; then
      add_error "$label[$i] must be a non-empty string"
    fi
  done
}

for key in feature context scope acceptance_criteria; do
  require_top_key "$key"
done

require_map ".feature" "feature"
require_map ".context" "context"
require_map ".scope" "scope"

require_non_empty_string ".feature.slug" "feature.slug"
require_non_empty_string ".feature.title" "feature.title"
require_non_empty_string ".feature.branch" "feature.branch"

status="$(yq_value ".feature.status // \"\"")"
case "$status" in
  draft|approved|in_progress|done) ;;
  *)
    add_error "feature.status must be one of: draft, approved, in_progress, done"
    ;;
esac
if [[ "$require_approved" == "true" && "$status" != "approved" ]]; then
  add_error "feature.status must be approved when using --require-approved"
fi

require_non_empty_string ".context.problem_statement" "context.problem_statement"
require_non_empty_string ".context.goal" "context.goal"
require_non_empty_string ".context.success_signal" "context.success_signal"

validate_non_empty_string_list ".scope.in_scope" "scope.in_scope"
validate_non_empty_string_list ".scope.out_of_scope" "scope.out_of_scope"

ac_type="$(yq_value ".acceptance_criteria | type")"
if [[ "$ac_type" != "!!seq" ]]; then
  add_error "acceptance_criteria must be a non-empty list"
else
  ac_len="$(yq_value ".acceptance_criteria | length")"
  if [[ "$ac_len" =~ ^[0-9]+$ ]] && (( ac_len > 0 )); then
    seen_ac_ids=$'\n'
    for ((i = 0; i < ac_len; i++)); do
      prefix="acceptance_criteria[$i]"

      ac_id="$(yq_value ".acceptance_criteria[$i].id // \"\"")"
      if [[ ! "$ac_id" =~ ^AC-[0-9]{3}$ ]]; then
        add_error "$prefix.id must match AC-### (for example: AC-001)"
      elif [[ "$seen_ac_ids" == *$'\n'"$ac_id"$'\n'* ]]; then
        add_error "$prefix.id duplicates $ac_id"
      else
        seen_ac_ids+="$ac_id"$'\n'
      fi

      require_non_empty_string ".acceptance_criteria[$i].title" "$prefix.title"

      priority="$(yq_value ".acceptance_criteria[$i].priority // \"\"")"
      case "$priority" in
        must|should|could) ;;
        *) add_error "$prefix.priority must be one of: must, should, could" ;;
      esac

      require_non_empty_string ".acceptance_criteria[$i].given" "$prefix.given"
      require_non_empty_string ".acceptance_criteria[$i].when" "$prefix.when"
      require_non_empty_string ".acceptance_criteria[$i].then" "$prefix.then"

      verification_type="$(yq_value ".acceptance_criteria[$i].verification | type")"
      if [[ "$verification_type" != "!!map" ]]; then
        add_error "$prefix.verification must be a mapping/object"
      else
        require_non_empty_string ".acceptance_criteria[$i].verification.type" "$prefix.verification.type"
        require_non_empty_string ".acceptance_criteria[$i].verification.artifact" "$prefix.verification.artifact"
      fi
    done
  else
    add_error "acceptance_criteria must be a non-empty list"
  fi
fi

if (( ${#errors[@]} > 0 )); then
  echo "FAIL: $spec_path failed ${#errors[@]} validation check(s):" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  exit 1
fi

echo "PASS: $spec_path is valid for feature-intake schema checks."
