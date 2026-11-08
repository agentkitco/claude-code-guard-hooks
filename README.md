# Claude Code guard hooks (free, MIT)

Three small, tested [Claude Code hooks](https://code.claude.com/docs/en/hooks) that put guard rails around what a coding agent can run. Plain bash plus `jq`, no network calls, no telemetry. From [AgentKit Co](https://agentkitco.com/).

| Hook | Event | What it does |
|---|---|---|
| `block-dangerous-bash.sh` | PreToolUse, `Bash` | Blocks recursive `rm` on `/`, `~`, `$HOME` or `..`; force push to main/master; `git reset --hard`; `git clean -f`; `curl`/`wget` piped into a shell; `chmod 777`; `mkfs` / `dd of=/dev/...`; SQL `DROP TABLE/DATABASE` |
| `protect-secrets.sh` | PreToolUse, `Read\|Edit\|Write\|Bash` | Keeps the agent out of `.env*`, SSH keys, `.pem`, `.npmrc`, `.pypirc`, `.netrc`, `~/.aws/credentials`. `.env.example`, `.env.sample` and `.env.template` stay allowed |
| `test-gate-on-stop.sh` | Stop | Opt-in: set `AGENTKIT_TEST_CMD` (for example `npm test`). If it fails, Claude is told to keep working instead of declaring done. Honors `stop_hook_active`, so it can't loop forever |

Blocked calls exit with code 2 and a one-line reason, so Claude sees why and picks a safer step.

## Install (about 2 minutes)

1. Copy `.claude/hooks/` into your project and keep the scripts executable (`chmod +x .claude/hooks/*.sh`).
2. Merge the `hooks` block from `.claude/settings.example.json` into your project's `.claude/settings.json` (or `~/.claude/settings.json` for every project).
3. Run `bash test.sh` to watch every rule fire (54 checks), then start a new Claude Code session and type `/hooks` to confirm they loaded.

Needs bash and `jq` (Linux, macOS, WSL or Git Bash).

## Honest limits

- This is a safety net, not a security boundary. The hooks read the command text the agent writes, so an obfuscated command can slip past. Keep permission rules, backups and code review.
- Patterns are deliberately short and readable. Edit them for your repo.
- Checked against the Claude Code hooks reference on 2026-11-07. Claude Code changes quickly; if a field changes, open an issue.

## Want the full setup?

- [AI Coding Agent Config Kit](https://agentkitco.com/products/agent-config-kit/): AGENTS.md, CLAUDE.md, Cursor and Copilot files for 12 stacks plus audit prompts.
- [Claude Code Subagent Pack](https://agentkitco.com/products/claude-code-subagent-pack/): ready subagents for review, tests and debugging.
- Free stack starters: [agent-config-templates](https://github.com/agentkitco/agent-config-templates) · Free skills: [agentkit-dev-skills](https://github.com/agentkitco/agentkit-dev-skills)

Not affiliated with or endorsed by Anthropic. AI-assisted, human-checked by running `test.sh`.
