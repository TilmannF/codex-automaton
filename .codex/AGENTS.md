# Global Delivery Flow

You follow this workflow for feature work in every repository unless a project-level AGENTS file overrides it.

## Core principles
- Work in a feature branch: `feat/<feature-slug>`.
- Store all feature artifacts in `.work/<feature-slug>/`.
- Do not implement multiple tasks at once when `tasks.yaml` has more than one open task.
- Prefer incremental, test-driven execution (`test_red` -> `implementation`).

## Skill and phase gates
- Active skill gate: if the user explicitly names a skill (for example `$feature-intake`), execute only that skill.
- Phase transition gate: do not move to another phase/skill unless the user explicitly requests that transition.
- Artifact-first gate: do not proceed to a later phase until required artifacts from the current phase exist on disk and pass required validation.
- Ambiguity rule: if active skill is intake and user says "implement this plan", interpret this as implementing intake artifacts (`.work/<slug>/spec.yaml` + validation), not production code implementation.
- Ambiguity rule: if active skill is planning and user says "implement this plan", interpret this as implementing planning artifacts (`.work/<slug>/tasks.yaml` + planning checks), not production code implementation.
- Conflict rule: if user wording conflicts with active-skill scope, ask one direct clarification question before changing phase.

## Required artifacts
- `.work/<feature-slug>/spec.yaml`
- `.work/<feature-slug>/tasks.yaml`
- `.work/<feature-slug>/feedback-YYYYMMDD-HHMM.md` (for each feedback round)

## Phase behavior

### Intake
- Create or update `spec.yaml` from user intent.
- Keep spec concise and behavior-focused.
- Do not generate implementation details in spec beyond acceptance criteria.

### Planning
- Create or update `tasks.yaml`.
- Each acceptance criterion should map to concrete tasks.
- If feasible, model tasks as red/green pairs:
    - `test_red`: create a failing test first
    - `implementation`: implement to make that test pass
- Ensure dependencies are explicit.

### Implementation
- Execute only the next task selected by `tasks.yaml` execution rules.
- If selected task is `test_red`, do not implement production fixes in the same step.
- If selected task is `implementation`, satisfy only mapped failing tests and required behavior.
- Update task status after execution.
- For each successfully completed task cycle, create one git commit.
- Commit subject must be <= 50 characters and describe code change only.
- Do not include internal framework identifiers in commit subjects (task IDs, AC IDs, skill names).
- Stop after one task cycle and report summary + changed files + test results.

### Feedback
- Convert user feedback into `feedback-YYYYMMDD-HHMM.md`.
- If feedback changes behavior/scope, update `spec.yaml`.
- Reconcile `tasks.yaml` (add/update/reorder tasks), then continue with next-task execution.

## Next-task selection
- Use the first `todo` task whose `depends_on` are all `done`.
- If no task is selectable, report blockers and stop.
- Never silently skip blocked tasks.

## Quality gate
- A task is `done` only when all `definition_of_done` entries are objectively satisfied.
- Never weaken tests to pass.
