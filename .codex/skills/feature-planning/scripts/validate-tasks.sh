#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: validate-tasks.sh [--spec <path-to-spec.yaml>] [--require-selectable] <path-to-tasks.yaml>

Validates a feature-planning tasks.yaml against required structural, dependency, and execution rules.
Implementation uses Bash + yq.
USAGE
}

spec_path=""
require_selectable="false"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    --spec)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --spec requires a path argument." >&2
        usage >&2
        exit 2
      fi
      spec_path="$2"
      shift 2
      ;;
    --require-selectable)
      require_selectable="true"
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

tasks_path="$1"
if [[ ! -f "$tasks_path" ]]; then
  echo "ERROR: File not found: $tasks_path" >&2
  exit 2
fi

if [[ -n "$spec_path" && ! -f "$spec_path" ]]; then
  echo "ERROR: Spec file not found: $spec_path" >&2
  exit 2
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq not found in PATH." >&2
  exit 2
fi
YQ_BIN="$(command -v yq)"

if ! "$YQ_BIN" eval '.' "$tasks_path" >/dev/null 2>&1; then
  echo "FAIL: Invalid YAML in $tasks_path" >&2
  exit 2
fi

if [[ -n "$spec_path" ]] && ! "$YQ_BIN" eval '.' "$spec_path" >/dev/null 2>&1; then
  echo "FAIL: Invalid YAML in $spec_path" >&2
  exit 2
fi

errors=()
cycle_reported="false"

add_error() {
  errors+=("$1")
}

yq_tasks() {
  local expr="$1"
  "$YQ_BIN" eval -r "$expr" "$tasks_path" 2>/dev/null
}

yq_spec() {
  local expr="$1"
  "$YQ_BIN" eval -r "$expr" "$spec_path" 2>/dev/null
}

is_task_id() {
  local value="$1"
  [[ "$value" =~ ^T-[0-9]{3}$ ]]
}

require_top_key() {
  local key="$1"
  local exists
  exists="$(yq_tasks "has(\"$key\")")"
  if [[ "$exists" != "true" ]]; then
    add_error "Missing required top-level key: $key"
  fi
}

require_map() {
  local path="$1"
  local label="$2"
  local t
  t="$(yq_tasks "$path | type")"
  if [[ "$t" != "!!map" ]]; then
    add_error "$label must be a mapping/object"
  fi
}

require_non_empty_string() {
  local path="$1"
  local label="$2"
  local t
  local value

  t="$(yq_tasks "$path | type")"
  if [[ "$t" != "!!str" ]]; then
    add_error "$label must be a non-empty string"
    return
  fi

  value="$(yq_tasks "$path // \"\"")"
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

  t="$(yq_tasks "$path | type")"
  if [[ "$t" != "!!seq" ]]; then
    add_error "$label must be a non-empty list"
    return
  fi

  len="$(yq_tasks "$path | length")"
  if [[ ! "$len" =~ ^[0-9]+$ ]] || (( len == 0 )); then
    add_error "$label must be a non-empty list"
    return
  fi

  for ((i = 0; i < len; i++)); do
    t="$(yq_tasks "$path[$i] | type")"
    if [[ "$t" != "!!str" ]]; then
      add_error "$label[$i] must be a non-empty string"
      continue
    fi
    item="$(yq_tasks "$path[$i] // \"\"")"
    if [[ -z "${item//[[:space:]]/}" ]]; then
      add_error "$label[$i] must be a non-empty string"
    fi
  done
}

set_has_value() {
  local set="$1"
  local value="$2"
  printf '%s' "$set" | grep -F -x -q -- "$value"
}

remove_from_set() {
  local set="$1"
  local id="$2"
  local line
  local out

  out=$'\n'
  while IFS= read -r line; do
    if [[ -z "${line//[[:space:]]/}" ]]; then
      continue
    fi
    if [[ "$line" == "$id" ]]; then
      continue
    fi
    out+="$line"$'\n'
  done <<< "$set"

  printf '%s' "$out"
}

is_visiting() {
  local id="$1"
  set_has_value "$visiting_ids" "$id"
}

is_visited() {
  local id="$1"
  set_has_value "$visited_ids" "$id"
}

mark_visiting() {
  local id="$1"
  if ! is_visiting "$id"; then
    visiting_ids+="$id"$'\n'
  fi
}

unmark_visiting() {
  local id="$1"
  visiting_ids="$(remove_from_set "$visiting_ids" "$id")"
}

mark_visited() {
  local id="$1"
  if ! is_visited "$id"; then
    visited_ids+="$id"$'\n'
  fi
}

find_task_index_by_id() {
  local id="$1"
  local idx
  for ((idx = 0; idx < tasks_len; idx++)); do
    if [[ "${task_ids[$idx]}" == "$id" ]]; then
      printf '%s' "$idx"
      return 0
    fi
  done
  return 1
}

status_for_task_id() {
  local id="$1"
  local idx
  idx="$(find_task_index_by_id "$id" || true)"
  if [[ -z "${idx//[[:space:]]/}" ]]; then
    return 1
  fi
  printf '%s' "${task_statuses[$idx]}"
  return 0
}

dfs_visit() {
  local id="$1"
  local deps_len
  local dep
  local i

  if ! is_task_id "$id"; then
    return 0
  fi

  if ! set_has_value "$seen_task_ids" "$id"; then
    return 0
  fi

  if is_visiting "$id"; then
    if [[ "$cycle_reported" != "true" ]]; then
      add_error "Dependency cycle detected in tasks graph (example at $id)"
      cycle_reported="true"
    fi
    return 1
  fi

  if is_visited "$id"; then
    return 0
  fi

  mark_visiting "$id"

  deps_len="$(yq_tasks ".tasks[] | select(.id == \"$id\") | .depends_on | length")"
  if [[ "$deps_len" =~ ^[0-9]+$ ]]; then
    for ((i = 0; i < deps_len; i++)); do
      dep="$(yq_tasks ".tasks[] | select(.id == \"$id\") | .depends_on[$i] // \"\"")"
      if [[ -n "${dep//[[:space:]]/}" ]] && is_task_id "$dep" && set_has_value "$seen_task_ids" "$dep"; then
        dfs_visit "$dep" || true
      fi
    done
  fi

  unmark_visiting "$id"
  mark_visited "$id"
  return 0
}

for key in feature_slug source_spec tasks execution; do
  require_top_key "$key"
done

require_non_empty_string ".feature_slug" "feature_slug"
require_non_empty_string ".source_spec" "source_spec"
require_map ".execution" "execution"

tasks_type="$(yq_tasks ".tasks | type")"
if [[ "$tasks_type" != "!!seq" ]]; then
  add_error "tasks must be a non-empty list"
  tasks_len=0
else
  tasks_len="$(yq_tasks ".tasks | length")"
  if [[ ! "$tasks_len" =~ ^[0-9]+$ ]] || (( tasks_len == 0 )); then
    add_error "tasks must be a non-empty list"
    tasks_len=0
  fi
fi

execution_strategy="$(yq_tasks ".execution.strategy // \"\"")"
if [[ "$execution_strategy" != "implement-next-task" ]]; then
  add_error "execution.strategy must be: implement-next-task"
fi

execution_selection_rule="$(yq_tasks ".execution.selection_rule // \"\"")"
if [[ "$execution_selection_rule" != "pick first todo task whose dependencies are done" ]]; then
  add_error "execution.selection_rule must be: pick first todo task whose dependencies are done"
fi

seen_task_ids=$'\n'
visiting_ids=$'\n'
visited_ids=$'\n'
task_ids=()
task_statuses=()

if [[ "$tasks_len" =~ ^[0-9]+$ ]] && (( tasks_len > 0 )); then
  for ((i = 0; i < tasks_len; i++)); do
    prefix="tasks[$i]"

    task_entry_type="$(yq_tasks ".tasks[$i] | type")"
    if [[ "$task_entry_type" != "!!map" ]]; then
      add_error "$prefix must be a mapping/object"
      continue
    fi

    task_id="$(yq_tasks ".tasks[$i].id // \"\"")"
    if ! is_task_id "$task_id"; then
      add_error "$prefix.id must match T-### (for example: T-001)"
    elif set_has_value "$seen_task_ids" "$task_id"; then
      add_error "$prefix.id duplicates $task_id"
    else
      seen_task_ids+="$task_id"$'\n'
    fi

    require_non_empty_string ".tasks[$i].title" "$prefix.title"

    task_type="$(yq_tasks ".tasks[$i].type // \"\"")"
    case "$task_type" in
      test_red|implementation|refactor|docs) ;;
      *) add_error "$prefix.type must be one of: test_red, implementation, refactor, docs" ;;
    esac

    task_status="$(yq_tasks ".tasks[$i].status // \"\"")"
    task_ids[$i]="$task_id"
    task_statuses[$i]="$task_status"
    case "$task_status" in
      todo|in_progress|done|blocked) ;;
      *) add_error "$prefix.status must be one of: todo, in_progress, done, blocked" ;;
    esac

    validate_non_empty_string_list ".tasks[$i].maps_to" "$prefix.maps_to"
    validate_non_empty_string_list ".tasks[$i].files" "$prefix.files"
    validate_non_empty_string_list ".tasks[$i].instructions" "$prefix.instructions"
    validate_non_empty_string_list ".tasks[$i].definition_of_done" "$prefix.definition_of_done"

    depends_type="$(yq_tasks ".tasks[$i].depends_on | type")"
    if [[ "$depends_type" != "!!seq" ]]; then
      add_error "$prefix.depends_on must be a list"
    fi

    expected_failure_present="$(yq_tasks ".tasks[$i] | has(\"expected_failure\")")"
    if [[ "$expected_failure_present" == "true" ]]; then
      validate_non_empty_string_list ".tasks[$i].expected_failure" "$prefix.expected_failure"
    fi
  done

  for ((i = 0; i < tasks_len; i++)); do
    task_id="$(yq_tasks ".tasks[$i].id // \"\"")"
    [[ -z "${task_id//[[:space:]]/}" ]] && continue

    depends_len="$(yq_tasks ".tasks[$i].depends_on | length")"
    if [[ "$depends_len" =~ ^[0-9]+$ ]]; then
      for ((j = 0; j < depends_len; j++)); do
        dep_id="$(yq_tasks ".tasks[$i].depends_on[$j] // \"\"")"
        if [[ -z "${dep_id//[[:space:]]/}" ]]; then
          add_error "tasks[$i].depends_on[$j] must be a non-empty string"
          continue
        fi
        if [[ "$dep_id" == "$task_id" ]]; then
          add_error "tasks[$i].depends_on[$j] cannot self-reference $task_id"
        fi
        if ! set_has_value "$seen_task_ids" "$dep_id"; then
          add_error "tasks[$i].depends_on[$j] references unknown task id: $dep_id"
        fi
      done
    fi
  done

  for ((i = 0; i < tasks_len; i++)); do
    task_id="$(yq_tasks ".tasks[$i].id // \"\"")"
    if is_task_id "$task_id"; then
      dfs_visit "$task_id" || true
    fi
  done

  if [[ -n "$spec_path" ]]; then
    spec_slug="$(yq_spec ".feature.slug // \"\"")"
    tasks_slug="$(yq_tasks ".feature_slug // \"\"")"
    if [[ -n "${spec_slug//[[:space:]]/}" && -n "${tasks_slug//[[:space:]]/}" && "$spec_slug" != "$tasks_slug" ]]; then
      add_error "feature_slug does not match spec.feature.slug ($tasks_slug != $spec_slug)"
    fi

    ac_ids=$'\n'
    ac_type="$(yq_spec ".acceptance_criteria | type")"
    if [[ "$ac_type" != "!!seq" ]]; then
      add_error "Spec acceptance_criteria must be a non-empty list when using --spec"
    else
      ac_len="$(yq_spec ".acceptance_criteria | length")"
      if [[ ! "$ac_len" =~ ^[0-9]+$ ]] || (( ac_len == 0 )); then
        add_error "Spec acceptance_criteria must be a non-empty list when using --spec"
      else
        for ((k = 0; k < ac_len; k++)); do
          ac_id="$(yq_spec ".acceptance_criteria[$k].id // \"\"")"
          if [[ -n "${ac_id//[[:space:]]/}" ]]; then
            ac_ids+="$ac_id"$'\n'
          fi
        done
      fi
    fi

    for ((i = 0; i < tasks_len; i++)); do
      maps_to_len="$(yq_tasks ".tasks[$i].maps_to | length")"
      if [[ "$maps_to_len" =~ ^[0-9]+$ ]]; then
        for ((j = 0; j < maps_to_len; j++)); do
          ac_id="$(yq_tasks ".tasks[$i].maps_to[$j] // \"\"")"
          if [[ -n "${ac_id//[[:space:]]/}" ]] && ! set_has_value "$ac_ids" "$ac_id"; then
            add_error "tasks[$i].maps_to[$j] references unknown AC id: $ac_id"
          fi
        done
      fi
    done
  fi

  if [[ "$require_selectable" == "true" ]]; then
    selectable_found="false"
    for ((i = 0; i < tasks_len; i++)); do
      task_status="$(yq_tasks ".tasks[$i].status // \"\"")"
      if [[ "$task_status" != "todo" ]]; then
        continue
      fi

      deps_done="true"
      depends_len="$(yq_tasks ".tasks[$i].depends_on | length")"
      if [[ "$depends_len" =~ ^[0-9]+$ ]]; then
        for ((j = 0; j < depends_len; j++)); do
          dep_id="$(yq_tasks ".tasks[$i].depends_on[$j] // \"\"")"
          dep_status=""
          if [[ -n "${dep_id//[[:space:]]/}" ]] && is_task_id "$dep_id" && set_has_value "$seen_task_ids" "$dep_id"; then
            dep_status="$(status_for_task_id "$dep_id" || true)"
          fi
          if [[ "$dep_status" != "done" ]]; then
            deps_done="false"
            break
          fi
        done
      fi

      if [[ "$deps_done" == "true" ]]; then
        selectable_found="true"
        break
      fi
    done

    if [[ "$selectable_found" != "true" ]]; then
      add_error "No selectable todo task found (status=todo with all depends_on tasks in done)."
    fi
  fi
fi

if (( ${#errors[@]} > 0 )); then
  echo "FAIL: $tasks_path failed ${#errors[@]} validation check(s):" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  exit 1
fi

echo "PASS: $tasks_path is valid for feature-planning schema checks."
