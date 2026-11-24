---
name: reconcile-plan-set-consistency
description: "Use when several plans, PRDs or spec documents for one project (a plan set, milestone plans, a PRD and its architecture doc) may contradict each other, or the user asks to review all plans for consistency, renumber items, or says they contradict each other: build one index of IDs across the set, find the same ID with different content and items with no home, then fix or ask."
---

## Reconciling a set of plans

Read every document in the set once and build an index, then compare. Don't compare documents pairwise from memory.

1. **Collect the set.** List the files (`specs/`, `specs/plans/`, PRD, `architecture.md`). Say which are in scope; the milestone or phase labels each uses (`M0..Mn`, phases, steps).
2. **Index.** One table with a row per ID found in any file: FR, NFR, step, phase, question, decision. Columns: ID, one-line meaning, each file that mentions it and what that file says about it (title, status, owner, dependency).
3. **Find conflicts**, in this order:
   - **Same ID, different content**: FR-12 means two things in two files.
   - **Same content, different IDs**: one requirement numbered twice (a rename that was not propagated).
   - **Dangling references**: a step cites an ID that no longer exists or was moved.
   - **Order and dependency conflicts**: step B needs A's output, but a plan puts B first or in an earlier milestone.
   - **Status conflicts**: done in one file, open in another.
   - **Decisions that disagree** with a recorded owner decision (`record-owner-decisions`).
4. **Resolve.** Where the answer is clear from an owner decision or a requirement the user stated, fix it in every file (`place-project-knowledge` propagation). Where two readings are possible, don't pick: list the conflict with both versions and ask the user.
5. **Report** with the index summary (counts), the conflicts found and fixed (file and line), and the open ones needing an answer. Re-run the index at the end and say it is clean, or what remains.

Keep the index as a scratch file unless the user wants it committed.
