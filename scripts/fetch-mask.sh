#!/usr/bin/env bash
#
# Fetch a GitHub App's credentials from AWS SSM, register them as masked secrets,
# and expose them for the downstream create-github-app-token step.
#
# SECURITY (the whole reason this action exists): `::add-mask::` is LINE-BASED.
# Masking a multi-line PEM as a single value only hides the first (BEGIN) line and
# leaves every key-body line visible to `set -x`, step-debug, or any tool that
# echoes it. We therefore mask the client id and EACH non-empty PEM line
# individually. The token itself is never echoed by this script.
#
# Preconditions (caller's responsibility): AWS credentials already configured via
# aws-actions/configure-aws-credentials (OIDC). This script consumes ambient creds.
#
# Inputs (environment):
#   INPUT_APP         logical app slug; resolves
#                     /itsjennyfiggy/global/<app>_github_app_{client_id,private_key}
#   INPUT_AWS_REGION  AWS region (default us-west-2)
set -euo pipefail

main() {
  local app region base client_id private_key
  app="${INPUT_APP:?INPUT_APP is required (the GitHub App slug)}"
  region="${INPUT_AWS_REGION:-us-west-2}"
  base="/itsjennyfiggy/global/${app}_github_app"

  client_id="$(aws ssm get-parameter \
    --name "${base}_client_id" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${region}")"

  private_key="$(aws ssm get-parameter \
    --name "${base}_private_key" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text \
    --region "${region}")"

  # Mask the client id (single line) ...
  echo "::add-mask::${client_id}"
  # ... and EVERY line of the PEM individually (see SECURITY note above).
  while IFS= read -r line; do
    [ -n "${line}" ] && echo "::add-mask::${line}"
  done <<< "${private_key}"

  # Hand the credentials to the next step. GITHUB_OUTPUT is line-oriented; the PEM
  # is multi-line, so it must be written with a heredoc delimiter.
  {
    echo "client-id=${client_id}"
    echo "private-key<<__EOF_PEM__"
    echo "${private_key}"
    echo "__EOF_PEM__"
  } >> "${GITHUB_OUTPUT}"
}

main "$@"
