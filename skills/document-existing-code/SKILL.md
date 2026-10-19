---
name: document-existing-code
description: "Use when the user wants the requirements, spec or intended behavior of code that already exists (\"what is this supposed to do\", \"write up the requirements for X\", \"reverse-engineer a spec\"). Runs the existing-feature entry: test-writer first when tests are missing, then requirements-analyst, and surfaces both agents' human-confirmation lists."
---

## Documenting existing code

The orchestrator's existing-feature entry (`Q` → `P`) without the rest of the graph. Does not edit production code.

1. **Tests present?** Yes → `requirements-analyst` alone. No → `test-writer` first, then `requirements-analyst` with the implementation **and** those tests. Order matters: the analyst needs both sources to tell a requirement from an accident.
2. Pass each agent only what its spec needs (see the orchestrator's *Context assembly*): `test-writer` gets the target implementation only.
3. Where to write the result follows `place-project-knowledge` (requirements normally go in `specs/`) and the format follows `write-requirements`. Do not invent a location silently; state where it went.
4. Optionally run `prd-architecture-consistency-checker` if the project has a PRD and `architecture.md` and the new document touches them.

### Report

The requirements document (or its path), the new tests if any, `test-writer`'s axis sweep, and both **Needs human confirmation** checklists **in full**. The user must decide whether the reconstructed intent is right before anyone treats it as ground truth; say that plainly.

Natural next steps to offer, not start: `improve-test-coverage`, `evaluate-code`, `plan-change`.
