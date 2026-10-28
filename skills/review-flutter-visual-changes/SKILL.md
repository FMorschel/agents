---
name: review-flutter-visual-changes
description: "Use when reviewing or verifying a Flutter change that affects how a screen looks or lays out (new/edited widgets, theme, spacing, responsive behavior, dark mode) and you need evidence it renders correctly and nothing unrelated changed. Covers: reading the screen's current state through the Dart MCP tools, capturing a baseline by stashing the change, before/after comparison, regression and visual-bug checks (overflow, clipping, contrast, theme, platform, states), and restoring the working tree safely."
---

## Reviewing Flutter visual changes

Code review cannot tell you what a screen looks like. This skill produces evidence: screenshots, widget-tree facts and runtime errors, taken **before** and **after** the change, on the same screen in the same state. Tool details are in `dart-mcp`; test rules are in `write-flutter-ui-tests`.

### 0. Preconditions

- The app must run in debug mode and be reachable over DTD (`find-dtd-uri`, then `dtd` `connect`). If there is no running app, ask for a DTD URI or launch the app as the user's instructions allow; if you can only review statically, say so in the report.
- Register the project roots with `roots` first.
- Identify the **target screens**: every screen that renders a changed widget, not just the one the author named. Use `lsp`/grep to find the changed widgets' usages. When a shared widget changed, every screen using it is a target (list them; sample the ones that differ most).

### 1. Read the current state of the screen (before judging)

With the app on the target screen:

1. `get_runtime_errors` (`clearRuntimeErrors: true` first, then navigate/reproduce, then read again). Layout overflows and build exceptions show up here, not in a screenshot.
2. `widget_inspector` `get_widget_tree` (`summaryOnly: true`) to learn the real widget types, keys and texts. Never guess a finder.
3. `flutter_driver_command` `screenshot`. Add `get_text` / `get_diagnostics_tree` when a number or a constraint matters.
4. Record the **state** the screen is in: route, logged profile/data, theme mode, platform, window size, locale, text scale. The comparison is only valid if every one of these is identical on both sides.

### 2. Baseline vs. change (stash flow)

The point is to prove that only the intended things changed.

1. **Tell the user before touching their tree**, because stashing moves their uncommitted work. Do it only after they agree (or they asked for this review), and never when there are changes you cannot account for.
2. Capture the **after** first: the step 1 screenshots and facts with the change applied, for every target screen and state.
3. `git stash push --include-untracked -m "visual-review baseline"` (new files must go too, otherwise the baseline still contains half the change). Confirm `git status` is clean.
4. `hot_restart` (not `hot_reload`: const and global changes and state need a restart). Re-establish the **same state** from step 1.4 and capture the **before** set the same way.
5. **Restore immediately:** `git stash pop`, confirm `git stash list` no longer has your entry and `git status` matches what you started with. `hot_restart` again. Do this even if a step above failed. A review that leaves the user's changes in the stash is a failed review. Never `stash drop`, `reset --hard`, `clean` or `checkout --` on the user's work.
6. If the change is already committed there is nothing to stash: compare against the parent commit or base branch (a separate worktree if the app can run from it), and say which you used.

### 3. What to compare

Pair every before/after screenshot and ask, for each difference you can see: *is this explained by the change?*

- **Unrelated differences** (a different padding, color, font, an element moved or missing that the change did not touch) are regressions until proven otherwise. A shared widget, theme token or default changing is the usual cause.
- **Missing differences** (the intended change is not visible) mean the change did not apply, or applies in a state you did not reach.
- Compare numbers too, not only pixels: sizes, paddings and text from `get_diagnostics_tree` catch 1-2 px shifts a screenshot hides.

### 4. Visual bug checklist

Check the **after** state against each. Look in the screenshot *and* in `get_runtime_errors`.

| Area | Look for |
|---|---|
| Layout | overflow (striped bars, `RenderFlex overflowed` errors), clipped or truncated text, unbounded constraints, content hidden behind keyboard/app bar/safe area |
| Sizing | tiny tap targets (under 48 dp on touch), elements that do not scale with window size, misalignment against siblings |
| Theme | light **and** dark mode, hard-coded colors that ignore the theme, low contrast, wrong elevation/shape (`flutter-conventions` `theming.md`) |
| Responsive/platform | narrow phone, wide desktop, mobile vs. desktop navigation, orientation; resize and re-check |
| Text | long strings, long translations, large text scale (1.5-2.0), empty and null values |
| States | loading, empty, error, many items, disabled, focused, hovered, pressed, selected. If a screen shows an error state (e.g. failed to load data), do not guess the cause from the screenshot: read the session's `<name>_dap.log` with `find-session-logs` for the actual exception first |
| Interaction | the screen still scrolls, taps hit the intended target, nothing flickers or jumps on rebuild |
| Accessibility | semantics labels on new interactive elements, sensible focus order |
| Consistency | icons, labels and placement match sibling screens (`ui surface agent` covers this in depth) |

Before driving the app to a screen, read `.agents/screens-navigation/` for a known route; if getting there (or to a state) takes real effort, record it per `document-app-navigation`. Reach each state by driving the app (`tap`, `enter_text`, `scroll`, `waitFor`) using finders taken from the tree, not by assuming it works.

Typing: `enter_text` needs the app's `main` to start with `enableFlutterDriverExtension(enableTextEntryEmulation: false);` and `flutter_driver_command` `set_text_entry_emulation` `enabled: "true"` called first. When you are done typing, and always before you finish the review, call it with `enabled: "false"` so the developer can type with their own keyboard again (see `dart-mcp`).

### 5. Test coverage of the change

State whether the change is guarded: a widget test for behavior and a golden test for appearance where the look must stay stable (rules in `write-flutter-ui-tests`). Run the existing tests that touch the changed widgets (`flutter test <paths>`; there is no MCP tool for it) and report failures verbatim. A golden that fails after an *unintended* difference is a finding; do not update goldens to make it pass. Use `flutter test --update-goldens` only for differences you confirmed are intended, and list which goldens changed.

### 6. Report

One section per target screen: state used, what changed (intended), what changed (unintended), bugs found with the evidence (screenshot, error text, widget path), states not reached and why, and the git state at the end ("stash restored, tree identical to start"). Report what the tools returned, not what you expect: if `get_runtime_errors` was silent, say it was silent. Do not call something a bug that you cannot point to on screen, in the tree or in an error.
