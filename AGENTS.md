# AGENTS.md — Repository Instructions for the Agentic AI Coding Kit

## Purpose of this repository
This repository is the **source of truth** for an installable Agentic AI Coding Kit.
It contains reusable assets (skills, templates, docs) that are installed into a device-level Codex directory.

Important:
- This file governs work **inside this repository**.
- This file is **not** the runtime AGENTS file used by Codex after installation.
- The runtime/system-wide AGENTS file lives in the installed device path (e.g. `~/.codex/AGENTS.md`).

## Repository intent
The kit exists to enable structured, repeatable AI-assisted delivery:
1. Intake -> `spec.yaml`
2. Planning -> `tasks.yaml`
3. Implementation -> one task at a time
4. Feedback -> artifact + replanning loop

This repository defines and evolves that framework.

## Current repository structure (authoritative)
- `.codex/skills/feature-intake/SKILL.md`
- `.codex/skills/feature-intake/assets/spec.yaml`
- `.codex/skills/feature-intake/scripts/validate-spec.sh`
- `.codex/skills/feature-planning/SKILL.md`
- `.codex/skills/feature-planning/assets/tasks.yaml`
- `.codex/skills/feature-planning/scripts/validate-tasks.sh`
- `.codex/skills/implement-next-task/SKILL.md`
- `.codex/skills/feature-feedback/SKILL.md`
- `.codex/contracts/spec-contract.md`
- `.codex/contracts/tasks-contract.md`
- `.codex/AGENTS.md` (runtime/system-wide file to be installed on device)
- `README.md`

## Scope boundaries
### In scope
- Maintaining skill behavior and wording
- Maintaining schema templates (`spec.yaml`, `tasks.yaml`)
- Keeping README installation/usage docs accurate
- Improving clarity and reliability of the framework

### Out of scope
- Project-specific business logic
- Project-specific tech constraints/commands
- App feature implementation unrelated to the kit itself

## Rules for modifying this repository
1. Keep templates minimal; add fields only when necessary for reliable agent execution.
2. Keep skill instructions concrete and actionable.
3. Preserve naming consistency:
    - `spec.yaml`
    - `tasks.yaml`
    - `implement-next-task`
4. If changing template fields, update all affected skills and docs in the same change.
5. Do not silently introduce project-specific assumptions into generic templates.
6. Prefer small, focused commits and reviewable diffs.
7. Use Conventional Commits for commit subjects.
8. Keep each commit atomic and code-focused; include docs/contracts updates in the same change when behavior changes.
9. Run relevant validators/tests before committing; do not weaken checks to pass.

## Helper script quality gates
1. Validation helper scripts must use stable exits: `0` pass, `1` validation fail, `2` usage/tool/file/parse error.
2. Treat artifact input as untrusted: no `eval`; no unescaped query interpolation.
3. Keep Bash `3.2` compatibility and avoid sparse-array failures under `set -u`.
4. Enforce real YAML types for string/string-list fields (no scalar coercion).
5. If helper script behavior changes, update contracts and README in the same change.

## Consistency contract
Any change touching one of these must check the others:
- `feature-intake` <-> `assets/spec.yaml`
- `feature-intake` <-> `scripts/validate-spec.sh`
- `feature-planning` <-> `assets/tasks.yaml`
- `feature-planning` <-> `scripts/validate-tasks.sh`
- `implement-next-task` <-> task status/type/dependency conventions
- `spec-contract.md` <-> `feature-intake` spec validation/status rules
- `tasks-contract.md` <-> planning/implementation/feedback task rules
- `README.md` <-> actual repository layout and install flow

## Definition of done for repository changes
A change is done when:
- YAML templates are valid,
- skills are aligned with current templates,
- README matches real behavior and structure,
- the end-to-end framework flow remains coherent:
  Intake -> Planning -> Implement Next Task -> Feedback.

## Guidance for agents
- Treat this repo as a framework product.
- Optimize for maintainability and portability.
- When unsure, preserve minimal structure and improve clarity rather than adding complexity.
