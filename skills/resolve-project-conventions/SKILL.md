---
name: resolve-project-conventions
description: "Use whenever you need to know how *this project* does something — doc comment style, layer names and boundaries, commit message format, UI shortcut/icon/label patterns, file naming — before judging or writing code. Defines the shared doc-first lookup: explicit doc, else a sample of 5–10 files, else say there is no consistent pattern."
---

## Resolving a project convention

Agents here check or follow *this project's* patterns, never an external style guide or personal preference. This skill is the one lookup procedure they all share. Apply it per aspect (comment style, layer names, commit format, …), not once for the whole project — a doc can cover one aspect and be silent on another.

### Resolution order

1. **Explicit doc — ground truth.** Look for it by topic:

   | Aspect | Look for |
   |---|---|
   | Code style, comments, naming, imports | `CONVENTIONS.md`, `STYLE.md`, a section of `architecture.md`, `analysis_options.yaml`, `CLAUDE.md` / `AGENTS.md` |
   | Layers and boundaries | `architecture.md` (or equivalent), the PRD's architecture section; if none, the `layered-architecture` skill is the default (use it only where the code's structure actually fits it) |
   | Commit messages | `CONTRIBUTING.md`, `.gitmessage` / commit template, `commitlint` config |
   | UI surface (shortcuts, icons, labels, placement) | `DESIGN.md`, a UX/style guide, a keymap/shortcuts doc |
   | Releases | `CHANGELOG.md` header conventions, `pubspec.yaml`, release docs |

   If it exists and covers the aspect, use it and stop. Do not "improve" on it.

2. **Sample the code — fallback.** If there is no doc, or it is silent on this aspect, read **5–10 representative files** from the *relevant directory* (same layer, same kind of file; not the whole repo) — for commits, `git log` over the last 20–30 non-merge commits. Find the dominant pattern. Only a deviation from *that* is a finding; deviation from general Dart practice is not.
   - Sample across files by different authors or dates when you can; five files from one afternoon is one data point.
   - Weigh recent code over old when they disagree and the recent code looks deliberate.
   - Ignore generated files (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`, `*.cristallyse.dart`), vendored code and tests when inferring production style, and vice versa.

3. **No clear signal — say so.** If the sample is genuinely mixed (no arm above roughly 55%), report "no consistent pattern for <aspect>" and do **not** pick a side or flag deviations. In an authoring role, use the closest existing category and note the mismatch instead of inventing a new convention unilaterally.

### Always report the source of truth

State which step resolved it, in one line, so the reader can judge the strength of the finding:

```
Source of truth: <CONVENTIONS.md found | inferred from N sample files in <dir> | no consistent pattern found>
```

When *inferring*, say so explicitly ("inferring the layers from directory names; no `architecture.md` found") — inferred conventions are weaker evidence than documented ones, and findings built on them are questions rather than violations.

### Confidence rules for findings

- **Documented convention, clear breach** → a finding.
- **Inferred convention, clear dominant pattern** → a finding, marked as inferred.
- **Inferred, ambiguous or thin sample** → a question ("does this project forbid X?"), never a violation.
- A style deviation is never "wrong" if `dart analyze` / `dart format` are silent; it is inconsistent. See the `dart-edit-protocol` skill's epistemic rule.

### Applying it when you are the one writing

Authoring agents (`implementer`, `api doc writer`, `commit composer`) run the same lookup *before* writing, and check for an existing `convention agent` finding for the repo first — defer to it rather than re-inferring. When a change does not cleanly fit the convention (a commit type the format has no prefix for, a symbol kind with no doc precedent), ask in human-gated mode; in autonomous mode use the closest category and note the mismatch in your output.
