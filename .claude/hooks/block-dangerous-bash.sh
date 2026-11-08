#!/usr/bin/env bash
# PreToolUse (matcher: Bash). Blocks a short list of destructive shell commands.
# Exit 2 = block; the stderr reason is shown to Claude so it can pick a safer step.
# This is a safety net, not a sandbox: it only reads the command text.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

block() { echo "Blocked by block-dangerous-bash: $1. Ask the user or choose a safer command." >&2; exit 2; }

# rm -rf aimed at /, ~, $HOME, or ..  (any flag order: -rf, -fr, -r -f)
if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*|-[a-zA-Z]+[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+)(/|~|\$HOME|\.\.)([[:space:]/*]|$)'; then
  block "recursive rm on /, ~, \$HOME or .."
fi
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([^;&|]*)[[:space:]](-f|--force)([[:space:]]|$)' && \
  printf '%s' "$cmd" | grep -Eq '(main|master)' && block "force push to main/master"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset[[:space:]]+--hard' && block "git reset --hard discards work"
printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' && block "git clean -f deletes untracked files"
printf '%s' "$cmd" | grep -Eq '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([[:space:]]|$)' && block "piping a download into a shell"
printf '%s' "$cmd" | grep -Eq 'chmod[[:space:]]+(-R[[:space:]]+)?777' && block "chmod 777"
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])(mkfs(\.[a-z0-9]+)?|dd[[:space:]]+[^;&|]*of=/dev/)' && block "formatting or overwriting a disk"
printf '%s' "$cmd" | grep -Eiq 'drop[[:space:]]+(table|database)' && block "SQL DROP TABLE/DATABASE"
exit 0
