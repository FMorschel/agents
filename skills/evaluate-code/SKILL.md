---
name: evaluate-code
description: "Use when the user asks to evaluate, review, audit, check or give feedback on existing or just-written Dart/Flutter code (a file, a diff, a branch, a feature) without asking for changes. Selects the meaningful review agents from the orchestrator's `H` and end-of-feature (`J`) passes by looking at the code, runs them in parallel, and returns one consolidated, findings-only report. Never edits code."
---

## Evaluating code

This is the review half of the orchestrator pipeline (`H` per-step checks and `J` end-of-feature passes) on its own, for code that did not come through the pipeline. Do **not** spawn the `orchestrator` for this: there is no plan, no phases and nothing to implement. Call the review agents directly.

### 1. Scope the target

Resolve what is being evaluated: a path, `git diff` against a base, a branch, or a feature area. Read the file list and skim enough to answer the selection questions below. State the MVC in one line (`Outcome: evaluate X`, `Touches: nothing`) and pass it to every agent. Evaluation never changes files.

### 2. Select agents by what the code contains

Run every agent that is meaningful, skip the ones that cannot apply. Skipping is silent; do not call an agent to get a "nothing to report".

| Agent | Run when |
| --- | --- |
| `architecture-guardian` | always |
| `convention-agent` | always |
| `test-adequacy-reviewer` | the target has tests (give it tests **and** implementation) |
| `code-smell-detector` | async code, streams, subscriptions, controllers, listeners or widgets |
| `memory-safety-agent` | same as above, plus anything owning disposable resources |
| `duplicate-code-detector` | two or more functions/methods/classes (full pass, not the light per-step one) |
| `sql-safety-agent` | a DataSource or hand-built queries |
| `sensitive-data-agent` (implementation-time) | passwords, tokens, secrets or personal data handled or logged |
| `dart-modernization-agent` | the target is more than a trivial file (fetches the SDK changelog) |
| `coverage-auditor` | the target has tests and the user asked for a broad evaluation, or the target is a whole feature |
| `ui-surface-agent` | only when the user also asks about UI consistency |

Not part of evaluation: `gap-finder`, `scope-arbiter`, `engineering-balance-critic` (they compare against a plan or request; there is none). Use `engineering-balance-critic` only if the user asks whether the code is over- or under-engineered, run on the code itself.

### 3. Run them in parallel

The agents are independent and read-only, so launch all selected agents in **one message** (multiple `Agent` calls), each with the MVC line, the file list or diff, and only what its spec asks for. Foreground is fine because you need all results before reporting. Agents that need tests (`test-adequacy-reviewer`) also get the test files.

If an agent rejects a finding the analyzer does not back, the `dart-edit-protocol` epistemic rule applies: nobody calls code incorrect unless `dart analyze` agrees.

### 4. Report

One consolidated report, not seven pasted ones:

- **Blocking** (architecture violations, leaks, SQL/sensitive-data exposures, `[blocking]` test gaps), each with `file:line` and the agent that raised it.
- **Informational** (smells, convention drift, duplication, modernization, coverage gaps, `[info]` test findings).
- **Skipped agents** with a one-clause reason each, so the user sees nothing was forgotten.
- Findings that point to work beyond what was asked go under `Unrequested extras — need your call`. Do not act on any of it.

End by offering the natural next step (fix the blocking findings, backfill tests via `improve-test-coverage`, tidy via `restructure-code`); do not start it.
