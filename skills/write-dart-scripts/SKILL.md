---
name: write-dart-scripts
description: "Use whenever you are about to run `python3 - <<EOF`, `python3 -c`, a `cat > script <<EOF`, or a `sed -i`/`awk` edit on source files, or otherwise need a small or quick script, including one-off bulk text transforms (regex replaces, batch renames, import rewrites) and ad-hoc data reads (a SQLite query): write it in Dart and save it in the user's scripts folder instead of running it inline from a shell heredoc. Says where to save it, when the Edit tool is enough instead, and how to make it reusable. Companion to `report-script-progress`."
---

## Writing quick scripts in Dart

### Where to save

Save the script to the first of these that exists:

1. `D:\dev\dart\scripts` (Windows) or `/mnt/shared/dev/dart/scripts/` (Linux; same underlying location).
2. `C:\Fontes\_local\dart\scripts`.

If neither exists, don't store the script anywhere (use the session's scratchpad if one is given).

### Rules

- Write every script in Dart, including one-off bulk text transforms (regex replaces, batch renames, import rewrites), and save it in that folder. Do not run it inline from a shell heredoc.
- For a change to a single file, or a handful of replacements in a few files, use the `Edit` tool. Reach for a script when the same change spans many files. Never use line-number `sed` (`sed -i '395d'`): the numbers drift as soon as another edit lands.
- **Stop signs.** If you catch yourself typing `python3 - <<`, `python3 -I -`, `cat > something.py <<`, `sed -i` with escaping that needed a retry, or a read-replace-write block, stop: it is either an `Edit` or a Dart script in the scripts folder. A script written to `$TMPDIR` does not count; it belongs in the scripts folder (or the scratchpad only when no scripts folder exists).
- The same applies to one-off data reads such as timing a SQLite query: write a small Dart script (open the database read-only), not a Python heredoc.
- Ideally make the script very abstract and reusable across occasions: take paths, patterns and replacements as arguments. A script that only fits its original occasion is fine too.
- If the script has more than one step or may run longer than a moment, follow `report-script-progress`.
- If the `dart` on `PATH` is too old for something the script needs, see `use-home-dart`.
