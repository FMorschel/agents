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
