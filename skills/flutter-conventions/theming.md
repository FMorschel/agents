## Theming and styling

Draft defaults; adjust to the project's own design system if it has one (`resolve-project-conventions`).

- No hardcoded colors, text styles or font sizes in widgets: read them from `Theme.of(context)` (`colorScheme`, `textTheme`) or from a project `ThemeExtension`.
- Repeated spacing, radii and durations come from named constants (or a `ThemeExtension`), not magic numbers scattered through `build`.
- Derive variants from the theme (`textTheme.bodyMedium?.copyWith(...)`, `colorScheme.primary.withValues(alpha: ...)`) instead of defining a parallel palette.
- Per `state.md`, cache `Theme.of(context)` in `didChangeDependencies` when a `State` uses it in several places; in a `StatelessWidget`, a single `final theme = Theme.of(context);` at the top of `build` is fine.
