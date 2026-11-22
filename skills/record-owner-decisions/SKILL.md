---
name: record-owner-decisions
description: "Use whenever the user answers open questions, approves or rejects extras, picks between options or changes a rule that affects a plan or requirements (an 'owner decision'): write each decision down, dated, in the plan and in the requirements or spec it changes, close the matching open item, and propagate it. Prevents resumed runs from re-asking or contradicting it."
---

## Recording owner decisions

A decision the user gave in chat exists only in this conversation until it is written down. Write it down in the same turn you receive it.

1. **List each decision** as one line: the question, the answer in the user's words where short, and the date (`YYYY-MM-DD`).
2. **Plan.** Append to a section `## Owner decisions` in the plan (`specs/plans/<run-id>.md`), newest last. Never rewrite earlier entries. If a later decision replaces an earlier one, add the new line and mark the old one `superseded by <date>`.
3. **Requirements/spec.** Update the requirements document (PRD, the FRs/NFRs, the contract) that the decision changes, in its own voice (normative in `specs/`, per `place-project-knowledge`). A decision that adds, removes or changes a requirement edits that requirement, with its ID.
4. **Close the open item.** Find the matching entry under open questions, unconfirmed items or "Unrequested extras" and mark it answered with the decision's date and a pointer to the recorded line. Don't delete it.
5. **Run-state.** If a run is in flight, copy the answered extras and questions into its run-state file so a resumed orchestrator does not ask again (`run-pipeline`).
6. **Propagate.** If the decision touches other plans, steps or milestones, name those files and update or flag each (`reconcile-plan-set-consistency` when several plans are involved).
7. **Confirm in one short list**: what you recorded and where, with file paths.

Never record something as a decision that the user did not say. "Seems fine" about one item is a decision about that item only.
