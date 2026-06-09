# Composite GitHub Action Template (template-composite-action)

The standard child template for building GitHub Actions as **composite / shell**
actions — a lightweight, Node-free alternative to
[`template-github-action`](https://github.com/ItsJennyFiggy/template-github-action) (TypeScript).

---

## 🎯 Purpose

Composite actions sequence shell steps and CLI tools without a JavaScript runtime, so they need
**no** `npm` install, TypeScript compilation, esbuild bundling, or committed `dist/`. This template
provides the structure, testing convention, CI gates, and release wiring to build small, well-tested
composite actions (CLI wrappers, credential/SSM plumbing, step sequencing).

**Use this template when** your action is mostly shell/CLI orchestration.
**Use `template-github-action` when** your action has logic-heavy behavior best expressed and
unit-tested in TypeScript.

---

## 📂 Repository Structure

```
├── .agents/                       # Shared developer rules, skills, and workflows (synced from template-base)
├── .github/
│   ├── ISSUE_TEMPLATE/            # Bug report and feature request templates
│   ├── workflows/
│   │   ├── ci.yml                 # Lint (shellcheck) + bats tests + local integration test
│   │   └── release.yml            # Release-please caller stub (see Releasing)
│   ├── dependabot.yml             # GitHub-actions dependency updates (no npm ecosystem)
│   └── pull_request_template.md
├── scripts/
│   └── greet.sh                   # Example action logic — replace with your own
├── tests/
│   └── greet.bats                 # bats unit tests for scripts/ (AAA pattern)
├── action.yml                     # Composite action metadata (using: composite)
├── release-please-config.json     # release-please config (release-type: simple)
├── .release-please-manifest.json  # release-please version manifest
├── .env.example                   # Sample local inputs (INPUT_<NAME> convention)
└── README.md
```

---

## 🧱 Authoring convention

Keep `action.yml` steps thin and put real logic in `scripts/` so it stays **lintable** (shellcheck)
and **testable** (bats):

```yaml
# action.yml
runs:
  using: 'composite'
  steps:
    - name: Greet
      id: greet
      shell: bash
      run: "${GITHUB_ACTION_PATH}/scripts/greet.sh"
      env:
        INPUT_WHO_TO_GREET: ${{ inputs.who-to-greet }}
```

Inputs are passed to scripts as `INPUT_<NAME>` environment variables. Outputs are written to
`$GITHUB_OUTPUT` (guard it so the script still runs locally and under test). See
[`scripts/greet.sh`](scripts/greet.sh).

---

## 🧪 Testing

Tests are written in [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System),
the Node-free analog of the TypeScript template's vitest suite. Structure each test Arrange-Act-Assert
and mock the runtime by pointing `GITHUB_OUTPUT` at a temp file (see
[`tests/greet.bats`](tests/greet.bats)).

```bash
# Run locally (install bats: `brew install bats-core`)
bats tests/

# Lint scripts (shellcheck is preinstalled on CI runners)
shellcheck scripts/*.sh
```

CI (`.github/workflows/ci.yml`) runs shellcheck → bats → a `uses: ./` local integration test that
asserts the action's real output. There is **no** build/bundle/coverage-diff gate (nothing to
compile). Because shell has no native coverage instrumentation, the convention is full-path bats
assertions over each script rather than a numeric coverage gate.

---

## 🚀 Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please) via the
shared reusable workflow. [`.github/workflows/release.yml`](.github/workflows/release.yml) is a thin
caller stub:

```yaml
jobs:
  release:
    uses: ItsJennyFiggy/release-workflows/.github/workflows/release.yml@v1
    with:
      release_type: simple
      update_major_tag: ${{ vars.UPDATE_MAJOR_TAG == 'true' }}
    secrets: inherit
```

Conventional-commit pushes to `main` open a release PR; merging it cuts a tag (e.g. `v1.2.3`). When
the repo's `UPDATE_MAJOR_TAG` Actions variable is `true`, the floating major tag (`v1`) is moved to
the release so consumers pinned to `@v1` track the latest patch. The OIDC role and `figgy_release`
SSM access the reusable workflow needs are provisioned per-repo via the platform Terraform
`github_repository` module.

### Consuming this template

Create a new repository **from this template** (template inheritance is applied only at creation),
then replace `action.yml`, `scripts/`, and `tests/` with your action. A repo created from this
template inherits the composite structure, CI, and release wiring out of the box.

---

## ⚖️ Licensing

Dedicated to the public domain under the **CC0 1.0 Universal** waiver. Repositories scaffolded from
this template carry no attribution requirement for the boilerplate and may be licensed however you
choose.
