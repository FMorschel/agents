---
name: dart-edit-protocol
description: "Use after editing any `.dart` file, before reporting the edit as done: the fix → format → analyze → test loop, MCP-first tool preference, Dart MCP project-roots setup, and the epistemic rule that no agent may call code incorrect unless `dart analyze` agrees. Binds implementer, tester, scope-arbiter and api-doc-writer as editors, and every reviewing agent for the epistemic rule."
---

## Dart edit protocol

Nothing is "done" until the loop below completes clean — analyzer silent, tests green — or you have explicitly given up and surfaced why (e.g. a failure you cannot attribute to your own change).

### Tool preference: the Dart SDK MCP server first

**When the Dart SDK MCP server (`dart mcp-server`, exposed as the `dart` MCP server) is available in your session, use its tools for every step of the loop instead of the equivalent shell commands.** Check for it before your first Dart command; do not default to Bash out of habit.

| Step | Dart MCP tool | CLI fallback |
|---|---|---|
| fix | `dart_fix` | `dart fix --apply` (`puro dart fix --apply`) |
| format | `dart_format` | `dart format` |
| analyze | `analyze_files` | `dart analyze` |
| tests | `run_tests` | `dart test -r failures-only` (`flutter test`) |
| dependencies | `pub` | `dart pub` / `flutter pub` |

Fall back to the CLI only when the server is not connected in this session, has no tool for what you need, or its tool fails. In that case say so in your report ("Dart MCP unavailable, used CLI") so the reader knows which tooling produced the result. Tool names above are the server's usual ones; if your session exposes them differently, use whichever tool does the same job.

### Setup (once per session, before the first Dart MCP call)

The Dart MCP server's analysis, fix, format and pub tools act on registered roots; with none registered they have nothing to work on. Register the workspace root first with the server's roots tool (`set_roots` / `add_roots`).

### The loop

```
1. dart fix --apply                (MCP: dart_fix)
2. dart format <files you edited>  (MCP: dart_format — edited files only, never the whole tree)
3. dart analyze                    (MCP: analyze_files)
   → new diagnostics appeared?     go back to step 1
4. diagnostics remain that
   `dart fix` can't resolve?       fix them manually, then go back to step 1
5. run the test suite
   → a failure requires an edit?   make the edit, then restart from step 1
```

- Read **every** diagnostic, including warnings and infos. "No errors" is not the bar; resolve the underlying issue unless the user has opted out of that lint. Do not silence with `// ignore:` to get to green unless the ignore is genuinely correct and you say why.
- Step 5 runs the full suite, not just your file. Prefer failures-only output (`dart test -r failures-only`) to keep it readable and you should mostly not need tail.
- Restart the loop from step 1 after *any* edit made to resolve a diagnostic or a failure; each edit can create new ones.

### Adding dependencies

When several packages are needed, add them in **one** `pub add` call (mix runtime and dev with the `dev:` prefix, e.g. `dart pub add dio dev:build_runner`), so pub solves them together. Never one call per package.

### Role-specific expectations

- **`tester`**: production code does not exist yet, so this step's new tests are *expected* to fail at step 5. Loop only for tooling problems in the test file (format, analyzer diagnostics), and confirm the failure is the expected `UnimplementedError`/missing-symbol one.
- **`api doc writer`**: you only touch doc comments and stubs, so it is a fast pass — still not optional.
- **`implementer` / `scope arbiter` handoffs**: report "tests pass" only after the loop finished clean; otherwise report the exact remaining diagnostic or failure.

### The epistemic rule (binds every reviewing agent, not just editors)

**Never assert code is incorrect unless `dart analyze` agrees.** You may flag style, smells, missed simplifications, weak tests and scope concerns on your own judgment — that is your job. But you may not claim something is *wrong* (a bug, invalid, broken) on your own authority when the analyzer, which actually has that authority, is silent or has not been run against the claim. If you believe something is genuinely incorrect and the analyzer does not catch it, say so as a **hypothesis to verify**, not a finding, and state why the analyzer would not catch it (a runtime-only issue, a logic error outside its diagnostic scope) instead of overriding it by assertion.
