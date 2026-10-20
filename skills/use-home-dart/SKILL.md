---
name: use-home-dart
description: Use whenever the `dart` on PATH is too old for a command or flag you need (e.g. `dart tooling-daemon` is unknown). The user keeps a Dart SDK close to Dart's main branch at `~/dart/bin` on every machine of theirs.
---

# Using the Dart SDK in `~/dart/bin`

The user has a Dart SDK very close to Dart's main branch at `~/dart/bin` on every machine of theirs. Use it when the `dart` on `PATH` lacks a command or flag you need.

- Linux/macOS/WSL: `~/dart/bin/dart <args>`
- Windows: `%USERPROFILE%\dart\bin\dart.exe <args>` (PowerShell: `$env:USERPROFILE\dart\bin\dart.exe`)

## Notes

- Use it only for the command that needs it; keep using the project's normal `dart`/`puro dart`/`flutter` for everything else (analysis, tests, pub, formatting), so the project's pinned SDK stays the source of truth.
- Being near main, it may behave differently from the stable SDK; don't use it to judge whether project code is valid for the project's SDK.
