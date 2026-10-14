---
name: place-project-knowledge
description: "Use whenever you are about to write knowledge down — a rule or preference for agents, a procedure, a fact about a project, a requirement or plan — and must decide whether it belongs in AGENTS.md/CLAUDE.md, a skill, the project's `docs/` folder or its `specs/` folder. Also use when reviewing one of those files for content that belongs in another, or when naming a new skill."
---

## Placing project knowledge

There are four places to write knowledge, and each has one job. Pick one based on when the content is loaded and whether it says *how to work*, *how the project is now*, or *what the project should become*.

### The four homes

| | **AGENTS.md / CLAUDE.md** | **Skill** | **Doc** | **Spec** |
|---|---|---|---|---|
| **Holds** | Standing rules and preferences for agents | How to do a *kind of task* | How *this project* is now | What *this project* should become, for one piece of work |
| **Lives at** | `~/.claude/CLAUDE.md` (global), a repo root, or a subdirectory | Global: `~/.claude/skills/<name>/SKILL.md`. Project: the project's `.claude/skills/<name>/SKILL.md` | The project's `docs/` folder | The project's `specs/` folder |
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
5. Is it intent or a plan for a change that isn't done yet? → **`specs/`**

Mixed content gets split. "Repositories here cache for five minutes; to add one, do X, Y, Z" has two parts. The fact goes in `docs/`. The procedure goes in a skill, which tells the reader to look up the cache policy in `docs/`.

| Knowledge | Home |
|---|---|
| "Prefer Mermaid over ASCII diagrams" | AGENTS.md |
| How to write a regression test | Global skill |
| The default layered architecture, used when a project has none of its own | Global skill |
| How this project cuts a release | Project skill |
| This project's layers and boundaries (`architecture.md`) | `docs/` |
| How to run or deploy the project, its domain glossary | `docs/` |
| A PRD, a feature's FRs/NFRs, its API contract | `specs/` |
| A pipeline run's plan (`specs/plans/<run-id>.md`) | `specs/` |

### How they relate

- **Write globally, use locally.** When you write something, put it at the most global scope where it is still true. Global AGENTS.md beats a repo's, a repo's beats a subdirectory's, and a global skill beats a project skill. When you use it, the most local version wins: a subdirectory's AGENTS.md overrides the repo's, which overrides the global one; a project skill overrides a global skill for the same task; and a project's `docs/` overrides any skill. So only write a local version where it has to differ from the global one.
- **Skills defer to docs.** A project's `docs/` is the ground truth for that project, and a global skill is the generic fallback (see `resolve-project-conventions`). A global skill never states facts about one specific project. When it needs one, it tells the reader where in `docs/` to find it. A project skill can use the project's own names and paths in its steps, but descriptions of how the project works still belong in `docs/`, and the skill points to them.
- **AGENTS.md points to things instead of copying them.** Every line costs context on every turn. Procedures and project facts live elsewhere, and AGENTS.md gives them at most a one-line pointer ("the formal version lives in the `minimum-viable-change` skill").
- **Specs and docs stay separate.** They are written differently: a spec states intent for one change, while a doc describes the current system. Neither is ever converted into the other. When a feature ships, its spec stays in `specs/` as the record of what was asked for and planned. Then update `docs/`, in its own descriptive voice, to reflect what now exists.

### Signs that something is in the wrong place

- **In AGENTS.md:** a multi-step procedure, a rule that only matters for some tasks, or a fact about the code's structure. Move it to a skill or to `docs/`.
- **In a global skill:** a specific project's class names, paths or decisions. Move the procedure to that project's skills and the facts to its `docs/`.
- **In a project skill:** a procedure that would work unchanged in any project. Move it to a global skill.
- **In a doc:** "shall" or "will", milestones, or plans for work that isn't built yet. Move it to `specs/`.
- **In a spec:** a description of how the system already works, with no change intended. Move it to `docs/`.

### Naming a skill

Skill names are kebab-case. Procedure skills start with an imperative verb: `write-dart-tests`, `compose-commits`, `resolve-project-conventions`. In English, the imperative is the bare, non-conjugated verb. A Brazilian Portuguese name can use either the infinitive (`escrever-testes-dart`) or the matching noun (`escrita-de-testes-dart`), because `write` translates to both `escrever` and `escrita`.
