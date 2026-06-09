# action-github-app-token

A reusable **composite** GitHub Action that mints a short-lived, repo-scoped GitHub App
installation token from credentials stored in AWS SSM — with **correct, line-by-line PEM masking**.

It centralizes the `SSM fetch → mask → mint` sequence that was previously hand-rolled (and subtly
broken) across many workflows, so the security-critical masking lives in exactly one reviewed,
tested place.

---

## 🔐 Why this exists

`echo "::add-mask::$KEY"` is **line-based**. A GitHub App private key is a multi-line PEM, so masking
the whole value as one string only hides the first line (`-----BEGIN PRIVATE KEY-----`, constant
boilerplate) and leaves **every key-body line visible** in run logs under `set -x`, step-debug
(`ACTIONS_STEP_DEBUG`), or any tool that echoes it. This action masks the client id and **each PEM
line individually**, then mints the token via `actions/create-github-app-token`. The token is exposed
as an output and is **never echoed**.

---

## 🚀 Usage

The caller runs OIDC first (this action consumes ambient AWS credentials):

```yaml
permissions:
  id-token: write   # for OIDC
  contents: read

steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v6
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      aws-region: us-west-2

  - name: Mint GitHub App token
    id: app-token
    uses: ItsJennyFiggy/action-github-app-token@v1
    with:
      app: figgy_release            # resolves the SSM credential paths
      # repositories: repo-a,repo-b # optional; requires `owner`. Omit to scope to this repo.

  - name: Use the token
    env:
      GH_TOKEN: ${{ steps.app-token.outputs.token }}
    run: gh pr list
```

### Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `app` | yes | — | App slug → `/itsjennyfiggy/global/<app>_github_app_{client_id,private_key}`. |
| `repositories` | no | `''` | Comma/newline repo list to scope the token. Requires `owner` when set. Empty (with empty `owner`) → **current repo only**. |
| `owner` | no | `''` | Owner/org for the installation. Empty → current repository. |
| `aws-region` | no | `us-west-2` | AWS region for SSM reads. |

### Outputs

| Output | Description |
|---|---|
| `token` | Installation access token (masked; never logged). |
| `client-id` | App client id (masked). |

### Precondition

The caller **must** configure AWS credentials (OIDC via
`aws-actions/configure-aws-credentials`) before this step. OIDC is intentionally kept separate — some
workflows need AWS creds without a GitHub token.

---

## 🧪 Testing

`scripts/fetch-mask.sh` holds the security logic and is unit-tested with **bats**
(`tests/fetch-mask.bats`), mocking the `aws` CLI on `PATH` so no network/SSM is touched. The suite
regresses the masking bug directly: it asserts every PEM body line — not just the BEGIN line — is
emitted as its own `::add-mask::`, and that the key is written to `$GITHUB_OUTPUT` only via a heredoc.
CI runs shellcheck + bats; there is no live token-mint integration test by design (it would hit real
SSM and mint a real token).

---

## ⚖️ Licensing

Dedicated to the public domain under **CC0 1.0 Universal**.
