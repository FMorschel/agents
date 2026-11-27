# Agents

## Git workflow

- Commits for this project may go directly on `main`. Do not create a feature branch for changes made in this repository.
- Push to `origin/main` once the commit is ready, when the user asks for it.

## Instruction files

- When adding a rule to `prompts/AGENTS.md` (the global instructions) or any other AGENTS.md, put the rule itself in the skill that covers that kind of task, and leave AGENTS.md only a one-line pointer that says when to load the skill. Write a plain rule in AGENTS.md only when no skill fits and the rule is too small to deserve one. See the `place-project-knowledge` skill.

## Agent files

- Every agent in `agents/` whose `tools:` list includes `Bash` (the `orchestrator` already loads the skill itself) must carry this line right after its first heading, or right after the frontmatter when it has no heading: "Before starting a background command or waiting on a long one, load the `spawn-subagents` skill; never end your turn with background work still running." Add it when creating such an agent or when giving an existing one `Bash`.
