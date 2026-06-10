# Claude Code Project Memory

@AGENTS.md

## Claude-Specific Notes

- Shared skills are mounted at `.claude/skills/` and backed by `./skills/`.
- Generated Claude subagents live in `.claude/agents/`.
- If a Claude-only workflow ever conflicts with `AGENTS.md`, keep the project-wide rule in `AGENTS.md` and add only the minimal Claude-specific delta here.
