---
name: find-dtd-uri
description: Use whenever you need a Dart Tooling Daemon (DTD) URI, e.g. to connect the Dart MCP server to an already-running app (`connect_dart_tooling_daemon`) for debugging, hot reload, widget tree or runtime errors. Lists running DTD instances from the CLI instead of asking the user.
---

# Finding a DTD URI

Before asking the user for a DTD URI, list the running ones:

```bash
dart tooling-daemon --list --machine
```

`--machine` prints machine-readable (JSON) output; pick the entry that matches the user's workspace/app and pass its URI to the Dart MCP server's `connect_dart_tooling_daemon`.

## The `workspaceRoot` field may be wrong

Each entry reports a `workspaceRoot`. Because of a temporary bug in the editor extensions, it can be bogus (empty, or not a folder that relates to the project). If it makes no sense, ignore it and pick the entry by other means (e.g. the only running one, or the one the app/IDE session belongs to); don't treat a mismatch as "no DTD for this project".

## If `dart` has no `tooling-daemon` command

The `dart` on `PATH` may be too old to know the command. Use the `use-home-dart` skill and run the same command with the `dart` in `~/dart/bin`:

```bash
~/dart/bin/dart tooling-daemon --list --machine
```

## If no app is running (empty list, or a DTD with no connected app)

A DTD can exist with no app on it: VS Code with Dart-Code runs one as soon as the project is open. After connecting, `dtd` `listConnectedApps` tells you; if it returns no app, there is no session and this section applies exactly as for an empty list. Do not treat "a DTD is listed" as "a session exists". A listed DTD with no app is also strong evidence that VS Code is open on the project.

No app is running. **First attempt: follow `launch-session-via-dart-code`.** If VS Code is open on the project, write `.dart_code/autolaunch.json` so Dart-Code starts the session, then find and connect to its DTD. Do not launch the app yourself first and do not ask the user to find a URI. Only if that skill's preferred path does not apply (no VS Code window on the project) or produced no session, launch the app yourself as described below (that skill's fallback leaves an attach config for the user).

### Start the session the way the project does

Do not launch with a bare `flutter run`. Use the project's own debug entry point, so the driver tools work:

1. Look in `.vscode/launch.json` for a `dart` launch configuration and reuse its `program` (the target), `flutterMode` and `args` (e.g. `--dart-define-from-file=.env`). Pick the one that fits; do not invent flags.
2. That `program` is normally a driver entry point such as `lib/driver_main.dart`: it calls `enableFlutterDriverExtension(enableTextEntryEmulation: false);` (guarded by `!kReleaseMode`) and then the app's real `main()`. Without that call the driver cannot screenshot, tap or type; with `enableTextEntryEmulation: true` or omitted, the developer's real keyboard stops working. Run it as `flutter run -t <program> [args]`.
3. If the project has no driver entry point or no matching launch configuration, tell the user and propose one and, once the user agrees, create it with the `setup-flutter-driver-launch` skill. Do not add it unasked.
4. Typing then needs `set_text_entry_emulation` on, and off again when you finish (see `dart-mcp`).
5. Prefer letting VS Code start the session so the developer can take over: see `launch-session-via-dart-code`.

Launch configurations mirror this: when you propose or change `launch.json`, keep every Flutter profile on the driver entry point, and note that a `--dart-define` only matters if the entry point reads it (a define the code never reads does nothing).

### Let the user take over the session

Prefer having VS Code (Dart-Code) own the session, so the user can keep debugging when you finish or get stuck. Follow the `launch-session-via-dart-code` skill: it detects an open VS Code window, has Dart-Code launch the session, and falls back to launching it yourself plus an attach config. Experimental.

## Setting up the driver launch

If the project has no driver entry point (`lib/driver_main.dart`) or no `launch.json` configuration that uses it, follow the `setup-flutter-driver-launch` skill to create both, with the user's agreement.
