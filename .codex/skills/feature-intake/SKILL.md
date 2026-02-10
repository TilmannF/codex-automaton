---
name: feature-intake
description: Interactively discover and refine requirements into a minimal, finalizable .work/<slug>/spec.yaml.
---

# Feature Intake Skill

## Purpose
Turn a feature request into a clear, minimal, implementation-ready `spec.yaml`.
This skill is requirement engineering, not implementation planning.
Every question and every summary must move the spec toward finalization.

## Primary artifact
- `.work/<slug>/spec.yaml`
- Use and preserve the schema from `assets/spec.yaml`
- Validation gate: `scripts/validate-spec.sh` (requires `yq`)

## Inputs
- Feature request from user
- Optional existing `.work/<slug>/spec.yaml`
- Optional repository context needed to phrase requirements precisely

## Non-goals
- Do not create `tasks.yaml` here.
- Do not produce implementation sequence, estimates, or delivery plans.
- Do not add speculative architecture details unless directly required by acceptance behavior.
- Do not start implementation in this skill.

## Interaction contract
- Work in short rounds.
- Ask at most 3 high-impact questions per round.
- After each round, synthesize decisions into spec-ready language.
- State assumptions explicitly and ask for confirmation.
- Prefer structured choices when the user is undecided.
- Active skill gate: if user invoked `feature-intake`, do not invoke planning or implementation skills.
- Artifact-first gate: intake is complete only when `.work/<slug>/spec.yaml` exists on disk and validation passes.
- Do not move to planning until the user confirms the intake draft and artifact-first gate is satisfied.
- If intake runs in Plan mode, do not consider intake complete until Plan mode handoff is executed and `spec.yaml` is written on disk.
- Ambiguity rule: if user says "implement this plan" during intake, interpret this as persisting and validating intake artifacts, not implementing production code.

## Internal workflow

### 1) Initialize and align
1. Propose a feature slug (kebab-case) and short title.
2. If spec exists, summarize what is already known and what is still ambiguous.
3. Confirm slug/title with the user.
4. Create or switch to feature branch:
   - Use project-level AGENTS branch convention when defined.
   - Default branch: `feat/<slug>`.
5. Ensure `.work/<slug>/` exists.
6. Create `.work/<slug>/spec.yaml` immediately if missing, using `assets/spec.yaml`:
   - set `feature.slug`, `feature.title`, `feature.branch`
   - set `feature.status` to `draft`
   - set timestamps
7. If spec already exists, normalize core fields (`slug`, `title`, `branch`) and keep `status` as `draft` until final approval.

### 2) Baseline understanding
1. Restate the request in 2-4 concise sentences.
2. Ask only high-leverage clarifications first:
   - target user or actor
   - current pain/problem
   - desired outcome
   - hard constraints from product behavior
3. Confirm shared understanding before drafting full sections.

### 3) Section-by-section refinement loops
Refine sections in this order:
1. `feature`
2. `context`
3. `scope`
4. `acceptance_criteria`

For each section, run this loop:
1. Ask 1-3 targeted questions.
2. Draft or revise section content.
3. Persist updates to `.work/<slug>/spec.yaml` after each round so the file reflects current "hard state".
4. Check for ambiguity, missing boundaries, and contradictions.
5. Ask for explicit status: `approved`, `change`, or `unsure`.
6. If `unsure` and high-impact, ask follow-up before continuing.

### 4) Acceptance criteria hardening
For each criterion:
1. Assign stable ID (`AC-001`, `AC-002`, ...).
2. Write a short behavior title.
3. Define `given`, `when`, and `then` with observable outcomes.
4. Assign realistic priority (`must`, `should`, `could`).
5. Add verification metadata aligned with project reality:
   - `type` (test/proof style)
   - `artifact` (expected path or proof location)
   - `notes` only when needed

Rules:
- Each AC must be independently testable.
- Avoid duplicate ACs with overlapping outcomes.
- Cover success path and critical failure path where behavior differs.

### 5) Scope lock
1. Ensure `in_scope` and `out_of_scope` are explicit and non-overlapping.
2. Ensure out-of-scope excludes likely follow-up asks that could derail planning.
3. Confirm boundaries with the user before final write.

### 6) Final consistency pass
Validate before saving:
1. Sections are complete and concise.
2. ACs match scope and goals.
3. No planning or task sequencing content is mixed into spec.
4. Wording is concrete enough for deterministic task generation.
5. Any remaining assumptions are explicit.
6. Run schema validation:
   - `./.codex/skills/feature-intake/scripts/validate-spec.sh .work/<slug>/spec.yaml`
   - If validation fails, resolve issues before asking for final approval.

### 7) Finalize spec
1. Write or update `.work/<slug>/spec.yaml`.
2. Ask for final spec approval from the user.
3. On approval, set `feature.status` to `approved` and refresh `updated_at`.
4. Run final gate:
   - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml`
5. If final gate fails, fix and re-validate before closing intake.
6. Provide a short readback:
   - feature slug/title
   - scope boundaries
   - final AC list
   - explicit assumptions
7. Stop after intake completion. Do not begin planning or implementation unless explicitly asked.

### 8) Plan mode handoff (mandatory when intake was run in Plan mode)
1. If current mode cannot write files, output `handoff required` and stop:
   - include branch name, slug, and target spec path
   - include exact validator command
   - explicitly state that planning/implementation must not start yet
2. Switch to an execution-capable mode that can write files.
3. Ensure branch and artifact exist on disk:
   - branch: project convention or `feat/<slug>`
   - file: `.work/<slug>/spec.yaml`
4. Persist the final approved spec content to disk.
5. Ensure `feature.status` is `approved`.
6. Run final validation on disk:
   - `./.codex/skills/feature-intake/scripts/validate-spec.sh --require-approved .work/<slug>/spec.yaml`
7. Report handoff evidence:
   - branch name
   - spec path
   - validation result
8. If handoff cannot be executed, explicitly report that intake is not completed yet and stop.

## Question design rules
- Ask decision questions, not open-ended brainstorming by default.
- Prefer tradeoff framing when useful: option A vs option B with recommendation.
- Use user language for behavior; avoid stack-specific terms unless necessary.
- Prioritize clarifications that impact implementation or testability:
  - role/permission behavior
  - failure and error behavior
  - user-visible feedback
  - backward compatibility expectations
  - performance expectations when user-impacting

## Writing rules for `spec.yaml`
- Keep content short, direct, and behavior-focused.
- Prefer observable outcomes over internal implementation details.
- Avoid passive vagueness such as "should be improved" without measurable effect.
- Use stable IDs and consistent terminology across sections.

## Output
- `.work/<slug>/spec.yaml`
- concise decision summary for the user

## Done criteria
- YAML valid
- Schema structure matches `assets/spec.yaml`
- Acceptance criteria are explicit, testable, and unambiguous
- Scope boundaries are clear enough for planning
- No delivery-plan or task-level sequencing content included
- `scripts/validate-spec.sh` passes for final `spec.yaml`
- Final approved spec has `feature.status: approved`
- Branch + artifact exist in repo (`feat/<slug>` and `.work/<slug>/spec.yaml`)
- If Plan mode was used, Plan mode handoff executed successfully and validated on-disk artifact
- Active skill gate respected (no implicit jump to planning/implementation)
- User explicitly approved final spec draft or accepted documented assumptions
