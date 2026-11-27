---
name: handle-generated-files
description: Use when editing Dart code that generates files (annotations, `part`, `*.g.dart`, `*.freezed.dart`, mocks) or when you see a generated file that is stale or wrong: the source changes and the output is regenerated with build_runner, never edited by hand.
---

# Generated files

- never edit a generated file by hand, not even for a one-line fix;
- change the source that produces it, then regenerate with `build_runner`;
- commit the regenerated output together with the source change.

```bash
dart run build_runner build --delete-conflicting-outputs
```

If the generator fails, fix the source or its configuration. Do not patch the generated output to work around the failure.
