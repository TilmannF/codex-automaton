# Tasks Contract

This document defines the canonical `tasks.yaml` contract for planning, execution, and feedback workflow skills.

## Canonical sources
- Schema template: `.codex/skills/feature-planning/assets/tasks.yaml`
- Validator script: `.codex/skills/feature-planning/scripts/validate-tasks.sh`

## Required validation commands
General schema/graph validation:
```bash
./.codex/skills/feature-planning/scripts/validate-tasks.sh .work/<slug>/tasks.yaml
```

Cross-file AC mapping validation:
```bash
./.codex/skills/feature-planning/scripts/validate-tasks.sh --spec .work/<slug>/spec.yaml .work/<slug>/tasks.yaml
```

Planning strict selectability validation:
```bash
./.codex/skills/feature-planning/scripts/validate-tasks.sh --spec .work/<slug>/spec.yaml --require-selectable .work/<slug>/tasks.yaml
```

## Planning artifact-first contract
1. Planning completion requires on-disk `.work/<slug>/tasks.yaml`.
2. If planning ran in Plan mode and files cannot be written, planning must output `handoff required` and stop.
3. While active skill is planning, phrase "implement this plan" means persist and validate planning artifacts, not production code implementation.

## Required behavior across skills
1. Ensure required tasks artifact exists on disk before consuming it.
2. Ensure source spec exists and passes the required validation gate for the current phase.
3. Run `validate-tasks.sh` before consuming `tasks.yaml`.
4. If a skill edits `tasks.yaml`, re-run `validate-tasks.sh` before proceeding.
5. If artifact is missing or consistency checks fail, stop and surface errors; do not continue silently.
6. Skills that both consume and edit `tasks.yaml` (for example feedback reconciliation) must validate both before consuming and after edits are applied.

## Task schema contract
1. Top-level fields are:
   - `feature_slug`
   - `source_spec`
   - `tasks`
   - `execution`
2. Task entry fields are:
   - `id`
   - `title`
   - `type`
   - `status`
   - `maps_to`
   - `depends_on`
   - `files`
   - `instructions`
   - optional: `expected_failure`
   - `definition_of_done`
3. `id` must match `T-###` and be unique.
4. `type` must be one of: `test_red`, `implementation`, `refactor`, `docs`.
5. `status` must be one of: `todo`, `in_progress`, `done`, `blocked`.
6. `execution.strategy` must be `implement-next-task`.
7. `execution.selection_rule` must be exactly `pick first todo task whose dependencies are done`.
8. `maps_to`, `files`, `instructions`, and `definition_of_done` must be non-empty string lists.
9. `depends_on` must be a list.
10. If present, `expected_failure` must be a non-empty string list.
11. Fields defined as strings (for example `feature_slug`, `source_spec`, and task `title`) must be YAML strings, not non-string scalars or objects.

## Task lifecycle and execution contract
1. New tasks should start in `todo` unless explicitly preserved history requires otherwise.
2. `test_red` tasks create failing tests and related scaffolding only; no full behavior fix.
3. `implementation` tasks implement only behavior required for mapped acceptance criteria and failing tests.
4. A task is `done` only when all `definition_of_done` entries are objectively satisfied.
5. Feedback reconciliation must keep completed task history stable (do not rewrite completed tasks).

## Dependency and selectability contract
1. `depends_on` values must reference existing `tasks[].id` values.
2. Self-dependencies are invalid.
3. Dependency cycles are invalid.
4. A task is selectable when:
   - `status` is `todo`
   - all `depends_on` tasks are `done`
5. Next-task selection rule is: pick the first selectable `todo` task.
6. Planning strictness (`--require-selectable`) requires at least one selectable `todo` task.
7. If no task is selectable in a phase that requires selection, report blockers and stop.

## AC ID mapping contract
1. Source AC IDs come from `.work/<slug>/spec.yaml` at `acceptance_criteria[].id`.
2. `tasks.yaml` entries in `tasks[].maps_to[]` must reference existing AC IDs when validator is run with `--spec`.
3. If a referenced AC ID is missing, task generation/reconciliation/execution must stop and report a blocker.
4. When run with `--spec`, `feature_slug` must match `spec.feature.slug`.

## Planning consistency checks
1. Run validator with `--spec` and `--require-selectable`.
2. `tasks` is non-empty.
3. At least one selectable `todo` task exists.
4. All `maps_to` values reference existing AC IDs from spec.
5. Dependency graph references only existing task IDs and has no cycles.
