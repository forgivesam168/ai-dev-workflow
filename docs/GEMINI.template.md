# Antigravity CLI Project Context

Primary project rules live in `AGENTS.md`. Apply that file as the source of truth for workflow stages, quality gates, and repo conventions.

## Runtime Notes

- Shared skills are backed by `./skills/`.
- `.agents/skills/` is the primary Antigravity CLI skill mount (also used by Codex CLI).
- `.agent/skills/` is kept as a compatibility mount for older Antigravity setups.
- If you adopt native Antigravity plugins later, treat this file plus `AGENTS.md` as the durable project context and keep plugin-specific behavior out of the shared workflow unless it is tool-agnostic.

## Skill Invocation

Antigravity CLI discovers skills from `.agents/skills/` automatically. Skills are activated based on their `description` when the task matches. No slash command is needed — describe what you want and the model selects the appropriate skill.
