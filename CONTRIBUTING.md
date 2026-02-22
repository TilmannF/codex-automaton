# Contributing to Codex Automaton

Thanks for helping improve the project.

## Communication
- Be kind, direct, and constructive. Assume positive intent.
- Prefer friendly wording in issues, PRs, and reviews.
- Positive emoji use is encouraged where it helps tone and clarity.
- Guidance reference: [GitLab communication handbook](https://handbook.gitlab.com/handbook/communication/).

## I Have a Question
- Check `README.md` and `AGENTS.md` first.
- Search existing [issues](https://github.com/TilmannF/codex-automaton/issues).
- If still unclear, open a new [issue](https://github.com/TilmannF/codex-automaton/issues/new) with context and your goal.

## Reporting Bugs
- Open a [bug report](https://github.com/TilmannF/codex-automaton/issues/new).
- Include reproduction steps, expected behavior, actual behavior, and environment details.
- If possible, include a minimal example.

## Suggesting Enhancements
- Open a [feature request](https://github.com/TilmannF/codex-automaton/issues/new).
- Explain the problem, proposed change, and expected impact.
- Link related issues or prior discussions when relevant.

## Code Contributions
- Scope for this repo: skills, templates, validators, contracts, and docs.
- Keep changes focused and reviewable.
- Use branch names as `<type>/<three-word-slug>` (for example `feat/tasks-validator-gate`).
- If behavior changes, update matching contracts/docs in the same PR.

Consistency expectations:
- `feature-intake` <-> `assets/spec.yaml` <-> `scripts/validate-spec.sh` <-> `spec-contract.md`
- `feature-planning` <-> `assets/tasks.yaml` <-> `scripts/validate-tasks.sh` <-> `tasks-contract.md`
- `README.md` reflects actual repository behavior

## Validation Before PR
Run relevant checks locally:
- `./.codex/skills/feature-intake/scripts/validate-spec.sh .codex/skills/feature-intake/assets/spec.yaml`
- `./.codex/skills/feature-planning/scripts/validate-tasks.sh --spec .codex/skills/feature-intake/assets/spec.yaml .codex/skills/feature-planning/assets/tasks.yaml`

For helper scripts:
- keep exit codes stable (`0` pass, `1` validation fail, `2` usage/tool/file/parse error)
- treat artifact inputs as untrusted (`no eval`, no unsafe interpolation)
- keep Bash `3.2` compatibility

## Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
- `feat: add tasks validator gate`
- `fix: prevent sparse array lookup crash`
- `docs: clarify feedback validation order`

Guidelines:
- one logical change per commit
- subject in imperative mood
- keep commit subject concise

## Pull Requests
- Describe intent and high-level changes.
- Include validation/test evidence.
- Call out tradeoffs or known follow-ups.

## Security
- Do not report vulnerabilities in public issues.
- Use GitHub Security Advisories for responsible disclosure.
