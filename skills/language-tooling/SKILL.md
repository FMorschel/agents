---
name: language-tooling
description: "Use whenever a generic skill (tests, commits, comments, review, scripts, conventions) needs a detail that depends on the language: which analyzer, formatter, test runner, coverage command, manifest and lockfile, generated files, doc comment format, how to suppress a lint, how to handle nulls, how to print progress. Concept-to-tool map for Dart/Flutter, TypeScript/Node.js, Java and Ruby, with one file per language. Always confirm in the project: what it already configures prevails."
---

## Tools by language

The process skills (`write-regression-test`, `compose-commits`, `comment-code`, `evaluate-code`, …) describe *what to do* without depending on a language. When one of them says "the project's analyzer", "the formatter", "generated files" or "the manifest", this skill says *which command or file that is* in the language at hand.

### How to use

1. Find the language from the project's manifest (table below). A repository can have more than one; use the one for the area you are editing.
2. Open only that language's file in `languages/`.
3. **The project prevails.** If `CLAUDE.md`/`AGENTS.md`, `CONTRIBUTING.md`, the manifest scripts (`scripts` in `package.json`, `Makefile`, Gradle/Maven tasks) or the CI configuration already define the command, use the project's. The commands in the files are the default when the project says nothing (see `resolve-project-conventions`).
4. A language that is not in the list: do not silently adapt from memory. Say there is no file for it, use `resolve-project-conventions` to find the project's tools and, if the language is recurring, propose adding a file (see the end).

### Which file to open

| Signal in the project | Language | File |
| --- | --- | --- |
| `pubspec.yaml` | Dart / Flutter | `languages/dart.md` |
| `package.json` (`tsconfig.json` indicates TypeScript; `angular.json` indicates Angular) | TypeScript / JavaScript on Node.js, including Angular (own section in the file) | `languages/typescript-node.md` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java (and other JVM languages) | `languages/java.md` |
| `Gemfile`, `*.gemspec` | Ruby (includes Rails) | `languages/ruby.md` |

For Angular there is `review-angular-async-and-disposal`. For Dart and Flutter there are also dedicated process skills, which apply in place of the file's short notes: `dart-edit-protocol`, `write-dart-tests`, `flutter-conventions`, `edit-dart-class`, `design-dart-class`, `review-flutter-async-and-disposal` and the others with `dart` or `flutter` in the name.

### Concepts each file answers

Each language file has, in this order, the same sections, so a generic skill can ask for "item X" without knowing the language:

| Concept | Used by |
| --- | --- |
| Static analysis and compilation | `evaluate-code`, `restructure-code`, `minimum-viable-change`, `compose-commits` (each commit compiles) |
| Formatting and automatic fixes | `preserve-existing-code`, `compose-commits`, `comment-code` |
| Checking without changing files | `evaluate-code` (mode against a spec), any read-only review |
| Tests and coverage | `write-regression-test`, `improve-test-coverage`, `review-test-adequacy` |
| Manifest, lockfile and dependencies | `compose-commits`, `resolve-project-conventions` |
| Generated files | `compose-commits`, `resolve-project-conventions`, `improve-test-coverage` and the `coverage-auditor` agent |
| Doc comments, references and TODO | `comment-code` |
| Suppressing a lint or a type error | `preserve-existing-code` |
| Nulls | `preserve-existing-code` |
| Script output (flush, inherited stdio) | `report-script-progress` |
| Post-edit flow | any skill that edits code |

### Adding a language

Copy an existing file, keep the same sections in the same order, and confirm each command against the tool's official documentation or by running it. Register the new row in the "Which file to open" table. Do not invent a command you could not confirm: write "no default, see the project".
