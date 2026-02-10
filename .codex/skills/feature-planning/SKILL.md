---
name: feature-planning
description: Generate or update .work/<slug>/tasks.yaml from spec.yaml with actionable, test-driven tasks.
---

# Feature Planning Skill

## Purpose
Create a minimal `tasks.yaml` that can drive implement-next-task loops.

## Interaction contract
- Active skill gate: if user invoked `feature-planning`, do not invoke `implement-next-task` unless user explicitly requests implementation.
- Artifact-first gate: planning is complete only when `.work/<slug>/tasks.yaml` exists on disk and planning checks pass.
- If planning runs in Plan mode, do not consider planning complete until Plan mode handoff is executed and `tasks.yaml` is written on disk.
- Ambiguity rule: if user says "implement this plan" during planning, interpret this as persisting and validating planning artifacts, not implementing production code.

## Phase preconditions
- Run only when user explicitly requests planning or invokes `feature-planning`.
- Require on-disk approved intake artifact:
  - `.work/<slug>/spec.yaml` exists
  - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml` passes
- If preconditions fail, stop and report blockers; do not generate `tasks.yaml`.

## Contract dependency
- Read and follow `.codex/contracts/spec-contract.md`.
- Validate approved spec before planning:
  - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml`

## Inputs
- `.work/<slug>/spec.yaml`
- Optional existing `.work/<slug>/tasks.yaml`

## Steps
1. Verify `.work/<slug>/spec.yaml` exists on disk.
2. Run spec validator with `--require-approved`. If it fails, stop and surface errors.
3. Read acceptance criteria from spec.
4. Create tasks with concrete instructions (not references only).
5. Prefer red/green pairs per AC:
    - `test_red` task first
    - `implementation` task second
6. Add explicit dependencies.
7. Fill `definition_of_done` with objective checks.
8. Ensure each `maps_to` entry references an existing `acceptance_criteria[].id`.
9. Add `execution` block for deterministic selection.
10. Persist `.work/<slug>/tasks.yaml` on disk.
11. Verify planning consistency on disk:
   - `tasks` is non-empty
   - at least one selectable `todo` task exists or blockers are explicit
   - all `maps_to` values reference existing AC IDs from spec

## Plan mode handoff (mandatory when planning was run in Plan mode)
1. If current mode cannot write files, output `handoff required` and stop:
   - include slug and target tasks path
   - include requirement that implementation must not start yet
2. Switch to an execution-capable mode that can write files.
3. Persist the finalized `.work/<slug>/tasks.yaml` on disk.
4. Re-run planning consistency checks on disk.
5. Report handoff evidence:
   - tasks path
   - planning consistency result
6. If handoff cannot be executed, explicitly report that planning is not completed yet and stop.

## Output
- `.work/<slug>/tasks.yaml`

## Done criteria
- Spec validator passed with `--require-approved` before planning
- Every task has actionable `instructions`
- Every task `maps_to` references existing AC IDs from spec
- Dependencies are coherent
- At least one selectable `todo` task exists (or blockers are explicit)
- No implicit transition to implementation in the same step unless user explicitly requested it
- If Plan mode was used, Plan mode handoff executed successfully and validated on-disk `tasks.yaml`
- Active skill gate respected (no implicit jump to implementation)
