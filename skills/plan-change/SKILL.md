---
name: plan-change
description: "Use when the user wants a new feature or non-trivial change designed before any code is written (\"plan this\", \"how should we build X\", \"write requirements and a plan for X\"). Runs the planning half of the pipeline (task-structurer → critic → conditional sensitive-data/api-designer/api-doc-writer → step-planner → critic) and stops with a persisted plan; implementation is a separate decision."
---

## Planning a change

The orchestrator's `A`→`E` stages. This skill stops once a plan exists. To then build it, use `run-pipeline`.

1. **`task-structurer`** turns the request into numbered FRs/NFRs, rough layer impact and the **MVC block** (Outcome, Done when, Touches, Budget, Out of scope). Load `minimum-viable-change`, `write-requirements`, and the project's own architecture doc (or `layered-architecture`).
2. **`engineering-balance-critic`** on the requirements against the request. Overengineering findings get exactly one trim round back to `task-structurer`; if it keeps the item with a reason, it becomes a question for the user.
3. Read the MVC `Budget`:
   - `small`: no contract or plan stages; write the MVC as a one-step plan and stop.
   - `medium` / `large`: continue.
4. **`sensitive-data-agent`** (design-time), only when the FRs mention credentials, tokens, secrets or personal data. Run it alongside step 5 when it does not change the contract's inputs; otherwise before it.
5. **`api-designer`** evaluates existing APIs first and only then defines new signatures. "No new API" short-circuits step 6.
6. **`api-doc-writer`** documents the finalized contract (`comment-code`, `dart-edit-protocol`).
7. **`gap-finder`** after steps 1 and 5, in parallel with the next stage; informational only.
8. **`step-planner`** decomposes into phases and atomic steps. Write the plan to `specs/plans/<run-id>.md` (run-id: task slug + timestamp). Mark UI-touching steps and run **`ui-surface-agent`** on those steps' plans.
9. **`engineering-balance-critic`** on the plan against the MVC (same one-trim-round rule).

### Report

Requirements, contract (or "no new API"), plan path and run-id, critic counterpoints, `Unrequested extras — need your call`. Never skip showing the critic's output even when it found nothing. Pause for the user's approval of the contract and plan; do not start implementing.
