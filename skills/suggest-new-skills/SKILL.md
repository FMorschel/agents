---
name: suggest-new-skills
description: "Use when you notice that something took a long time to figure out (many retries, dead ends, a command that had to be reworked, a correction the user already gave you before) and the answer would help next time: decide whether it deserves a skill, whether that skill is global or belongs to the current project, and ask the user to confirm before creating anything. Never creates a skill on its own."
---

## Suggesting a new skill

A skill is worth suggesting when figuring something out cost real effort and the answer will be needed again. This skill says when to suggest one, where it would live, and how to ask. **You never create or edit a skill without the user's yes.**

### When to suggest

Suggest one when at least one of these happened in this task:

- You needed **several attempts** at the same thing: a command retried with different flags or quoting, a tool that failed in a way you had to work around (for example a sandbox restriction), or a dead end you backed out of.
- The user **corrected you on the same point twice**, or told you something they had already said in earlier sessions ("as I said", "again").
- You **read many files or ran many searches** to learn something about the project or the machine that a short written note would have given you at once.
- You repeated the **same multi-step procedure** you already ran earlier in this session or recall from the memory files.

Do not suggest one for: a one-off (a single project's data, a single file), something an existing skill already covers (check the skill list first; if one almost fits, propose **extending** it instead), or something that was hard only because the task itself was new, not because the environment or the procedure was awkward.

### Global or project

Apply `place-project-knowledge`:

- Would it work unchanged in any project (a shell or sandbox workaround, a tool's quirk, a commit routine)? → a **global skill**, in `~/.claude/skills/` (the `skills/` folder of the user's agents repo, which it links to).
- Does it only make sense here (this project's release steps, its test database, its log folder, its plan layout)? → a **project skill**, in that project's `.claude/skills/<name>/SKILL.md`. When it can't be used everywhere, default to the project.
- Facts about the project (where its data lives, its layers) go in `docs/`, and the project skill points to them.
- Name it with a verb first, kebab-case, matching the folder and the `name:` line (`write-dart-tests`, `restart-desktop-app`).

### How to ask

1. **Finish the user's task first.** Don't interrupt it; raise the suggestion at the end of the turn, in your closing message or the wrap-up question.
2. Keep it to one proposal per turn, in this shape:

   > Suggest a skill: `<name>` (global | project: <project>) — <when it triggers, one line>. It took me <what the struggle was, with a number: "5 retries of the same pkill", "12 greps to find the log folder">. It would say: <2–3 bullets>. Create it?

   Give a concrete before and after when you can: "next time: one command instead of 5 attempts".
3. **Wait for a clear yes.** On yes, write it (`place-project-knowledge` for placement; keep it a short procedure, not an essay), then wire it in where it must be noticed (the same skill's "propagate" step). On no, drop it and don't re-propose the same one in this session.
4. If you are a subagent, put the suggestion in your report's "Unrequested extras" section instead of asking directly.
