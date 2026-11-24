---
name: restart-desktop-app
description: "Use whenever you must stop, kill, relaunch or restart a desktop app or other long-running process (a Flutter desktop build, an Electron app, a dev server) on Linux or Windows, especially when pkill matched nothing, the user says 'again' or 'it is still running', or the process name is long. One verified procedure instead of repeated kill/launch attempts."
---

## Restarting a desktop app

Find the real process, stop it, start it detached, then verify by PID. Never report "restarted" without the verification step.

### Linux / macOS

1. **Find it.** `pgrep -fa <fragment of the executable path or name>`. Use `-f` (full command line): plain `pgrep`/`pkill` match only the first 15 characters of the process name, so a long name silently matches nothing. Check the result is the app and not your own shell or the editor.
2. **Stop it.** `kill <pid>` (TERM), wait up to about 5 seconds, then `pgrep -fa` again. Only if it is still there, `kill -9 <pid>`. Kill by PID, not by a broad pattern.
3. **Start it detached** so it outlives the command: `setsid -f <executable> [args] > $TMPDIR/app.log 2>&1`. For a Flutter debug session the user owns, use the project's launch flow instead (`launch-session-via-dart-code`), not a second copy.
4. **Verify.** `pgrep -fa <fragment>` returns a new PID, and the log has no immediate crash. Report `running, PID 4312` or `not running` plus the last log lines.

### Windows (PowerShell)

1. **Find it.** `Get-Process -Name <name> -ErrorAction SilentlyContinue | Select-Object Id,ProcessName,Path`. Names have no `.exe`. For a process whose name is generic (`dart`, `node`), filter by command line: `Get-CimInstance Win32_Process | Where-Object CommandLine -like '*<fragment>*' | Select-Object ProcessId,CommandLine`.
2. **Stop it.** `Stop-Process -Id <pid>` (asks the window to close where it can), wait a few seconds, check again, then `Stop-Process -Id <pid> -Force` if it is still there. `taskkill /PID <pid> /T /F` also ends child processes.
3. **Start it detached.** `Start-Process -FilePath <exe> -ArgumentList '<args>' -RedirectStandardOutput $env:TEMP\app.log -RedirectStandardError $env:TEMP\app.err.log`.4. **Verify.** `Get-Process -Id (Get-Process -Name <name>).Id` shows the new PID; read the log. Report as above.

### Rules

- A restart is one scripted sequence, run once. If it fails, change one thing and say what you changed, not the same command five times.
- Never kill by a pattern that could match the user's editor, terminal or the agent itself (`pkill dart` can end the analysis server).
- If the app holds unsaved user state, ask before killing it.
