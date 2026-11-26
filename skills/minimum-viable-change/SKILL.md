---
name: minimum-viable-change
description: "Use whenever you define, plan, implement, test or review a change in this pipeline: the Minimum Viable Change (MVC) is the smallest diff that makes the requested feature true or the reported bug gone, verified by tests. Defines how to state the MVC up front, the per-line 'would the request be unmet without it?' test, what the MVC never trims (correctness, tests, regression tests, real exposures), the diff budget, and the 'Unrequested extras' rule: work beyond the request is left out and asked about, never added by default. Also covers proportionality (over- and under-engineering signals) and the exception for tests. Do not load it just to limit changed lines in a local edit of existing code; use `preserve-existing-code`."
---

## Minimum Viable Change (MVC)

The **MVC** is the smallest change that gets the user what they asked for: the requested feature
works, or the reported bug is gone, and a test proves it. Everything in this pipeline is measured
against it. Requirements, contract, plan, tests, code and reviews all answer to one question:

> **Would the request be unmet without this?**

If yes, it's part of the MVC. If no, it's an **unrequested extra**, and extras are left out by
default and asked about (see below), no matter how good an idea they are.

The MVC is about **scope, not quality**. It's the smallest *correct* change, not the sloppiest.

### Stating the MVC (task-structurer does this once, at the start)

```
## Minimum viable change
Outcome: <the observable result the user asked for, in their terms — "exporting an empty list
          produces a CSV with only the header row", "crash on null avatar is gone">
Done when: <the test(s) that would prove the outcome — for a fix, the regression test>
Touches: <the files/symbols most likely to change — best guess, from reading the code>
Budget: <small | medium | large> — ~<N> files, <new public API: none | list>
Out of scope: <tempting adjacent work that is NOT part of this — named so nobody drifts into it>
```

`Outcome` and `Done when` come from the user's words, not from what a thorough spec would add.
When the request is ambiguous enough that two readings would give materially different MVCs,
that's an open question for the human, not a reason to build both.

Every later stage inherits this block. When an agent's output doesn't mention the MVC, the
orchestrator hands it the block. It's the baseline every "is this in scope?" call is measured against.

### Shaping the MVC — prefer, in order

1. **Change nothing new** — the behavior can come from configuring or calling existing code.
2. **Edit before create** — change an existing function/file before adding a new one.
3. **Private before public** — a private helper is invisible to the contract; a new public member is not.
4. **Reuse before abstract** — no new interface, base class, layer, stream, config option or
   parameter unless the requested outcome can't be reached without it.
5. **Fix at the root, narrowly** — for a bug, change the line(s) that cause it. Refactoring the
   surrounding code isn't part of the fix.

### What the MVC never trims

Minimal scope never means skipping these. They're part of *every* MVC:

- **Correctness** — the outcome actually works, including the edge cases the request itself implies.
- **Tests that pin the requested behavior**, and for a fix, **a regression test** that fails on the
  old code and passes on the new (see `write-regression-test`).
- **The `dart-edit-protocol` loop** — clean analyze, formatted, green suite (for other languages see `language-tooling`).
- **Project conventions and layer rules** for the code the change touches (the change fits in;
  it doesn't rearrange what it didn't touch).
- **Real exposures the change itself creates** — e.g. the new code logs a token. That's a defect in
  the change, not hardening.

### Unrequested extras — the rule

If something you're about to add does more than the request asked for — "just because", "for
completeness", "while we're here", "for future flexibility", or to make things "more secure" /
"more robust" when the request never mentioned that — **don't add it.** Instead:

1. List it in your output under `Unrequested extras`, one line each:
   `- <what> — <why it's tempting> — necessary?`
2. Leave it out of your artifact (requirements, contract, plan, tests, code).
3. The orchestrator collects these and puts them to the human. An extra becomes work **only if the
   human says yes**. With no answer, it stays out, and it's listed in the final report as an
   optional follow-up.

**Exception: tests.** A suggested test case (by the sweep, a reviewer, the user or you) is not an
extra, even "just because", "for completeness" or "to be more robust": write it. More tests help,
and the user can remove them later. Only a test that needs a production-code change to pass is an
extra (`skills/write-dart-tests/test-case-matrix.md`, "Suggested cases, even for completeness").

This applies to every agent and every stage. Reviewers use it too: a reviewer finding that asks
for work outside the MVC (and isn't one of the "never trims" items above, nor a test case) is an
unrequested extra, not a gap and not a blocking finding.

### The diff budget

The MVC's `Budget` is a tripwire, not a target. If the actual change grows well past it — roughly
double the files, or any public API the MVC said would be `none` — the orchestrator stops and asks
the human whether to continue, re-scope, or trim before going further. Scope creep that shows up
gradually, one reasonable-looking step at a time, is exactly what this catches.

### Proportionality

This skill is mostly about not over-building. The other half of proportionality is not
under-building what the request already implies. Both are an **opinion to offer, never a blocking
finding**: phrase it as "this looks like more/less than the request needs, because X", not as a
violation. Compare against the user's **original request**, not only the requirements: the
requirements may already have grown past the request.

Over-engineering signals:
- An abstraction with exactly one implementation and no plausible second one.
- A configuration option or parameter nobody asked for.
- A layer or indirection added "for future flexibility" with nothing in the request pointing that way.

Under-engineering signals (all measured against what the request already implies):
- A decision the next adjacent requirement will force you to revisit.
- An error path silently ignored instead of handled or explicitly deferred.
- A contract too narrow for an extension the requirements already imply.

Offer the finding with what to cut (over-engineering) or what to add (under-engineering). If that
part of the work isn't in the original request, it goes under `Unrequested extras` as a question.
If nothing stands out, say the change looks proportional to the request, so it's clear the check
was done. In the pipeline this opinion is `engineering balance critic`'s job; this section is the
criterion it applies.

### Quick self-check before handing off

- Could I delete any part of my output and still meet `Outcome` / `Done when`? → that part is an extra.
- Did I touch a file outside `Touches`? → say why, or move it to extras.
- Did I add a public symbol, abstraction, config, or layer? → it must be unavoidable for the `Outcome`.
- Is my `Unrequested extras` list empty because I checked, or because I didn't look? Say which.
