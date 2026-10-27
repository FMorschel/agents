---
name: find-session-logs
description: Use whenever you need the user's session logs: Dart analyzer, DAP/debug, DevTools, MCP server, Flutter daemon, DTD, VS Code extension logs, etc. Say, to diagnose an analyzer crash, a debug-session problem or an MCP failure. Also use when a debug session, launch, DTD connection or driver command fails, stalls or behaves unusually, before guessing or retrying blindly. Explains where the logs live and how they are named.
---

# Finding session logs

The user's Dart/Flutter VS Code settings write every log into one root folder, with one subfolder per workspace.

## Locating the log root

The project can override the user's location: its `.vscode/settings.json` (or the `.code-workspace` file) may set the `dart.*LogFile` settings listed below to another path, for example a `.logs` folder inside the project. Those settings apply to the current session's logs, so check them first and use them when present. They may use VS Code variables such as `${workspaceFolder}`; resolve those against the project folder.

Otherwise use the first that exists:

1. `D:\dev\logs` (Windows) or `/mnt/shared/dev/logs` (Linux, same underlying location)
2. `C:\Fontes\_local\log`
3. A `.logs` (or similarly named) folder in the current project folder
4. None of them: ask the user where the logs are.

## Layout

`<log-root>\<workspaceName>\<file>`, where `<workspaceName>` is the VS Code workspace name (usually the project folder name). Files per workspace:

| File | Written by |
| --- | --- |
| `<name>_dap.log` | Debug adapter, one per launch config / session `<name>` |
| `analyzer.log` | Analysis server |
| `analyzerInstrumentation.log` | Analysis server instrumentation |
| `devtools.log` | DevTools |
| `extension.log` | Dart-Code VS Code extension |
| `mcp.log` | Dart MCP server |
| `flutterDaemon.log` | Flutter daemon |
| `dtd.log` | Dart Tooling Daemon |
| `flutterWidgetPreview.log` | Flutter widget preview |
| `webDaemon.log` | Web daemon |

(From the settings `dart.dapLogFile`, `dart.analyzerLogFile`, `dart.devToolsLogFile`, `dart.extensionLogFile`, `dart.mcpServerLogFile`, `dart.flutterDaemonLogFile`, `dart.toolingDaemonLogFile`, `dart.flutterWidgetPreviewLogFile`, `dart.analyzerInstrumentationLogFile`, `dart.webDaemonLogFile`.)

## When a debug session misbehaves

Read the logs before retrying or guessing. Start with the symptom:

| Symptom | Look at |
| --- | --- |
| Launch fails, hangs or takes long; no `vmServiceUri` | `<name>_dap.log` (progress events, Gradle/build errors, `terminated`) |
| Nothing launches from `.dart_code/autolaunch.json` | `extension.log` (did Dart-Code read the file?), then `<name>_dap.log` |
| No DTD, or DTD has no app | `dtd.log`, `extension.log` |
| `hot_reload`, driver or `dtd` MCP call fails or times out | `mcp.log`, then `<name>_dap.log` |
| Device or emulator not found | `flutterDaemon.log` |
| Widget inspector / DevTools errors | `devtools.log` |

Tail the file and filter to the time window of the failure. Quote the relevant lines in your report.

## Tips

- Pick the workspace folder matching the project at hand; list the root first if unsure of the name.
- Logs can be large: read the tail or grep for the error/time window instead of reading whole files.
- Only the logs relevant to the problem: e.g. `analyzer.log` for analysis issues, `<name>_dap.log` for debug-session issues, `mcp.log` for MCP tool failures.
