---
name: improve-test-coverage
description: "Use when the user asks for tests on existing code, more coverage, to cover the gaps, or to backfill tests (for only "what's missing / are these tests enough", use `review-test-adequacy`). Chooses between test-writer (never-tested code) and coverage-auditor + tester (gaps in tested code), folds in pending regression-test backlog entries, and finishes with test-adequacy-reviewer."
---

## Improving test coverage

If the user only asked **what is missing** or whether the tests are good enough, and not for tests to be written, use `review-test-adequacy` on its own (report-only) and offer this skill as the next step.

The orchestrator's *narrow: more coverage* route and the existing-feature `test-writer` entry, as a standalone flow. No requirements, no plan, no contract changes. Production code is never edited.

### 1. Establish the situation

- Does the target have any structured tests? None → `test-writer`. Some → measure first.
- Check the project's `specs/regression-test-backlog.md` for pending entries on this module; they join the work (see `write-regression-test`).

### 2. Run

**Never tested:** `test-writer` on the target implementation only. It follows `write-dart-tests` and the axis sweep from `test-case-matrix.md`, and ends with a "Needs human confirmation" list.

**Partly tested:** `coverage-auditor` first (it runs `dart test --coverage`), then hand its findings, risky gaps before trivial ones, to `tester` (or `test-writer` if the existing tests are not structured) to add only the missing cases. Add the backlog entries from step 1.

Then always `test-adequacy-reviewer` with the new tests **and** the implementation, plus the axis sweep. `[blocking]` findings go back to the test-writing agent (max 3 rounds, then surface them).

Running `coverage-auditor` again at the end to show before/after is worthwhile; skip it if the first run was skipped.

### 3. Report

Tests added, coverage before/after when measured, adequacy findings, and the **Needs human confirmation** checklist in full (cases where current behavior may be a bug rather than intent). That checklist is informational and must reach the user; do not let it stall the run.

If the tests expose a real bug, hand off to `hunt-bug` instead of fixing it here.
