---
name: write-changelog-and-semver
description: "Use when preparing a pub.dev package release (essential_lints, due_date, pub_watcher, or any other): classifying the public-API diff into MAJOR/MINOR/PATCH per Dart semantics, choosing the next version, and writing the CHANGELOG entry from the user's perspective. Never publishes or edits files itself unless told to."
---

## Changelog and semver for a pub.dev release

Recommend and draft; do not edit `pubspec.yaml` or `CHANGELOG.md`, tag, or run `dart pub publish` unless explicitly told to. Publishing is irreversible on pub.dev (a version can only be retracted, never reused).

### 1. Establish the range

- Last release: the version in the latest `CHANGELOG.md` heading / git tag (`git tag --sort=-v:refname | head`). If they disagree, report the disagreement instead of picking one.
- Diff `<last-tag>..HEAD` for the package directory only (in a monorepo, scope every command to the package's path).
- If an `## Unreleased` / in-progress section exists in `CHANGELOG.md`, reconcile with it rather than writing a duplicate.

### 2. Diff the public API surface

Prefer a structural tool over eyeballing: `dart pub global run dart_apitool:main diff --old <last-version-or-path> --new .` if `dart_apitool` is available. Otherwise compare, for everything reachable from the package's public entry points (`lib/<pkg>.dart` and its `export`s; `lib/src/` is private unless exported):

- removed, renamed or moved public symbols, and changes to what a barrel file exports;
- signature changes: added/removed/reordered positional parameters, an optional parameter becoming required, changed types, nullability, return types;
- changed default values and changed behavior of documented contracts;
- for lint packages: rule additions/removals, **default severity** changes, and rules newly enabled in a shipped preset.

### 3. Classify (Dart-flavored semver)

**Pre-1.0 (`0.y.z`):** a breaking change bumps the *minor* (`0.y+1.0`); everything else bumps the *patch*. Use the rules below and shift them down one slot.

- **MAJOR** — anything that can break existing consumers' code or green builds:
  - removing/renaming/moving a public symbol, or removing it from an export;
  - a breaking signature change: a new required parameter, an optional parameter becoming required, a tightened parameter type, a changed generic bound;
  - a changed return type to something broader or unrelated (narrowing/specializing the return type to a subtype is not breaking);
  - adding an abstract member to a public class/interface that consumers may `implement`, or making a class `final`/`sealed`/`base`/`interface` when it was open;
  - a raised minimum SDK or Flutter constraint that excludes versions consumers may use;
  - lints: a new rule at `error` severity by default, or raising an existing rule to `error`, in a preset consumers include (inside lib/, not the package's own analysis_options);
  - a behavior change that invalidates a documented guarantee.
- **MINOR** — additive only: new public API (not in a previously implementable class), a new optional or named parameter with a default, a new lint rule at `warning`/`info` severity, a new export, a relaxed type (widening a parameter).
- **PATCH** — bug fixes with no contract change, docs, internal refactors, tests, dependency bumps that do not change this package's own surface.

**If unsure whether something is breaking, treat it as breaking.** Note the uncertainty in the report.

Deprecating (`@Deprecated`) is *not* breaking by itself: MINOR, and the CHANGELOG entry names the replacement.

### 4. Check consistency

- Compare `pubspec.yaml`'s current `version` with your recommendation; flag a version already bumped past (or below) what the diff warrants.
- Verify pub-relevant metadata a release depends on: `CHANGELOG.md` top heading matches the version, `dart pub publish --dry-run` is clean (run it — it is read-only), no unintended `publish_to: none`.

### 5. Write the CHANGELOG entry

Follow the file's existing format (heading style, bullets vs. sentences, link references); infer it from the last 3 entries if there is no template.

- **User perspective**, not diff perspective: what a consumer sees or must do, not which file changed. "Added `Foo.bar` to …", not "Refactored `_helper`".
- Group with the file's own labels (Added / Changed / Fixed / Deprecated / Removed) if it uses them; otherwise a flat list, breaking changes first and marked **BREAKING**.
- Every breaking change gets a one-line migration: what to replace with what.
- Omit purely internal changes unless they are the only reason for a PATCH.
- Reference issues/PRs only if the file already does.

### Output format

```
## Release check: <package>

Current pubspec version: X.Y.Z   (last tag: X.Y.Z)
Recommended next version: X.Y.Z  (MAJOR/MINOR/PATCH — <one-line reason>)
Uncertain classifications: <symbol — why it might be breaking>   (omit if none)

### CHANGELOG entry
## X.Y.Z
- <user-facing phrasing>

### Breaking changes detail (if any)
- <symbol> — <what changed> — migration: <one line>

### Pre-publish checks
- dart pub publish --dry-run: <clean | issues>
- Version / CHANGELOG consistency: <ok | mismatch>
```
