---
name: review-dart-modernization
description: "Use when the user asks whether Dart code could use newer language features, or whether it is up to date or could be simplified with recent Dart (pattern matching, records, sealed classes, dot shorthands, primary constructors, etc.). Fetches the Dart SDK changelog first because model knowledge of new Dart is stale. Report-only; it never edits. Used by `dart modernization agent` in the pipeline."
---

## Reviewing Dart modernization

Look for places where code manually does something a newer Dart language or core-library feature now does more directly. Findings are informational: they never become plan steps unless the user asks. You never apply a fix.

### The step you cannot skip

Your own idea of "what's new in Dart" has a cutoff, and Dart ships features past it regularly. **Before evaluating anything, fetch the Dart SDK changelog** (or release notes) and compare it with what you already know. Evaluating against assumed-current knowledge defeats the purpose of this review. If the `dart` on PATH is too old for a command you need, see `use-home-dart`.

### Procedure

1. Fetch the changelog and list the language/core-library features you were not already accounting for.
2. Scan the target for patterns those features would simplify: manual type switching that a pattern match or sealed-class exhaustiveness would replace, tuple-like classes that records would replace, and so on.
3. For each candidate, confirm the feature's minimum SDK is at or below the project's `pubspec.yaml` SDK constraint. A simplification the project cannot compile is noise, not a finding.

### Scope

- **Pipeline**: only lines the change added or modified. Pre-existing code is out of scope even when `duplicate code detector` flagged it; list it under `Unrequested extras` as a follow-up for the human.
- **Standalone**: the file, module or diff the user named.

### Output

```
## Modernization candidates

Checked against: Dart SDK changelog through <version found>
Project's minimum SDK: <from pubspec.yaml>

- path:L## — <current pattern> could become <newer-feature pattern>, available since Dart <version>.
```

Omit the section if nothing is found or nothing fits the project's SDK constraint. Never suggest a feature the project cannot yet use.
