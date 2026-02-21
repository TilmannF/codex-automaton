---
name: feature-feedback
description: Capture user feedback into timestamped artifact and reconcile spec/tasks.
---

# Feature Feedback Skill

## Purpose
Turn feedback into durable artifacts and update plan safely.

## Contract dependency
- Read and follow:
  - `.codex/contracts/spec-contract.md`
  - `.codex/contracts/tasks-contract.md`
- Validate spec before processing feedback:
  - `./.codex/skills/feature-intake/scripts/validate-spec.sh .work/<slug>/spec.yaml`
- Validate tasks before reconciliation:
  - `./.codex/skills/feature-planning/scripts/validate-tasks.sh --spec .work/<slug>/spec.yaml .work/<slug>/tasks.yaml`
- Validate tasks after reconciliation:
  - `./.codex/skills/feature-planning/scripts/validate-tasks.sh --spec .work/<slug>/spec.yaml .work/<slug>/tasks.yaml`

## Inputs
- User feedback text
- `.work/<slug>/spec.yaml`
- `.work/<slug>/tasks.yaml`

## Steps
1. Run spec validator. If it fails, stop and surface errors.
2. Create `.work/<slug>/feedback-YYYYMMDD-HHMM.md`.
3. Summarize:
    - what is accepted
    - what must change
    - priority
4. If behavior/scope changed: update `spec.yaml`.
5. If `spec.yaml` changed, run validator again before touching tasks.
6. Run tasks validator with `--spec` before touching `tasks.yaml`. If it fails, stop and surface errors.
7. Reconcile `tasks.yaml`:
    - add new tasks
    - adjust dependencies
    - keep history stable (do not rewrite completed tasks)
    - ensure `maps_to` only references existing `acceptance_criteria[].id`
8. Run tasks validator with `--spec` after reconciliation. If it fails, stop and surface errors.
9. Identify next selectable task.

## Output
- feedback file
- updated spec/tasks as needed
