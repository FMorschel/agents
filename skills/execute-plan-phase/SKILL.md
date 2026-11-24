---
name: execute-plan-phase
description: "Use when the user says to execute, implement or continue a phase or milestone of an existing plan (for example 'do phase 2 of the plan', 'continue', 'implement M3'): read the plan and run-state, run exactly that phase's steps through the pipeline, update the plan's status, and stop at the phase boundary with a report. Not for planning (`plan-change`)."
---

## Executing one plan phase

1. **Locate the plan** (`specs/plans/<run-id>.md`) and its run-state (`agents/.run-state/<run-id>.md` or the project's equivalent). Read the phase to run, the steps it contains, the recorded owner decisions and any step already marked done. If the user did not name a phase, take the first one not done and say which.
2. **Check readiness.** Each step's contract and docs exist (the earlier stages ran). Prior phases are done. `git status` is clean or only holds this run's changes. If something is missing, say so and stop; don't plan inside this skill.
3. **Run the phase** with the `orchestrator` as `run-pipeline` describes: a fresh orchestrator scoped to this phase, with the brief covering the outcome, inputs by path, decisions already made and the process constraints (`spawn-subagents`). Do not run the next phase.
4. **Update status as steps finish**: mark each step done in the plan, with the commit or the date, and the test counts. A step is done only when its tests pass and the review gates are clean (`dart-edit-protocol` closing gates).
5. **Stop at the phase boundary.** Report using `report-milestone-progress`: what was built, verification numbers, deviations from the plan, owner questions that came up (record the answers with `record-owner-decisions`), and the extras left out. Commit only when the user asked.
6. **If it fails** midway, follow `run-pipeline` ("When a run fails instead of halting") and tell the user which steps finished.
