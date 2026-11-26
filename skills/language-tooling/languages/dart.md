# Dart / Flutter

In Dart prefer the Dart MCP server's tools (`dart-mcp`) over the same commands on the CLI. In a Flutter package, swap `dart` for `flutter` where indicated.

## Static analysis and compilation

- `dart analyze` (`flutter analyze`); rules in `analysis_options.yaml`, with chained `include:`.
- There is no separate build step to check: clean analysis is the criterion for "compiles".
- Epistemic rule: no agent calls code incorrect unless `dart analyze` agrees (`dart-edit-protocol`).

## Formatting and automatic fixes

- `dart format <files>`; width in `formatter.page_width` of `analysis_options.yaml` (80 by default).
- `dart fix --apply` for the lint fixes.
- Post-edit order: `dart fix --apply` → `dart format` → `dart analyze` → tests. Follow `dart-edit-protocol`, the canonical source for the loop.

## Checking without changing files

For a review, which never writes: `dart analyze`, `dart format --output=none --set-exit-if-changed <files>` (only says whether it would change), `dart fix --dry-run` and the tests. Never `dart fix --apply`, `dart format` without those flags, nor `dart pub get`/`upgrade` (they change files and `pubspec.lock`).

## Tests and coverage

- `dart test` (`flutter test`); filter by tag `-t`, exclude `-x`; tags declared in `dart_test.yaml`.
- Coverage: `dart test --coverage-path=./agent-coverage/lcov.info` (`flutter test --coverage --coverage-path=…`), summarized with `package:coverage`. See the `coverage-auditor` agent and `improve-test-coverage`.
- How to write: `write-dart-tests` (general rules, packages and syntax); UI: `write-flutter-ui-tests`.
- `git stash push -- <production files>` serves for the red → green proof (`write-regression-test`).

## Manifest, lockfile and dependencies

- `pubspec.yaml` and `pubspec.lock`; `dart pub get` / `dart pub add` (or the Dart MCP equivalent, see `dart-mcp`).
- The lockfile goes with the manifest in the same commit.

## Generated files

- `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `*.gr.dart`, `*.config.dart`, `*.drift.dart`; regenerate with `dart run build_runner build --delete-conflicting-outputs` (`handle-generated-files`).
- Generated output goes in the same commit as the source that triggers it; it stays out of coverage and of style inference.

## Doc comments, references and TODO

- `///` doc comments; symbol references `[name]`, `[Class.member]`, `[Class.new]`. The analyzer flags an unresolved reference.
- Multi-line TODO: each continuation starts with `//` plus **two spaces**.
- Declaration docs: `comment-code`.

## Suppressing a lint or a type error

- `// ignore: lint_name` and `// ignore_for_file: lint_name`.

## Nulls

- Sound null safety. `!` asserts non-null; type promotion removes the `!` after `if (x == null) return;`.
- A local variable only promotes fields and getters (`final entity = _entity;`). Parameters and locals already promote.

## Script output

- `stdout.write(...)` followed by `await stdout.flush()` before slow work; errors on `stderr`.
- Child process: `ProcessStartMode.inheritStdio` so the output is not captured.
- When creating a Dart script or CLI with several steps, follow `report-script-progress`.

## Post-edit flow

`dart-edit-protocol`.
