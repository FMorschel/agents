# Global instructions

## Scripting preference

When writing small/quick scripts, prefer Dart, saved to `D:\dev\dart\scripts` (on Windows) or `/mnt/shared/dev/dart/scripts/` (on Linux — same underlying location). If neither exists, use `C:\Fontes\_local\dart\scripts`. If that doesn't exist either, don't store the scripts anywhere.

- Write every script in Dart, including one-off bulk text transforms (regex replaces, batch renames, import rewrites) — and save it in that folder instead of running it inline from a shell heredoc.
- For changes to a single file, use the `Edit` tool; reach for a script when the same change spans many files.
- Ideally, make scripts very abstract and reusable across different occasions (take paths, patterns, and replacements as arguments). A script that only fits its original occasion is fine too.

## Git

- New repositories' default branch should be named `main`, never `master`. (`git config --global init.defaultBranch main` is already set — this just documents the preference for any repo/tool where that isn't picked up automatically.)

## Agents and skills

- Before doing a task yourself, check whether an available agent (via the Agent tool) or skill is designed to do it. If one matches what the user is asking for, suggest using it instead of just doing the task directly yourself.
  - Example: the user says "fix this" without naming the actual problem. Before guessing or diving straight into a fix, check for agents/skills built for that step — e.g. a bug-hypothesis-former-style agent to turn symptoms/logs/repro steps into ranked hypotheses, and a bug-verifier-style agent to confirm which one is actually the root cause — and suggest those rather than immediately writing a fix on a guess.

## Scope: minimum viable change (MVC)

- Aim every change at the **minimum viable change**: the smallest change that makes the requested feature work or the bug go away, proven by tests. Before adding anything, ask: *would the request be unmet without this?*
- Minimal scope doesn't mean lower quality. Correctness, tests for the requested behavior, regression tests for fixes, and the post-edit workflow are always part of it.
- If something would do more than asked — "just because", for completeness, "while I'm here", for future flexibility, or to make things "more secure"/"more robust" when the request didn't mention that — don't do it. Mention it briefly and ask whether it's necessary; it stays out unless I say yes.
- This is a habit, not a ritual: no need to write out a formal MVC statement for ordinary tasks. The formal version (Outcome / Done when / Touches / Budget / Out of scope) lives in the `minimum-viable-change` skill and is used by the agent pipeline, or whenever a task is big enough that its scope needs pinning down.

## Fixing bugs

- Whenever fixing a bug, add a regression test for it (unless the user explicitly says not to). It should fail on the old code and pass with the fix.

## Diagrams

- **Always prefer Mermaid over plain-text (ASCII/box-drawing) code blocks** when drawing diagrams (architecture layers, flows, sequences, state machines, dependency graphs). Use a ```` ```mermaid ```` block instead of a ```` ```text ```` block. Fall back to text only for things Mermaid can't express (e.g. directory trees, literal terminal output).

## Tool preference

- **Always prefer MCP tools over equivalent CLI commands.** If an MCP server exposes a tool that does the same thing as a shell command (e.g. the Dart MCP server's analyze/fix/format/test/pub tools vs. running `dart analyze`(or `puro dart analyze`)/`dart fix`(or `puro dart fix`)/`dart format`(or `puro dart format`)/`dart test -r failures-only`/`dart pub` in Bash), use the MCP tool. Only fall back to the CLI when no MCP equivalent exists or the MCP tool fails.

## Adding Dart/Flutter packages

- **When adding multiple dependencies, do it in a single `pub add` invocation** so pub solves all versions together (and avoids intermediate states where the lockfile is partially resolved). Mix runtime and dev deps in one call using the `dev:` prefix — e.g. `dart pub add dio dev:build_runner dev:build_runner_core` (or `flutter pub add ...` for Flutter packages). Don't run a separate `pub add` per package.

## Dart MCP server: project roots

- **Before the first Dart MCP tool call in a session, set the project roots.** The Dart MCP server's analysis, fix, and pub tools operate against registered roots — without them, the tools have nothing to act on. Use the server's roots-management tool (e.g. `set_roots` / `add_roots`) to register the current workspace root before calling any other Dart MCP tool.

## Debugging Dart/Flutter apps

- **Prefer connecting to the already-running app via the Dart Tooling Daemon (DTD) over starting a new debug session.** Ask the user for a DTD URI (e.g. `dart mcp-server` / editor's DTD URI, usually printed when the app is launched with `--print-dtd` or shown in the IDE's Dart/Flutter debug session) and connect the Dart MCP server to it. Only if the user doesn't have one available should you fall back to launching/debugging the app yourself — e.g. running it as Flutter web, or whatever other approach fits the situation — instead of asking them to find one.

## Post-edit Dart workflow

- **After completing any edits to Dart files, run this sequence via the Dart MCP server:**
  1. `dart fix --apply` (apply automated fixes)
  2. `dart analyze` — read every diagnostic and fix the underlying issues. Don't stop at "no errors"; resolve warnings and infos too unless the user has explicitly opted out of a lint.
  3. `dart format` on every file you edited (not the whole tree).
- Treat this as part of "done." Do not report a Dart task complete until all three steps have run cleanly.
