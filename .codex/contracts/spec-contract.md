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

## Type strictness contract
1. Fields defined as strings in `spec.yaml` must be YAML strings (not coercible non-string scalars or objects).
2. `scope.in_scope` and `scope.out_of_scope` must be non-empty string lists.

## Status lifecycle contract
1. Intake works in `feature.status: draft` during refinement.
2. After user approval, intake must set `feature.status: approved`.
3. Planning must only start from an approved spec.

## Intake artifact-first contract
1. Intake completion requires on-disk `.work/<slug>/spec.yaml`.
2. If intake ran in Plan mode and files cannot be written, intake must output `handoff required` and stop.
3. While active skill is intake, phrase "implement this plan" means persist and validate intake artifact, not production code implementation.

## Tasks contract handoff
All `tasks.yaml` schema, lifecycle, selection, and AC-mapping rules are defined in:
- `.codex/contracts/tasks-contract.md`
