---
name: restructure-code
description: "Use when the user asks for a behavior-preserving reorganization: split a file, move code to another folder or module, extract into its own module/class, rename, or reshape layers. Runs implementer for the mechanical change, then the structural reviewers in parallel. Not for new features or bug fixes."
---

## Restructuring code

The orchestrator's *narrow: split/reorganize* route. The request is the MVC: state `Outcome` and `Touches` in one line and pass it to each agent.

1. **Safety net first.** Existing tests must be green before you touch anything (`dart-edit-protocol`). If the target has no tests, say so and offer `improve-test-coverage` first; proceed only if the user accepts the risk.
2. **`implementer`** performs the mechanical move/rename/extract. No behavior change, no new public API, nothing "while I'm here". Follow `edit-dart-class` and `design-dart-class` for class layout and `layered-architecture` (or the project's own architecture doc) for placement.
3. **Review in parallel** (one message, multiple `Agent` calls) on the resulting diff:
   - `architecture-guardian`: new boundaries and dependency direction.
   - `convention-agent`: naming, file layout, import order.
   - `duplicate-code-detector`: only if the split could leave near-duplicate leftovers.
4. Blocking findings (architecture violations) go back to `implementer`, then re-run the same reviewers, max 3 rounds.
5. Tests are the proof. Do not route through `tester` unless the move changed a public contract; if it did, that is a tripwire: stop and ask.

Report the moves made, review findings, and extras as questions. Offer `compose-commits`; renames and moves usually deserve their own commit separate from edits.
