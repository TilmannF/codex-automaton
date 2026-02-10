---
name: implement-next-task
description: Execute exactly one selectable task from tasks.yaml, then stop with evidence.
---

# Implement Next Task Skill

## Purpose
Run one incremental delivery cycle safely and predictably.

## Phase preconditions
- Run only when user explicitly requests implementation or invokes `implement-next-task`.
- Require on-disk approved spec artifact:
  - `.work/<slug>/spec.yaml` exists
  - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml` passes
- Require tasks artifact:
  - `.work/<slug>/tasks.yaml` exists
- If any precondition fails, stop and report blockers; do not execute tasks.

## Contract dependency
- Read and follow `.codex/contracts/spec-contract.md`.
- Validate approved spec before task selection:
  - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml`

## Inputs
- `.work/<slug>/tasks.yaml`
- `.work/<slug>/spec.yaml`
- Repository files/tests

## Selection rule
Pick the first `todo` task whose `depends_on` are all `done`.

## Execution rules
- Verify `.work/<slug>/tasks.yaml` exists before selecting/executing a task. If missing, stop.
- Run spec validator with `--require-approved` before selecting/executing a task. If it fails, stop.
- Before executing selected task, verify all `maps_to` IDs exist in `spec.yaml`.
- If `maps_to` is invalid, mark selected task `blocked` with reason and stop.
- Execute exactly one task.
- Respect task `type`:
    - `test_red`: only create failing test + related scaffolding; no full feature fix.
    - `implementation`: implement only behavior needed for mapped AC + failing tests.
    - `refactor/docs`: scope strictly to task instructions.
- Run relevant tests/commands needed to validate `definition_of_done`.
- Update selected task status (`in_progress` -> `done` or `blocked`) in `tasks.yaml`.
- If selected task is `done`, create exactly one git commit for this task cycle.
- Commit subject must be <= 50 characters.
- Commit subject must be code-focused and must not include internal framework identifiers:
  - no task IDs (for example `T-001`)
  - no AC IDs (for example `AC-001`)
  - no internal workflow labels (for example `implement-next-task`, `feature-planning`)
- If commit cannot be created, do not leave the task as `done`; set `blocked` with reason and stop.

## Required report
At the end, provide:
1. Task id + title
2. Spec/mapping preflight result
3. Files changed
4. Commands/tests run + result
5. Commit evidence (hash + subject) or blocker reason
6. Why DoD is satisfied (or blocker reason)

## Stop condition
Stop immediately after one task cycle.
