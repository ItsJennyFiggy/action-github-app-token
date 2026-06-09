#!/usr/bin/env bats
#
# Unit tests for scripts/greet.sh — the Node-free analog of the TypeScript
# template's __tests__/main.test.ts (vitest). Each test follows Arrange-Act-Assert
# and mocks the GitHub Actions runtime by pointing GITHUB_OUTPUT at a temp file.

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../scripts/greet.sh"
  export GITHUB_OUTPUT="${BATS_TEST_TMPDIR}/github_output"
  : > "${GITHUB_OUTPUT}"
}

@test "greets the provided name" {
  # Arrange
  export INPUT_WHO_TO_GREET="Jenny"
  # Act
  run bash "${SCRIPT}"
  # Assert
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, Jenny!" ]
}

@test "defaults to World when no name is given" {
  # Arrange
  unset INPUT_WHO_TO_GREET
  # Act
  run bash "${SCRIPT}"
  # Assert
  [ "${status}" -eq 0 ]
  [ "${output}" = "Hello, World!" ]
}

@test "writes the greeting to GITHUB_OUTPUT" {
  # Arrange
  export INPUT_WHO_TO_GREET="Jenny"
  # Act
  run bash "${SCRIPT}"
  # Assert
  [ "${status}" -eq 0 ]
  grep -qx 'greeting=Hello, Jenny!' "${GITHUB_OUTPUT}"
}
