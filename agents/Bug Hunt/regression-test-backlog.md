---
name: regression test backlog
description: Discovered bugs confirmed by bug-verifier, pending regression test creation by test-writer or implementer
metadata:
  type: reference
---

# Regression Test Backlog

This file records bugs confirmed by `bug-verifier` that need regression tests to prevent recurrence. When `bug-verifier` reaches a **CONFIRMED** verdict, it saves the findings here so that `test-writer`, the implementer, or a follow-up bug-fix task can convert the discovery into a lasting test case.

## Format for each entry

Each confirmed bug entry includes:

- **Bug ID** — unique identifier (e.g., `BUG-001`, or reference to the issue tracker)
- **Hypothesis** — the original falsifiable claim checked
- **Root cause location** — exact file:line where the defect lives
- **What went wrong** — concise description of the symptom and mechanism
- **Minimal repro** — the test case, input data, or execution steps that trigger the bug (copy from the throwaway test bug-verifier wrote)
- **Confirmation method** — how bug-verifier verified it (existing test, throwaway repro script, static trace, etc.)
- **Date discovered** — when bug-verifier confirmed it
- **Status** — "pending regression test" or "regression test merged" (updated by implementer or test-writer when they act on it)

## Example entry

```
### BUG-001: Off-by-one in pagination cursor
**Hypothesis:** The cursor calculation at lib/src/paginator.dart:42 doesn't account for zero-indexed arrays.

**Root cause:** `lib/src/paginator.dart:42` in `_calculateNextCursor()` — adds 1 to the length instead of to the index.

**What went wrong:** When paginating with page_size=10, the last page's cursor points beyond the collection, causing the next page request to return no results even though more data exists.

**Minimal repro:**
```dart
test('pagination cursor doesn\'t go past end of collection', () {
  final data = List.generate(25, (i) => i);
  final paginator = Paginator(data, pageSize: 10);
  
  final page1 = paginator.getPage(1);
  expect(page1.items, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  
  final page2 = paginator.getPage(page1.nextCursor);
  expect(page2.items, [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]);
  
  final page3 = paginator.getPage(page2.nextCursor);
  expect(page3.items, [20, 21, 22, 23, 24]); // This fails; cursor is 26, past the end
});
```

**Confirmation method:** Throwaway test written and run in scratchpad; test fails with current implementation, proving the off-by-one.

**Date discovered:** 2026-09-14

**Status:** Pending regression test (test-writer should add this to the pagination test suite)

```

## Entries

(Entries saved here by bug-verifier confirmed verdicts — see examples above for format)

---

## Handoff to test-writer

When routing a follow-up task to `test-writer` to backfill tests:
1. Point it to this backlog
2. Provide the section(s) of the backlog for bugs in the target module/file
3. `test-writer` creates a proper regression test for each, runs it, and updates the status to "regression test merged" once the test suite passes

Backlog entries are not actionable PR diffs — they are discovery artifacts. The implementer, test-writer, or whoever fixes the bug is responsible for:
- Converting the minimal repro into a proper test case that fits the project's test suite
- Potentially fixing the defect (if a separate bug-fix task is warranted)
- Updating the "Status" field here to track completion
