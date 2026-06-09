#!/usr/bin/env bats
#
# Tests for scripts/fetch-mask.sh — the security core of action-github-app-token.
# These regress the masking incident: a multi-line PEM passed to a single
# `::add-mask::` only masks the first (BEGIN) line, leaving the key body exposed.
# We mock the `aws` CLI on PATH so no network/SSM is touched (unit-isolated).

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../scripts/fetch-mask.sh"
  export GITHUB_OUTPUT="${BATS_TEST_TMPDIR}/gh_output"
  : > "${GITHUB_OUTPUT}"

  # Arrange: a fake `aws` that returns fixture SSM values by parameter name.
  MOCKBIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "${MOCKBIN}"
  cat > "${MOCKBIN}/aws" <<'MOCK'
#!/usr/bin/env bash
name=""; prev=""
for arg in "$@"; do
  [ "$prev" = "--name" ] && name="$arg"
  prev="$arg"
done
case "$name" in
  *_client_id)   printf 'Iv23testclientid\n' ;;
  *_private_key) printf -- '-----BEGIN PRIVATE KEY-----\nLINE1abc\nLINE2def\nLINE3ghi\n-----END PRIVATE KEY-----\n' ;;
  *) echo "unexpected SSM parameter: $name" >&2; exit 1 ;;
esac
MOCK
  chmod +x "${MOCKBIN}/aws"
  export PATH="${MOCKBIN}:${PATH}"
  export INPUT_APP="figgy_release"
}

@test "masks the client id" {
  run bash "${SCRIPT}"
  [ "${status}" -eq 0 ]
  echo "${output}" | grep -qx '::add-mask::Iv23testclientid'
}

@test "masks EVERY private-key line, not just the BEGIN line" {
  run bash "${SCRIPT}"
  [ "${status}" -eq 0 ]
  echo "${output}" | grep -qx '::add-mask::-----BEGIN PRIVATE KEY-----'
  echo "${output}" | grep -qx '::add-mask::LINE1abc'
  echo "${output}" | grep -qx '::add-mask::LINE2def'
  echo "${output}" | grep -qx '::add-mask::LINE3ghi'
  echo "${output}" | grep -qx '::add-mask::-----END PRIVATE KEY-----'
}

@test "emits exactly one mask per non-empty line (regression: line-based masking)" {
  run bash "${SCRIPT}"
  [ "${status}" -eq 0 ]
  # 1 client-id + 5 PEM lines = 6 distinct ::add-mask:: directives.
  count="$(printf '%s\n' "${output}" | grep -c '^::add-mask::')"
  [ "${count}" -eq 6 ]
}

@test "writes client-id and the full private-key heredoc to GITHUB_OUTPUT" {
  run bash "${SCRIPT}"
  [ "${status}" -eq 0 ]
  grep -qx 'client-id=Iv23testclientid' "${GITHUB_OUTPUT}"
  grep -q  'private-key<<' "${GITHUB_OUTPUT}"
  grep -qx '-----BEGIN PRIVATE KEY-----' "${GITHUB_OUTPUT}"
  grep -qx '-----END PRIVATE KEY-----' "${GITHUB_OUTPUT}"
}

@test "fails fast when INPUT_APP is unset" {
  unset INPUT_APP
  run bash "${SCRIPT}"
  [ "${status}" -ne 0 ]
}
