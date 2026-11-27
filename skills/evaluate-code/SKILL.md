---
name: evaluate-code
description: "Use when the user asks to evaluate, review, audit, check or give feedback on existing or just-written code (Dart/Flutter, TypeScript/Angular, Java, Ruby: a file, a diff, a branch, a feature) without asking for changes. Selects the meaningful review agents from the orchestrator's `H` and end-of-feature (`J`) passes by looking at the code, runs them in parallel, and returns one consolidated, findings-only report. When the target implements a spec from `docs/specs/`, reviews against it (spec mode: verdict, report in `docs/reviews/`, at most 3 review rounds). Never edits code."
---

## Evaluating code

This is the review half of the orchestrator pipeline (`H` per-step checks and `J` end-of-feature passes) on its own, for code that did not come through the pipeline. Do **not** spawn the `orchestrator` for this: there is no plan, no phases and nothing to implement. Call the review agents directly.

When the question is narrow (only the tests, only duplication, only newer-Dart opportunities, only sensitive-data handling), skip the selection below and load the matching skill instead: `review-test-adequacy`, `review-duplicate-code`, `review-dart-modernization` or `review-sensitive-data`. The agents in the table load the same skills.

### 1. Scope the target

Resolve what is being evaluated: a path, `git diff` against a base, a branch, or a feature area. Read the file list and skim enough to answer the selection questions below. State the MVC in one line (`Outcome: evaluate X`, `Touches: nothing`) and pass it to every agent. Evaluation never changes files.

### 1b. Spec mode

When the target is the implementation of a spec from `docs/specs/` (the user cited its number or name, or exactly one `in progress`/`done` spec matches the branch), **the spec is the source of truth for what should have been done**: read it before looking at the code, and add this checklist to the agents of section 2.

1. **Spec adherence:** every acceptance criterion is implemented (each with the file and the test that covers it); nothing beyond the scope was changed (an out-of-scope improvement should be a new spec); nothing from "Out of scope" was implemented.
2. **Status and documentation:** the spec status and the index were updated, the criteria ticked, and the README and docs reflect the change. Docs, prompts and comments describe only the current behavior, with no "before spec X".
3. **Schema and configuration:** a database schema change has its migration; new configuration is declared everywhere the project declares it (validation, example, README, CI).
4. **Tests:** every new or changed file has a test; each criterion has a test; error paths are covered; no test uses the real network; no existing test was removed or weakened.
5. **An ambiguous or incomplete spec is a finding against the spec**, not against the code.

Rules of this mode:

- **Do not fix.** Point out and explain; fixing belongs to `execute-spec` (the spec itself comes from `write-spec`).
- Every finding has `file:line` and the spec or project rule it violates. If no rule exists, it is a suggestion (`[info]`), optional, and say it is opinion.
- Do not report pre-existing code outside the diff; if relevant, record it as a suggestion proposing a new spec.
- **Do not invent findings.** Approving without caveats is a legitimate answer when the code is correct.
- Run the validations **without changing files**: the check variants of the linter and formatter (lint check, format check, `rubocop` without `-a`, `spotless:check`), never `--fix`, `--write`, `dart fix`, a `format` that writes, `git add`/`commit`/`checkout` or dependency installation (see `language-tooling`, section "Verification without changing files"). A failure in any of them is blocking.

### 2. Select agents by what the code contains

Run every agent that is meaningful, skip the ones that cannot apply. Skipping is silent; do not call an agent to get a "nothing to report".

| Agent | Run when |
| --- | --- |
| `architecture-guardian` | always |
| `convention-agent` | always |
| `test-adequacy-reviewer` | the target has tests (give it tests **and** implementation) |
| `code-smell-detector` | async code, streams, subscriptions, controllers, listeners or components/widgets; see `review-flutter-async-and-disposal` (Flutter) or `review-angular-async-and-disposal` (Angular) |
| `memory-safety-agent` | same as above, plus anything owning disposable resources (same two skills) |
| `duplicate-code-detector` | two or more functions/methods/classes (full pass, not the light per-step one) |
| `sql-safety-agent` | a DataSource or hand-built queries, or a validator of SQL from an untrusted source (e.g. AI-generated); see `review-sql-safety` |
| `sensitive-data-agent` (implementation-time) | passwords, tokens, secrets or personal data handled or logged |
| `dart-modernization-agent` | the target is more than a trivial file (fetches the SDK changelog) |
| `coverage-auditor` | the target has tests and the user asked for a broad evaluation, or the target is a whole feature |
| `ui-surface-agent` | the change adds or alters anything the user sees or presses (button, menu entry, icon, label, dialog, shortcut); see `check-ui-surface` |
| `flutter-visual-reviewer` | only when the user also asks whether a UI change looks right or caused visual regressions, and a debug app is reachable. It stashes the working tree for the baseline, so run it only with the user's agreement and alone (not in parallel with anything that edits or reads the tree) |

Not part of evaluation: `gap-finder`, `scope-arbiter`, `engineering-balance-critic` (they compare against a plan or request; there is none). Use `engineering-balance-critic` only if the user asks whether the code is over- or under-engineered, run on the code itself, clearly marked as opinion and using the "Proportionality" section of `minimum-viable-change`.

### 3. Run them in parallel

The agents are independent and read-only, so launch all selected agents in **one message** (multiple `Agent` calls), each with the MVC line, the file list or diff, and only what its spec asks for. Foreground is fine because you need all results before reporting. Agents that need tests (`test-adequacy-reviewer`) also get the test files.

If an agent rejects a finding the analyzer does not back, the `dart-edit-protocol` epistemic rule applies: nobody calls code incorrect unless `dart analyze` agrees.

**Line length (Dart).** Only check line length if the `lines_longer_than_80_chars` lint is not enabled; when it is on, the analyzer already reports long lines, so skip it. (That lint may be renamed, see sdk/issues/59552, so match it by its current name and check the enabled-lints list again if it stops matching.) Otherwise, for each file, find the nearest `analysis_options.yaml` by walking up from the file's directory, and follow its `include:` entries (recursively, resolving relative paths) until you find `formatter.page_width`. Measure the long lines with a command (e.g. `awk 'length > N' file`) against that value. If no `analysis_options.yaml` sets it, assume 80 and say so in the report.

For non-Dart projects, the width comes from the project's formatter configuration (`.prettierrc` `printWidth`, `.editorconfig` `max_line_length`, `checkstyle`, `.rubocop.yml` `Layout/LineLength`); skip the check if the formatter already enforces it.

### 4. Report

One consolidated report, not seven pasted ones:

- **Blocking** (architecture violations, leaks, SQL/sensitive-data exposures, `[blocking]` test gaps), each with `file:line` and the agent that raised it.
- **Informational** (smells, convention drift, duplication, modernization, coverage gaps, `[info]` test findings).
- **Skipped agents** with a one-clause reason each, so the user sees nothing was forgotten.
- Findings that point to work beyond what was asked go under `Unrequested extras — need your call`. Do not act on any of it.

#### Saved report and verdict (spec mode)

In spec mode, besides the chat report, write the report to `docs/reviews/NNN-short-title.md` (the same `NNN` as the spec; without a spec, `YYYY-MM-DD-scope.md`) and return in chat only the **verdict**, the count per severity, the blocking items and the file path. The verdict is **approved**, **approved with caveats** or **rejected**.

Severities in this mode (the same categories as above, with finer names):

| Severity | When | Effect |
| --- | --- | --- |
| Blocking | Breaks the build or a test, security flaw, departs from the spec, violates the architecture | Cannot be merged |
| Important | Convention violated, missing test, unhandled error case, outdated documentation | Fix before merge |
| Suggestion | Readability, names, future opportunity | At the author's discretion |

File template: header (date, scope, verdict), validations table with the command and result, findings per severity (each with `file:line`, the problem, the violated rule and how to fix it), spec coverage (each criterion, met or not, with the file and test) and a summary of two or three paragraphs.

**Re-reviews.** After `execute-spec` fixes the blocking items, the review is repeated and written beside the first with the suffix `-rev2`, `-rev3`. The limit is **3 rounds** (the original review plus 2 re-reviews): whatever remains after the 3rd goes to the user, who decides, and the loop does not continue on its own. Each re-review first checks whether the previous findings were resolved and only then looks for new findings in what changed.

End by offering the natural next step (fix the blocking findings, backfill tests via `improve-test-coverage`, tidy via `restructure-code`); do not start it.
