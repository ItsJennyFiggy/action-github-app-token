#!/usr/bin/env bash
#
# Sample composite-action logic.
#
# Convention: a composite action's `action.yml` step should be a thin shim that
# calls a script in this directory. Keeping the logic in a standalone script
# (rather than inline `run:` YAML) makes it unit-testable with bats and lintable
# with shellcheck — the Node-free analog of the TypeScript template's src/ +
# vitest setup. Replace this with your action's real logic.
#
set -euo pipefail

main() {
  local who="${INPUT_WHO_TO_GREET:-World}"
  local greeting="Hello, ${who}!"

  echo "${greeting}"

  # Expose the result as a step output when running inside GitHub Actions.
  # GITHUB_OUTPUT is unset when running locally / under test, so guard it.
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "greeting=${greeting}" >> "${GITHUB_OUTPUT}"
  fi
}

main "$@"
