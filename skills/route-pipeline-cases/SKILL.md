---
name: route-pipeline-cases
description: "Use when the orchestrator agent needs the detail for a case outside the plain new-feature route: the existing-feature, bug-hunt or narrow-request entry points, the definition of done for a fix, UI-touching steps (widget catalog, ui-surface-agent, flutter-visual-reviewer) or reaching a human when it was spawned by another agent. Reference files read on demand so the orchestrator's own prompt stays small."
---

## Orchestrator reference files

`agents/orchestrator.md` keeps the new-feature route in its own prompt and points here for the rest. Read only the file the situation needs:

- `entry-points.md`: existing-feature, bug-hunt and narrow single-concern entries.
- `fix-definition-of-done.md`: a run that fixes something broken is not done without a regression test.
- `ui-steps.md`: steps that add or change a public widget or screen.
- `reaching-a-human.md`: what to do at a checkpoint when the caller is an agent, not a human.
