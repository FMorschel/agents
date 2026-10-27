---
name: dart-mcp
description: "Use whenever you need to use the Dart SDK MCP server (`dart-sdk`) tools: registering project roots, analyzing or fixing code, looking up symbols, managing pub dependencies, reading package sources, connecting to a running Flutter app over DTD, inspecting the widget tree, taking screenshots, interacting with the running app (tapping, scrolling, typing text into fields, waiting for widgets), reading runtime errors, or hot reloading. Says which tool does which job, what each one needs first, and what it cannot do."
---

## Dart SDK MCP server

The `dart-sdk` server exposes 13 tools. Check that they are present before a Dart task; if they are not, fall back to the CLI and say so in your report.

### What each tool is for

| Job | Tool | Needs first |
|---|---|---|
| Register the workspace | `roots` (`add` / `remove`, `uris`) | nothing; do this once per session |
| Analyze files, optionally apply quick fixes | `analyze_files` (`roots[].paths`, `applyFixes`) | roots |
| Symbol info: hover, signature help, workspace symbol search | `lsp` (`hover`, `signatureHelp`, `resolveWorkspaceSymbol`) | roots |
| Pub commands: add, get, remove, upgrade, deps, outdated | `pub` (`command`, `packageNames`, `roots`) | roots |
| Read a dependency's source or examples | `read_package_uris` (`package:` and `package-root:` URIs) | roots |
| Grep through dependency source | `rip_grep_packages` (`arguments`, `packageNames`, `searchDir`) | roots, and `ripgrep` installed |
| Search pub.dev | `pub_dev_search` | nothing |
| Find and connect to a running app | `dtd` (`listDtdUris`, `connect`, `listConnectedApps`, `disconnect`) | a DTD URI, see `find-dtd-uri` |
| Widget tree | `widget_inspector` (`get_widget_tree`, `get_selected_widget`, `set_widget_selection_mode`) | live DTD connection |
| Drive the app: screenshot, tap, read text, scroll, diagnostics tree | `flutter_driver_command` (`command` + finder fields) | live DTD connection, widget names from `widget_inspector` |
| Runtime errors of the app | `get_runtime_errors` (`clearRuntimeErrors`) | live DTD connection |
| Apply code changes to the running app | `hot_reload`, `hot_restart` | live DTD connection; restart for const and global changes |

There is no MCP tool for `dart format`, `dart fix` on its own, or running tests. Use `analyze_files` with `applyFixes: true` for quick fixes, and the CLI (`dart format <files>`, `dart test -r failures-only` or `flutter test`) for formatting and tests. Say which tool produced a result.

### Setup

1. Call `roots` with `command: "add"` and the workspace as a `file:///` URI. Every analysis, lsp, pub, and package tool fails or does nothing without a root.
2. Only then call the other tools.

### Analysis and fixes

- `analyze_files` with the paths you changed is the fast check. Omit `roots[].paths` to analyze the whole root.
- `applyFixes: true` applies quick fixes before returning diagnostics. Run it on your edited files, then read every remaining diagnostic. Warnings and infos count, not just errors.
- Keep the loop from `dart-edit-protocol`: fix, format, analyze, test. Re-run analysis after any edit that resolved a diagnostic.

### Symbols and packages

- `lsp` `hover` and `signatureHelp` take `uri`, zero-based `line`, and zero-based `column`. Use them to check a type or parameter before you write a call, instead of guessing from memory.
- `lsp` `resolveWorkspaceSymbol` takes `query` and fuzzy-searches the workspace. Use it to find where a symbol is declared.
- `read_package_uris` reads `package:x/y.dart` (relative to `lib/`) or `package-root:x/example/main.dart` (relative to the package root). Use `package-root:` to read a package's examples and tests.
- `rip_grep_packages` searches dependency sources. Set `searchDir` to `""` to search the whole package, for example its `example` or `test` folders. Use it to find how a package is used before you guess at an API.
- `pub` `add` takes `packageNames`, with the `dev:` prefix for dev dependencies. Add all the packages you need in one call; do not call once per package.
- `pub_dev_search` finds packages. Use the pub.dev query syntax (`topic:`, `publisher:`, `sdk:flutter`, and so on). Do not use it to check a package you already know; use `read_package_uris` for that.

### Running apps

1. Use `dtd` `listDtdUris` to find a running DTD. If the list is empty, ask the user to start the app with `--print-dtd`, or follow `find-dtd-uri`.
2. `dtd` `connect` with that URI. The apps on that DTD connect automatically; `listConnectedApps` shows them and their `appUri`.
3. Pass `appUri` to the other app tools whenever more than one app is connected.

#### Looking at the UI

1. `widget_inspector` `get_widget_tree` (use `summaryOnly: true` to see only user-code widgets) to get real text, keys, and types.
2. `flutter_driver_command` `screenshot` to see the screen. It needs no finder.
3. For interactions, use a finder taken from the tree: `ByValueKey` with `keyValueString` and `keyValueType`, `ByText` with `text`, `ByTooltipMessage`, `BySemanticsLabel`, or `ByType`. Then `tap`, `enter_text`, `scroll`, or `waitFor`. Never guess a finder.
4. `get_text` reads a widget's text. `get_diagnostics_tree` (`diagnosticsType: "widget"` or `"renderObject"`) gives layout and state detail when a screenshot is not enough.
5. `timeout` defaults to 5000 ms. Raise it for slow screens; do not treat a timeout as proof that a widget is missing without checking the tree.

#### Reaching a screen

Before navigating by tapping and scrolling, read `.agents/screens-navigation/` for a note on the target screen. If you struggle to reach a screen (dead ends, hidden controls, preconditions, waits), write or update a note there so the next session does not; the procedure is in `document-app-navigation`.

#### After editing running code

- `hot_reload` keeps state and does not update global or const values.
- `hot_restart` resets state and applies const and global changes.
- `get_runtime_errors` after either one. Use `clearRuntimeErrors: true` first to drop stale errors, then reproduce and read again.

### Limits

- The driver and inspector tools need the app running in debug mode with DTD. They cannot see a release build or a device the app is not on.
- `hot_reload` on a non-Flutter Dart CLI program does not work. Use `hot_restart` only on Flutter apps.
- `rip_grep_packages` needs ripgrep installed on the host. If it fails, use `read_package_uris` on specific files instead.
- The Dart SDK tools do not replace tests. A passing screenshot does not prove logic is correct; use golden tests (see `write-flutter-ui-tests`) to guard appearance. To check a UI change against a baseline with these tools, follow `review-flutter-visual-changes`.

### Epistemic rule

Report what a tool returned, not what you expect it to return. If `analyze_files` is silent, say it was silent; do not claim the code is correct beyond what analysis and tests show.
