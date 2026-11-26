---
name: check-ui-surface
description: "Use when a planned or existing UI change adds or changes something a user sees or presses (a button, menu entry, icon, label, dialog, keyboard shortcut, screen) and you must check it for consistency with the app's existing surface: shortcut collisions, icon reuse or drift, label patterns, placement, visibility, duplicate controls. Used by `ui surface agent`; companion to `sweep-app-for-ui-pattern`."
---

## Checking the UI surface

Treat the app's visible surface (buttons, menu items, icons, labels, dialogs, keyboard shortcuts) as an API contract, the way `api-designer` treats signatures. Users learn this surface, and a new piece that breaks the existing pattern costs them. Catch inconsistency before it is built or during review; it also checks a finished change. Stay on what the user sees or presses: code correctness, architecture and business logic belong to other reviews. Report only; do not edit files.

### When to run

Only for a step whose plan adds or changes something a user directly sees or triggers. For a backend, data or logic-only step, say so and stop; don't invent surface concerns. It runs once per qualifying step, after the plan exists and before tests and implementation start, so it checks the *planned* surface. Outside the pipeline it can check a finished change the same way.

### Resolution order (doc-first, `resolve-project-conventions`)

1. An explicit UI/UX spec (style guide, `DESIGN.md`, a keymap or shortcuts doc) is ground truth.
2. Without one, or where it doesn't cover the element, build the inventory from the UI source: widget/view trees, menu and action definitions, shortcut registrations, icon usage. Extract:
   - shortcut → action bindings, per scope (global, screen, dialog);
   - icon → meaning;
   - label patterns for actions of the same kind (verb, tense, capitalization, punctuation);
   - placement conventions (toolbar, overflow, context menu, keyboard only);
   - visibility and enablement conventions (always shown vs. contextual; disabled vs. hidden).

   Flutter starting points: shortcuts (`Shortcuts`, `Actions`, `CallbackShortcuts`, `LogicalKeySet`, `SingleActivator`, menu accelerators); icons (`Icon(`, `IconButton`, icon constants, assets). A key bound in a dialog does not collide with the same key on the screen behind it, but binding one key twice in the same scope is a collision.

   Compare a reasonable number of sibling surfaces: one example is not a pattern. If the examples diverge, mark the aspect "mixed" instead of choosing a side.
3. If neither a doc nor a clear dominant pattern exists, say so rather than asserting a convention.

### What to check

- **Shortcut collisions**: the planned shortcut is already bound to a different action reachable in the same scope.
- **Icon reuse or drift**: the icon is used elsewhere for another action; or an established icon for this exact action exists and should be reused.
- **Label pattern**: verb or noun, capitalization and phrasing match sibling actions ("Delete" vs. "Remove" for the same kind of action).
- **Placement**: matches where similar controls live, not a one-off.
- **Visibility and enablement**: consistent with comparable controls.
- **Duplication**: a new control for something an existing control already does.

### Output format

```
## UI Surface Check

Scope: <step/plan reference, or the change or screen reviewed>
Source of truth: <UI spec doc found | inferred from N sample surfaces | no consistent pattern found>

### Conflicts
- <element> — collides with <existing element> at <location>. Existing: <describe>.

### Consistency gaps
- <element> — doesn't match established <shortcut/icon/label/placement/visibility> pattern. Established: <describe>. Planned: <describe>.

### No consistent pattern for
- <aspect> — the app has no established convention here.

### Clean
- (one line, if nothing found)
```

Call something a conflict only when it is a genuine collision or a clear break from an established pattern you can point to with file paths. A convention inferred from a few ambiguous examples is a question, not a finding. For a check over the whole app, not one planned change, use `sweep-app-for-ui-pattern`.
