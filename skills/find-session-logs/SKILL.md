---
name: find-session-logs
description: Use whenever you need the user's session logs: Dart analyzer, DAP/debug, DevTools, MCP server, Flutter daemon, DTD, VS Code extension logs, etc. Say, to diagnose an analyzer crash, a debug-session problem or an MCP failure. Explains where the logs live and how they are named.
---

# Finding session logs

The user's Dart/Flutter VS Code settings write every log into one root folder, with one subfolder per workspace.

## Locating the log root

Use the first that exists:

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

## Tips

- Pick the workspace folder matching the project at hand; list the root first if unsure of the name.
- Logs can be large: read the tail or grep for the error/time window instead of reading whole files.
- Only the logs relevant to the problem: e.g. `analyzer.log` for analysis issues, `<name>_dap.log` for debug-session issues, `mcp.log` for MCP tool failures.
