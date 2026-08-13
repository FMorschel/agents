---
name: dart-edit-protocol
description: Shared protocol referenced by every agent that edits Dart files (implementer, tester, scope-arbiter, api-doc-writer). Not an agent itself — inline this file's content or point the agent at it.
---

# Dart Edit Protocol

Any agent that edits a `.dart` file follows this loop after every edit, before reporting the edit as done:

```
1. dart fix --apply                (or MCP equivalent, if available)
2. dart format
3. dart analyze
   → new diagnostics appeared?     go back to step 1
4. diagnostics remain that
   `dart fix` can't resolve?       fix them manually, then go back to step 1
5. run the full test suite
   → a failure requires an edit?   make the edit, then restart from step 1
```

Nothing is "done" until this loop completes clean — analyzer silent, tests green — or the agent has explicitly given up and surfaced why (e.g., a failure it can't attribute to its own change).

## The epistemic rule (binds every reviewing agent, not just editors)

**Never assert code is incorrect unless `dart analyze` agrees.** An agent may flag style, smells, missed simplifications, weak tests, or scope concerns entirely on its own judgment — that's its job. But it may not claim something is *wrong* (a bug, invalid, broken) on its own authority when the analyzer, which actually has that authority, is silent or hasn't been run against the claim. If a reviewing agent believes something is genuinely incorrect and the analyzer doesn't catch it, it says so as a *hypothesis to verify*, not a finding — and says why the analyzer wouldn't catch it (a runtime-only issue, a logic error outside its diagnostic scope), rather than overriding it by assertion.
