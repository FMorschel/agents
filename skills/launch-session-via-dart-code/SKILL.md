---
name: launch-session-via-dart-code
description: "Use when you need a Flutter/Dart debug session and no DTD is running, to get VS Code (Dart-Code) to own the session so the user can keep debugging after you finish or if you get stuck. Detects an open VS Code window on the project, has Dart-Code launch the session through `.dart_code/autolaunch.json`, then finds and connects to its DTD; falls back to launching it yourself plus an attach config. Experimental."
---

<!-- EXPERIMENT: relies on Dart-Code's experimental `.dart_code/autolaunch.json` (Dart-Code#5516) and is untested. Revisit once it has been tried in practice. -->

## Launching a debug session through Dart-Code

Dart-Code starts the configurations in `.dart_code/autolaunch.json` when it finds the file at startup or when the file is created ([Dart-Code#5516](https://github.com/Dart-Code/Dart-Code/issues/5516), experimental). Same format as `launch.json`: a `"configurations"` list. Use it so the session belongs to the user's IDE: they can continue debugging when you are done, or take over if you get stuck.

Use this after `find-dtd-uri` found no DTD. Take the launch settings from the project's own `launch.json` (its `program`, `flutterMode`, `args`), as described in `find-dtd-uri`; if the project has no driver entry point, see `setup-flutter-driver-launch` first.

Rules for the file, in both paths below:

- Never put these entries in `launch.json`: it is usually committed.
- Make sure `.dart_code/` is gitignored; if it is not, tell the user rather than editing `.gitignore` unasked.
- Name your entries so they are clearly yours (`... (Claude session)`).
- Delete the file, or your entry, as soon as it has done its job or you give up. Otherwise the IDE launches it again the next time it opens the project.

### Preferred: VS Code is open on the project, so it launches the session

1. **Detect an open window.** Run `code --status` and read the `window [N] (...)` lines: the title contains the folder name, e.g. `window [1] (launch.json - myapp - ... - Visual Studio Code)`. Match the project folder's name. It is a heuristic: two folders with the same name collide, and a window with no folder shows no name. Weaker signals: a DTD in `dart tooling-daemon --list --machine` whose `workspaceRoot` is the project (it can be bogus, see `find-dtd-uri`), or `lastActiveWindow.folder` in VS Code's `storage.json` (only the last window; can be stale). The analysis server does not help: its process does not carry the workspace folder. A DTD that is listed but has no connected app (`listConnectedApps` empty) also means Dart-Code is running for some window, and counts as a match when the folder is plausible. No matching window and no such DTD: use the fallback.
2. **Get a device ready first if the app needs one** (Android/iOS): start the emulator or simulator yourself (`flutter emulators --launch <id>`, then wait for `adb shell getprop sys.boot_completed` to be `1`), because Dart-Code may otherwise prompt the user for a device. Then write `.dart_code/autolaunch.json` with a `"request": "launch"` configuration copied from the project's launch configuration, named e.g. `Launch (Claude session)`, and set `"deviceId"` to that device (from `flutter devices`).
3. **Wait, then connect.** Give the build a few seconds, then list DTDs (`dart tooling-daemon --list --machine`; pick the entry as in `find-dtd-uri`), connect with the Dart MCP server (the DTD may be the one you were already connected to), and wait for `listConnectedApps` to show the app. A cold Android build is slow (one measured launch took about 80 s: Gradle about 55 s, install, sync), so do not time out on a fixed minute. Watch the session's progress instead (next section) and wait while it advances.
4. **Delete the file** once the session is up (or when you give up).

### Telling that a session is starting

Dart-Code runs each session through a debug adapter (DAP) process, and the user's settings log it (`find-session-logs`).

- **DAP log (best signal):** `<log-root>\<workspace>\<launch name>_dap.log`, where the file name is the launch configuration's `name` lowercased with non-alphanumerics turned into `_` (`Flutter (Claude session) (teste-integracao-emu)` gives `flutter_claude_session_teste_integracao_emu_dap.log`). It appears when the session starts. Poll its tail:
  - `"event":"dart.progressStart"` / `dart.progressUpdate` with a `message` (`Launching…`, `Running Gradle task 'assembleDebug'...`, `Installing ...`, `Syncing files to device ...`): still starting; keep waiting while new lines keep arriving.
  - `"event":"dart.debuggerUris"` with a `vmServiceUri`: the app is up. Then connect (`dtd`) and confirm with `listConnectedApps`.
  - `"event":"terminated"`, or `"category":"stderr"` / Gradle `FAILURE` output: the launch failed. Report the message, delete the file and use the fallback.
- **Process:** a `flutter debug_adapter` / `dart debug_adapter` process (a `puro flutter debug_adapter` wrapper on this machine) is started per session and lives until it ends. Compare the process list (`Get-CimInstance Win32_Process` filtered on `debug_adapter`) from before writing the file with after; a new one means Dart-Code accepted the launch. Existing ones belong to other sessions, so do not rely on presence alone.
- **Build activity:** while Gradle runs there are `java`/`gradle` processes and, after the build, `adb` installs. This only tells you it is busy, not that it succeeded.
- **Give up** only when the DAP log has shown no new line for several minutes, or the session terminated, or no DAP log/process appeared at all within about 30 s of writing the file (Dart-Code did not pick the file up; the window may be a different one).

If anything fails or looks unusual (no log appears, a build error, a stalled session, a refused connection), use the `find-session-logs` skill to read the user's logs before retrying.

### Fallback: launch it yourself and leave an attach config

Use this when no window is open on the project, or the preferred path produced no session. Launch the app yourself (`flutter run -t <program> [args]`, as in `find-dtd-uri`), then write an attach entry to `.dart_code/autolaunch.json`, so a VS Code opened later attaches to your running app:

- `"request": "attach"`, `"type": "dart"` and `vmServiceUri` taken from the launch output.
- The VM service URI dies with the app: overwrite the file when you relaunch and delete it when you stop the app.
- Only when you started the app. If you connected to the user's existing DTD, they already have a session.

### Report

Say which path you used, whether a window was detected (and how), and that you deleted or left the file.
