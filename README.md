# Claude Code guard hooks (free, MIT)

Four small, tested [Claude Code hooks](https://code.claude.com/docs/en/hooks) that put guard rails around what a coding agent can run. Plain bash plus `jq`, no network calls, no telemetry. From [AgentKit Co](https://agentkitco.com/).

| Hook | Event | What it does |
|---|---|---|
| `block-dangerous-bash.sh` | PreToolUse, `Bash` | Blocks recursive `rm` on `/`, `~`, `$HOME` or `..`; force push to main/master; `git reset --hard`; `git clean -f`; `curl`/`wget` piped into a shell; `chmod 777`; `mkfs` / `dd of=/dev/...`; SQL `DROP TABLE/DATABASE` |
| `protect-secrets.sh` | PreToolUse, `Read\|Edit\|Write\|Bash` | Keeps the agent out of `.env*`, SSH keys, `.pem`, `.npmrc`, `.pypirc`, `.netrc`, `~/.aws/credentials`. `.env.example`, `.env.sample` and `.env.template` stay allowed |
| `test-gate-on-stop.sh` | Stop | Opt-in: set `AGENTKIT_TEST_CMD` (for example `npm test`). If it fails, Claude is told to keep working instead of declaring done. Honors `stop_hook_active`, so it can't loop forever |
| `loop-guard.sh` | PreToolUse, `Bash\|Edit\|Write` | Stops the retry loop: after the exact same Bash command runs 3 times in a row with no file edit in between, the next identical run is blocked with a nudge to read the error and change approach. Any edit or different command resets it. Tune with `AGENTKIT_LOOP_LIMIT` (`0` turns it off). State lives in a small temp file per session |

Blocked calls exit with code 2 and a one-line reason, so Claude sees why and picks a safer step.

## Install (about 2 minutes)

```bash
git clone https://github.com/agentkitco/claude-code-guard-hooks && cd claude-code-guard-hooks
bash install.sh --project /path/to/your/repo --dry-run   # preview, writes nothing
bash install.sh --project /path/to/your/repo             # or --user for ~/.claude
```

The installer copies the four hooks, merges them into `.claude/settings.json` without touching your other settings or hooks, backs up the old file first, and is safe to run twice. Then it runs a doctor check.

- `bash install.sh --project DIR --doctor` re-checks dependencies, file permissions, the settings entries and one live block.
- `bash install.sh --project DIR --uninstall` removes only these hooks.
- Prefer doing it by hand? Copy `.claude/hooks/` and merge the `hooks` block from `.claude/settings.example.json`.

Run `bash test.sh` to watch every rule fire plus the installer round-trip (68 checks), then start a new Claude Code session and type `/hooks` to confirm they loaded.

Needs bash and `jq` (Linux, macOS, WSL or Git Bash).

## Honest limits

- This is a safety net, not a security boundary. The hooks read the command text the agent writes, so an obfuscated command can slip past. Keep permission rules, backups and code review.
- `loop-guard` matches commands exactly, so a tiny change (an extra flag) counts as a new attempt. It is a nudge against blind retries, not a budget cap.
- Patterns are deliberately short and readable. Edit them for your repo.
- Checked against the Claude Code hooks reference on 2026-11-07. Claude Code changes quickly; if a field changes, open an issue.

## Want the full setup?

- [AI Coding Agent Config Kit](https://agentkitco.com/products/agent-config-kit/): AGENTS.md, CLAUDE.md, Cursor and Copilot files for 12 stacks plus audit prompts.
- [Claude Code Subagent Pack](https://agentkitco.com/products/claude-code-subagent-pack/): ready subagents for review, tests and debugging.
- Free stack starters: [agent-config-templates](https://github.com/agentkitco/agent-config-templates) · Free skills: [agentkit-dev-skills](https://github.com/agentkitco/agentkit-dev-skills)

Not affiliated with or endorsed by Anthropic. AI-assisted, human-checked by running `test.sh` (last run 2026-11-10).
