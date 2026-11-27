---
name: dart-flutter-packages
description: "Use whenever you need to find, install, upgrade, remove or read a Dart or Flutter package: searching pub.dev, adding a dependency to a Dart workspace, checking a package's API before calling it, or reading a dependency's source. Prefers the Dart MCP server (`mcp__dart__*`: pub_dev_search, pub, read_package_uris, rip_grep_packages) over shell commands, and says how to install in this repo's workspace without tripping the sandbox."
---

## Dart and Flutter packages

The Dart MCP server can do almost all package work: search pub.dev, add, remove and upgrade dependencies, read dependency source, and analyze the result. Use it first. Fall back to the CLI only when an MCP tool fails or has no equivalent (see the user's CLAUDE.md).

### 1. Check for an existing package before writing code

- Read the project's `pubspec.yaml` (and the workspace root's) first. The package may already be a dependency.
- If it is not, search pub.dev with `mcp__dart__pub_dev_search`. Use the query syntax (`topic:`, `publisher:`, `sdk:flutter`, `"exact phrase"`). Do not use it to check a package you already know.
- Do not add a package just to get one small helper. New dependencies need the user's approval; see the MVC rule in the user's CLAUDE.md.

Example: `mcp__dart__pub_dev_search` with `query: "sdk:flutter topic:file-picker"`.

### 2. Register the roots first

Call `mcp__dart__roots` with `command: "add"` once per session, before any analysis, lsp, pub or read tool. Register both the Flutter app and the server, for example:

`uris: ["file:///mnt/shared/dev/flutter/redstone_deck/ui", "file:///mnt/shared/dev/flutter/redstone_deck/server"]`

Load the schemas of the tools you need with `ToolSearch` (`select:mcp__dart__pub,mcp__dart__read_package_uris`) before calling them.

### 3. Install

- Use `mcp__dart__pub` with `command: "add"`, `packageNames` and the `roots` for the package folder. Add every package in one call. Prefix a dev dependency with `dev:`.
- Pub commands need network access, so the sandbox blocks them. Run the CLI fallback outside the sandbox (set `dangerouslyDisableSandbox: true`) only when the MCP tool fails. Say this in your report.
- CLI equivalents, run from the package folder: `flutter pub add <pkg>` for Flutter packages, `dart pub add <pkg>` for Dart-only packages. Use `dev:` for dev dependencies.
- This repo is a Dart workspace. The root `pubspec.yaml` and `pubspec.lock` are shared, so a change in `ui/` also changes the root lockfile. Run `git diff --stat` after adding and expect those files to change.
- Flutter plugins change the generated registrant files. For example `ui/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` and `ui/macos/Flutter/GeneratedPluginRegistrant.swift`. That is normal; include them in the commit.
- Prefer the newest version pub suggests. Check that the version constraint fits the SDK range in the pubspec.
- Upgrade with `mcp__dart__pub` `upgrade`, and check what can move with `outdated`. Remove with `remove`.

### 4. Read the API before you call it

Do not write a call from memory. Confirm it in the source.

1. Find the library entry file. Read it with `mcp__dart__read_package_uris` using `package:<name>/<name>.dart`. Read the src files it exports next.
2. For examples and tests, use `package-root:<name>/example/...` or `package-root:<name>/test/...`.
3. `mcp__dart__rip_grep_packages` greps dependency sources, but it needs ripgrep. **Ripgrep is NOT installed on this machine**, so this tool fails with "ripgrep not found in PATH". Do not retry it. Fall back to `read_package_uris` on specific files.
4. Check each call's exact signature: static versus instance method, required versus named parameters, and whether the result is nullable.
5. Use `mcp__dart__lsp` `hover` or `signatureHelp` on the call site once the code is written, to confirm the types the analyzer sees.

Example (file_picker 13.4.1, the version in the lockfile): `FilePicker.pickFile(...)` is a static method that returns `PlatformFile?`, and `PlatformFile.readAsBytes()` gives the bytes. The project's `ui/lib/src/data/platform_file_picker.dart` calls it this way, and `file?.readAsBytes()` handles the nullable result. Do not use the static `FilePicker.platform` form from older versions. Checked against the source: `package:file_picker/src/file_picker.dart` declares `pickFile` and `pickFiles`, and `package:file_picker_platform_interface/src/platform_file.dart` declares `readAsBytes`. Read those with `read_package_uris`, which works for this package even though `rip_grep_packages` does not.

### 5. Check the code after adding

1. `mcp__dart__analyze_files` on the changed paths, with `roots`. Use `applyFixes: true` for quick fixes, then read every remaining diagnostic, including warnings and infos.
2. Format the changed files with the CLI: `dart format <files>` (or `puro dart format` where the project uses puro). No MCP tool formats.
3. Run the tests of the package that uses the dependency (`dart test -r failures-only` or `flutter test`). Read `dart-edit-protocol` for the full loop.
4. If the package affects the web build (a web plugin, a JS interop package, a change to `web/`), also run `flutter build web` or the project's deploy step.

### Pitfalls on this machine

- Flutter and puro write under `~/.puro` and `~/.dart-tool`, which the sandbox blocks. Run `flutter` and `dart` commands outside the sandbox (`dangerouslyDisableSandbox: true`), or they fail with a permission error.
- `dart` errors on the read-only home folder for the telemetry file under the sandbox. The same fix applies: run outside the sandbox.
- `rip_grep_packages` fails with "ripgrep not found in PATH". Use `read_package_uris`.
- Do not install a package for one helper function. Check the MVC rule and ask the user first.
- Do not trust a signature from memory. Read the source.

### Waiting rules

Waiting rules: no `until grep`/`until pgrep` polling loops; use a foreground command when you will wait anyway, or `run_in_background` and wait for its exit notification, or `Monitor` with a hard bound (`timeout 1800 bash -c '...'`) on a process exiting or a file existing, never on matching output text. A `timeout` that kills a run leaves any output-matching waiter hanging forever. One waiter per run; stop the previous run and its waiter before re-running. Before you report, `TaskStop` every background command you started that is still running.
