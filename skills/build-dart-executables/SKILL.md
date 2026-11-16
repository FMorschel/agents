---
name: build-dart-executables
description: "Use whenever a Dart CLI or script must run on another OS or architecture than the machine building it, e.g. a Windows host building for WSL/Ubuntu: Dart can cross-compile native executables from Windows to Linux with `dart compile exe --target-os` and `--target-arch`, so no Linux Dart SDK is needed."
---

## Building Dart executables for other platforms

Dart can cross-compile native executables from Windows to Linux. Do not download a Linux Dart SDK for this.

To build a Dart CLI for WSL/Ubuntu, run on the Windows host:

```bash
dart compile exe --target-os=linux --target-arch=x64 bin/app.dart -o <out>
```

Then copy the binary into WSL.

- `--target-arch=arm64` (and other architectures the SDK supports) work the same way.
- Pass any `--define=` values the project's own build script would. Look for that script (or the CI config) before building so the binary matches what the project ships.
- Use the project's Dart (via `puro dart` where the project uses puro) and prefer the Dart MCP tools for anything they cover; compiling has no MCP equivalent, so the CLI is correct here.
- Say in the report which target OS and architecture the binary was built for and where it was written.
