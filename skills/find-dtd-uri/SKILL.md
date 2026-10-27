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

## If the list is empty

No DTD is running. Fall back to launching the app yourself, as described in the global "Debugging Dart/Flutter apps" instructions, rather than asking the user to find a URI.

<!-- EXPERIMENT: this section relies on Dart-Code's experimental `.dart_code/autolaunch.json` and is untested. Revisit once it has been tried in practice. -->

### Let the user take over the session you started

When you launch the app yourself from scratch, also write an attach configuration to `.dart_code/autolaunch.json` in the workspace root, so the user's VS Code (Dart-Code, [Dart-Code#5516](https://github.com/Dart-Code/Dart-Code/issues/5516), experimental) attaches to your running app on its own. They can then keep debugging when you finish or if you get stuck, without relaunching.

- Same format as `launch.json`: a `"configurations"` list. Use `"request": "attach"`, `"type": "dart"` and the app's VM service URI (`vmServiceUri`), taken from the launch output. Name it so it is clearly yours, e.g. `Attach (Claude session)`.
- Never put this in `launch.json`: that file is usually committed. Make sure `.dart_code/` is gitignored; if it is not, tell the user rather than editing `.gitignore` unasked.
- The VM service URI dies with the app. Overwrite the file when you relaunch, and delete it when you stop the app, so the IDE does not try to attach to a dead session.
- Do this only when you started the app. If you connected to the user's existing DTD, they already have a session.
