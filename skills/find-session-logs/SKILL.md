---
name: find-session-logs
description: Use whenever you need the user's session logs: Dart analyzer, DAP/debug, DevTools, MCP server, Flutter daemon, DTD, VS Code extension logs, etc. Say, to diagnose an analyzer crash, a debug-session problem or an MCP failure. Also use when a debug session, launch, DTD connection or driver command fails, stalls or behaves unusually, and when the running app itself shows an error (an error screen, a failed request, or a stack trace/exception the user pastes, such as a 4xx/5xx from a backend API), before guessing or retrying blindly. Explains where the logs live and how they are named.
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
| The running app shows an error, or the user pastes an exception/stack trace (e.g. a failed API request) | `<name>_dap.log` of the session running the app: it holds the app's console output, so the full error and the lines before it are there. Read it before asking the user for more output or changing anything |

## When the error comes from a backend API

A pasted trace like `403`/`503` from an API is the app's side of the failure. Before starting, restarting or killing anything, and before asking the user which instance to use:

1. Read the app's own HTTP logging. The app is the one party that always saw the request and the response, so its log usually names the cause (status, error code and message, URI, body) even with no backend log. Look in two places:
   - the session's `<name>_dap.log` (the app's console output, around the failing request), and
   - the app's own log files, if it writes any (e.g. myapp: `%APPDATA%\RECH INFORMÁTICA\myapp\logs\<profile>\log_<date>.txt`). Check the project's docs or its log service for the path.
2. If the app does not log that request or response (URI, status, body, headers that matter), say so and propose adding the logging, then reproduce and read it. This is cheap and beats guessing.
3. Read the backend's own logs too, if the project documents where they are. Only then decide whether the backend needs starting or fixing. When the user says "there should be an api running", treat that as "find out why it isn't answering", not as "start another one".

Tail the file and filter to the time window of the failure. Quote the relevant lines in your report.

## Tips

- Pick the workspace folder matching the project at hand; list the root first if unsure of the name.
- Logs can be large: read the tail or grep for the error/time window instead of reading whole files.
- Only the logs relevant to the problem: e.g. `analyzer.log` for analysis issues, `<name>_dap.log` for debug-session issues, `mcp.log` for MCP tool failures.
