# Agentic AI Coding Kit (WIP)

This repository is the source code for an installable Codex kit that enforces a structured feature-delivery workflow.

## Author

- Tilmann Felgner ([GitHub @TilmannF](https://github.com/TilmannF))

## License

This project is licensed under BUSL-1.1.  
See:
- `LICENSE`
- `LICENSE-COMMERCIAL.md`

## Setup (Important)

Before starting Codex, run:

```bash
./dev install
```

This command is the official setup path for this framework. It:
- checks required tools (`codex`, `yq`, `zip`)
- creates a timestamped backup zip of existing framework files in `$CODEX_HOME`
- installs this repository's `.codex` framework files into `$CODEX_HOME` (default: `~/.codex`)

If needed, install into a custom location:

```bash
CODEX_HOME=/path/to/custom/.codex ./dev install
```

## What this project is

The kit is designed to help engineers avoid ad-hoc AI coding by using explicit artifacts and repeatable steps:

1. Intake -> `spec.yaml`
2. Planning -> `tasks.yaml`
3. Implementation -> one task cycle at a time
4. Feedback -> artifact + reconciliation loop

The expected loop is:
Intake -> Planning -> Implement Next Task -> Feedback -> repeat until accepted.

## Current status

This project is still work in progress.

Current focus:
- Tightening skill instructions for reliability and consistency
- Keeping templates minimal and implementation-oriented
- Improving install/runtime clarity for cross-project use
- Hardening the one-task-at-a-time delivery loop

## Important file responsibility split

There are two AGENTS files with different roles:
- `AGENTS.md` (repo root): governs how this repository itself is maintained
- `.codex/AGENTS.md`: runtime/global behavior that should be installed into `$CODEX_HOME/AGENTS.md`

Do not treat these as interchangeable.

## Repository structure

- `.codex/skills/feature-intake/SKILL.md`
- `.codex/skills/feature-intake/assets/spec.yaml`
- `.codex/skills/feature-planning/SKILL.md`
- `.codex/skills/feature-planning/assets/tasks.yaml`
- `.codex/skills/implement-next-task/SKILL.md`
- `.codex/skills/feature-feedback/SKILL.md`
- `.codex/contracts/spec-contract.md`
- `.codex/AGENTS.md`
- `AGENTS.md`

## Spec contract

Cross-skill schema behavior is centralized in:
- `.codex/contracts/spec-contract.md`

All workflow skills should use:
- `.codex/skills/feature-intake/assets/spec.yaml` as canonical schema template
- `.codex/skills/feature-intake/scripts/validate-spec.sh` as the validation gate

## How engineers should use this kit (today)

1. Run `./dev install` (see Setup section above).
2. In a target project, start a feature under `.work/<feature-slug>/`.
3. Run the flow using the skills:
   - `feature-intake`
   - `feature-planning`
   - `implement-next-task`
   - `feature-feedback`
4. Keep task execution incremental and evidence-based.

## Design principles

- Minimal schemas over comprehensive metadata
- Concrete instructions over vague references
- Deterministic task selection over subjective picking
- Small, reviewable changes over large batch generation

## Not the goal of this repository

- Embedding project-specific business logic
- Hardcoding framework/tool-specific implementation details
- Replacing project-level AGENTS decisions

## Contributing during WIP phase

When changing templates, skills, or docs:
- Keep changes focused and small
- Update all linked files in the same change set
- Preserve the end-to-end flow contract
- Prefer clarity and portability over extra complexity
