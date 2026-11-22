# Global instructions

## Scripting preference

When writing small/quick scripts, write them in Dart and save them to `D:\dev\dart\scripts` (Windows) or `/mnt/shared/dev/dart/scripts/` (Linux), never inline from a shell heredoc. Follow the `write-dart-scripts` skill.

## Git

- New repositories' default branch should be named `main`, never `master`. (`git config --global init.defaultBranch main` is already set — this just documents the preference for any repo/tool where that isn't picked up automatically.)
- Whenever I ask for a "new project", initialize it as a git repository (`git init`) unless I say otherwise.
- Whenever I ask for a new branch, consider first rebasing the project's main/master onto its remote counterpart (fetch, then rebase the local main onto the remote's main), and create the new branch from that updated base. Skip the rebase and base the branch on what I name if I say which branch or commit it should start from.

## Agents and skills

- Before doing a task yourself, check whether an available agent (via the Agent tool) or skill is designed to do it. If one matches what the user is asking for, suggest using it instead of just doing the task directly yourself.
  - Example: the user says "fix this" without naming the actual problem. Before guessing or diving straight into a fix, check for agents/skills built for that step — e.g. a bug-hypothesis-former-style agent to turn symptoms/logs/repro steps into ranked hypotheses, and a bug-verifier-style agent to confirm which one is actually the root cause — and suggest those rather than immediately writing a fix on a guess.

- Before spawning a subagent (Agent tool), starting a background task (`run_in_background`, Monitor) or waiting on a long-running command such as a full test suite, load the `spawn-subagents` skill: it covers the brief, shared-working-tree collisions and waiting without stuck background commands.

- When something took a long time to figure out and the answer would help next time, load the `suggest-new-skills` skill: it decides whether a skill is worth suggesting, whether it is global or belongs to the current project, and asks me to confirm before anything is created.

- Before asking me to run a command and paste its output, load `run-host-commands-yourself`: run it yourself unless it needs my credentials or a physical action.

## Scope: minimum viable change (MVC)

- Aim every change at the **minimum viable change**: the smallest change that makes the requested feature work or the bug go away, proven by tests. Before adding anything, ask: *would the request be unmet without this?*
- Minimal scope doesn't mean lower quality. Correctness, tests for the requested behavior, regression tests for fixes, and the post-edit workflow are always part of it.
- If something would do more than asked — "just because", for completeness, "while I'm here", for future flexibility, or to make things "more secure"/"more robust" when the request didn't mention that — don't do it. Mention it briefly and ask whether it's necessary; it stays out unless I say yes.
- This is a habit, not a ritual: no need to write out a formal MVC statement for ordinary tasks. The formal version (Outcome / Done when / Touches / Budget / Out of scope) lives in the `minimum-viable-change` skill and is used by the agent pipeline, or whenever a task is big enough that its scope needs pinning down.

## Architecture

- Whenever writing code, consider the layered architecture (see the `layered-architecture` skill). If the project has no architecture in place, use it; otherwise follow it as closely as possible while respecting the project's current structure and conventions.
- At the very least, keep a clear separation of concerns in all code you write, even when no layered structure applies.
- Keep SOLID in mind as an overall guide, but don't treat it as mandatory: apply it where it pays off and skip it where it would be overengineering for the project's size.
- Prefer composition over inheritance.
- Before adding or specifying a new Dart class, top-level function or helper, load the `design-dart-class` skill: it decides where helpers go (no new top-level functions).
- Keep the public surface small: expose only what callers need and keep everything else private.
- Design for testability: pure functions where possible, side effects at the edges.
- Where practical, aim to make illegal states unrepresentable (sealed classes, enums, non-nullable types instead of flags and nullable fields kept in sync). This is a goal, not a requirement.

## Fixing bugs

- Whenever fixing a bug, add a regression test for it (unless the user explicitly says not to). It should fail on the old code and pass with the fix.

## Tests

- Whenever you get or think of a suggestion for a new test (from a reviewer, an adequacy pass, your own sweep, or a "missing test cases" list), **add it** — don't leave it as an "unrequested extra" to ask about. I can remove tests later; more tests is always better than fewer. This applies even when the test is for a branch that was only ported or already existed. It does not extend to production-code changes: a test that needs a behavior change in production code is still an extra to ask about.

## Reviewer findings and "extras"

- To decide what to do with each reviewer finding (fix now, ask, or refactor), load the `triage-reviewer-findings` skill. The rules below are what it applies.

- When a reviewer, smell detector, memory-safety pass or similar — or your own finding while implementing — flags a real defect or robustness gap (unhandled async errors, leaked subscriptions/resources on a failure path, null-bang that can throw, missing disposal, background work with no owner that outlives a failed or disposed start, error swallowed), **fix it right away** with a regression test, in the same change. Don't park it as an "unrequested extra" to ask about.
- "Extras" are reserved for things that **change behavior** or widen scope (new features, changed semantics, different UX, new dependencies, API reshaping). Those still need my yes.
- Refactors that are **related to the task** are fine without asking: e.g. when the task needs a function that does the same as an existing one, extract a shared helper and migrate the existing case too. Unrelated "while I'm here" changes in the same file that don't help reading or the task still need my yes.

## Diagrams

- **Always prefer Mermaid over plain-text (ASCII/box-drawing) code blocks** when drawing diagrams (architecture layers, flows, sequences, state machines, dependency graphs). Use a ```` ```mermaid ```` block instead of a ```` ```text ```` block. Fall back to text only for things Mermaid can't express (e.g. directory trees, literal terminal output).

## Tool preference

- **Always prefer MCP tools over equivalent CLI commands.** If an MCP server exposes a tool that does the same thing as a shell command (e.g. the Dart MCP server's analyze/fix/format/test/pub tools vs. running `dart analyze`(or `puro dart analyze`)/`dart fix`(or `puro dart fix`)/`dart format`(or `puro dart format`)/`dart test -r failures-only`/`dart pub` in Bash), use the MCP tool. Only fall back to the CLI when no MCP equivalent exists or the MCP tool fails.
- **Don't format by hand or fix non-semantic lints yourself while building.** Formatting and lints that don't change meaning (whitespace, ordering, trailing commas, `prefer_const`-style fixes, etc.) are handled by the formatter and `fix` tooling, via the CLI or MCP. Only hand-edit a lint when it needs a real semantic decision the tools can't make.

## Dart MCP server and debugging

- Before the first Dart MCP tool call in a session, set the project roots, and prefer connecting to the already-running app over starting a new debug session: see the `dart-mcp` and `find-dtd-uri` skills.
- To build a Dart executable for another OS (e.g. Windows to Linux/WSL), see the `build-dart-executables` skill.

## Post-edit Dart workflow

- After editing `.dart` files, follow the `dart-edit-protocol` skill before reporting the task done.
