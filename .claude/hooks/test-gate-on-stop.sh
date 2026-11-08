#!/usr/bin/env bash
# Stop hook. Opt-in: set AGENTKIT_TEST_CMD (e.g. "npm test" or "pytest -q").
# If tests fail, exit 2 so Claude keeps working instead of declaring done.
# Respects stop_hook_active so it cannot loop forever.
input=$(cat)
[ -z "${AGENTKIT_TEST_CMD:-}" ] && exit 0
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')
[ "$active" = "true" ] && exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if ! out=$(bash -c "$AGENTKIT_TEST_CMD" 2>&1); then
  echo "Tests are failing (\`$AGENTKIT_TEST_CMD\`). Fix them before finishing, or tell the user why you can't. Last output:" >&2
  printf '%s\n' "$out" | tail -n 25 >&2
  exit 2
fi
exit 0
