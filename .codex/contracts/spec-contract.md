# Spec Contract

This document defines the canonical `spec.yaml` contract for all workflow skills.

## Canonical sources
- Schema template: `.codex/skills/feature-intake/assets/spec.yaml`
- Validator script: `.codex/skills/feature-intake/scripts/validate-spec.sh`

## Phase and skill gate contract
1. If user explicitly names a skill, execute only that skill.
2. Phase transitions require explicit user request.
3. Do not implicitly jump intake -> planning -> implementation.

## Required validation command
```bash
./.codex/skills/feature-intake/scripts/validate-spec.sh .work/<slug>/spec.yaml
```

For planning preflight:
```bash
./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml
```

## Required behavior across skills
1. Ensure required artifact exists on disk before consuming it.
2. Validate `spec.yaml` before consuming it.
3. If a skill edits `spec.yaml`, re-run validation before proceeding.
4. If artifact is missing or validation fails, stop and surface errors; do not continue silently.

## Status lifecycle contract
1. Intake works in `feature.status: draft` during refinement.
2. After user approval, intake must set `feature.status: approved`.
3. Planning must only start from an approved spec.

## Intake artifact-first contract
1. Intake completion requires on-disk `.work/<slug>/spec.yaml`.
2. If intake ran in Plan mode and files cannot be written, intake must output `handoff required` and stop.
3. While active skill is intake, phrase "implement this plan" means persist and validate intake artifact, not production code implementation.

## Planning artifact-first contract
1. Planning completion requires on-disk `.work/<slug>/tasks.yaml`.
2. If planning ran in Plan mode and files cannot be written, planning must output `handoff required` and stop.
3. While active skill is planning, phrase "implement this plan" means persist and validate planning artifacts, not production code implementation.

## AC ID mapping contract
1. Source AC IDs come from `.work/<slug>/spec.yaml` at `acceptance_criteria[].id`.
2. `tasks.yaml` entries in `tasks[].maps_to[]` must reference existing AC IDs.
3. If a referenced AC ID is missing, task generation/execution must stop and report a blocker.
