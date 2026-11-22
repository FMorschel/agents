---
name: diagnose-slow-operations-with-logs
description: "Use when the user says an operation in an app is slow ('search takes seconds', 'opening it hangs', 'sync is slow') and you must find where the time goes: look for the app's logs and existing timings first, add timing logs the way the project already logs, measure per layer, and compare with the user's number. Also says where apps keep their data and logs and how to open their database safely."
---

## Diagnosing a slow operation with logs

Measure before guessing. The goal is a table of milliseconds per layer, next to the number the user reported.

### 1. Look for evidence that already exists

- The app's own logs first. Where they live (check, in order): the project's docs or `AGENTS.md`; a `logs/` folder inside the app's data folder; on Linux `~/.local/share/<bundle id or app name>/` (and `~/.config/<name>/`, `~/.cache/<name>/`); on Windows `%APPDATA%\<name>` and `%LOCALAPPDATA%\<name>`. Open the **newest** file (`ls -t`). For Dart/Flutter tooling logs (analyzer, DAP, DTD) use `find-session-logs`.
- `grep -in "slow\|took\|elapsed\|ms\b"` over the newest log. If the operation already logs its duration, you may already have the answer.
- A copy of a database is opened **read-only** (`sqlite3 -readonly <copy>`, or copy the file to `$TMPDIR` first). Never write to the user's data. Use a Dart script for any query beyond a quick look (`write-dart-scripts`).

### 2. Add timing the way the project logs

- Use the project's existing logging approach and its conventions (logger class, levels, where output goes). Don't introduce a second style.
- If the project has no logging: check `pubspec.yaml` for `package:logging`. If it is there, use it. If it is not, **ask the user** before adding any logging dependency. Without it, use `debugPrint`-style temporary output and remove it after.
- Time each layer with a **decorator** around the abstraction, not edits inside every method: a wrapper implementing the repository/service interface that logs `layer.method took N ms`, registered at the composition root. One wrapper per layer (data source, repository, service, controller) gives a per-layer table from one run.
- Log the duration and the size of the input (rows, characters), never the content (`review-sensitive-data`).
- Temporary timing code is removed or lowered to a debug level before the task is done, unless the user asks to keep it.

### 3. Measure and compare

1. Reproduce the user's action with the app running (see `document-app-navigation` for reaching the screen; the Dart MCP driver can tap and type).
2. Read the new log lines and build the table: layer, calls, total ms, slowest call.
3. Compare the total with what the user reported. If it matches, the slow layer is the finding. If it does not, say the slowness is outside what was timed (UI build, startup, the machine) and time that next.
4. Report the table and one hypothesis for the slow layer, with the evidence. Fix only if asked.
