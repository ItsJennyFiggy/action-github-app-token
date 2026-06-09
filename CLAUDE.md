# action-github-app-token

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

- **Composite/shell** action — no Node.js, bundle, or lockfile.
- **Security core:** `scripts/fetch-mask.sh` fetches the App's SSM credentials and masks the PEM
  **line-by-line** (`::add-mask::` is line-based — masking a whole multi-line PEM only hides the
  first line). The minted token is never echoed.
- Tested with **bats** (`tests/fetch-mask.bats`) with the `aws` CLI mocked on `PATH` — no
  network/SSM in unit tests. The suite regresses the masking incident directly.
- **No live token-mint integration test** by design (it would hit real SSM and mint a real token).
- **Precondition:** the caller must run `aws-actions/configure-aws-credentials` (OIDC) before this
  action; it consumes ambient AWS credentials.
