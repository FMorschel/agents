---
name: write-skills
description: Use when creating, renaming or reviewing a skill in this repository, including frontmatter, trigger descriptions, content, references and general vs. specific scope. Also covers testing a skill's triggers with `claude plugin eval`.
---

## Writing and maintaining skills

### Before writing

1. Use `place-project-knowledge` to decide whether the content belongs in a skill, in the project's documentation or in a spec.
2. Read neighboring skills and reuse their procedures and references instead of copying existing rules.
3. Decide whether the skill is general, project, team or environment specific. Separate reusable knowledge from specific details, and declare the scope in the metadata when that prevents use outside its context.

### Identity and triggers

- Create a folder `skills/<name>/` containing `SKILL.md`; the folder name must equal `name` in the frontmatter.
- Use kebab-case names that start with a bare imperative verb (`write-dart-tests`, `compose-commits`). Prefer the verb that describes the action; use an action noun only when there is no natural verb. The full naming rules are in `place-project-knowledge`.
- Write a `description` that says when to load the skill, which tasks and signals trigger it and which important limits apply. Do not use the description as a long summary of the content. Say when a neighboring skill is the right one instead.
- Before renaming an existing skill, find and update every reference to the name and path (skills, `agents/`, `prompts/`, README, AGENTS.md; see "After you change a rule, name or path" in `place-project-knowledge`).
- A new skill only takes effect where something points to it: wire it into the agents, skills and AGENTS.md lines that cover the same kind of task.

### Metadata

The frontmatter requires `name` and `description`. It may also carry a `metadata:` block declaring the skill's context. Keys in use:

- `scope`: `general`, `environment`, `project` or `team`.
- `project`, `team`, `system`, `language`, `framework`: the specific context, when `scope` is not `general` (for example `language: Dart`, `framework: Flutter`).
- `type: reference`: a lookup skill, loaded on demand, not a procedure.

Use only keys that already exist, unless there is a clear need. When creating a skill, declare `scope` whenever it depends on a project, team or environment.

### Content

- Write an actionable procedure: preconditions, steps, decisions, safety limits, validation and expected result, as the task requires.
- Keep general rules in the general skill and details of a language, framework, project or environment in specific skills. The specific one complements or replaces the general one only within its declared scope.
- Point to the canonical source instead of duplicating rules. Put long material, or material consulted only for some tasks, in reference files and load it on demand.
- Prefer concise, verifiable instructions; distinguish mandatory requirements from examples and recommendations. Include tool details only when needed to carry out the task, and keep them aligned with the tools available.
- Never include credentials, personal data or project facts in a general skill.

### Review

Before finishing:

- check that `name` matches the folder and follows the naming rule;
- check that the description triggers the skill for the right requests, without needlessly overlapping neighboring skills;
- check relative links, skill names and cited paths;
- look for duplicated content, contradictory instructions and specific details in the wrong place;
- follow the repository's explicit conventions first and keep the requested scope.

### Testing triggers with `claude plugin eval`

To know whether a skill is actually triggered by the right requests (and not by the wrong ones), use `claude plugin eval` if the author has the Claude CLI installed and available; otherwise skip this step. It runs each case in an isolated `claude -p` session with only the plugin loaded, repeats it (`runs`, default 3) and scores it.

- **Target.** `claude plugin eval` needs a plugin root (a folder with `.claude-plugin/plugin.json`). If this repository does not have one at its root, build a temporary folder outside the repository with `.claude-plugin/plugin.json` (`{"name":"...","version":"0.0.0"}`) and a copy of `skills/`, and recopy the skills before each measurement. Keep the cases in that folder, not in the repository, unless the owner decides otherwise.
- **One case per request**, in `<evals-folder>/<name>/`: a `prompt.md` with the frontmatter `max_turns: 4`, `allowed_tools: [Read, Glob, Grep, Skill]` and `runs: 2`, and the request in the body; and one grader per skill in `graders/*.md`:
  ```
  type: tool_used
  tool: Skill
  input_match: '"skill"\s*:\s*"(?:[\w-]+:)?<skill-name>"'
  min: 1
  ```
- **Negative case:** the same grader with `min: 0` and `max: 0`. `max: 0` alone always fails, because the default `min` is 1. Use it with a request meant for the neighboring skill, to prove the description does not overlap.
- **Write the request the way the user would, and mention a file or the project** (for example `in lib/total.dart...`). A loose task request with no file makes the agent go straight to work without loading skills, and the case fails through no fault of the description. Questions about rules ("what care should I take when...") trigger skills more easily than tasks.
- **Run** `claude plugin eval <folder> --eval-dir <evals-folder> --ablation none --no-publish --trust-plugin -j 4 --threshold 0 --max-cost-usd <limit> --json <file>` (target before the flags). Without `--ablation none`, the `tool_used: Skill` grader becomes only an indicator and does not count toward the score. The JSON shows, per case and grader, how many runs passed.
- **Check for errors before reading the score.** A run that failed on a usage limit (`"error": "...limit..."`) shows up as a failed grader. If there are errors, the result is not valid; run again later.
- Each execution is a real session (roughly US$ 0.15 to 0.20 per run) and spends tokens. Check the flags with `claude plugin eval --help`.
- `/skill-doctor` does not predict triggers: it shows the context cost and the actual use of each skill (and the never-used ones). Use it to find dead or expensive skills, and `claude plugin validate <path>` for structure.
