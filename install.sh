#!/usr/bin/env bash
# AgentKit Co guard hooks installer. Idempotent; backs up settings.json before any change.
# Usage: bash install.sh [--project DIR | --user] [--dry-run] [--uninstall] [--doctor]
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
TARGET="$PWD"; MODE=install; DRY=0
while [ $# -gt 0 ]; do case "$1" in
  --project) TARGET="$2"; shift 2;;
  --user) TARGET="$HOME"; shift;;
  --dry-run) DRY=1; shift;;
  --uninstall) MODE=uninstall; shift;;
  --doctor|doctor) MODE=doctor; shift;;
  -h|--help) sed -n '2,3p' "$0"; exit 0;;
  *) echo "Unknown option: $1" >&2; exit 1;;
esac; done
HOOKS=(block-dangerous-bash.sh protect-secrets.sh test-gate-on-stop.sh loop-guard.sh)
DEST="$TARGET/.claude/hooks"; SET="$TARGET/.claude/settings.json"
# When installing to ~/.claude, hook commands must not depend on the project dir.
if [ "$TARGET" = "$HOME" ]; then PREFIX="$HOME/.claude/hooks"; else PREFIX='"$CLAUDE_PROJECT_DIR"/.claude/hooks'; fi
say() { echo "$*"; }
run() { if [ $DRY -eq 1 ]; then say "[dry-run] $*"; else eval "$@"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }
block() { jq --arg p "$PREFIX" '(.hooks // {}) | map_values(map(.hooks |= map(.command |= sub("\"\\$CLAUDE_PROJECT_DIR\"/.claude/hooks"; $p))))' "$SRC/.claude/settings.example.json" | jq '{hooks: .}'; }
strip() { # remove any of our hook entries from a settings file on stdin
  jq 'if .hooks then .hooks |= (map_values(map(.hooks |= map(select((.command // "") | test("(block-dangerous-bash|protect-secrets|test-gate-on-stop|loop-guard)\\.sh") | not))) | map(select((.hooks|length) > 0))) | with_entries(select((.value|length) > 0))) else . end | if (.hooks // {}) == {} then del(.hooks) else . end'; }
doctor() {
  local ok=0 bad=0
  chk() { if eval "$2"; then say "ok   $1"; ok=$((ok+1)); else say "FAIL $1"; bad=$((bad+1)); fi; }
  chk "bash present" "command -v bash >/dev/null"
  chk "jq present" "command -v jq >/dev/null"
  for h in "${HOOKS[@]}"; do chk "$DEST/$h is executable" "[ -x '$DEST/$h' ]"; done
  chk "$SET is valid JSON" "[ -f '$SET' ] && jq empty '$SET' 2>/dev/null"
  for h in "${HOOKS[@]}"; do chk "settings.json references $h" "[ -f '$SET' ] && jq -e --arg h '$h' '[.. | .command? // empty | select(contains(\$h))] | length > 0' '$SET' >/dev/null 2>&1"; done
  chk "dangerous command is blocked" "! printf '%s' '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"rm -rf /\"}}' | '$DEST/block-dangerous-bash.sh' >/dev/null 2>&1"
  say "$ok ok, $bad failed. In Claude Code, type /hooks to confirm they loaded."
  [ $bad -eq 0 ]
}
need jq
case $MODE in
doctor) doctor;;
install)
  say "Installing guard hooks into $TARGET/.claude"
  run "mkdir -p '$DEST'"
  for h in "${HOOKS[@]}"; do run "cp '$SRC/.claude/hooks/$h' '$DEST/$h' && chmod +x '$DEST/$h'"; done
  if [ -f "$SET" ]; then jq empty "$SET" || { echo "$SET is not valid JSON; fix it first." >&2; exit 1; }; BASE=$(strip < "$SET"); else BASE='{}'; fi
  NEW=$(jq -s '.[0] as $a | .[1] as $b | $a * {hooks: (($a.hooks // {}) as $h | reduce ($b.hooks|keys[]) as $k ($h; .[$k] = ((.[$k] // []) + $b.hooks[$k])))}' <(echo "$BASE") <(block))
  if [ $DRY -eq 1 ]; then say "[dry-run] would write $SET:"; echo "$NEW"; exit 0; fi
  [ -f "$SET" ] && cp "$SET" "$SET.bak.$(date +%Y%m%d%H%M%S)" && say "Backed up existing settings.json"
  echo "$NEW" > "$SET"; say "Done."; doctor;;
uninstall)
  say "Removing guard hooks from $TARGET/.claude"
  for h in "${HOOKS[@]}"; do run "rm -f '$DEST/$h'"; done
  if [ -f "$SET" ]; then NEW=$(strip < "$SET")
    if [ $DRY -eq 1 ]; then say "[dry-run] would write $SET:"; echo "$NEW"; else cp "$SET" "$SET.bak.$(date +%Y%m%d%H%M%S)"; echo "$NEW" > "$SET"; fi; fi
  say "Done. Your other settings and hooks were left alone.";;
esac
