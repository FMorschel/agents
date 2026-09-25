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
5. **Suggested milestone** — one line.

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

## Milestone
<one line>
```

### Mode B — reverse (existing code: `requirements analyst`)

Recover what the software is supposed to do from the **two** sources jointly; either alone misleads. Implementation shows behavior but not intent; tests show intent but go stale.

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

### Common defects to avoid

- Requirements that restate the solution (`FR: uses a debounce of 300 ms`) instead of the need (`FR: search results reflect the final input within 500 ms of the user stopping typing`).
- Vague quality words with no bound: *fast, robust, user-friendly, appropriate, etc.*
- Hidden requirements in prose: if a paragraph implies a behavior, it becomes a numbered line or it doesn't exist.
- Two requirements that can't both be true. Flag it as an open question; don't resolve it silently.
