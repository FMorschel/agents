---
name: document-app-navigation
description: "Use whenever you drive a running app (taps, scrolls, text entry, waits through the Dart MCP driver or any UI automation) to reach a specific screen or state. Read `.agents/screens-navigation/` first for a known route; if you had to struggle to get somewhere (wrong turns, hidden menus, required data, waits, dead ends), write or update a markdown note there so later agents and sessions do not repeat the search."
---

## Documenting how to reach a screen

Finding a screen by trial and error costs many tool calls, and the next session pays the same cost again. The notes in `.agents/screens-navigation/` (at the root of the project being driven) are the shared memory for that. Applies with `dart-mcp` (driver tools) and `review-flutter-visual-changes`.

### 1. Look before you navigate

Before the first tap, list `.agents/screens-navigation/` and read the note for your target screen (or the closest one: a note for a parent screen often covers the first steps). Follow it, and verify each step on screen rather than trusting it blindly. If a step no longer works, the note is stale: fix it (section 3).

### 2. When to write a note

Write one when reaching the screen took you more than a couple of attempts or any of these happened:

- you tried a path that led nowhere, or a control was hidden (drawer, overflow menu, long-press, scroll-to-reveal, a desktop-only or mobile-only entry);
- the screen needs a precondition: logged-in profile, seeded data, a feature flag, a setting, an earlier flow completed, a particular window size or platform;
- a step needed a specific wait, a scroll, or a finder that is not obvious (a key that only exists in one state, a label that changes);
- you found the shortest working route after longer ones failed.

Do not write notes for screens that were reached on the first obvious path; an index of trivial routes is noise. Write the note as soon as you succeed, while the dead ends are fresh, even if the task you were on is not finished.

### 3. File format

One file per target screen or state, named after it in kebab-case (`order-picking-detail.md`). Keep an `index.md` with one line per note (screen, file) so the folder can be scanned in one read; add the line when you add a note.

```markdown
# <Screen or state name>

Route / widget: <route name or page class, and the key to wait for>
Platforms and size: <where this route exists, window size or orientation if it matters>

## Preconditions
- <profile, data, flags, settings needed; describe how to create them, never include real credentials>

## Steps
1. <action> using <finder: key / text / tooltip / type> -> <what you should see, the key to wait for>
2. ...

## Pitfalls
- <dead end you hit and why it fails, hidden controls, needed waits, state that breaks the route>

## Verified
<date>, <platform and size>, <how: driver commands via DTD / integration test helper>
```

Rules for the content:

- Use finders from the widget tree (`ByValueKey`, `ByText`, `ByTooltipMessage`, `BySemanticsLabel`); quote them exactly. Prefer keys over visible text, since text changes with data and locale.
- Say what confirms each step worked, so the next agent notices a wrong turn immediately.
- State the preconditions and how to satisfy them (test profile, seed data location, the step that creates it). Never write passwords, tokens or real customer data into a note; point to where the project keeps its test fixtures.
- Keep it short and imperative. Describe the route, not the screen's design.
- If the project already has a helper that gets there (an integration test step helper, a deep link, a debug route), name it first: that beats a manual tap list.

### 4. Keep notes true

- When you follow a note and a step fails, fix or replace that step and update **Verified**. A wrong note is worse than none.
- If a route changed because of the change you are working on, update the note in the same change.
- Delete a note when its screen no longer exists, and remove its line from `index.md`.
- Create the folder if it is missing. These files are project knowledge: commit them with the project's normal change, not separately from it, and only when the user's git workflow allows committing.

### 5. Report

When you wrote or changed a note, say so in one line with the file name, so the user can review it.
