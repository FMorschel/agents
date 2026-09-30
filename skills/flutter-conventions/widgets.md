## Widget composition

Extract UI into widget classes, never into helper methods.

- Split a large `build` into `StatelessWidget` (or `StatefulWidget`) classes, not `_buildHeader()`-style methods or functions returning `Widget`.
- Why: a widget class can be `const`, gets its own element and rebuild scope (a `setState` or dependency change rebuilds only that subtree), and shows up by name in DevTools. A helper method rebuilds with its parent every time and cannot be `const`.
- Give extracted widgets a `const` constructor whenever their fields allow it, and use `const` at the call site.
- Keep extracted widgets in the same file while they are private to one screen (`_Header`); move them to their own file once reused.
- A method that returns a non-widget value used in `build` (a formatted string, a computed list) is not affected by this rule.
