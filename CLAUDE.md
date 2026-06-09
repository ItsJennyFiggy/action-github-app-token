# template-composite-action

@.agents/rules/git_safety.md
@.agents/rules/dependency_management.md
@.agents/rules/subagent_orchestration.md
@.agents/rules/environment_bootstrapping.md
@.agents/rules/testing_standards.md

## Context-Triggered Workflows

Read these before acting on the topic. Do not load preemptively.

| Topic | File |
|---|---|
| Starting a task, committing, opening PRs | `.agents/workflows/git-workflow.md` |
| Setting up local environment | `.agents/workflows/bootstrap.md` |
| Auditing packages, upgrading dependencies | `.agents/skills/dependency-auditor/SKILL.md` |

## Repo-specific notes

- This is a **composite/shell** action template — no Node.js, no bundle, no lockfile.
- Action logic lives in `scripts/`; `action.yml` steps are thin shims that call them.
- Tests are **bats** (`tests/*.bats`), the Node-free analog of the TS template's vitest suite.
- CI lints with `shellcheck` (preinstalled on the runner) and runs bats + a `uses: ./`
  integration test. There is no build/bundle step.
