---
name: place-project-knowledge
description: "Use whenever you are about to write knowledge down — a rule or preference for agents, a procedure, a fact about a project, a requirement or plan — and must decide whether it belongs in AGENTS.md/CLAUDE.md, a skill, the project's `docs/` folder or its specs folder (`docs/specs/` or `specs/`). Also use when reviewing one of those files for content that belongs in another, or when naming a new skill."
---

## Placing project knowledge

There are four places to write knowledge, and each has one job. Pick one based on when the content is loaded and whether it says *how to work*, *how the project is now*, or *what the project should become*.

### The four homes

| | **AGENTS.md / CLAUDE.md** | **Skill** | **Doc** | **Spec** |
|---|---|---|---|---|
| **Holds** | Standing rules and preferences for agents | How to do a *kind of task* | How *this project* is now | What *this project* should become, for one piece of work |
| **Lives at** | `~/.claude/CLAUDE.md` (global), a repo root, or a subdirectory | Global: `~/.claude/skills/<name>/SKILL.md`. Project: the project's `.claude/skills/<name>/SKILL.md` | The project's `docs/` folder | The project's specs folder: `docs/specs/NNN-short-title.md` for lightweight specs (`write-spec`), `specs/plans/<run-id>.md` for pipeline run plans (`plan-change`). If the project already has its own convention, that wins |
| **Loaded** | Always, in full, in every session within its scope | On demand, when a task matches its `description` | When someone needs to know something about the project | While the change is being planned and built |
| **Scope** | Everything under the folder it sits in | Global: any project. Project: that one project | One project | One feature or run |
| **Read by** | Agents | Agents | Humans and agents | Humans and agents |
| **Written as** | Short imperative rules | A procedure: steps, checklists, defaults | Descriptive, present tense: "the sync engine retries three times" | Normative: "the system shall …", numbered FRs/NFRs, contracts, milestones, plans |

AGENTS.md and CLAUDE.md are the same thing under two names: CLAUDE.md is Claude Code's file, and AGENTS.md is the convention shared across tools. Everything here applies to both. Write to whichever one the project already uses.

### Deciding

Ask these in order. The first yes wins:

1. Must it apply to every task in its scope without anyone asking for it? → **AGENTS.md**
2. Is it how to do a kind of task, valid in any project? → **global skill**
3. Is it how to do a kind of task that only exists or only works this way in this project, such as its release steps or how it adds a migration? → **project skill**
4. Is it a fact about this project as it stands now? → **`docs/`**
5. Is it intent or a plan for a change that isn't done yet? → **a spec** (`docs/specs/`, or `specs/plans/` for a pipeline run plan; the project's own convention wins)

Mixed content gets split. "Repositories here cache for five minutes; to add one, do X, Y, Z" has two parts. The fact goes in `docs/`. The procedure goes in a skill, which tells the reader to look up the cache policy in `docs/`.

| Knowledge | Home |
|---|---|
| "Prefer Mermaid over ASCII diagrams" | AGENTS.md |
| How to write a regression test | Global skill |
| The default layered architecture, used when a project has none of its own | Global skill |
| How this project cuts a release | Project skill |
| This project's layers and boundaries (`architecture.md`) | `docs/` |
| How to run or deploy the project, its domain glossary | `docs/` |
| A lightweight spec for one change (`docs/specs/NNN-short-title.md`); its review report goes in `docs/reviews/` | Spec |
| A PRD, a feature's FRs/NFRs, its API contract | Spec |
| A pipeline run's plan (`specs/plans/<run-id>.md`) | Spec |

### How they relate

- **Write globally, use locally.** When you write something, put it at the most global scope where it is still true. Global AGENTS.md beats a repo's, a repo's beats a subdirectory's, and a global skill beats a project skill. When you use it, the most local version wins: a subdirectory's AGENTS.md overrides the repo's, which overrides the global one; a project skill overrides a global skill for the same task; and a project's `docs/` overrides any skill. So only write a local version where it has to differ from the global one.
- **Skills defer to docs.** A project's `docs/` is the ground truth for that project, and a global skill is the generic fallback (see `resolve-project-conventions`). A global skill never states facts about one specific project. When it needs one, it tells the reader where in `docs/` to find it. A project skill can use the project's own names and paths in its steps, but descriptions of how the project works still belong in `docs/`, and the skill points to them.
- **AGENTS.md points to things instead of copying them.** Every line costs context on every turn. Procedures and project facts live elsewhere, and AGENTS.md gives them at most a one-line pointer ("the formal version lives in the `minimum-viable-change` skill").
- **Rules about a kind of task live in that task's skill.** Even a rule that must always apply (question 1) goes in the skill for that kind of task when one exists, such as "no new top-level functions" in `design-dart-class`. AGENTS.md then gets one line saying when to load the skill ("before adding a Dart class or helper, load `design-dart-class`"). Pipeline agents load skills, not AGENTS.md, so a rule written only in AGENTS.md never reaches them. A plain rule in AGENTS.md is for preferences no skill covers, such as diagram format.
- **Specs and docs stay separate.** They are written differently: a spec states intent for one change, while a doc describes the current system. Neither is ever converted into the other. When a feature ships, its spec stays where it was written (`docs/specs/` or `specs/`) as the record of what was asked for and planned. Then update `docs/`, in its own descriptive voice, to reflect what now exists.

### Before you write a rule: look for its skill

When the user says "add a rule to AGENTS.md" (or a prompt file, or a project's agents.md), do not write it there first. `grep -rn "<topic keywords>" skills/` and check the skill list for one that covers that kind of task. If one fits, the rule goes in that skill and AGENTS.md gets at most a one-line pointer saying when to load it. A plain rule in AGENTS.md is only for a preference no skill covers and that is too small for one. Then tell the user, in a short list, where each rule landed.

### After you change a rule, name or path: propagate it

A rule, skill name, folder or file name rarely lives in one file. Before editing, grep the whole repo for the old name or the topic (`skills/`, `agents/`, `prompts/`, `README.md`, the orchestrator, `plugin.config.json`, and the installed copy under `~/.claude/` when it is not a symlink). List every file that mentions it, update each, then re-run the grep and confirm no stale reference remains. When you say you are done, list the files you touched.

A **new skill** needs the same pass: it only takes effect where something points to it. After creating one, grep for the agents, skills, README sections and AGENTS.md lines that cover the same kind of task, wire each one in, and show the list of wiring edits before committing.

### Signs that something is in the wrong place

- **In AGENTS.md:** a multi-step procedure, a rule that only matters for some tasks, or a fact about the code's structure. Move it to a skill or to `docs/`.
- **In a global skill:** a specific project's class names, paths or decisions. Move the procedure to that project's skills and the facts to its `docs/`.
- **In a project skill:** a procedure that would work unchanged in any project. Move it to a global skill.
- **In a doc:** "shall" or "will", milestones, or plans for work that isn't built yet. Move it to a spec.
- **In a spec:** a description of how the system already works, with no change intended. Move it to `docs/`.

### Naming a skill

Skill names are kebab-case. Procedure skills start with a verb in its imperative (base) form, preferring the verb that describes the main action: `write-dart-tests`, `compose-commits`, `resolve-project-conventions`. Use a noun of action (`writing-dart-tests`) only when there is no natural verb. A name that only identifies the topic, without saying the action (for example `architecture-layers`), fails the pattern.

The folder name must be identical to the `name` field in the `SKILL.md` frontmatter. Keep names concise and specific enough to tell close tasks apart, without encoding a version, a tool or a long description in the identifier. Visible headings in the body may be nouns.

To create or review a skill in this repository, also use `write-skills`.
