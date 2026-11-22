---
name: report-milestone-progress
description: "Use when the user asks where the work stands ('where are we at?', 'status', 'progress on the milestone'), or when a plan phase or milestone finishes and you must report it: build the status from the plan, the run-state, git and a test run, not from memory, and state done, in progress, blocked and not started with evidence."
---

## Reporting milestone progress

Status comes from the files, not from recall. A report from memory is a guess.

1. **Read** the plan (`specs/plans/*.md`), the run-state, the recorded owner decisions, `git log` since the plan started and `git status`. If tests are cheap to run, run the suite once (to a file, `dart-edit-protocol`) so the numbers are current.
2. **Per milestone and phase, one line** with a status:
   - **Done**: steps complete, tests green, gates passed. Give the commit or date.
   - **In progress**: which step, what is finished in it, what remains.
   - **Blocked**: on whom or what (an owner question, a failing test, a dependency). Name the question.
   - **Not started.**
3. **Numbers**: steps done of total, tests passing and failing or skipped, coverage if measured. Say what you did not run (build, reviews) first.
4. **Deviations and extras**: where the work differs from the plan and why; extras left out and waiting for the user.
5. **Next**: the next step and what it needs from the user, if anything.

Keep it a short table plus a few lines. Say "not verified" for any status you could not confirm from a file or a run.
