#!/usr/bin/env bash
# PreToolUse (matcher: Bash|Edit|Write). Stops the "run it again and hope" loop:
# if the agent runs the exact same Bash command AGENTKIT_LOOP_LIMIT times in a row (default 3)
# with no Edit/Write in between, the next identical run is blocked with a nudge to change approach.
# Any edit or any different command resets the count. AGENTKIT_LOOP_LIMIT=0 turns it off.
input=$(cat)
limit=${AGENTKIT_LOOP_LIMIT:-3}
[ "$limit" -gt 0 ] 2>/dev/null || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // "default"' | tr -c 'A-Za-z0-9_-' '_')
dir="${TMPDIR:-/tmp}/agentkit-loop-guard"; mkdir -p "$dir" 2>/dev/null || exit 0
state="$dir/$sid"
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool" != "Bash" ]; then : > "$state"; exit 0; fi
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0
key=$(printf '%s' "$cmd" | cksum | cut -d' ' -f1)
last=$(head -n1 "$state" 2>/dev/null); count=$(sed -n 2p "$state" 2>/dev/null)
if [ "$last" = "$key" ]; then count=$(( ${count:-0} + 1 )); else count=1; fi
if [ "$count" -gt "$limit" ]; then
  echo "Blocked by loop-guard: you've run this exact command $limit times in a row without changing any files. Read the last error, change something (code, flags or approach), or ask the user." >&2
  exit 2
fi
printf '%s\n%s\n' "$key" "$count" > "$state"
exit 0
