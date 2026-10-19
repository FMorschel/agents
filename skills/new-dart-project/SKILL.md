---
name: new-dart-project
description: Use whenever the user asks to create, scaffold, or set up a new Dart or Flutter project (e.g. "new flutter project", "create a dart package", "scaffold a CLI"). Applies the standard analysis_options.yaml and adds the essential_lints dev dependency.
---

# New Dart / Flutter project setup

Every new Dart or Flutter project gets two things right after it is created:

1. The standard `analysis_options.yaml` bundled next to this skill (`analysis_options.yaml` in this skill's folder). Copy it to the project root, replacing the default one.
2. The `essential_lints` dev dependency, which the analysis options load as an analyzer plugin.

## Steps

1. Create the project as usual (`dart create` or `flutter create`), or work in the folder the user gave you.
2. Copy the bundled file into the project root:
   `cp <skill-dir>/analysis_options.yaml <project-root>/analysis_options.yaml`
   Do not edit its contents; it is the user's standard, not a per-project choice.
3. Add the dev dependency in a single `pub` call:
   - Dart project: `dart pub add dev:essential_lints`
   - Flutter project: `flutter pub add dev:essential_lints`
4. Run `dart analyze` (or `flutter analyze`) once to confirm the plugin loads and the project is clean.

## Notes

- If the project already has an `analysis_options.yaml` that differs, tell the user before overwriting it.
- Prefer the Dart MCP server's `pub` and `analyze_files` tools over the CLI when they are available, per the global tool preference.
- Follow the post-edit Dart workflow (`dart fix --apply`, analyze, format) once the setup is done.
