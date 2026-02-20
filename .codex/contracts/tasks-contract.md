# Tasks Contract

This document defines the canonical `tasks.yaml` contract for planning, execution, and feedback workflow skills.

## Canonical source
- Schema template: `.codex/skills/feature-planning/assets/tasks.yaml`

## Planning artifact-first contract
1. Planning completion requires on-disk `.work/<slug>/tasks.yaml`.
2. If planning ran in Plan mode and files cannot be written, planning must output `handoff required` and stop.
3. While active skill is planning, phrase "implement this plan" means persist and validate planning artifacts, not production code implementation.

## Required behavior across skills
1. Ensure required tasks artifact exists on disk before consuming it.
2. Ensure source spec exists and passes the required validation gate for the current phase.
3. If a skill edits `tasks.yaml`, re-check task consistency before proceeding.
4. If artifact is missing or consistency checks fail, stop and surface errors; do not continue silently.

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
3. `type` must be one of: `test_red`, `implementation`, `refactor`, `docs`.
4. `status` must be one of: `todo`, `in_progress`, `done`, `blocked`.
5. `execution.strategy` must be `implement-next-task`.
6. `execution.selection_rule` must reflect deterministic first-selectable-task behavior.

## Task lifecycle and execution contract
1. New tasks should start in `todo` unless explicitly preserved history requires otherwise.
2. `test_red` tasks create failing tests and related scaffolding only; no full behavior fix.
3. `implementation` tasks implement only behavior required for mapped acceptance criteria and failing tests.
4. A task is `done` only when all `definition_of_done` entries are objectively satisfied.
5. Feedback reconciliation must keep completed task history stable (do not rewrite completed tasks).

## Dependency and selectability contract
1. `depends_on` values must reference existing `tasks[].id` values.
2. A task is selectable when:
   - `status` is `todo`
   - all `depends_on` tasks are `done`
3. Next-task selection rule is: pick the first selectable `todo` task.
4. If no task is selectable, report blockers and stop.

## AC ID mapping contract
1. Source AC IDs come from `.work/<slug>/spec.yaml` at `acceptance_criteria[].id`.
2. `tasks.yaml` entries in `tasks[].maps_to[]` must reference existing AC IDs.
3. If a referenced AC ID is missing, task generation/reconciliation/execution must stop and report a blocker.

## Planning consistency checks
1. `tasks` is non-empty.
2. At least one selectable `todo` task exists, or blockers are explicit.
3. All `maps_to` values reference existing AC IDs from spec.
4. Dependency graph references only existing task IDs.

## Validation note
There is no standalone `tasks.yaml` validator script in this repository.
Contract enforcement is performed through planning, execution, and feedback skill checks.
