---
name: prepare-release
description: "Use when the user asks to prepare, review or check a release of a pub.dev package (\"ready to publish?\", \"next version\", \"changelog for X\"). Runs a pre-release evaluation of the diff since the last release in parallel with pubdev-release-agent, then proposes the version bump and CHANGELOG entry. Never publishes."
---

## Preparing a release

The orchestrator's `J`→`M`→`N` tail for a package, usable on its own.

1. Find the last release (latest version tag or the CHANGELOG head) and the diff since it.
2. In **one message**, in parallel:
   - `pubdev-release-agent`: semver classification and CHANGELOG draft (`write-changelog-and-semver`).
   - The `evaluate-code` selection on that diff, trimmed to release concerns: `architecture-guardian`, `convention-agent`, `dart-modernization-agent`, `coverage-auditor`, and `sensitive-data-agent` if relevant. Skip the rest unless the diff is large.
3. Check that public-API changes have dartdoc (`comment-code`) and that `dart analyze` and the tests are clean (`dart-edit-protocol`).

### Report

Proposed version and why, the CHANGELOG entry, blocking findings (anything that would make the release wrong), and informational ones. Editing `CHANGELOG.md` / `pubspec.yaml`, tagging and `dart pub publish` are the user's call: propose, and only edit files if told to. Publishing is never done by the agents.
