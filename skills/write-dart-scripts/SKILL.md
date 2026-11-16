---
name: write-dart-scripts
description: "Use whenever you need a small or quick script, including one-off bulk text transforms (regex replaces, batch renames, import rewrites): write it in Dart and save it in the user's scripts folder instead of running it inline from a shell heredoc. Says where to save it, when a script is worth it versus the Edit tool, and how to make it reusable. Companion to `report-script-progress`."
---

## Writing quick scripts in Dart

### Where to save

Save the script to the first of these that exists:

1. `D:\dev\dart\scripts` (Windows) or `/mnt/shared/dev/dart/scripts/` (Linux; same underlying location).
2. `C:\Fontes\_local\dart\scripts`.

If neither exists, don't store the script anywhere (use the session's scratchpad if one is given).

### Rules

- Write every script in Dart, including one-off bulk text transforms (regex replaces, batch renames, import rewrites), and save it in that folder. Do not run it inline from a shell heredoc.
- For a change to a single file, use the `Edit` tool. Reach for a script when the same change spans many files.
- Ideally make the script very abstract and reusable across occasions: take paths, patterns and replacements as arguments. A script that only fits its original occasion is fine too.
- If the script has more than one step or may run longer than a moment, follow `report-script-progress`.
- If the `dart` on `PATH` is too old for something the script needs, see `use-home-dart`.
