---
name: sweep-app-for-ui-pattern
description: "Use when the user asks whether a UI behavior or pattern is applied everywhere in the app ('does every search box clear on escape', 'all dialogs have a cancel button', 'every list shows an empty state'), or after adding it to one place: find every instance in the code, then report each as covered or not. Companion to `check-ui-surface`."
---

## Sweeping the app for a UI pattern

A pattern added to one screen is rarely added everywhere. Enumerate first, then judge each instance.

1. **Define the pattern** in one sentence, with what counts as covered (for example "a search field has a clear button and clears on Escape"). Ask if the definition is ambiguous.
2. **Enumerate every instance** from the code, not from memory: grep for the widget or class (`TextField`, `SearchBar`, `showDialog`, `ListView`), the shared wrapper widgets the project defines, and routes or screens that use them. List the files and lines. Include instances inside shared widgets once, and every screen that uses them.
3. **Judge each instance** as covered, not covered, or not applicable (with a reason). Read the code; don't infer from the widget name.
4. **Report a table**: instance (file:line, the screen it appears on), status, the missing piece. Give the counts (`7 of 11 covered`) and say how the enumeration was done, so gaps in the sweep are visible.
5. **Fix only when asked.** If the user asks for the fix and the same behavior is wanted in every instance, prefer one shared widget or behavior over copying it; apply `ui-steps` in `route-pipeline-cases` for steps that touch UI surface, and `check-ui-surface` for the planned change.
