---
name: setup-flutter-driver-launch
description: "Use when a Flutter project has no driver entry point or no matching `.vscode/launch.json` configuration and you (or the user) need the Dart MCP driver tools to work: screenshot, tap, scroll, type text. Creates `lib/driver_main.dart` (enables the Flutter Driver extension with text entry emulation off, then runs the real `main()`) and the launch configurations that use it. Propose first; never add it unasked."
---

## Setting up a Flutter driver launch

The Dart MCP driver tools (`dart-mcp`) need a debug app that called `enableFlutterDriverExtension`. Keep that call out of the app's real `main()`: put it in a separate entry point and launch through it.

Ask the user before creating or editing anything. State the files you will add (the entry point, the `launch.json` entries, and a `flutter_driver` dev dependency if missing) and wait for a yes.

### 1. Check what exists

- Look for an existing driver entry point (`grep -r enableFlutterDriverExtension lib test_driver`) and read `.vscode/launch.json`. If a configuration already launches it, you are done: use that one (`find-dtd-uri`).
- Check `pubspec.yaml` for `flutter_driver` (SDK `flutter`) and `flutter_test` under `dev_dependencies`. If missing, add it with one `pub add` call (`dev:` prefix, see the global instructions).
- Find the app's real entry point (usually `lib/main.dart`) and its package name from `pubspec.yaml`.

### 2. Create `lib/driver_main.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:<package_name>/main.dart' as app;

/// Entry point for debugging with UI automation (screenshot, tap, scroll).
///
/// Enables the Flutter Driver extension before starting the normal app.
void main() {
  if (!kReleaseMode) {
    enableFlutterDriverExtension(enableTextEntryEmulation: false);
  }
  app.main();
}
```

- `enableTextEntryEmulation: false` is required: with emulation on from the start, the developer's real keyboard stops working. The agent switches it on only while typing (`set_text_entry_emulation`, see `dart-mcp`).
- Keep the `!kReleaseMode` guard, so the extension never ships in a release build.
- If the real `main` is `async` or takes arguments, mirror its signature and `await` it. Write the doc comment in the project's language (`resolve-project-conventions`).

### 3. Point the launch configurations at it

In `.vscode/launch.json`, make every Flutter profile launch `lib/driver_main.dart`: copy each existing `dart` configuration that runs the app and set `"program": "lib/driver_main.dart"`, keeping its `flutterMode` and `args` (for example `--dart-define-from-file=.env`). If there is none, add:

```jsonc
{
    "name": "Flutter",
    "request": "launch",
    "type": "dart",
    "flutterMode": "debug",
    "program": "lib/driver_main.dart"
}
```

- Do not touch unrelated configurations (integration tests, other targets).
- Do not add a `--dart-define` that no code reads; it does nothing.
- Never add the agent's temporary attach config here; that goes in `.dart_code/autolaunch.json` (`find-dtd-uri`).
- `launch.json` may contain comments and trailing commas; edit it with `Edit`, not a JSON parser.

### 4. Verify

Launch through the new configuration (`flutter run -t lib/driver_main.dart`), connect the DTD (`dart-mcp`), and confirm `flutter_driver_command` `get_health` answers and a `screenshot` works. Report which files you added and what you ran; if you could not launch the app, say the setup is unverified.
