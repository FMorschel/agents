---
name: write-requirements
description: "Use when writing functional/non-functional requirements — either forward (turning a raw request into numbered FRs/NFRs, as `task structurer` does) or in reverse (recovering requirements from existing code and tests, as `requirements analyst` does). Covers numbering, testable phrasing, what not to include, evidence/confidence tagging, and open questions."
---

## Writing requirements

Requirements are the *what and why*, true regardless of the eventual signatures. No method names, parameters or return types (that is `api designer`'s job), no implementation steps (`step planner`), no code.

Two modes share the same rules for the requirement lines themselves. Only the source of evidence differs.

### The requirement line

- **One behavior per line.** If a line contains "and" joining two observable behaviors, split it.
- **Observable and testable.** A reader must be able to say what a passing test would assert. Prefer "The system rejects an export request with no rows and reports why" over "The system handles empty exports well".
- **Phrase as behavior in context:** "The system shall/does X when Y." Not a narration of code ("`foo()` loops over the list") and not a solution ("uses a `Map` cache").
- **Numbered and stable:** `FR-#` for functional, `NFR-#` for non-functional, contiguous, never renumbered once referenced downstream. If a requirement is dropped, keep the ID and mark it withdrawn, so `FR-4` never silently means something else.
- **Use the project's own vocabulary** (entity, layer and feature names from `architecture.md`/PRD), and one name per concept. Naming drift here becomes drift between the PRD and the architecture doc.
- **Functional (FR):** inputs accepted, outputs/effects, business rules and validation, states and transitions, error behavior visible to the caller.
- **Non-functional (NFR):** only where genuinely relevant — performance/latency, offline behavior, data integrity, reliability (retries, idempotency, partial failure), security and validation boundaries, concurrency/ordering, compatibility (platform, schema/API versioning), resource limits. Give a measurable bound when one exists; never invent generic boilerplate ("shall be scalable").

Prefer the smallest correct scope. If the request implies more than it needs, say so rather than writing requirements for the extras.

### Mode A — forward (new feature: `task structurer`)

1. **Restate the intent** in one or two sentences: the problem being solved, not just the literal ask.
2. **Write the FRs/NFRs** by the rules above.
3. **Rough architecture impact:** which layer(s) each requirement touches, using *this project's* layer names (resolve them with the `resolve-project-conventions` skill — don't assume View/Controller/Service/Repository/DataSource), and whether it's a new component or a change to an existing one. If a requirement conflicts with the existing architecture, raise it as an open question instead of quietly going along.
4. **Open questions** — only genuine ambiguities that change the shape of the work. Don't ask what you can reasonably default; do state the default you assumed.
   - When an FR takes text, numbers or dates from the user or an external system and the request doesn't say what happens to bad values (empty, whitespace-only, out of range, unparseable, a date in a DST gap), ask here, phrased as observable behaviour: "What should happen when the name is blank: reject with a message, or save after trimming?" Don't turn it into an FR or NFR on your own, and don't ask when the request already answers it or the value comes only from trusted code.
5. **Suggested milestone** — one line.
6. **Minimum viable change** — the block from the `minimum-viable-change` skill. Every FR/NFR must trace to something the user said or clearly implied; one a complete spec might add but the request didn't mention is not numbered: it goes under "Unrequested extras" as a "necessary?" question and stays out unless the user says yes.

If you catch yourself naming a method, parameter or return type, stop: that belongs to the next stage.

```
## Intent
<1-2 sentences>

## Requirements
- FR-1: ...
- NFR-1: ...

## Architecture impact (rough)
- FR-1 → <layer> (new component / modifies existing <name>)

## Open questions
- ...

## Unrequested extras (omit if none)
- <requirement a complete spec might add> — not in the request — necessary?

## Milestone
<one line>

## Minimum viable change
<Outcome / Done when / Touches / Budget / Out of scope, per `minimum-viable-change`>
```

### Mode B — reverse (existing code: `requirements analyst`)

Recover what the software is supposed to do from the **two** sources jointly; either alone misleads. Implementation shows behavior but not intent; tests show intent but go stale.

0. If the code has no tests, write them first (with `write-dart-tests`, derived from the implementation only) so there are two sources to compare. Production code is not edited. Where the result is written follows `place-project-knowledge`; say where the requirements went.
1. Read the full implementation, including dependencies where they affect observable behavior (a timeout passed from a caller, a retry policy in a wrapped client).
2. Read every test that touches it — integration/e2e too — and note what each *asserts*, not what it is named.
3. Cross-reference every behavior or constraint and classify it:
   - **Confirmed** — implementation and test agree (highest confidence)
   - **Implementation only** — real behavior, unguarded, unverified as *wanted* (medium)
   - **Test only / conflicting** — a test asserts something the code doesn't do or contradicts (flag immediately: wrong test, regressed code, or stale test)
4. Tag **every** requirement line with its classification and an evidence pointer (`path:line` or test name).
5. NFRs need real evidence (a test, a constant, a config value, a comment). No evidence, no NFR.

Always end with:

```
## Needs human confirmation
- [ ] <requirement> — evidence: implementation only | test only | conflicting at path:line — confirm this is actually intended before relying on it.
```

Include the section even when empty, and say explicitly that everything had dual evidence if that is true. It is rare enough to state plainly. The document is a starting point a human corrects and signs off, not a finished spec; do not let a confident tone imply more certainty than the evidence supports.

### Cross-check against the architecture document

When the PRD (numbered FRs/NFRs, milestones) or the architecture document is written or changed, and before implementation starts, check that the two agree. Only their consistency is in question, not whether either is good. The `prd architecture consistency checker` agent runs this same check; when done without that agent, follow this section. Read both as given and take their layer/component names and section structure as the reference; don't assume a fixed template. Report to the user.

Count as an inconsistency:
- An FR/NFR with no component, layer responsibility or data flow in the architecture document.
- An architectural component or endpoint that no FR/NFR justifies.
- A milestone that needs something the architecture document doesn't yet describe.
- Naming drift (see "Use the project's own vocabulary" above): the PRD and the architecture document call the same thing by different names, ambiguously.
- A protocol or contract in the PRD that doesn't match the architecture document's endpoint/stream definitions, or the reverse.
- Numbering gaps or duplicate FR/NFR IDs (a withdrawn requirement that keeps its ID is not a gap).

Don't flag:
- Architecture decisions the PRD doesn't reflect when they are clearly infrastructure or non-functional, with no user-facing FR.
- Style, prose quality or formatting of either document.

Report format (omit any subsection with no findings):

```
## Consistency Report

### PRD → Architecture gaps
- FR-##: <intent> — no corresponding architecture coverage found.

### Architecture → PRD gaps
- <component/endpoint> — no FR/NFR justifies this.

### Drift / naming mismatches
- PRD calls it "<X>", architecture doc calls it "<Y>" — confirm same concept.

### Milestone risk
- M#: requires <capability> per FR-##, not yet described in the architecture doc.
```

End with a one-line verdict: consistent / small gaps / needs reconciliation before implementation.

### Common defects to avoid

- Requirements that restate the solution (`FR: uses a debounce of 300 ms`) instead of the need (`FR: search results reflect the final input within 500 ms of the user stopping typing`).
- Vague quality words with no bound: *fast, robust, user-friendly, appropriate, etc.*
- Hidden requirements in prose: if a paragraph implies a behavior, it becomes a numbered line or it doesn't exist.
- Two requirements that can't both be true. Flag it as an open question; don't resolve it silently.
