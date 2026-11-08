#!/usr/bin/env bash
# PreToolUse (matcher: Read|Edit|Write|Bash). Keeps the agent out of common secret files.
# .env.example / .env.sample / .env.template stay allowed.
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
if [ "$tool" = "Bash" ]; then
  target=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
else
  target=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')
fi
[ -z "$target" ] && exit 0
clean=$(printf '%s' "$target" | sed -E 's/\.env\.(example|sample|template)//g')
if printf '%s' "$clean" | grep -Eq '(^|[/[:space:]"'"'"'=])\.env(\.[A-Za-z0-9_-]+)?([[:space:]"'"'"';|&]|$)|id_(rsa|ed25519|ecdsa)([[:space:]"'"'"']|$)|\.pem([[:space:]"'"'"']|$)|\.npmrc|\.pypirc|\.aws/credentials|\.netrc'; then
  echo "Blocked by protect-secrets: this touches a secrets file. Use .env.example or ask the user for the value." >&2
  exit 2
fi
exit 0
